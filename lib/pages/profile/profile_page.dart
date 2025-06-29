import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/profile_menu_item.dart';
import '../settings/setting_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State variable to hold the user data
  User? _user;

  @override
  void initState() {
    super.initState();
    // When the widget is initialized, get the current user
    _loadCurrentUser();
  }

  // Method to get the current user from Firebase Auth
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _user = user;
      });
    }
  }

  // Helper method to get user initials
  String getUserInitials() {
    if (_user?.displayName?.isNotEmpty == true) {
      final names = _user!.displayName!.split(' ');
      if (names.length > 1) {
        return names[0][0].toUpperCase() + names[1][0].toUpperCase();
      }
      return names[0][0].toUpperCase();
    }
    // Fallback to email if no display name
    if (_user?.email?.isNotEmpty == true) {
      return _user!.email![0].toUpperCase();
    }
    return '?'; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    // Use a variable for the theme for cleaner code
    final theme = Theme.of(context);

    return Scaffold(
      // We can use the reusable AppBar we created
      appBar: MyAwesomeAppBar(title: 'Profile', hasBackButton: true),
      body: _user == null
          ? const Center(child: CircularProgressIndicator()) // Show loader while user data is loading
          : RefreshIndicator(
        onRefresh: _loadCurrentUser, // Allow pull-to-refresh
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(theme),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            _buildProfileMenuList(theme),
          ],
        ),
      ),
    );
  }

  // Extracted widget for the profile header for cleaner code
  Widget _buildProfileHeader(ThemeData theme) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
              child: _user?.photoURL == null
                  ? Text(
                getUserInitials(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  onPressed: _showImageSourceActionSheet,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          // Use a fallback if displayName is null
          _user?.displayName ?? 'No Name',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          // Use a fallback if email is null
          _user?.email ?? 'No Email',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // The polished version with a modal loading indicator
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile == null) {
      return; // User canceled the picker
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // --- SUGGESTION 1: Show a modal loading dialog ---
    // Create a context that can be used after async operations
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss the dialog
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Uploading..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(user.uid)
          .child('profile.jpg');

      await ref.putFile(file);
      final photoURL = await ref.getDownloadURL();

      await user.updatePhotoURL(photoURL);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoURL': photoURL});

      await _loadCurrentUser();

      navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!"), backgroundColor: Colors.green));
      }

    } on FirebaseException catch (e) { // --- SUGGESTION 2: Catch specific exceptions ---
      // Hide the loading dialog on error
      navigator.pop();
      debugPrint("Failed to upload profile photo: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to upload photo: ${e.message}"), backgroundColor: Colors.red));
      }
    }
  }

  // Extracted widget for the menu list
  Widget _buildProfileMenuList(ThemeData theme) {
    return Column(
      children: [
        ProfileMenuItem(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () {
            // TODO: Implement change password flow
            _showChangePasswordDialog(context);
          },
        ),
        ProfileMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingPage(),
              ),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            // TODO: Navigate to Help Page
            debugPrint("Navigate to Help Page");
          },
        ),
        const Divider(),
        ProfileMenuItem(
          icon: Icons.logout,
          title: 'Logout',
          textColor: Colors.red, // Make logout visually distinct
          onTap: () async {
            await FirebaseAuth.instance.signOut();

            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
        )
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _isChangingPassword = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to manage dialog's state
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Current Password"),
                        validator: (value) => value!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "New Password"),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Required";
                          if (value.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Confirm New Password"),
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isChangingPassword ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isChangingPassword = true);

                      final user = FirebaseAuth.instance.currentUser;
                      final currentPassword = _currentPasswordController.text.trim();
                      final newPassword = _newPasswordController.text.trim();

                      try {
                        // Create a credential to re-authenticate
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user!.email!,
                          password: currentPassword,
                        );

                        // 1. RE-AUTHENTICATE
                        await user.reauthenticateWithCredential(credential);

                        // 2. UPDATE PASSWORD
                        await user.updatePassword(newPassword);

                        // Close the dialog and show success message
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Password changed successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        // Handle errors
                        String errorMessage = "An error occurred.";
                        if (e.code == 'wrong-password') {
                          errorMessage = 'The current password you entered is incorrect.';
                        } else if (e.code == 'weak-password') {
                          errorMessage = 'The new password is too weak.';
                        } else if (e.code == 'requires-recent-login') {
                          errorMessage = 'This is a sensitive action. Please log out and log back in before changing your password.';
                        }
                        print("Change Password Error: ${e.code}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => _isChangingPassword = false);
                      }
                    }
                  },
                  child: _isChangingPassword
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Change"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}