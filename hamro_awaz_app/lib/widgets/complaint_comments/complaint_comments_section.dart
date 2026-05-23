import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/comment_models.dart';
import '../../repositories/comment_repository.dart';
import '../../services/auth_service.dart';
import 'comment_bubble.dart';
import 'comment_input_dialog.dart';

/// Expandable comments block for a single complaint (create / view / edit / delete).
class ComplaintCommentsSection extends StatefulWidget {
  const ComplaintCommentsSection({
    super.key,
    required this.complaintUniqueId,
    this.expanded = false,
    this.onExpansionChanged,
  });

  final String complaintUniqueId;
  final bool expanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ComplaintCommentsSection> createState() =>
      _ComplaintCommentsSectionState();
}

class _ComplaintCommentsSectionState extends State<ComplaintCommentsSection>
    with SingleTickerProviderStateMixin {
  List<ComplaintComment> _comments = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _currentUserId;
  String? _currentUserPhone;
  late bool _expanded;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    if (_expanded) {
      _animController.value = 1;
      _loadComments();
    }
    _resolveCurrentUser();
  }

  @override
  void didUpdateWidget(ComplaintCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      setExpanded(widget.expanded);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentUser() async {
    final user = await context.read<AuthService>().getStoredUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = user?.id ?? '';
      _currentUserPhone = user?.phone ?? '';
    });
  }

  void setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() => _expanded = value);
    widget.onExpansionChanged?.call(value);
    if (value) {
      _animController.forward();
      if (!_loaded) _loadComments();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _loadComments() async {
    if (widget.complaintUniqueId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = context.read<CommentRepository>();
    final result = await repo.viewComments(
      ViewCommentsRequest(complaintUniqueId: widget.complaintUniqueId),
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loaded = true;
      if (result.success) {
        _comments = result.data ?? [];
        _error = null;
      } else {
        _comments = [];
        _error = result.message;
      }
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final message = await showCommentInputDialog(
      context: context,
      title: 'Add comment',
      submitLabel: 'Send',
    );
    if (message == null || !mounted) return;

    setState(() => _loading = true);
    final repo = context.read<CommentRepository>();
    final result = await repo.createComment(
      CreateCommentRequest(
        message: message,
        complaintUniqueId: widget.complaintUniqueId,
      ),
    );

    if (!mounted) return;
    if (result.success) {
      _showSnack(result.message);
      if (!_expanded) setExpanded(true);
      await _loadComments();
    } else {
      setState(() => _loading = false);
      _showSnack(result.message, isError: true);
    }
  }

  Future<void> _editComment(ComplaintComment comment) async {
    final message = await showCommentInputDialog(
      context: context,
      title: 'Edit comment',
      initialMessage: comment.message,
      submitLabel: 'Update',
    );
    if (message == null || !mounted) return;

    setState(() => _loading = true);
    final repo = context.read<CommentRepository>();
    final result = await repo.updateComment(
      UpdateCommentRequest(
        message: message,
        complaintUniqueId: widget.complaintUniqueId,
        commentUniqueId: comment.uniqueId,
      ),
    );

    if (!mounted) return;
    if (result.success) {
      _showSnack(result.message);
      await _loadComments();
    } else {
      setState(() => _loading = false);
      _showSnack(result.message, isError: true);
    }
  }

  Future<void> _confirmDelete(ComplaintComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final repo = context.read<CommentRepository>();
    final result = await repo.deleteComment(
      DeleteCommentRequest(
        complaintUniqueId: widget.complaintUniqueId,
        commentUniqueId: comment.uniqueId,
      ),
    );

    if (!mounted) return;
    if (result.success) {
      _showSnack(result.message);
      await _loadComments();
    } else {
      setState(() => _loading = false);
      _showSnack(result.message, isError: true);
    }
  }

  bool _isOwnComment(ComplaintComment c) {
    final uid = _currentUserId;
    if (uid != null &&
        uid.isNotEmpty &&
        c.commentBy.uniqueId.isNotEmpty &&
        c.commentBy.uniqueId == uid) {
      return true;
    }
    final phone = _currentUserPhone;
    final authorPhone = c.commentBy.phoneNumber;
    if (phone != null &&
        phone.isNotEmpty &&
        authorPhone != null &&
        authorPhone.isNotEmpty &&
        phone == authorPhone) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _expandAnim,
      axisAlignment: -1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Comments (${_loaded ? _comments.length : '…'})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loading ? null : _loadComments,
                  ),
                ],
              ),
              if (_loading && !_loaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _loadComments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No comments available',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: RefreshIndicator(
                    onRefresh: _loadComments,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final c = _comments[index];
                        final own = _isOwnComment(c);
                        return CommentBubble(
                          comment: c,
                          isOwnComment: own,
                          onEdit: own ? () => _editComment(c) : null,
                          onDelete: own ? () => _confirmDelete(c) : null,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens add-comment dialog (used from comment icon on card).
  Future<void> openAddCommentDialog() => _openCreateDialog();
}

/// Wraps a complaint card with expansion + comment actions.
class ComplaintCommentsHost extends StatefulWidget {
  const ComplaintCommentsHost({
    super.key,
    required this.complaintUniqueId,
    required this.child,
    this.onComplaintTap,
    this.onEdit,
  });

  final String complaintUniqueId;
  final Widget child;
  final VoidCallback? onComplaintTap;
  final VoidCallback? onEdit;

  @override
  State<ComplaintCommentsHost> createState() => _ComplaintCommentsHostState();
}

class _ComplaintCommentsHostState extends State<ComplaintCommentsHost> {
  final GlobalKey<_ComplaintCommentsSectionState> _commentsKey =
      GlobalKey<_ComplaintCommentsSectionState>();
  bool _expanded = false;

  void _toggleExpansion() {
    setState(() => _expanded = !_expanded);
    _commentsKey.currentState?.setExpanded(_expanded);
    widget.onComplaintTap?.call();
  }

  void _onCommentIconPressed() {
    if (!_expanded) {
      setState(() => _expanded = true);
      _commentsKey.currentState?.setExpanded(true);
    }
    _commentsKey.currentState?.openAddCommentDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _toggleExpansion,
              behavior: HitTestBehavior.opaque,
              child: widget.child,
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onEdit != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: widget.onEdit,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 22,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Material(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _onCommentIconPressed,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ComplaintCommentsSection(
          key: _commentsKey,
          complaintUniqueId: widget.complaintUniqueId,
          expanded: _expanded,
          onExpansionChanged: (v) {
            if (_expanded != v) setState(() => _expanded = v);
          },
        ),
      ],
    );
  }
}
