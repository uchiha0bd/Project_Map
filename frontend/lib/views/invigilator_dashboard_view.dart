import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'profile_view.dart';
import 'widgets/history_sheet.dart';

class InvigilatorDashboardView extends StatefulWidget {
  const InvigilatorDashboardView({super.key});

  @override
  State<InvigilatorDashboardView> createState() => _InvigilatorDashboardViewState();
}

class _InvigilatorDashboardViewState extends State<InvigilatorDashboardView> {
  final _matricController = TextEditingController();

  @override
  void dispose() {
    _matricController.dispose();
    super.dispose();
  }

  void _handleStart(String hallId) {
    final dash = context.read<DashboardViewModel>();
    final result = dash.startTrip(hallId, _matricController.text);

    String message;
    switch (result) {
      case StartTripResult.started:
        message = 'Timer started';
        _matricController.clear();
        break;
      case StartTripResult.queued:
        message = 'Hall is full - student added to the queue';
        _matricController.clear();
        break;
      case StartTripResult.invalidMatric:
        message = 'Invalid matric number (format: B23CS1099)';
        break;
      case StartTripResult.duplicate:
        message = 'This student is already out or in a queue';
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final dash = context.watch<DashboardViewModel>();
    final user = authVM.currentUser;

    final hall = dash.hallById(user?.hallId ?? '') ?? dash.halls.first;
    final active = dash.activeTrips(hall.id);
    final queue = dash.queue(hall.id);
    final isFull = dash.isFull(hall.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UTM Counter',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
            Text(
              'EXAM SESSION / ${hall.name.toUpperCase()} (${user?.fullName ?? "Invigilator"})',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My profile',
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileView()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capacity pill
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
                        ? 'Capacity: ${active.length}/${hall.maxCapacity} (FULL)'
                        : 'Capacity: ${active.length}/${hall.maxCapacity} (Slot Available)',
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

            // Start a trip
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start a washroom trip',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _matricController,
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _handleStart(hall.id),
                      decoration: InputDecoration(
                        hintText: 'Enter matric number (e.g. B23CS1099)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          tooltip: 'Student history',
                          icon: const Icon(Icons.history),
                          onPressed: () => showHistorySheet(context, _matricController.text),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _handleStart(hall.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          isFull ? 'Put in Queue (#${queue.length + 1})' : 'Start Timer',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active trips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${active.length} students out', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No students outside the hall.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...active.map((trip) => _buildTripCard(
                    trip: trip,
                    time: DashboardViewModel.formatDuration(dash.elapsed(trip)),
                    isOverdue: dash.isOverdue(trip),
                    onReturn: () => context.read<DashboardViewModel>().returnTrip(trip.id),
                  )),

            // Queue
            if (queue.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waiting queue (${queue.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    for (var i = 0; i < queue.length; i++)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFFEF3C7),
                            child: Text('${i + 1}',
                                style: TextStyle(fontSize: 12, color: Colors.amber[800], fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(queue[i].matric,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          if (i == 0 && !isFull)
                            ElevatedButton(
                              onPressed: () => context.read<DashboardViewModel>().approveNext(hall.id),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          IconButton(
                            tooltip: 'Remove from queue',
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            onPressed: () => context.read<DashboardViewModel>().cancelQueued(queue[i].id),
                          ),
                        ],
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
    required TripModel trip,
    required String time,
    required bool isOverdue,
    required VoidCallback onReturn,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
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
                Text(trip.matric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                Text(time,
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red : Colors.green[800])),
                OutlinedButton(onPressed: onReturn, child: const Text('Mark returned')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
