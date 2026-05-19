import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(String email) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Support Request - HamroAwaz App',
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _launchPhone(String phone) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: 'How do I file a complaint?',
            answer:
                'Tap the "Create Complaint" button on the home screen, fill in the details, add photos if needed, and submit. You can track the status in the "My Complaints" section.',
          ),
          _buildFAQItem(
            question: 'How long does it take to resolve a complaint?',
            answer:
                'Response time varies depending on the type of complaint. Most complaints are acknowledged within 24-48 hours, and resolution typically takes 3-7 business days.',
          ),
          _buildFAQItem(
            question: 'Can I edit or delete my complaint?',
            answer:
                'You can edit your complaint if it\'s still pending. Once it\'s under review or resolved, you cannot edit it. Contact support if you need to make changes.',
          ),
          _buildFAQItem(
            question: 'How do I track my complaint status?',
            answer:
                'Go to "My Complaints" section to see all your complaints with their current status. You\'ll receive notifications when the status changes.',
          ),
          const Divider(height: 32),
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@hamroawaz.com',
            onTap: () => _launchEmail('support@hamroawaz.com'),
          ),
          _buildContactItem(
            icon: Icons.phone,
            title: 'Phone Support',
            subtitle: '+977 1-1234567',
            onTap: () => _launchPhone('+97711234567'),
          ),
          _buildContactItem(
            icon: Icons.access_time,
            title: 'Support Hours',
            subtitle: 'Monday - Friday: 9:00 AM - 5:00 PM',
            onTap: null,
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Need Immediate Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For urgent matters, please call our emergency support line or visit our office during business hours.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}

