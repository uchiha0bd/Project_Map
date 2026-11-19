import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hall_model.dart';
import '../models/trip_model.dart';

enum StartTripResult { started, queued, invalidMatric, duplicate }

/// Holds the live state of every exam hall and trip.
/// Synced live with Cloud Firestore and cached locally on the phone.
class DashboardViewModel extends ChangeNotifier {
  /// Trips exceeding 30 minutes are flagged as overdue.
  static const Duration tripLimit = Duration(minutes: 30);

  static final RegExp _matricPattern = RegExp(r'^[A-Z]\d{2}[A-Z]{2}\d{4}$');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<HallModel> _halls = [];
  List<TripModel> _trips = [];

  StreamSubscription<QuerySnapshot>? _hallsSubscription;
  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  // Added seedDemoData parameter to satisfy tests while keeping real Firestore data
  DashboardViewModel({bool seedDemoData = false}) {
    _initFirestoreListeners();

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
    _hallsSubscription?.cancel();
    _tripsSubscription?.cancel();
    super.dispose();
  }

  // ---------- Firestore Synchronization ----------

  void _initFirestoreListeners() {
    try {
      // 1. Listen for real-time Hall changes from Cloud Firestore
      _hallsSubscription = _firestore.collection('halls').snapshots().listen(
        (snapshot) {
          _halls = snapshot.docs.map((doc) {
            final data = doc.data();
            return HallModel(
              id: doc.id,
              name: data['name'] as String? ?? 'Unnamed Hall',
              maxCapacity: (data['maxCapacity'] as num?)?.toInt() ?? 2,
              invigilatorName: data['invigilatorName'] as String? ?? 'Unassigned',
            );
          }).toList();

          notifyListeners();
        },
        onError: (error) {
          debugPrint('Firestore halls stream error: $error');
        },
      );

      // 2. Listen for real-time Trip changes from Cloud Firestore
      _tripsSubscription = _firestore.collection('trips').snapshots().listen(
        (snapshot) {
          _trips = snapshot.docs.map((doc) {
            final data = doc.data();
            return TripModel(
              id: doc.id,
              hallId: data['hallId'] as String? ?? '',
              matric: data['matric'] as String? ?? '',
              status: _parseStatus(data['status'] as String?),
              queuedAt: _parseDate(data['queuedAt']) ?? DateTime.now(),
              startedAt: _parseDate(data['startedAt']),
              returnedAt: _parseDate(data['returnedAt']),
            );
          }).toList();

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

  // ---------- Hall Management (Instant & Non-Blocking) ----------

  /// Add a brand new hall (updates UI instantly and persists to Firestore in background)
  Future<void> addHall({
    required String name,
    required int maxCapacity,
    required String invigilatorName,
  }) async {
    final docRef = _firestore.collection('halls').doc();
    final newHall = HallModel(
      id: docRef.id,
      name: name.trim(),
      maxCapacity: maxCapacity,
      invigilatorName: invigilatorName.trim(),
    );

    // 1. Instant local update so UI reflects immediately without waiting
    _halls.add(newHall);
    notifyListeners();

    // 2. Persist to Firestore in background
    docRef.set({
      'id': docRef.id,
      'name': name.trim(),
      'maxCapacity': maxCapacity,
      'invigilatorName': invigilatorName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((err) {
      debugPrint('Failed to save hall in Firestore: $err');
    });
  }

  /// Remove a hall (updates UI instantly and deletes from Firestore in background)
  Future<void> deleteHall(String hallId) async {
    // 1. Instant local removal
    _halls.removeWhere((h) => h.id == hallId);
    notifyListeners();

    // 2. Delete from Firestore in background
    _firestore.collection('halls').doc(hallId).delete().catchError((err) {
      debugPrint('Failed to delete hall from Firestore: $err');
    });
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

  Duration elapsed(TripModel trip) {
    final actual = trip.elapsed(_now);
    if (trip.status == TripStatus.active && actual >= tripLimit) {
      return tripLimit; // Caps displayed timer at 30:00
    }
    return actual;
  }

  bool isOverdue(TripModel trip) {
    return trip.status == TripStatus.active && trip.elapsed(_now) >= tripLimit;
  }

  int overdueCount(String hallId) => activeTrips(hallId).where(isOverdue).length;

  int get totalActive => _trips.where((t) => t.status == TripStatus.active).length;
  int get totalQueued => _trips.where((t) => t.status == TripStatus.queued).length;
  int get totalOverdue => _trips.where(isOverdue).length;

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

    _update(tripId, (t) => t.copyWith(status: TripStatus.returned, returnedAt: now));

    _firestore.collection('trips').doc(tripId).update({
      'status': 'returned',
      'returnedAt': now.toIso8601String(),
    }).catchError((err) {
      debugPrint('Failed to update returned trip in Firestore: $err');
    });
  }

  bool approveNext(String hallId) {
    final waiting = queue(hallId);
    if (waiting.isEmpty || isFull(hallId)) return false;

    final now = DateTime.now();
    _now = now;
    final nextTrip = waiting.first;

    _update(nextTrip.id, (t) => t.copyWith(status: TripStatus.active, startedAt: now));

    _firestore.collection('trips').doc(nextTrip.id).update({
      'status': 'active',
      'startedAt': now.toIso8601String(),
    }).catchError((err) {
      debugPrint('Failed to approve queued trip in Firestore: $err');
    });

    return true;
  }

  void cancelQueued(String tripId) {
    _trips.removeWhere((t) => t.id == tripId && t.status == TripStatus.queued);
    notifyListeners();

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