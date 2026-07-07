class Role {
  final String roleId;
  final String? roleName;
  final String? description;

  const Role({
    required this.roleId,
    this.roleName,
    this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['roleId']?.toString() ?? json['role_id']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? json['role_name']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
