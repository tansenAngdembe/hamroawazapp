import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';

class EditComplaintScreen extends StatefulWidget {
  const EditComplaintScreen({super.key, required this.complaint});

  final Complaint complaint;

  @override
  State<EditComplaintScreen> createState() => _EditComplaintScreenState();
}

class _EditComplaintScreenState extends State<EditComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _municipalityController;
  late final TextEditingController _photoUrlController;
  File? _newPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.complaint;
    _titleController = TextEditingController(text: c.title);
    _descriptionController = TextEditingController(text: c.description);
    _municipalityController = TextEditingController(text: c.department);
    _photoUrlController = TextEditingController(
      text: c.imageUrls.isNotEmpty ? c.imageUrls.first : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _municipalityController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newPhoto = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<ComplaintService>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final desc = _descriptionController.text;
    if (desc.isNotEmpty && desc.length < 20) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Description must be at least 20 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await service.updateComplaint(
        complaintUniqueId: widget.complaint.id,
        complaintTitle: _titleController.text.trim(),
        complaintDescription: desc.isEmpty ? null : desc,
        municipality: _municipalityController.text.trim().isEmpty
            ? null
            : _municipalityController.text.trim(),
        photoUrl: _photoUrlController.text.trim().isEmpty
            ? null
            : _photoUrlController.text.trim(),
        categoryId: widget.complaint.categoryIdStr ?? widget.complaint.category.apiCategoryId,
        photoFile: _newPhoto,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Updated'),
            backgroundColor: AppColors.success,
          ),
        );
        nav.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Update failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (min 20 characters if changed)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (v.length < 20) return 'At least 20 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _municipalityController,
                decoration: const InputDecoration(
                  labelText: 'Municipality',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Photo URL (optional)',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(_newPhoto == null ? 'Replace photo (upload)' : 'Photo selected'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
