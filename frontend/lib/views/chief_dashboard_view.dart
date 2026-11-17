import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hall_model.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'profile_view.dart';

class ChiefDashboardView extends StatelessWidget {
  const ChiefDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardViewModel>();
    final halls = dash.halls;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UTM Counter',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
            Text('CHIEF SUPERVISOR / ALL FACULTY VENUES', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary
          Row(
            children: [
              _statTile('Out now', dash.totalActive, const Color(0xFF0F172A)),
              const SizedBox(width: 10),
              _statTile('In queue', dash.totalQueued, Colors.amber[800]!),
              const SizedBox(width: 10),
              _statTile('Overdue', dash.totalOverdue, Colors.red[700]!),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Exam Halls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${halls.length} Active Venues', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          for (final hall in halls) _buildHallCard(context, dash, hall),
        ],
      ),
    );
  }

  Widget _statTile(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHallCard(BuildContext context, DashboardViewModel dash, HallModel hall) {
    final active = dash.activeCount(hall.id);
    final queued = dash.queue(hall.id).length;
    final overdue = dash.overdueCount(hall.id);
    final isFull = dash.isFull(hall.id);

    return Card(
      elevation: 0,
      color: Colors.white,
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
                Expanded(
                  child: Text(hall.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text('Max: ${hall.maxCapacity} Students', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                    '$active / ${hall.maxCapacity}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isFull ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                    ),
                  ),
                  Text(
                    isFull ? 'FULL ($queued in Queue)' : '${hall.maxCapacity - active} Available',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Invigilator: ${hall.invigilatorName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (overdue > 0)
                  Text('$overdue overdue',
                      style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _inspectHall(context, hall),
                child: const Text('Inspect Hall'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inspectHall(BuildContext context, HallModel hall) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Consumer<DashboardViewModel>(
        builder: (context, dash, _) {
          final active = dash.activeTrips(hall.id);
          final queue = dash.queue(hall.id);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(hall.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Invigilator: ${hall.invigilatorName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  Text('Students out (${active.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (active.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('None', style: TextStyle(color: Colors.grey)),
                    ),
                  ...active.map((t) {
                    final overdue = dash.isOverdue(t);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.matric),
                      trailing: Text(
                        DashboardViewModel.formatDuration(dash.elapsed(t)),
                        style: TextStyle(fontWeight: FontWeight.bold, color: overdue ? Colors.red : Colors.green[800]),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text('Waiting queue (${queue.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (queue.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Empty', style: TextStyle(color: Colors.grey)),
                    ),
                  for (var i = 0; i < queue.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text('#${i + 1}', style: const TextStyle(color: Colors.grey)),
                      title: Text(queue[i].matric),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
