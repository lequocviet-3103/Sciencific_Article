import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sent = false;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Failed to send reset email');
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
      appBar: AppBar(title: const Text('Reset password')),
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
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
                  if (_sent)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password reset email sent. Please check your inbox.',
                        style: TextStyle(color: colorScheme.primary, fontSize: 13),
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
                          : const Text('Send reset link'),
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
