import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Introduction',
              content:
                  'HamroAwaz ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              title: '2. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n• Personal Information: Name, email address, phone number\n• Complaint Data: Details of complaints you file, including location, description, and photos\n• Device Information: Device type, operating system, unique device identifiers\n• Usage Data: How you interact with the app, features used, and time spent',
            ),
            _buildSection(
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n• Process and manage your complaints\n• Communicate with you about your complaints\n• Improve our services and user experience\n• Send you important updates and notifications\n• Ensure the security and integrity of our platform\n• Comply with legal obligations',
            ),
            _buildSection(
              title: '4. Information Sharing',
              content:
                  'We may share your information with:\n\n• Local authorities and government agencies to process your complaints\n• Service providers who assist us in operating the app\n• Law enforcement when required by law\n• We do not sell your personal information to third parties',
            ),
            _buildSection(
              title: '5. Data Security',
              content:
                  'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
            ),
            _buildSection(
              title: '6. Your Rights',
              content:
                  'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your data\n• Object to processing of your data\n• Data portability\n• Withdraw consent at any time',
            ),
            _buildSection(
              title: '7. Location Data',
              content:
                  'We collect location data to accurately report the location of complaints. You can control location permissions through your device settings. Location data is only used for complaint processing and is not shared with unauthorized parties.',
            ),
            _buildSection(
              title: '8. Cookies and Tracking',
              content:
                  'We may use cookies and similar tracking technologies to track activity on our app and hold certain information. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent.',
            ),
            _buildSection(
              title: '9. Children\'s Privacy',
              content:
                  'Our app is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
            ),
            _buildSection(
              title: '10. Changes to This Policy',
              content:
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            _buildSection(
              title: '11. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@hamroawaz.com\nPhone: +977 1-1234567\nAddress: [Your Address Here]',
            ),
            const SizedBox(height: 32),
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'By using HamroAwaz, you agree to the collection and use of information in accordance with this policy.',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

