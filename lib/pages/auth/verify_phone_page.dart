// lib/pages/auth/verify_phone_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pinput/pinput.dart';

import '../../widgets/countdown_timer.dart';

class VerifyPhonePage extends StatefulWidget {
  final String verificationId;
  final User? userToLink;
  final String? firstName;
  final String? lastName;
  final String phoneNumber;

  const VerifyPhonePage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.userToLink,
    this.firstName,
    this.lastName,
  });

  @override
  _VerifyPhonePageState createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final otpController = TextEditingController();
  final focusNode = FocusNode();
  bool _loading = false;
  bool _canResend = false;

  Key _timerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    otpController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onTimerEnd() {
    setState(() => _canResend = true);
  }

  void _resendCode() {
    if (_canResend) {
      // TODO: Implement your Firebase phone number verification logic again
      debugPrint("Resending code to ${widget.phoneNumber}...");

      // By changing the key, we tell Flutter to create a new instance
      // of CountdownTimer, which restarts its internal timer.
      setState(() {
        _canResend = false;
        _timerKey = UniqueKey();
      });
    }
  }

  Future<void> _verifyAndProceed(String smsCode) async {
    if (smsCode.length != 6) return;
    setState(() => _loading = true);

    try {
      // Create the credential with the verification ID and the OTP code.
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      // --- SCENARIO A: LINK phone to an existing EMAIL account ---
      if (widget.userToLink != null) {
        await widget.userToLink!.linkWithCredential(credential);

        // Update the user's document in Firestore with the verified phone number
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userToLink!.uid)
            .update({
          'phone': widget.phoneNumber,
          'pendingPhoneConfirmation': false,
        });

        Fluttertoast.showToast(msg: "Phone number linked successfully!");
      }
      // --- SCENARIO B: SIGN IN with a new PHONE-ONLY account ---
      else {
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final newUser = userCredential.user;

        if (newUser != null) {
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(newUser.uid);
          final docSnapshot = await userDocRef.get();

          if (!docSnapshot.exists) {
            // Since this is a new phone-only user, create their document in Firestore.
            await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
              'uid': newUser.uid,
              'firstName': widget.firstName,
              'lastName': widget.lastName,
              'displayName': '${widget.firstName} ${widget.lastName}',
              'email': null, // No email provided
              'phone': widget.phoneNumber,
              'createdOn': FieldValue.serverTimestamp(),
              'pendingEmailConfirmation': false,
              'pendingPhoneConfirmation': false,
            });

            await newUser.updateDisplayName('${widget.firstName} ${widget.lastName}');
            await newUser.reload();
          }
        }
      }

      // Navigate to the home page, clearing the auth stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      // Handle common errors like invalid OTP
      Fluttertoast.showToast(
        msg: "Verification Failed: ${e.code == 'invalid-verification-code' ? 'The code you entered is incorrect.' : e.message}",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pinput theme for a more modern look
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Verify Phone"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.phonelink_ring_outlined, size: 72, color: Colors.purple),
              const SizedBox(height: 24),
              const Text(
                "Verification Code",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter the 6-digit code sent to\n${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // The styled Pinput widget
              Pinput(
                length: 6,
                controller: otpController,
                focusNode: focusNode,
                autofocus: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                onCompleted: (pin) => _verifyAndProceed(pin),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
              ),
              const SizedBox(height: 30),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : () => _verifyAndProceed(otpController.text),
                  child: _loading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text("Verify & Continue", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              // Resend Code logic
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive code? "),
                  TextButton(
                    onPressed: _canResend ? _resendCode : null,
                    child: _canResend
                        ? const Text("Resend Code", style: TextStyle(color: Colors.purple))
                        : Row(
                      children: [
                        const Text("Resend in "),
                        CountdownTimer(
                          duration: const Duration(seconds: 60),
                          onEnd: _onTimerEnd,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        const Text("s"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}