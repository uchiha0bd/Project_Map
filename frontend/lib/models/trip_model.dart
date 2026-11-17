enum TripStatus { queued, active, returned }

/// One washroom trip (or a request waiting in the queue for one).
class TripModel {
  final String id;
  final String hallId;
  final String matric;
  final TripStatus status;
  final DateTime queuedAt;
  final DateTime? startedAt;
  final DateTime? returnedAt;

  const TripModel({
    required this.id,
    required this.hallId,
    required this.matric,
    required this.status,
    required this.queuedAt,
    this.startedAt,
    this.returnedAt,
  });

  TripModel copyWith({
    TripStatus? status,
    DateTime? startedAt,
    DateTime? returnedAt,
  }) {
    return TripModel(
      id: id,
      hallId: hallId,
      matric: matric,
      status: status ?? this.status,
      queuedAt: queuedAt,
      startedAt: startedAt ?? this.startedAt,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }

  /// Time spent outside the hall. Runs live while active, frozen once returned.
  Duration elapsed(DateTime now) {
    if (startedAt == null) return Duration.zero;
    return (returnedAt ?? now).difference(startedAt!);
  }
}
