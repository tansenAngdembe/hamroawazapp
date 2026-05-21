import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class VerificationRequiredPanel extends StatelessWidget {
  const VerificationRequiredPanel({
    super.key,
    required this.onUploadDocuments,
    this.isPendingApproval = false,
  });

  final VoidCallback onUploadDocuments;
  final bool isPendingApproval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPendingApproval ? Icons.hourglass_top : Icons.verified_user_outlined,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                isPendingApproval
                    ? 'Verification pending approval'
                    : 'Verification required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isPendingApproval
                    ? 'Your documents were submitted. An administrator will review them shortly. You can create complaints once your account is verified.'
                    : 'Your account must be verified before creating complaints.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isPendingApproval)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onUploadDocuments,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Documents'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: onUploadDocuments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check verification status'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
