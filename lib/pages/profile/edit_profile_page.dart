import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _dobController = TextEditingController();

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
    _dobController.dispose();
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
        _dobController.text = data['dateOfBirth'] ?? '';
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
        'displayName': displayName,
        'dateOfBirth': _dobController.text.trim()
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

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Softer background color
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          // A cleaner save button in the AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Save", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            _buildSectionHeader("Personal Information", "Update your personal details."),
            _buildInfoCard(
              children: [
                _buildTextFormField(
                  controller: _firstNameController,
                  labelText: "First Name",
                  icon: Icons.person_outline,
                ),
                const Divider(height: 1),
                _buildTextFormField(
                  controller: _lastNameController,
                  labelText: "Last Name",
                  icon: Icons.person_outline,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Additional Details", "Provide more information about yourself."),
            _buildInfoCard(
              children: [
                _buildDropdownFormField(),
                const Divider(height: 1),
                _buildTextFormField(
                  controller: _dobController,
                  labelText: "Date of Birth",
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionHeader("Contact & Identity", "Update your contact and identity information."),
            _buildInfoCard(
              children: [
                _buildTextFormField(
                  controller: _phoneController,
                  labelText: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const Divider(height: 1),
                _buildTextFormField(
                  controller: _idNumberController,
                  labelText: "ID Number",
                  icon: Icons.badge_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER HELPERS ---

  /// A helper to build styled section headers
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// A helper to create a consistent card container
  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }


  /// A helper to create a styled and reusable TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
    );
  }

  /// A specific helper for the gender dropdown for clarity
  Widget _buildDropdownFormField() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: "Gender",
        prefixIcon: Icon(Icons.wc_outlined, color: Colors.grey[600]),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      items: _genders.map((gender) {
        return DropdownMenuItem(value: gender, child: Text(gender));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
      validator: (value) => value == null ? 'Please select a gender' : null,
    );
  }
}