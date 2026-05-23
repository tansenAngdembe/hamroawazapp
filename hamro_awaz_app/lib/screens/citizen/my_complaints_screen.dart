import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/complaint_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/complaint.dart';
import '../../models/search_param.dart';
import '../../services/complaint_service.dart';
import 'create_complaint_screen.dart';
import 'edit_complaint_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  List<Complaint> _complaints = [];
  int _total = 0;
  bool _isLoading = true;
  String? _error;
  ComplaintStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  SearchParam _buildSearchParam() {
    if (_selectedFilter == null) {
      return SearchParam.defaults(pageSize: 50);
    }
    return SearchParam.withStatus(
      complaintStatusToApiParam(_selectedFilter!),
      pageSize: 50,
    );
  }

  Future<void> _loadComplaints() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final complaintService = context.read<ComplaintService>();
      final page = await complaintService.listMyComplaints(
        searchParam: _buildSearchParam(),
      );

      if (!mounted) return;
      setState(() {
        _complaints = page.records;
        _total = page.total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _complaints = [];
        _total = 0;
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onFilterSelected(ComplaintStatus? status) {
    setState(() => _selectedFilter = status);
    _loadComplaints();
  }

  Future<void> _openEditComplaint(Complaint complaint) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditComplaintScreen(complaint: complaint),
      ),
    );
    if (updated == true && mounted) {
      _loadComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          if (_total > 0 && !_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_total total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('New', ComplaintStatus.pending),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Progress', ComplaintStatus.inProgress),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved', ComplaintStatus.resolved),
                  const SizedBox(width: 8),
                  _buildFilterChip('Escalated', ComplaintStatus.escalated),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComplaints,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SkeletonLoader(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadComplaints,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_complaints.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.description_outlined,
            title: 'No Complaints',
            message: _selectedFilter == null
                ? 'You haven\'t created any complaints yet'
                : 'No complaints with this status',
            actionLabel: _selectedFilter == null ? 'Create Complaint' : null,
            onAction: _selectedFilter == null
                ? () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const CreateComplaintScreen(),
                          ),
                        )
                        .then((_) => _loadComplaints());
                  }
                : null,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final complaint = _complaints[index];
        return ComplaintCard(
          complaint: complaint,
          enableComments: true,
          onEdit: () => _openEditComplaint(complaint),
          onVoteYes: () => _handleVote(complaint.id, true),
          onVoteNo: () => _handleVote(complaint.id, false),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ComplaintStatus? status) {
    final isSelected = _selectedFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onFilterSelected(selected ? status : null);
      },
    );
  }

  Future<void> _handleVote(String complaintId, bool isYes) async {
    final complaintService = context.read<ComplaintService>();
    await complaintService.voteComplaint(complaintId, '', isYes);
    _loadComplaints();
  }
}
