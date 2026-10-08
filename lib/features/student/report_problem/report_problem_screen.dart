import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/motion/animated_state_views.dart';
import '../../../core/motion/interactive_card.dart';
import '../../../core/motion/motion_reveal.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/complaint_model.dart';
import '../../../services/campus_location_service.dart';
import '../../../services/providers.dart';

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  ConsumerState<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  int _currentStep = 0;
  final _formKeyStep2 = GlobalKey<FormState>();

  // Form State
  String? _selectedCategory;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _pickedImage;

  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _submittedComplaintId;
  String? _errorMessage;

  // Campus Geofence State
  CampusLocationResult? _locationResult;
  bool _isCheckingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation({bool silent = false}) async {
    if (_isCheckingLocation) return;
    setState(() {
      _isCheckingLocation = true;
    });

    final devMode = ref.read(devLocationModeProvider);
    final locationService = ref.read(campusLocationServiceProvider);
    final result = await locationService.verifyCampusLocation(
      testMode: devMode,
    );

    if (mounted) {
      setState(() {
        _locationResult = result;
        _isCheckingLocation = false;
      });
      if (!silent && !result.isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = picked;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitComplaint() async {
    // 8. Prevent duplicate submission
    if (_isSubmitting) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile unavailable. Please log in again.')),
      );
      return;
    }

    // Check location verification
    if (_locationResult == null || !_locationResult!.isVerified) {
      await _checkLocation();
      if (_locationResult == null || !_locationResult!.isVerified) {
        setState(() {
          _errorMessage = _locationResult?.message ?? 'Location verification required before submitting.';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    debugPrint('[CampusFix] Starting complaint submission');

    try {
      // 1. Re-verify campus location immediately before final submission
      debugPrint('[CampusFix] Location verification started');
      final devMode = ref.read(devLocationModeProvider);
      final locationService = ref.read(campusLocationServiceProvider);
      final freshLocation = await locationService.verifyCampusLocation(
        testMode: devMode,
      );
      debugPrint('[CampusFix] Location verification completed');

      if (!freshLocation.isVerified) {
        setState(() {
          _locationResult = freshLocation;
          _errorMessage = freshLocation.message;
        });
        return;
      }
      _locationResult = freshLocation;

      // 2. Generate complaint ID
      final complaintId = IdGenerator.generateComplaintId();
      String? imageUrl;

      // 3. Image upload to Firebase Storage with strict timeout and fallback
      if (_pickedImage != null) {
        final storage = ref.read(storageServiceProvider);
        try {
          imageUrl = await storage.uploadComplaintImage(
            file: _pickedImage!,
            complaintId: complaintId,
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );
        } catch (storageError) {
          debugPrint('[CampusFix] Storage upload handled with fallback/warning: $storageError');
        }
      }

      // 4. Firestore complaint write with server batch
      final now = DateTime.now();
      final complaint = ComplaintModel(
        complaintId: complaintId,
        studentId: user.uid,
        studentName: user.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? 'Other',
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
        status: AppConstants.statusPending,
        createdAt: now,
        updatedAt: now,
        priority: AppConstants.priorityMedium,
        locationData: freshLocation.toMap(),
      );

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.createComplaint(complaint);

      if (mounted) {
        setState(() {
          _submittedComplaintId = complaintId;
        });
      }
    } catch (e, stack) {
      debugPrint('[CampusFix] Complaint submission error: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = 'Submission failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_submittedComplaintId != null) {
      return _buildSuccessScreen(isDark);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            _buildStepIndicator(isDark),
            const Divider(height: 1),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildCurrentStepContent(isDark),
                  ),
                ),
              ),
            ),

            // Step Navigation Footer
            _buildNavigationFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['Category', 'Details', 'Evidence', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.success
                              : (isCurrent ? AppColors.primary : (isDark ? AppColors.darkCard : const Color(0xFFE2E8F0))),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? Colors.white : AppColors.lightTextSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? (isDark ? Colors.white : AppColors.primary)
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: isCompleted ? AppColors.success : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Category(isDark);
      case 1:
        return _buildStep2Details(isDark);
      case 2:
        return _buildStep3Evidence(isDark);
      case 3:
      default:
        return _buildStep4Review(isDark);
    }
  }

  // STEP 1: CATEGORY SELECTION
  Widget _buildStep1Category(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'What kind of maintenance problem are you experiencing?',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppConstants.categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final cat = AppConstants.categories[index];
            final name = cat['name'] as String;
            final icon = cat['icon'] as IconData;
            final color = cat['color'] as Color;
            final isSelected = _selectedCategory == name;

            return MotionReveal.staggered(
              index: index,
              intervalMs: 40,
              child: InteractiveCard(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(12),
                backgroundColor: isSelected
                    ? color.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkCard : Colors.white),
                hoverBorderColor: color,
                onTap: () {
                  setState(() {
                    _selectedCategory = name;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 24, color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? color
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 2: PROBLEM INFORMATION
  Widget _buildStep2Details(bool isDark) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Problem Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Provide accurate details so the maintenance crew can address it quickly.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _titleController,
            label: 'Issue Title',
            hintText: 'e.g. Broken ceiling fan in Lab 302',
            prefixIcon: Icons.title_rounded,
            validator: (val) => Validators.validateRequired(val, 'Title'),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _locationController,
            label: 'Specific Location',
            hintText: 'e.g. Science Block, 3rd Floor, Room 302, Bench 4',
            prefixIcon: Icons.location_on_outlined,
            validator: (val) => Validators.validateRequired(val, 'Location'),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _descriptionController,
            label: 'Detailed Description',
            hintText: 'Explain the issue, how long it has been occurring, and any safety hazards...',
            prefixIcon: Icons.notes_rounded,
            maxLines: 4,
            validator: (val) => Validators.validateRequired(val, 'Description'),
          ),
        ],
      ),
    );
  }

  // STEP 3: ATTACH EVIDENCE
  Widget _buildStep3Evidence(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Evidence (Photo)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A photo helps technicians bring the right tools and spare parts.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),

        if (_pickedImage != null) ...[
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.65),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _pickedImage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.change_circle_rounded),
              label: const Text('Change Photo'),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 52,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No photo attached yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Take a quick photo or choose one from your gallery',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // STEP 4: REVIEW COMPLAINT
  Widget _buildStep4Review(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Complaint',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please verify all information before final submission.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // DEVELOPER TEST MODE BANNER (DEBUG BUILDS ONLY)
        if (kDebugMode && ref.watch(devLocationModeProvider) == DevLocationTestingMode.simulateInsideCampus) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade700, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVELOPER TEST MODE — CAMPUS LOCATION BYPASS ACTIVE',
                        style: TextStyle(
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Simulated location: LBRCE Campus | Real GPS geofence bypassed for testing',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Campus Location Geofence Status Card
        _buildLocationVerificationCard(isDark),
        const SizedBox(height: 16),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.errorDark, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.errorDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Category', _selectedCategory ?? 'Unspecified', Icons.category_outlined),
                const Divider(),
                _buildReviewRow('Title', _titleController.text, Icons.title_rounded),
                const Divider(),
                _buildReviewRow('Location', _locationController.text, Icons.location_on_outlined),
                const Divider(),
                _buildReviewRow('Description', _descriptionController.text, Icons.description_outlined),
                const Divider(),
                _buildReviewRow(
                  'Evidence Photo',
                  _pickedImage != null ? 'Attached (Ready to upload)' : 'None attached',
                  Icons.image_outlined,
                ),
              ],
            ),
          ),
        ),

        if (_isSubmitting && _uploadProgress > 0) ...[
          const SizedBox(height: 20),
          LinearProgressProgress(value: _uploadProgress),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Uploading evidence (${(_uploadProgress * 100).toInt()}%)...',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationVerificationCard(bool isDark) {
    final devMode = ref.watch(devLocationModeProvider);

    if (_isCheckingLocation) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Verifying campus GPS location...',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final isVerified = _locationResult != null && _locationResult!.isVerified;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.successContainer)
            : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : AppColors.errorContainer),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_rounded : Icons.location_off_rounded,
                color: isVerified ? AppColors.successDark : AppColors.errorDark,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVerified ? 'Campus location verified' : 'Campus location required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isVerified ? AppColors.successDark : AppColors.errorDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVerified
                          ? "You're inside the campus"
                          : (_locationResult?.message ??
                              'Reports can only be submitted while you are inside the college campus.'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isVerified ? AppColors.successDark : AppColors.errorDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _checkLocation(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Check Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isVerified ? AppColors.successDark : AppColors.errorDark,
                  side: BorderSide(
                    color: (isVerified ? AppColors.success : AppColors.error).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          // Developer Testing Mode Controls (ONLY PRESENT IN DEBUG BUILDS)
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.developer_mode_rounded, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Text(
                  'DEVELOPER TEST MODE:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber.shade900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Real GPS', style: TextStyle(fontSize: 12)),
                  selected: devMode == DevLocationTestingMode.realGps,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(devLocationModeProvider.notifier).state = DevLocationTestingMode.realGps;
                      _checkLocation();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Simulate Inside LBRCE', style: TextStyle(fontSize: 12)),
                  selected: devMode == DevLocationTestingMode.simulateInsideCampus,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(devLocationModeProvider.notifier).state = DevLocationTestingMode.simulateInsideCampus;
                      _checkLocation();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Simulate Outside', style: TextStyle(fontSize: 12)),
                  selected: devMode == DevLocationTestingMode.simulateOutsideCampus,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(devLocationModeProvider.notifier).state = DevLocationTestingMode.simulateOutsideCampus;
                      _checkLocation();
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationFooter(bool isDark) {
    final bool isOutsideCampus = _currentStep == 3 &&
        _locationResult != null &&
        !_locationResult!.isVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _currentStep--;
                            });
                          },
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: _currentStep == 3 ? 'SUBMIT COMPLAINT' : 'Continue',
                  isLoading: _isSubmitting,
                  icon: _currentStep == 3 ? Icons.send_rounded : Icons.arrow_forward_rounded,
                  onPressed: isOutsideCampus
                      ? null
                      : () {
                          if (_currentStep == 0) {
                            if (_selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a category.')),
                              );
                              return;
                            }
                            setState(() => _currentStep = 1);
                          } else if (_currentStep == 1) {
                            if (!_formKeyStep2.currentState!.validate()) return;
                            setState(() => _currentStep = 2);
                          } else if (_currentStep == 2) {
                            setState(() => _currentStep = 3);
                            _checkLocation(silent: true);
                          } else {
                            _submitComplaint();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SUCCESS ANIMATION SCREEN
  Widget _buildSuccessScreen(bool isDark) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSuccessView(
          complaintId: _submittedComplaintId!,
          title: _titleController.text.trim(),
          onViewComplaint: () {
            Navigator.pop(context);
          },
          onDone: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class LinearProgressProgress extends StatelessWidget {
  final double value;
  const LinearProgressProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: AppColors.lightBorder,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }
}
