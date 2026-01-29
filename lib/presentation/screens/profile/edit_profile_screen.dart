import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';

import '../../../data/models/user.dart';
import '../../../data/remote/appwrite_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common.dart';

/// Edit profile screen with profile picture upload
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  // ignore: prefer_final_fields
  bool _isUploadingImage = false;
  String? _newAvatarUrl;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) return;

      // Upload new avatar if selected
      String? avatarUrl = _newAvatarUrl ?? currentUser.avatarUrl;
      if (_selectedImage != null) {
        avatarUrl = await _uploadProfileImage(_selectedImage!, currentUser.id);
      }
      
      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim(),
        bio: _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        avatarUrl: avatarUrl,
        authProviders: currentUser.authProviders,
        totalXp: currentUser.totalXp,
        weeklyXp: currentUser.weeklyXp,
        currentStreakDays: currentUser.currentStreakDays,
        longestStreakDays: currentUser.longestStreakDays,
        followerCount: currentUser.followerCount,
        followingCount: currentUser.followingCount,
        lessonsCompleted: currentUser.lessonsCompleted,
        lastLessonDate: currentUser.lastLessonDate,
        lastSyncAt: currentUser.lastSyncAt,
        syncStatus: currentUser.syncStatus,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
        version: currentUser.version + 1,
      );
      
      await ref.read(authProvider.notifier).updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профайл амжилттай хадгалагдлаа'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _uploadProfileImage(File imageFile, String userId) async {
    try {
      final appwrite = AppwriteClient();
      final storage = appwrite.storage;
      
      // Generate unique file ID
      final fileId = ID.unique();
      final fileName = 'profile_$userId.${imageFile.path.split('.').last}';
      
      // Upload to Appwrite storage
      final file = await storage.createFile(
        bucketId: AppwriteClient.profileImagesBucket,
        fileId: fileId,
        file: InputFile.fromPath(path: imageFile.path, filename: fileName),
      );

      // Get the file URL
      // Format: https://cloud.appwrite.io/v1/storage/buckets/{bucketId}/files/{fileId}/view?project={projectId}
      final fileUrl = '${appwrite.client.endPoint}/storage/buckets/${AppwriteClient.profileImagesBucket}/files/${file.$id}/view?project=${appwrite.client.config['project']}';
      
      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Зураг сонгоход алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Зураг авахад алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAvatar() {
    setState(() {
      _selectedImage = null;
      _newAvatarUrl = ''; // Empty string to indicate removal
    });
  }

  Future<void> _changeAvatar() async {
    // Show avatar selection dialog
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Профайл зураг солих',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Галерейгаас сонгох'),
                subtitle: const Text('Төхөөрөмжөөс зураг сонгох'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: const Text('Зураг авах'),
                subtitle: const Text('Камераар зураг авах'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (ref.read(authProvider).user?.avatarUrl != null || _selectedImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text('Зураг устгах'),
                  subtitle: const Text('Профайл зургийг арилгах'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Determine which image to show
    // ignore: unused_local_variable
    ImageProvider? avatarImage;
    if (_selectedImage != null) {
      avatarImage = FileImage(_selectedImage!);
    } else if (_newAvatarUrl == '') {
      avatarImage = null; // Removed avatar
    } else if (user?.avatarUrl != null) {
      avatarImage = NetworkImage(user!.avatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профайл засах'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Хадгалах'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section with upload indicator
              Center(
                child: Stack(
                  children: [
                    // Avatar
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 104,
                                height: 104,
                              )
                            : (_newAvatarUrl == '' || user?.avatarUrl == null)
                                ? Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Center(
                                      child: Text(
                                        (user?.displayName ?? '?')[0].toUpperCase(),
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 104,
                                    height: 104,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      child: Center(
                                        child: Text(
                                          (user.displayName)[0].toUpperCase(),
                                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    // Upload indicator
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Camera button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _changeAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // New image indicator
                    if (_selectedImage != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _changeAvatar,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(_selectedImage != null ? 'Өөр зураг сонгох' : 'Зураг солих'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Шинэ зураг сонгогдсон (Хадгалах дээр дарна уу)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Form fields
              AppTextField(
                controller: _displayNameController,
                label: 'Нэр',
                hint: 'Таны нэр',
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Нэр оруулна уу';
                  }
                  if (value.trim().length < 2) {
                    return 'Нэр хамгийн багадаа 2 тэмдэгт байна';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _usernameController,
                label: 'Хэрэглэгчийн нэр',
                hint: '@хэрэглэгчийн_нэр',
                prefixIcon: const Icon(Icons.alternate_email),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 3) {
                      return 'Хэрэглэгчийн нэр хамгийн багадаа 3 тэмдэгт байна';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Зөвхөн үсэг, тоо, доогуур зураас ашиглана уу';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _bioController,
                label: 'Танилцуулга',
                hint: 'Өөрийнхөө тухай бичнэ үү',
                prefixIcon: const Icon(Icons.info_outline),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 24),

              // Email (read-only)
              AppTextField(
                controller: TextEditingController(text: user?.email ?? ''),
                label: 'Имэйл',
                prefixIcon: const Icon(Icons.email),
                enabled: false,
              ),
              const SizedBox(height: 32),

              // Danger zone removed: account deletion UI intentionally disabled
            ],
          ),
        ),
      ),
    );
  }

  // Account deletion removed — UI intentionally disabled.
}
