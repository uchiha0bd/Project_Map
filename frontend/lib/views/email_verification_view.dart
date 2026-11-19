import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    final authVM = context.read<AuthViewModel>();
    final verified = await authVM.checkEmailVerification();

    if (!mounted) return;

    setState(() => _isChecking = false);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your email is not verified yet. Please check your inbox.',
          ),
        ),
      );
    }
    // If verified, RoleRouter will automatically show the dashboard.
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.resendVerificationEmail();

    if (!mounted) return;

    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Verification email sent. Please check your inbox.'
              : authVM.errorMessage ?? 'Could not send verification email.',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final email = authVM.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: _logout, child: const Text('Logout'))],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Color(0xFF0F172A),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'We have sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please open the email and click the verification link. '
                'After that, return here and confirm your verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  child: _isChecking
                      ? const CircularProgressIndicator()
                      : const Text("I've Verified My Email"),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isResending ? null : _resendVerification,
                child: _isResending
                    ? const CircularProgressIndicator()
                    : const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
