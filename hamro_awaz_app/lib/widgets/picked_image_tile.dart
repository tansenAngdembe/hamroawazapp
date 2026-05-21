import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageTile extends StatelessWidget {
  const PickedImageTile({
    super.key,
    required this.label,
    required this.file,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onClear,
  });

  final String label;
  final File? file;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (file != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
              ),
            ),
            if (file != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: 'Remove',
              ),
            ],
          ],
        ),
      ],
    );
  }

  static Future<File?> pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }
}
