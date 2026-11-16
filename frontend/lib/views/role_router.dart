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
    final user = authVM.currentUser;

    if (user == null) {
      return const LoginView();
    }

    if (user.role == 'chief') {
      return const ChiefDashboardView();
    } else {
      return const InvigilatorDashboardView();
    }
  }
}