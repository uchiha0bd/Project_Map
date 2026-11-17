import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hall_model.dart';
import '../models/trip_model.dart';

enum StartTripResult { started, queued, invalidMatric, duplicate }

/// Holds the live state of every exam hall: who is out, who is queued and
/// how long each student has been away. Shared by the invigilator and chief
/// dashboards so the chief sees what invigilators record.
class DashboardViewModel extends ChangeNotifier {
  /// A trip longer than this is flagged as overdue.
  static const Duration tripLimit = Duration(minutes: 5);

  static final RegExp _matricPattern = RegExp(r'^[A-Z]\d{2}[A-Z]{2}\d{4}$');

  final List<HallModel> _halls = const [
    HallModel(id: 'hall_a', name: 'Hall A (CS101)', maxCapacity: 2, invigilatorName: 'Mahmood Talib'),
    HallModel(id: 'hall_dsi', name: 'Dewan Sultan Iskandar (DSI)', maxCapacity: 4, invigilatorName: 'Dr. Jumail'),
    HallModel(id: 'hall_n24', name: 'Hall N24 (Lab 3)', maxCapacity: 3, invigilatorName: 'Ms. Hanie'),
  ];
  final List<TripModel> _trips = [];

  Timer? _ticker;
  DateTime _now = DateTime.now();
  int _nextId = 1;

  DashboardViewModel({bool seedDemoData = true}) {
    if (seedDemoData) _seed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      if (_trips.any((t) => t.status == TripStatus.active)) notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---------- Queries ----------

  List<HallModel> get halls => List.unmodifiable(_halls);

  HallModel? hallById(String id) {
    for (final h in _halls) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<TripModel> activeTrips(String hallId) {
    final list = _trips.where((t) => t.hallId == hallId && t.status == TripStatus.active).toList();
    list.sort((a, b) => a.startedAt!.compareTo(b.startedAt!));
    return list;
  }

  List<TripModel> queue(String hallId) {
    final list = _trips.where((t) => t.hallId == hallId && t.status == TripStatus.queued).toList();
    list.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return list;
  }

  int activeCount(String hallId) => activeTrips(hallId).length;

  bool isFull(String hallId) {
    final hall = hallById(hallId);
    return hall != null && activeCount(hallId) >= hall.maxCapacity;
  }

  Duration elapsed(TripModel trip) => trip.elapsed(_now);

  bool isOverdue(TripModel trip) => trip.status == TripStatus.active && elapsed(trip) > tripLimit;

  int overdueCount(String hallId) => activeTrips(hallId).where(isOverdue).length;

  int get totalActive => _trips.where((t) => t.status == TripStatus.active).length;
  int get totalQueued => _trips.where((t) => t.status == TripStatus.queued).length;
  int get totalOverdue => _trips.where(isOverdue).length;

  /// Past (returned) trips for one student, newest first.
  List<TripModel> historyFor(String rawMatric) {
    final matric = normalizeMatric(rawMatric);
    final list = _trips.where((t) => t.matric == matric && t.status == TripStatus.returned).toList();
    list.sort((a, b) => b.startedAt!.compareTo(a.startedAt!));
    return list;
  }

  // ---------- Commands ----------

  StartTripResult startTrip(String hallId, String rawMatric) {
    final matric = normalizeMatric(rawMatric);
    if (!isValidMatric(matric)) return StartTripResult.invalidMatric;

    final alreadyOut = _trips.any((t) => t.matric == matric && t.status != TripStatus.returned);
    if (alreadyOut) return StartTripResult.duplicate;

    final now = DateTime.now();
    _now = now;
    final full = isFull(hallId);
    _trips.add(TripModel(
      id: 'trip_${_nextId++}',
      hallId: hallId,
      matric: matric,
      status: full ? TripStatus.queued : TripStatus.active,
      queuedAt: now,
      startedAt: full ? null : now,
    ));
    notifyListeners();
    return full ? StartTripResult.queued : StartTripResult.started;
  }

  void returnTrip(String tripId) {
    final now = DateTime.now();
    _now = now;
    _update(tripId, (t) => t.copyWith(status: TripStatus.returned, returnedAt: now));
  }

  /// Moves the first queued student out of the queue if a slot is free.
  bool approveNext(String hallId) {
    final waiting = queue(hallId);
    if (waiting.isEmpty || isFull(hallId)) return false;
    final now = DateTime.now();
    _now = now;
    _update(waiting.first.id, (t) => t.copyWith(status: TripStatus.active, startedAt: now));
    return true;
  }

  void cancelQueued(String tripId) {
    _trips.removeWhere((t) => t.id == tripId && t.status == TripStatus.queued);
    notifyListeners();
  }

  // ---------- Helpers ----------

  static String normalizeMatric(String raw) => raw.trim().toUpperCase();

  static bool isValidMatric(String matric) => _matricPattern.hasMatch(matric);

  static String formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _update(String id, TripModel Function(TripModel) change) {
    final i = _trips.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _trips[i] = change(_trips[i]);
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    TripModel trip(String hall, String matric, TripStatus status, {Duration? ago, Duration? length}) {
      final start = ago == null ? null : now.subtract(ago);
      return TripModel(
        id: 'trip_${_nextId++}',
        hallId: hall,
        matric: matric,
        status: status,
        queuedAt: start ?? now,
        startedAt: start,
        returnedAt: (start != null && length != null) ? start.add(length) : null,
      );
    }

    _trips.addAll([
      trip('hall_a', 'B23CS1042', TripStatus.active, ago: const Duration(minutes: 5, seconds: 32)),
      trip('hall_a', 'B23CS1088', TripStatus.active, ago: const Duration(minutes: 1, seconds: 15)),
      trip('hall_a', 'B23CS1099', TripStatus.queued),
      trip('hall_dsi', 'B22CS2001', TripStatus.active, ago: const Duration(minutes: 2)),
      trip('hall_a', 'B23CS1042', TripStatus.returned, ago: const Duration(minutes: 40), length: const Duration(minutes: 3, seconds: 20)),
    ]);
  }
}
