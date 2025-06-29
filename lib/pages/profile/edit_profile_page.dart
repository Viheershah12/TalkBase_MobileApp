import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // A key to manage the state of the form
  final _formKey = GlobalKey<FormState>();

  // Controllers for each text field
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homePhoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passportController = TextEditingController();

  // State variables
  String? _selectedGender;
  bool _isLoading = true; // To show a loader while fetching data
  bool _isSaving = false; // To show a loader on the save button

  // List of gender options for the dropdown
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _homePhoneController.dispose();
    _idNumberController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  // --- DATA LOADING ---
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in case
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch user data from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _homePhoneController.text = data['homePhone'] ?? '';
        _idNumberController.text = data['idNumber'] ?? '';
        _passportController.text = data['passport'] ?? '';
        _selectedGender = data['gender'];
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load profile: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DATA SAVING ---
  Future<void> _saveProfile() async {
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      // 1. Update displayName in Firebase Authentication
      final displayName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      if (user.displayName != displayName) {
        await user.updateDisplayName(displayName);
      }

      // 2. Update all other data in Firestore
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'homePhone': _homePhoneController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'passport': _passportController.text.trim(),
        'gender': _selectedGender,
        'displayName': displayName, // Keep it consistent
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to the profile page
      }

    } catch (e) {
      debugPrint("Error saving profile: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save profile: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          // Save button in the AppBar
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveProfile,
            tooltip: "Save Changes",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- FORM FIELDS ---
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "First Name", prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => value!.isEmpty ? 'Cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Last Name", prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => value!.isEmpty ? 'Cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            // --- GENDER DROPDOWN ---
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: "Gender", prefixIcon: Icon(Icons.wc)),
              items: _genders.map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _homePhoneController,
              decoration: const InputDecoration(labelText: "Home Phone Number", prefixIcon: Icon(Icons.home_work_outlined)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(labelText: "ID Number", prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passportController,
              decoration: const InputDecoration(labelText: "Passport Number", prefixIcon: Icon(Icons.book_outlined)),
            ),
            const SizedBox(height: 32),
            // --- SAVE BUTTON ---
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}