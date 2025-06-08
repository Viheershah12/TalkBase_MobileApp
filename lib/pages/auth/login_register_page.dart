import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool isLogin = true;

  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  String tenant = '';

  bool loading = false;
  String? errorMessage;

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = null;
    });
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (isLogin) {
      success = await auth.login(username, password, tenant);
    }
    else {
      // success = await auth.register(username, password);
      // if (success) {
      //   setState(() {
      //     isLogin = true;
      //   });
      // }
    }

    setState(() => loading = false);

    if (!success) {
      setState(() {
        errorMessage = "Invalid username, password, or tenant";
      });
    } else {
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Register'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tenant Name'),
                onSaved: (val) => tenant = val?.trim() ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Enter tenant name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                onSaved: (val) => username = val?.trim() ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (val) => password = val ?? '',
                validator: (val) => val == null || val.length < 6
                    ? 'Password must be 6+ chars'
                    : null,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: loading ? null : toggleForm,
                child: Text(isLogin
                    ? "Don't have an account? Register"
                    : "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
