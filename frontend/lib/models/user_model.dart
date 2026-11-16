class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String staffId;
  final String role; // 'invigilator' or 'chief'
  final String avatarUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.staffId,
    required this.role,
    this.avatarUrl = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      staffId: data['staffId'] ?? '',
      role: data['role'] ?? 'invigilator',
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'staffId': staffId,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}