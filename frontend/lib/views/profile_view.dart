import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _staffController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _staffController = TextEditingController(text: user?.staffId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _staffController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authVM = context.read<AuthViewModel>();
    final ok = await authVM.updateProfile(
      fullName: _nameController.text,
      staffId: _staffController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Profile updated' : (authVM.errorMessage ?? 'Could not save profile'))),
    );
  }

  Future<void> _logout() async {
    final authVM = context.read<AuthViewModel>();
    final navigator = Navigator.of(context);
    await authVM.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final dash = context.watch<DashboardViewModel>();
    final user = authVM.currentUser;

    if (user == null) return const LoginView();

    final isChief = user.role == 'chief';
    final hallName = isChief ? 'All faculty venues' : (dash.hallById(user.hallId)?.name ?? 'Unassigned');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text('My Profile',
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(_initials(user.fullName),
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isChief ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isChief ? 'CHIEF SUPERVISOR' : 'HALL INVIGILATOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isChief ? Colors.amber[900] : Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Read-only info
              _readOnlyField('Email', user.email, Icons.email_outlined),
              const SizedBox(height: 14),
              _readOnlyField('Assigned venue', hallName, Icons.meeting_room_outlined),
              const SizedBox(height: 14),

              // Editable fields
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Full name', Icons.person_outline),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Full name is required';
                  if (value.length < 3) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _staffController,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration('Staff ID', Icons.badge_outlined),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Staff ID is required' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: authVM.isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: authVM.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return InputDecorator(
      decoration: _decoration(label, icon).copyWith(filled: true, fillColor: const Color(0xFFF1F5F9)),
      child: Text(value.isEmpty ? '-' : value, style: const TextStyle(color: Color(0xFF475569))),
    );
  }
}
