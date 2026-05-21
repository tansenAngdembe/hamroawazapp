import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/nepal_location_data.dart';
import '../../models/location_option.dart';
import '../../models/upload_document_request.dart';
import '../../models/user_profile.dart';
import '../../repositories/document_repository.dart';
import '../../repositories/user_profile_repository.dart';
import '../../widgets/picked_image_tile.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _citizenshipController = TextEditingController();
  final _nidController = TextEditingController();

  LocationOption? _province;
  LocationOption? _district;
  List<LocationOption> _districts = [];

  File? _frontImage;
  File? _backImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _citizenshipController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickFront(ImageSource source) async {
    final file = await PickedImageTile.pick(source);
    if (file != null && mounted) setState(() => _frontImage = file);
  }

  Future<void> _pickBack(ImageSource source) async {
    final file = await PickedImageTile.pick(source);
    if (file != null && mounted) setState(() => _backImage = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_province == null || _district == null) {
      _showSnack('Please select province and district', isError: true);
      return;
    }
    if (_frontImage == null || _backImage == null) {
      _showSnack('Please upload both citizenship images', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final docRepo = context.read<DocumentRepository>();
      final profileRepo = context.read<UserProfileRepository>();

      final request = UploadDocumentRequest(
        citizenShipNumber: _citizenshipController.text.trim(),
        nationalIdentityNumber: _nidController.text.trim(),
        provinceUniqueId: _province!.uniqueId,
        districtUniqueId: _district!.uniqueId,
      );

      final uploadResult = await docRepo.uploadDocuments(
        request: request,
        citizenshipFront: _frontImage!,
        citizenshipBack: _backImage!,
      );

      if (!mounted) return;

      if (!uploadResult.success) {
        _showSnack(uploadResult.message, isError: true);
        return;
      }

      _showSnack(uploadResult.message, isError: false);

      final profileResult = await profileRepo.fetchProfile();
      if (!mounted) return;

      if (profileResult.success && profileResult.data != null) {
        final profile = profileResult.data!;
        if (profile.isUserVerified) {
          Navigator.of(context).pop<DocumentUploadResult>(
            DocumentUploadResult.verified(profile),
          );
          return;
        }
        Navigator.of(context).pop<DocumentUploadResult>(
          DocumentUploadResult.pending(profile),
        );
        return;
      }

      Navigator.of(context).pop<DocumentUploadResult>(
        DocumentUploadResult.pending(null),
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Upload failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
      ),
      body: AbsorbPointer(
        absorbing: _isUploading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Citizenship verification',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload clear photos of your citizenship (front and back).',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _citizenshipController,
                      decoration: const InputDecoration(
                        labelText: 'Citizenship Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Citizenship number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nidController,
                      decoration: const InputDecoration(
                        labelText: 'National Identity Number',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'National ID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LocationOption>(
                      value: _province,
                      decoration: const InputDecoration(
                        labelText: 'Province',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: NepalLocationData.provinces
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: _isUploading
                          ? null
                          : (v) {
                              setState(() {
                                _province = v;
                                _district = null;
                                _districts = v == null
                                    ? []
                                    : NepalLocationData.districtsForProvince(
                                        v.uniqueId,
                                      );
                              });
                            },
                      validator: (v) => v == null ? 'Select a province' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LocationOption>(
                      value: _district,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      items: _districts
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name),
                            ),
                          )
                          .toList(),
                      onChanged: _isUploading || _province == null
                          ? null
                          : (v) => setState(() => _district = v),
                      validator: (v) => v == null ? 'Select a district' : null,
                    ),
                    const SizedBox(height: 24),
                    PickedImageTile(
                      label: 'Citizenship — front',
                      file: _frontImage,
                      onPickCamera: () => _pickFront(ImageSource.camera),
                      onPickGallery: () => _pickFront(ImageSource.gallery),
                      onClear: () => setState(() => _frontImage = null),
                    ),
                    const SizedBox(height: 20),
                    PickedImageTile(
                      label: 'Citizenship — back',
                      file: _backImage,
                      onPickCamera: () => _pickBack(ImageSource.camera),
                      onPickGallery: () => _pickBack(ImageSource.gallery),
                      onClear: () => setState(() => _backImage = null),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit documents'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Result returned to [CreateComplaintScreen] after document upload flow.
class DocumentUploadResult {
  const DocumentUploadResult._({required this.verified, this.profile});

  factory DocumentUploadResult.verified(UserProfile profile) =>
      DocumentUploadResult._(verified: true, profile: profile);

  factory DocumentUploadResult.pending(UserProfile? profile) =>
      DocumentUploadResult._(verified: false, profile: profile);

  final bool verified;
  final UserProfile? profile;
}
