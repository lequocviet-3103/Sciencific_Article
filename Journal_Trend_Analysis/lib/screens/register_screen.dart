import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../models/api_error.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(_fullNameController.text.trim());
      }

      final idToken = await credential.user?.getIdToken();
      if (idToken == null) {
        throw const ApiError('Missing Firebase ID token');
      }

      final authService = AuthService();
      final user = await authService.verifyIdToken(idToken);

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.setUser(user);

      if (!mounted) return;
      // Don't push a route: the root widget already watches AuthProvider
      // and swaps to HomeShell once authenticated. Just pop back to it
      // since RegisterScreen was reached via a push from /login.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Registration failed');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_errorMessage != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
