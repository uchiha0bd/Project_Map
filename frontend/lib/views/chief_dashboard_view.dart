import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hall_model.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'profile_view.dart';

class ChiefDashboardView extends StatefulWidget {
  const ChiefDashboardView({super.key});

  @override
  State<ChiefDashboardView> createState() => _ChiefDashboardViewState();
}

class _ChiefDashboardViewState extends State<ChiefDashboardView> {
  // Shows dialog to add a brand new hall into Cloud Firestore
  void _showAddHallDialog(BuildContext context) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '2');
    final invigilatorController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Add Exam Hall', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Hall Name / Venue',
                    hintText: 'e.g. Dewan Sultan Iskandar (DSI)',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Max Out Capacity',
                    hintText: 'e.g. 2, 3, 4',
                    prefixIcon: Icon(Icons.people_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: invigilatorController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Invigilator',
                    hintText: 'e.g. Dr. Jumail / Mahmood',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final capacity = int.tryParse(capacityController.text.trim()) ?? 0;
                      final invigilator = invigilatorController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a hall name.')),
                        );
                        return;
                      }

                      if (capacity <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Max capacity must be at least 1.')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final dash = context.read<DashboardViewModel>();
                      await dash.addHall(
                        name: name,
                        maxCapacity: capacity,
                        invigilatorName: invigilator.isNotEmpty ? invigilator : 'Unassigned',
                      );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green[800],
                          content: Text('Hall "$name" added successfully!'),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Add Hall'),
            ),
          ],
        ),
      ),
    );
  }

 // Shows confirmation dialog before deleting a hall
  void _confirmDeleteHall(BuildContext context, HallModel hall) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove Hall?'),
        content: Text('Are you sure you want to remove "${hall.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final dash = context.read<DashboardViewModel>();

              // 1. Close dialog immediately
              Navigator.pop(ctx);

              // 2. Delete hall instantly (updates UI & Firestore)
              dash.deleteHall(hall.id);

              // 3. Show feedback without async context issues
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red[800],
                  content: Text('Removed "${hall.name}".'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
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
            Text('CHIEF SUPERVISOR / ALL VENUES', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Hall',
            icon: const Icon(Icons.add_business_outlined, color: Color(0xFF0F172A)),
            onPressed: () => _showAddHallDialog(context),
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHallDialog(context),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Hall'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary statistics
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

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Exam Halls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${halls.length} Active Venues', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state placeholder
          if (halls.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'No Exam Halls Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap "Add Hall" below to create your first venue.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddHallDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Hall'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final hall in halls) _buildHallCard(context, dash, hall),

          // Extra spacing so FAB doesn't cover content
          const SizedBox(height: 80),
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
                  child: Text(
                    hall.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove Hall',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDeleteHall(context, hall),
                ),
              ],
            ),
            Text('Max: ${hall.maxCapacity} Students at once', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
            const SizedBox(height: 10),
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