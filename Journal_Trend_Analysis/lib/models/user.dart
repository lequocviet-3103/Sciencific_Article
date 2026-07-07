class User {
  final String userId;
  final String firebaseUid;
  final String email;
  final String fullName;
  final String roleId;
  final String roleName;
  final bool? isBanned;

  const User({
    required this.userId,
    required this.firebaseUid,
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.roleName,
    this.isBanned,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      firebaseUid: json['firebaseUid']?.toString() ?? json['firebase_uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      roleId: json['roleId']?.toString() ?? json['role_id']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? json['role_name']?.toString() ?? '',
      isBanned: json['isBanned'] as bool? ?? json['is_banned'] as bool?,
    );
  }
}
