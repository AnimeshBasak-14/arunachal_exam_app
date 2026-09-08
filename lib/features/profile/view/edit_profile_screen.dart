import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/avatar_utils.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _cityController;

  String? _selectedProfilePic;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _dobController = TextEditingController(text: user?.dob ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _selectedProfilePic = user?.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1960, 1, 1),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    } else {
      final photosStatus = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();
      if (!photosStatus.isGranted && !storageStatus.isGranted) return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 240,
        maxHeight: 240,
        imageQuality: 75,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _isUploadingPhoto = true;
          _uploadProgress = 0.3;
        });

        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _uploadProgress = 0.8;
          _selectedProfilePic = base64Image;
        });

        await ref.read(authViewModelProvider.notifier).updateProfile(
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              dob: _dobController.text,
              profilePic: base64Image,
              city: _cityController.text,
            );

        if (mounted) {
          setState(() {
            _isUploadingPhoto = false;
            _uploadProgress = 1.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated and synced across devices!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera or gallery: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startPhotoUpload() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXL)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.m),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                  title: const Text('Choose from Gallery',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                  title: const Text('Take from Camera',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_rounded,
                      color: AppColors.primary),
                  title: const Text('Choose Avatar Color',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showColorPicker();
                  },
                ),
                const SizedBox(height: AppSpacing.s),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        final list = [
          {
            'name': 'Mint Green',
            'value': 'avatar_green',
            'color': AppColors.primary
          },
          {
            'name': 'Teal',
            'value': 'avatar_teal',
            'color': AppColors.secondary
          },
          {
            'name': 'Amber Gold',
            'value': 'avatar_gold',
            'color': AppColors.accent
          },
          {
            'name': 'Blue Accent',
            'value': 'avatar_blue',
            'color': const Color(0xff3b82f6)
          },
          {
            'name': 'Orange Earth',
            'value': 'avatar_orange',
            'color': const Color(0xffe07a5f)
          },
        ];
        return AlertDialog(
          title: const Text('Choose Avatar Color'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: list.map((item) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProfilePic = item['value'] as String;
                    });
                    ref.read(authViewModelProvider.notifier).updateProfile(
                          name: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          dob: _dobController.text,
                          profilePic: item['value'] as String,
                          city: _cityController.text,
                        );
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile avatar updated successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: item['color'] as Color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePersonalDetails() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authViewModelProvider.notifier).updateProfile(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            dob: _dobController.text,
            profilePic: _selectedProfilePic,
            city: _cityController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal details updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    Color getAvatarColor(String? avatarName) {
      switch (avatarName) {
        case 'avatar_teal':
          return AppColors.secondary;
        case 'avatar_gold':
          return AppColors.accent;
        case 'avatar_blue':
          return const Color(0xff3b82f6);
        case 'avatar_orange':
          return const Color(0xffe07a5f);
        case 'avatar_green':
        default:
          return AppColors.primary;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('SETTINGS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.m),

                // Photo upload block
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _startPhotoUpload,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor:
                                      getAvatarColor(_selectedProfilePic),
                                  backgroundImage: AvatarUtils.getAvatarImageProvider(_selectedProfilePic),
                                  child: AvatarUtils.getAvatarImageProvider(_selectedProfilePic) != null
                                      ? null
                                      : Text(
                                          _nameController.text.isNotEmpty
                                              ? _nameController.text[0]
                                                  .toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        if (_isUploadingPhoto) ...[
                          const SizedBox(height: AppSpacing.s),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              color: AppColors.primary,
                              backgroundColor: AppColors.divider,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Uploading Photo: ${(_uploadProgress * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // SECTION 1: Personal Details
                const Text(
                  'PERSONAL DETAILS',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: AppSpacing.s),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Candidate Full Name',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.m),
                      CustomTextField(
                        label: 'City / District',
                        controller: _cityController,
                        prefixIcon: Icons.location_city_rounded,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      GestureDetector(
                        onTap: () => _selectDob(context),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            label: 'Date of Birth (DOB)',
                            controller: _dobController,
                            prefixIcon: Icons.calendar_month_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select Date of Birth';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      PrimaryButton(
                        text: 'SAVE PERSONAL DETAILS',
                        isLoading: state.isLoading,
                        onPressed: _savePersonalDetails,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // SECTION 2: Account Security
                const Text(
                  'ACCOUNT & SECURITY',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: AppSpacing.s),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined,
                            color: AppColors.primary),
                        title: const Text('Change Gmail Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_emailController.text,
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: AppColors.textHint),
                        onTap: () async {
                          final result =
                              await context.push<String?>('/change-email');
                          if (result != null) {
                            setState(() {
                              _emailController.text = result;
                            });
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_android_rounded,
                            color: AppColors.primary),
                        title: const Text('Change Phone Number',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _phoneController.text.isNotEmpty
                              ? '+91 ${_phoneController.text}'
                              : 'Add verified phone number',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: AppColors.textHint),
                        onTap: () async {
                          final result =
                              await context.push<String?>('/change-phone');
                          if (result != null) {
                            setState(() {
                              _phoneController.text = result;
                            });
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primary),
                        title: const Text('Change Password',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                          'Update your current login password',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: AppColors.textHint),
                        onTap: () {
                          context.push('/change-password');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded,
                            color: AppColors.primary),
                        title: const Text('Forgot / Reset Password',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                          'Recover or reset password via email or phone',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: AppColors.textHint),
                        onTap: () {
                          context.push('/forgot-password');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
