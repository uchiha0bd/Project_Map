import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hall_model.dart';
import '../models/trip_model.dart';

enum StartTripResult { started, queued, invalidMatric, duplicate }

/// Holds the live state of every exam hall: who is out, who is queued, and
/// how long each student has been away. Synced live with Cloud Firestore.
class DashboardViewModel extends ChangeNotifier {
  /// Trips exceeding 30 minutes are flagged as overdue.
  static const Duration tripLimit = Duration(minutes: 30);

  static final RegExp _matricPattern = RegExp(r'^[A-Z]\d{2}[A-Z]{2}\d{4}$');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<HallModel> _halls = const [
    HallModel(id: 'hall_a', name: 'Hall A (CS101)', maxCapacity: 2, invigilatorName: 'Mahmood Talib'),
    HallModel(id: 'hall_dsi', name: 'Dewan Sultan Iskandar (DSI)', maxCapacity: 4, invigilatorName: 'Dr. Jumail'),
    HallModel(id: 'hall_n24', name: 'Hall N24 (Lab 3)', maxCapacity: 3, invigilatorName: 'Ms. Hanie'),
  ];

  List<TripModel> _trips = [];
  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  DashboardViewModel() {
    _initFirestoreListener();

    // 1-second ticker to update live timers
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      if (_trips.any((t) => t.status == TripStatus.active)) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tripsSubscription?.cancel();
    super.dispose();
  }

  // ---------- Firestore Synchronization ----------

  void _initFirestoreListener() {
    try {
      _tripsSubscription = _firestore.collection('trips').snapshots().listen(
        (snapshot) {
          final loadedTrips = snapshot.docs.map((doc) {
            final data = doc.data();
            return TripModel(
              id: doc.id,
              hallId: data['hallId'] as String? ?? 'hall_a',
              matric: data['matric'] as String? ?? '',
              status: _parseStatus(data['status'] as String?),
              queuedAt: _parseDate(data['queuedAt']) ?? DateTime.now(),
              startedAt: _parseDate(data['startedAt']),
              returnedAt: _parseDate(data['returnedAt']),
            );
          }).toList();

          _trips = loadedTrips;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Firestore trips stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Firestore initialization failed: $e');
    }
  }

  TripStatus _parseStatus(String? status) {
    switch (status) {
      case 'queued':
        return TripStatus.queued;
      case 'returned':
        return TripStatus.returned;
      case 'active':
      default:
        return TripStatus.active;
    }
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
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
    list.sort((a, b) => (a.startedAt ?? a.queuedAt).compareTo(b.startedAt ?? b.queuedAt));
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

  /// Stops timer counting at 30 minutes (30:00) once overdue limit is reached
  Duration elapsed(TripModel trip) {
    final actual = trip.elapsed(_now);
    if (trip.status == TripStatus.active && actual >= tripLimit) {
      return tripLimit; // Caps displayed timer at 30:00
    }
    return actual;
  }

  /// True if student has been away for 30 minutes or more
  bool isOverdue(TripModel trip) {
    return trip.status == TripStatus.active && trip.elapsed(_now) >= tripLimit;
  }

  int overdueCount(String hallId) => activeTrips(hallId).where(isOverdue).length;

  int get totalActive => _trips.where((t) => t.status == TripStatus.active).length;
  int get totalQueued => _trips.where((t) => t.status == TripStatus.queued).length;
  int get totalOverdue => _trips.where(isOverdue).length;

  /// Past (returned) trips for one student, newest first.
  List<TripModel> historyFor(String rawMatric) {
    final matric = normalizeMatric(rawMatric);
    final list = _trips.where((t) => t.matric == matric && t.status == TripStatus.returned).toList();
    list.sort((a, b) => (b.startedAt ?? b.queuedAt).compareTo(a.startedAt ?? a.queuedAt));
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
    final status = full ? TripStatus.queued : TripStatus.active;

    // 1. Optimistic local update (instant UI reaction)
    final tempDocRef = _firestore.collection('trips').doc();
    final newTrip = TripModel(
      id: tempDocRef.id,
      hallId: hallId,
      matric: matric,
      status: status,
      queuedAt: now,
      startedAt: full ? null : now,
    );
    _trips.add(newTrip);
    notifyListeners();

    // 2. Persist to real Cloud Firestore database
    tempDocRef.set({
      'id': tempDocRef.id,
      'hallId': hallId,
      'matric': matric,
      'status': full ? 'queued' : 'active',
      'queuedAt': now.toIso8601String(),
      'startedAt': full ? null : now.toIso8601String(),
      'returnedAt': null,
    }).catchError((err) {
      debugPrint('Failed to save trip to Firestore: $err');
    });

    return full ? StartTripResult.queued : StartTripResult.started;
  }

  void returnTrip(String tripId) {
    final now = DateTime.now();
    _now = now;

    // 1. Optimistic local update
    _update(tripId, (t) => t.copyWith(status: TripStatus.returned, returnedAt: now));

    // 2. Update Firestore
    _firestore.collection('trips').doc(tripId).update({
      'status': 'returned',
      'returnedAt': now.toIso8601String(),
    }).catchError((err) {
      debugPrint('Failed to update returned trip in Firestore: $err');
    });
  }

  /// Moves the first queued student out of the queue if a slot is free.
  bool approveNext(String hallId) {
    final waiting = queue(hallId);
    if (waiting.isEmpty || isFull(hallId)) return false;

    final now = DateTime.now();
    _now = now;
    final nextTrip = waiting.first;

    // 1. Optimistic local update
    _update(nextTrip.id, (t) => t.copyWith(status: TripStatus.active, startedAt: now));

    // 2. Update Firestore
    _firestore.collection('trips').doc(nextTrip.id).update({
      'status': 'active',
      'startedAt': now.toIso8601String(),
    }).catchError((err) {
      debugPrint('Failed to approve queued trip in Firestore: $err');
    });

    return true;
  }

  void cancelQueued(String tripId) {
    // 1. Optimistic local update
    _trips.removeWhere((t) => t.id == tripId && t.status == TripStatus.queued);
    notifyListeners();

    // 2. Delete from Firestore
    _firestore.collection('trips').doc(tripId).delete().catchError((err) {
      debugPrint('Failed to delete queued trip from Firestore: $err');
    });
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
}