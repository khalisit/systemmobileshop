class AppUserModel {
  final String id;
  final String username;
  final String fullName;
  final String? email;
  final String role; // 'admin' or 'cashier'
  final DateTime createdAt;

  AppUserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.role = 'admin',
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    final meta = json['raw_user_meta_data'] as Map<String, dynamic>? ??
        json['user_metadata'] as Map<String, dynamic>? ?? {};
    final email = json['email'] as String?;
    final rawUsername = json['username'] as String? ??
        meta['username'] as String? ??
        email?.split('@').first ??
        '';
    final rawFullName = json['full_name'] as String? ??
        json['fullName'] as String? ??
        meta['full_name'] as String? ??
        rawUsername;
    final role = (json['role'] as String?) ??
        (meta['role'] as String?) ??
        'admin';

    return AppUserModel(
      id: json['id'] as String? ?? '',
      username: rawUsername,
      fullName: rawFullName,
      email: email,
      role: role,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
