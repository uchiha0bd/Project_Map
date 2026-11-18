import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'invigilator_dashboard_view.dart';
import 'chief_dashboard_view.dart';
import 'login_view.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    // If still checking phone disk on launch, show a loading indicator
    if (authVM.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      );
    }

    final user = authVM.currentUser;

    // No user saved on phone? Go to Login
    if (user == null) {
      return const LoginView();
    }

    // User is saved on phone! Open their dashboard immediately
    if (user.role == 'chief') {
      return const ChiefDashboardView();
    } else {
      return const InvigilatorDashboardView();
    }
  }
}