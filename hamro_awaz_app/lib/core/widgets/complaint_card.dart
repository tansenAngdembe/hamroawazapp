import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import 'status_chip.dart';
import '../../models/complaint.dart';
import '../../widgets/complaint_comments/complaint_comments_section.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback? onTap;
  final VoidCallback? onVoteYes;
  final VoidCallback? onVoteNo;
  final bool enableComments;
  final VoidCallback? onEdit;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
    this.onVoteYes,
    this.onVoteNo,
    this.enableComments = true,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: enableComments ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (complaint.isOwnSubmission) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('Yours', style: TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                  ],
                  const SizedBox(width: 8),
                  StatusChip(status: complaint.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    complaint.categoryName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.department,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (onVoteYes != null && onVoteNo != null)
                    _buildVoteButtons(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (enableComments && complaint.id.isNotEmpty) {
      return ComplaintCommentsHost(
        complaintUniqueId: complaint.id,
        onComplaintTap: onTap,
        onEdit: onEdit,
        child: card,
      );
    }

    return card;
  }

  Widget _buildVoteButtons(BuildContext context) {
    if (complaint.userHasVoted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (complaint.userVote == 'yes'
                  ? AppColors.success
                  : AppColors.error)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              complaint.userVote == 'yes' ? Icons.thumb_up : Icons.thumb_down,
              size: 14,
              color: complaint.userVote == 'yes'
                  ? AppColors.success
                  : AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Voted ${complaint.userVote == 'yes' ? 'Yes' : 'No'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: complaint.userVote == 'yes'
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onVoteYes,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_up, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  '${complaint.yesVotes}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onVoteNo,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_down, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '${complaint.noVotes}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
