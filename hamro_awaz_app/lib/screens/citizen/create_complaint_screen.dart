import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/create_complaint_request.dart';
import '../../models/user_profile.dart';
import '../../repositories/complaint_repository.dart';
import '../../repositories/user_profile_repository.dart';
import '../../services/complaint_service.dart';
import '../../services/location_service.dart';
import '../../widgets/picked_image_tile.dart';
import '../../widgets/verification_required_panel.dart';
import 'document_upload_screen.dart';

enum _CreateComplaintPhase {
  loadingProfile,
  unverified,
  pendingApproval,
  verifiedForm,
  profileError,
}

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  _CreateComplaintPhase _phase = _CreateComplaintPhase.loadingProfile;
  String? _profileError;
  UserProfile? _profile;
  bool _documentsSubmitted = false;

  List<Category> _categories = [];
  bool _categoriesLoading = true;
  String? _categoriesError;
  Category? _selectedCategory;
  File? _photo;
  bool _isSubmitting = false;
  bool _isResolvingLocation = false;
  String? _locationStatus;
  ComplaintCoordinates? _coordinates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });

    try {
      final complaintService = context.read<ComplaintService>();
      final categories = await complaintService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
        if (_selectedCategory != null &&
            !_categories.any((c) => c.uniqueId == _selectedCategory!.uniqueId)) {
          _selectedCategory = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _phase = _CreateComplaintPhase.loadingProfile;
      _profileError = null;
    });

    try {
      final repo = context.read<UserProfileRepository>();
      final result = await repo.fetchProfile();

      if (!mounted) return;

      if (!result.success || result.data == null) {
        setState(() {
          _phase = _CreateComplaintPhase.profileError;
          _profileError = result.message;
        });
        return;
      }

      final profile = result.data!;
      _profile = profile;

      if (profile.isUserVerified) {
        setState(() => _phase = _CreateComplaintPhase.verifiedForm);
        _resolveLocation();
      } else if (_documentsSubmitted) {
        setState(() => _phase = _CreateComplaintPhase.pendingApproval);
      } else {
        setState(() => _phase = _CreateComplaintPhase.unverified);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _CreateComplaintPhase.profileError;
        _profileError = e.toString();
      });
    }
  }

  Future<void> _openDocumentUpload() async {
    final result = await Navigator.of(context).push<DocumentUploadResult>(
      MaterialPageRoute(builder: (_) => const DocumentUploadScreen()),
    );

    if (!mounted || result == null) return;

    _documentsSubmitted = true;
    if (result.profile != null) {
      _profile = result.profile;
    }

    if (result.verified) {
      setState(() => _phase = _CreateComplaintPhase.verifiedForm);
      _resolveLocation();
      _showSnack('Account verified. You can create complaints.', isError: false);
    } else {
      setState(() => _phase = _CreateComplaintPhase.pendingApproval);
      _showSnack(
        'Verification pending approval',
        isError: false,
      );
    }
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _isResolvingLocation = true;
      _locationStatus = 'Getting GPS location…';
    });

    try {
      final locationService = context.read<LocationService>();
      final result = await locationService.resolveComplaintCoordinates();
      if (!mounted) return;
      setState(() {
        _coordinates = result.coordinates;
        _locationStatus = result.warning ??
            'Location: ${result.coordinates.latitude.toStringAsFixed(5)}, '
                '${result.coordinates.longitude.toStringAsFixed(5)}';
        _isResolvingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResolvingLocation = false;
        _locationStatus = 'Using default location (GPS unavailable)';
        _coordinates = const ComplaintCoordinates(
          latitude: ApiConstants.defaultLatitude,
          longitude: ApiConstants.defaultLongitude,
        );
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await PickedImageTile.pick(source);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Please select a category', isError: true);
      return;
    }
    if (_coordinates == null) {
      await _resolveLocation();
      if (_coordinates == null) {
        _showSnack('Location is required. Enable GPS and try again.', isError: true);
        return;
      }
    }

    final complaintRepo = context.read<ComplaintRepository>();
    final complaintService = context.read<ComplaintService>();

    setState(() => _isSubmitting = true);

    try {
      final request = CreateComplaintRequest(
        complaintTitle: _titleController.text.trim(),
        complaintDescription: _descriptionController.text.trim(),
        categoryId: _selectedCategory!.uniqueId,
        complaintCoordinates: _coordinates!,
      );

      final result = await complaintRepo.createComplaint(
        request: request,
        photo: _photo,
      );

      if (!mounted) return;

      if (result.success && result.data != null) {
        await complaintService.cacheComplaintLocally(result.data!);
        _showSnack(result.message, isError: false);
        Navigator.of(context).pop();
      } else {
        _showSnack(result.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: const Text('Create Complaint'),
        actions: [
          if (_phase == _CreateComplaintPhase.verifiedForm)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Refresh location',
              onPressed: _isResolvingLocation ? null : _resolveLocation,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _CreateComplaintPhase.loadingProfile:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking account verification…'),
            ],
          ),
        );

      case _CreateComplaintPhase.unverified:
        return VerificationRequiredPanel(
          onUploadDocuments: _openDocumentUpload,
        );

      case _CreateComplaintPhase.pendingApproval:
        return VerificationRequiredPanel(
          isPendingApproval: true,
          onUploadDocuments: _loadProfile,
        );

      case _CreateComplaintPhase.profileError:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  _profileError ?? 'Could not load profile',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case _CreateComplaintPhase.verifiedForm:
        return _buildComplaintForm();
    }
  }

  Widget _buildComplaintForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_profile != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          _profile!.fullName.isNotEmpty
                              ? _profile!.fullName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(_profile!.fullName),
                      subtitle: Text(_profile!.email),
                      trailing: const Icon(Icons.verified, color: AppColors.success),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'At least 20 characters',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (v.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildCategoryField(),
                const SizedBox(height: 16),
                Card(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (_isResolvingLocation)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationStatus ?? 'Resolving location…',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: _isResolvingLocation ? null : _resolveLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Photo (optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _photo!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                    if (_photo != null)
                      IconButton(
                        onPressed: () => setState(() => _photo = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSubmitting ||
                          _categoriesLoading ||
                          _categoriesError != null ||
                          _categories.isEmpty
                      ? null
                      : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Complaint'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    if (_categoriesLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading categories…'),
          ],
        ),
      );
    }

    if (_categoriesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category),
              errorText: _categoriesError,
            ),
            child: Text(
              _categoriesError!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry loading categories'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<Category>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
      ),
      items: _categories.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(c.categoryName),
        );
      }).toList(),
      onChanged: _isSubmitting
          ? null
          : (v) => setState(() => _selectedCategory = v),
      validator: (v) => v == null ? 'Select a category' : null,
    );
  }
}
