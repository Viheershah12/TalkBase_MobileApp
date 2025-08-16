// lib/pages/auth/login_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:talkbase/pages/auth/verify_phone_page.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Email Tab
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Controllers for Phone Tab
  final phoneController = TextEditingController();
  String _fullPhoneNumber = '';

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool loading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // --- LOGIC FOR EMAIL LOGIN ---
  Future<void> _signInWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Email and password are required.");
      return;
    }
    setState(() => loading = true);
    final user = await AuthService().signInWithEmail(email, password);
    setState(() => loading = false);

    if (user != null) {
      await user.reload();
      if (!user.emailVerified) {
        Fluttertoast.showToast(msg: "Please verify your email first.", toastLength: Toast.LENGTH_LONG);
        await AuthService().signOut();
        return;
      }
      await _onLoginSuccess(user);
    }
  }

  // --- LOGIC FOR PHONE OTP ---
  Future<void> _sendPhoneOtp() async {
    final phone = _fullPhoneNumber;
    if (phone.isEmpty || phone.length < 10) { // Basic validation
      Fluttertoast.showToast(msg: "Please enter a valid phone number.");
      return;
    }
    setState(() => loading = true);

    // First check if a user with this phone number exists
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      Fluttertoast.showToast(msg: "No account found with this phone number.");
      setState(() => loading = false);
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() => loading = false);
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        await _onLoginSuccess(userCredential.user!);
      },
      verificationFailed: (e) {
        setState(() => loading = false);
        Fluttertoast.showToast(msg: "Phone verification failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyPhonePage(
              verificationId: verificationId,
              phoneNumber: phone,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (id) {
        if (mounted) setState(() => loading = false);
      },
    );
  }

  Future<void> _onLoginSuccess(User user) async {
    final token = await user.getIdToken();
    await storage.write(key: 'token', value: token);
    await NotificationService().initNotifications();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 32),
                _tabBar(context),
                _tabBarView(context),
                const SizedBox(height: 24),
                _forgotPassword(context),
                _signup(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return const Column(
      children: [
        Text(
          "Welcome Back",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Enter your credentials to login"),
      ],
    );
  }

  Widget _tabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.purple,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.purple,
      tabs: const [
        Tab(text: 'Email'),
        Tab(text: 'Phone'),
      ],
    );
  }

  Widget _tabBarView(BuildContext context) {
    return SizedBox(
      height: 300, // Give the TabBarView a defined height
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildEmailTab(context),
          _buildPhoneTab(context),
        ],
      ),
    );
  }

  // --- WIDGET FOR EMAIL LOGIN TAB ---
  Widget _buildEmailTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(
                hintText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                fillColor: Colors.purple.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: "Password",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.purple),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : _signInWithEmail,
            style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple),
            child: loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("Login with Password", style: TextStyle(fontSize: 18, color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- WIDGET FOR PHONE LOGIN TAB ---
  Widget _buildPhoneTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntlPhoneField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true,
            ),
            initialCountryCode: 'KE', // Kenya
            onChanged: (phone) {
              _fullPhoneNumber = phone.completeNumber;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : _sendPhoneOtp,
            style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple),
            child: loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("Send OTP", style: TextStyle(fontSize: 18, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _forgotPassword(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: const Text("Forgot password?", style: TextStyle(color: Colors.purple)),
    );
  }

  Widget _signup(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text("Sign Up", style: TextStyle(color: Colors.purple)),
        )
      ],
    );
  }
}