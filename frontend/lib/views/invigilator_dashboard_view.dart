import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class InvigilatorDashboardView extends StatefulWidget {
  const InvigilatorDashboardView({super.key});

  @override
  State<InvigilatorDashboardView> createState() => _InvigilatorDashboardViewState();
}

class _InvigilatorDashboardViewState extends State<InvigilatorDashboardView> {
  final _matricController = TextEditingController();
  final List<String> _queue = ['B23CS1099'];
  int _activeCount = 2;
  final int _maxCapacity = 2;

  @override
  void dispose() {
    _matricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final isFull = _activeCount >= _maxCapacity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UTM Counter',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              'EXAM SESSION / HALL A · CS101 (${authVM.currentUser?.fullName ?? "Invigilator"})',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await authVM.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capacity Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isFull ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isFull ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  Icon(isFull ? Icons.warning_amber : Icons.check_circle_outline,
                      size: 16, color: isFull ? Colors.red : Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    isFull
                        ? 'Capacity: $_activeCount/$_maxCapacity (FULL) • Saved locally'
                        : 'Capacity: $_activeCount/$_maxCapacity (Slot Available)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFull ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Start a Trip Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start a washroom trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _matricController,
                      decoration: InputDecoration(
                        hintText: 'Enter matric number (e.g. B23CS1099)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_matricController.text.isNotEmpty) {
                            setState(() {
                              _queue.add(_matricController.text.trim());
                              _matricController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          isFull ? 'Put in Queue (#${_queue.length + 1})' : 'Start Timer',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Trips Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$_activeCount students out', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            // Card 1 (Red Overdue)
            _buildTripCard(
              matric: 'B23CS1042',
              time: '05:32',
              isOverdue: true,
              onReturn: () {
                setState(() => _activeCount = (_activeCount > 0) ? _activeCount - 1 : 0);
              },
            ),

            // Card 2 (Normal)
            _buildTripCard(
              matric: 'B23CS1088',
              time: '01:15',
              isOverdue: false,
              onReturn: () {
                setState(() => _activeCount = (_activeCount > 0) ? _activeCount - 1 : 0);
              },
            ),

            // Queue Section
            if (_queue.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Text('Q', style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Waiting Queue: ${_queue.join(", ")}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    if (!isFull)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _queue.removeAt(0);
                            _activeCount++;
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard({
    required String matric,
    required String time,
    required bool isOverdue,
    required VoidCallback onReturn,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isOverdue ? Colors.red : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(matric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOverdue ? 'OVERDUE' : 'Within limit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red : Colors.green[800])),
                OutlinedButton(
                  onPressed: onReturn,
                  child: const Text('Mark returned'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}