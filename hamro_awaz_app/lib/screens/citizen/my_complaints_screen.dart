import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/complaint_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
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
  bool _isLoading = true;
  ComplaintStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final complaintService = context.read<ComplaintService>();
      final user = await auth.getStoredUser();
      final uid = user?.id ?? '';

      final complaints = await complaintService.getComplaints(uid);

      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _complaints = [];
        _isLoading = false;
      });
    }
  }

  List<Complaint> get _filteredComplaints {
    if (_selectedFilter == null) return _complaints;
    return _complaints.where((c) => c.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
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
                  _buildFilterChip('Pending', ComplaintStatus.pending),
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
              child: _isLoading
                  ? ListView.builder(
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
                    )
                  : _filteredComplaints.isEmpty
                      ? EmptyState(
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _filteredComplaints[index];
                            return ComplaintCard(
                              complaint: complaint,
                              onTap: () {
                                _showComplaintDetails(complaint);
                              },
                              onVoteYes: () {
                                _handleVote(complaint.id, true);
                              },
                              onVoteNo: () {
                                _handleVote(complaint.id, false);
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ComplaintStatus? status) {
    final isSelected = _selectedFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
    );
  }

  void _showComplaintDetails(Complaint complaint) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  complaint.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  complaint.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Category', complaint.categoryName),
                _buildDetailRow('Department', complaint.department),
                _buildDetailRow('Status', complaint.statusName),
                if (complaint.address != null)
                  _buildDetailRow('Location', complaint.address!),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit complaint'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final updated = await Navigator.of(parentContext).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditComplaintScreen(complaint: complaint),
                      ),
                    );
                    if (updated == true && mounted) {
                      _loadComplaints();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVote(String complaintId, bool isYes) async {
    final auth = context.read<AuthService>();
    final complaintService = context.read<ComplaintService>();
    final user = await auth.getStoredUser();
    final uid = user?.id ?? '';
    await complaintService.voteComplaint(complaintId, uid, isYes);
    _loadComplaints();
  }
}

