import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/complaint_card.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import 'create_complaint_screen.dart';
import 'my_complaints_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Complaint> _recentComplaints = [];
  bool _isLoading = true;
  
  int _totalComplaints = 0;
  int _resolvedComplaints = 0;
  int _inProgressComplaints = 0;
  int _escalatedComplaints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final complaintsService = context.read<ComplaintService>();
      final user = await auth.getStoredUser();
      final uid = user?.id ?? '';
      final complaints = await complaintsService.getComplaints(uid);

      if (!mounted) return;
      setState(() {
        _recentComplaints = complaints.take(3).toList();
        _totalComplaints = complaints.length;
        _resolvedComplaints =
            complaints.where((c) => c.status == ComplaintStatus.resolved).length;
        _inProgressComplaints =
            complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
        _escalatedComplaints =
            complaints.where((c) => c.status == ComplaintStatus.escalated).length;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Stats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.05,
                        children: [
                          StatCard(
                            title: 'Total',
                            value: '$_totalComplaints',
                            icon: Icons.description,
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MyComplaintsScreen(),
                                ),
                              );
                            },
                          ),
                          StatCard(
                            title: 'Resolved',
                            value: '$_resolvedComplaints',
                            icon: Icons.check_circle,
                            color: AppColors.success,
                          ),
                          StatCard(
                            title: 'In Progress',
                            value: '$_inProgressComplaints',
                            icon: Icons.hourglass_empty,
                            color: AppColors.inProgress,
                          ),
                          StatCard(
                            title: 'Escalated',
                            value: '$_escalatedComplaints',
                            icon: Icons.priority_high,
                            color: AppColors.escalated,
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Complaints',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyComplaintsScreen(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_recentComplaints.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('No complaints yet'),
                        ),
                      )
                    else
                      ..._recentComplaints.map(
                        (complaint) => ComplaintCard(
                          complaint: complaint,
                          onTap: () {
                            // Navigate to complaint details
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateComplaintScreen(),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Complaint'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}

