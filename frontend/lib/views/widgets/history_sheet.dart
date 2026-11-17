import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

String _clock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 1-click lookup of a student's past washroom trips.
void showHistorySheet(BuildContext context, String rawMatric) {
  final dash = context.read<DashboardViewModel>();
  final matric = DashboardViewModel.normalizeMatric(rawMatric);

  if (!DashboardViewModel.isValidMatric(matric)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid matric number first (e.g. B23CS1099)')),
    );
    return;
  }

  final history = dash.historyFor(matric);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History · $matric', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${history.length} previous trip(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No previous trips recorded.'),
            )
          else
            ...history.map((t) {
              final overdue = t.elapsed(DateTime.now()) > DashboardViewModel.tripLimit;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(overdue ? Icons.warning_amber : Icons.check_circle_outline,
                    color: overdue ? Colors.red : Colors.green),
                title: Text('${_clock(t.startedAt!)} – ${_clock(t.returnedAt!)}'),
                trailing: Text(
                  DashboardViewModel.formatDuration(t.elapsed(DateTime.now())),
                  style: TextStyle(fontWeight: FontWeight.bold, color: overdue ? Colors.red : Colors.green[800]),
                ),
              );
            }),
        ],
      ),
    ),
  );
}
