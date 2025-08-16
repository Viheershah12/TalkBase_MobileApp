// lib/pages/auth/signup_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:talkbase/pages/auth/verify_phone_page.dart';
import '../../core/services/auth_service.dart';

enum AuthMethod { email, phone }

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  String _fullPhoneNumber = '';

  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  AuthMethod _selectedMethod = AuthMethod.email;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // --- PATH 1: User chose to register with EMAIL ---
      if (_selectedMethod == AuthMethod.email) {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();
        final firstName = firstNameController.text.trim();
        final lastName = lastNameController.text.trim();

        // Check if email already exists
        final emailQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
        if (emailQuery.docs.isNotEmpty) {
          throw Exception("This email address is already in use.");
        }

        // Create user with email and password
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        final user = userCredential.user;
        if (user == null) {
          throw Exception("Failed to create user account.");
        }

        await user.updateDisplayName("$firstName $lastName");

        // Create user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'displayName': "$firstName $lastName",
          'email': user.email,
          'phone': null, // Phone is not yet linked
          'createdOn': FieldValue.serverTimestamp(),
        });

        // Send verification email and navigate
        await user.sendEmailVerification();
        Fluttertoast.showToast(msg: "A verification link has been sent to your email.");
        Navigator.pushReplacementNamed(context, '/login');

        // --- PATH 2: User chose to register with PHONE ---
      } else {
        final phone = _fullPhoneNumber;
        final firstName = firstNameController.text.trim();
        final lastName = lastNameController.text.trim();

        if (phone == null || phone.isEmpty) {
          throw Exception("Phone number is invalid.");
        }

        // Check if phone number already exists
        final phoneQuery = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).limit(1).get();
        if (phoneQuery.docs.isNotEmpty) {
          throw Exception("This phone number is already in use.");
        }

        // If phone doesn't exist, proceed to send OTP
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // This is for auto-retrieval, less common.
            // You could sign in the user here directly if needed.
          },
          verificationFailed: (FirebaseAuthException e) {
            throw Exception("Phone verification failed: ${e.message}");
          },
          codeSent: (String verificationId, int? resendToken) {
            // Navigate to the OTP page. Pass all necessary user info.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyPhonePage(
                  verificationId: verificationId,
                  phoneNumber: phone,
                  firstName: firstName,
                  lastName: lastName,
                  // `userToLink` is null because we are creating a NEW user, not linking.
                  userToLink: null,
                ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      // Use a more specific error message if possible
      final errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : "An unknown error occurred.";
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Future<void> _signup() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   final email = emailController.text.trim();
  //   final password = passwordController.text.trim();
  //   final firstName = firstNameController.text.trim();
  //   final lastName = lastNameController.text.trim();
  //   final phone = _fullPhoneNumber;
  //
  //   if (email.isEmpty && phone.isEmpty) {
  //     _showError("Please provide either an email or a phone number.");
  //     return;
  //   }
  //   if (email.isNotEmpty && password.isEmpty) {
  //     _showError("Password is required when signing up with email.");
  //     return;
  //   }
  //
  //   setState(() => _loading = true);
  //
  //   try {
  //     User? user;
  //
  //     final usersRef = FirebaseFirestore.instance.collection('users');
  //     bool emailExists = false;
  //     bool phoneExists = false;
  //
  //     // Check if email exists
  //     if (email.isNotEmpty) {
  //       final emailQuery = await usersRef.where('email', isEqualTo: email).limit(1).get();
  //       if (emailQuery.docs.isNotEmpty) {
  //         emailExists = true;
  //       }
  //     }
  //
  //     // Check if phone number exists
  //     if (phone.isNotEmpty) {
  //       final phoneQuery = await usersRef.where('phone', isEqualTo: phone).limit(1).get();
  //       if (phoneQuery.docs.isNotEmpty) {
  //         phoneExists = true;
  //       }
  //     }
  //
  //     if (emailExists) {
  //       throw Exception("This email address is already in use by another account.");
  //     }
  //     if (phoneExists) {
  //       throw Exception("This phone number is already in use by another account.");
  //     }
  //
  //     // --- PATH A: User provides Email (primary auth method) ---
  //     if (email.isNotEmpty) {
  //       user = await AuthService().registerWithEmail(email, password, firstName, lastName);
  //       if (user == null) throw Exception("Email may already be in use.");
  //
  //       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //         'uid': user.uid,
  //         'firstName': firstName,
  //         'lastName': lastName,
  //         'displayName': user.displayName,
  //         'email': user.email,
  //         'phone': null, // Phone is pending verification
  //         'createdOn': FieldValue.serverTimestamp(),
  //         'pendingEmailConfirmation': true,
  //         'pendingPhoneConfirmation': phone.isNotEmpty,
  //       });
  //
  //       await user.sendEmailVerification();
  //       Fluttertoast.showToast(msg: "Verification email sent to $email");
  //     }
  //
  //     if (phone.isNotEmpty) {
  //       await FirebaseAuth.instance.verifyPhoneNumber(
  //         phoneNumber: phone,
  //         codeSent: (String verificationId, int? resendToken) {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => VerifyPhonePage(
  //                 verificationId: verificationId,
  //                 userToLink: user,
  //                 firstName: firstName,
  //                 lastName: lastName,
  //                 phoneNumber: phone,
  //               ),
  //             ),
  //           );
  //         },
  //         verificationCompleted: (credential) {},
  //         verificationFailed: (e) => _showError("Phone verification failed: ${e.message}"),
  //         codeAutoRetrievalTimeout: (id) {},
  //       );
  //     } else {
  //       Navigator.pushReplacementNamed(context, '/login');
  //     }
  //   } catch (e) {
  //     _showError("Sign-up Error: $e");
  //   } finally {
  //     if (mounted) setState(() => _loading = false);
  //   }
  // }

  void _showError(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Welcome!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Create an account to get started.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // --- First and Last Name (Unchanged) ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: "First Name",
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.name,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: "Last Name",
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.name,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- STYLISH TOGGLE: SegmentedButton ---
                SegmentedButton<AuthMethod>(
                  segments: const <ButtonSegment<AuthMethod>>[
                    ButtonSegment<AuthMethod>(
                      value: AuthMethod.email,
                      label: Text('Email'),
                      icon: Icon(Icons.email_outlined),
                    ),
                    ButtonSegment<AuthMethod>(
                      value: AuthMethod.phone,
                      label: Text('Phone'),
                      icon: Icon(Icons.phone_outlined),
                    ),
                  ],
                  selected: <AuthMethod>{_selectedMethod},
                  onSelectionChanged: (Set<AuthMethod> newSelection) {
                    setState(() {
                      _selectedMethod = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.purple,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: Colors.purple,
                  ),
                ),
                const SizedBox(height: 24),

                // --- DYNAMIC FORM FIELDS ---
                // Show fields based on the selected method
                if (_selectedMethod == AuthMethod.email)
                  _buildEmailFields()
                else
                  _buildPhoneField(),

                const SizedBox(height: 32),

                // --- Register Button ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _signup,
                  child: _loading
                      ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text("Register", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper widget for Email fields ---
  Widget _buildEmailFields() {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Password is required';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  // --- Helper widget for Phone field ---
  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: phoneController,
      decoration: const InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(),
      ),
      initialCountryCode: 'KE',
      onChanged: (phone) {
        _fullPhoneNumber = phone.completeNumber;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (phone) {
        if (phone == null || phone.number.isEmpty) {
          return 'Phone number is required';
        }
        return null;
      },
    );
  }
}