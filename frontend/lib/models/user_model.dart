class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String staffId;
  final String role; // 'invigilator' or 'chief'
  final String avatarUrl;
  final String hallId; // hall assigned to an invigilator

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.staffId,
    required this.role,
    this.avatarUrl = '',
    this.hallId = 'hall_a',
  });

  UserModel copyWith({String? fullName, String? staffId, String? avatarUrl}) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      staffId: staffId ?? this.staffId,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hallId: hallId,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      staffId: data['staffId'] ?? '',
      role: data['role'] ?? 'invigilator',
      avatarUrl: data['avatarUrl'] ?? '',
      hallId: data['hallId'] ?? 'hall_a',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'staffId': staffId,
      'role': role,
      'avatarUrl': avatarUrl,
      'hallId': hallId,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}