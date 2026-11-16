import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class ChiefDashboardView extends StatelessWidget {
  const ChiefDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UTM Counter', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
            Text('CHIEF SUPERVISOR / ALL FACULTY VENUES', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('All Exam Halls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('3 Active Venues', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          // Hall 1: Hall A (Max 2 - FULL)
          _buildHallCard(
            context: context,
            hallName: 'Hall A (CS101)',
            maxCapacity: 2,
            activeCount: 2,
            queueCount: 1,
            invigilator: 'Mahmood Talib',
            isFull: true,
          ),

          // Hall 2: DSI (Max 4 - 3 Available)
          _buildHallCard(
            context: context,
            hallName: 'Dewan Sultan Iskandar (DSI)',
            maxCapacity: 4,
            activeCount: 1,
            queueCount: 0,
            invigilator: 'Dr. Jumail',
            isFull: false,
          ),

          // Hall 3: Hall N24 (Max 3 - All Available)
          _buildHallCard(
            context: context,
            hallName: 'Hall N24 (Lab 3)',
            maxCapacity: 3,
            activeCount: 0,
            queueCount: 0,
            invigilator: 'Ms. Hanie',
            isFull: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHallCard({
    required BuildContext context,
    required String hallName,
    required int maxCapacity,
    required int activeCount,
    required int queueCount,
    required String invigilator,
    required bool isFull,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isFull ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(hallName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Max: $maxCapacity Students', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFull ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$activeCount / $maxCapacity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isFull ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                    ),
                  ),
                  Text(
                    isFull ? 'FULL ($queueCount in Queue)' : '${maxCapacity - activeCount} Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFull ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Invigilator: $invigilator', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Inspect Hall'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}