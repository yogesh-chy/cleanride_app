class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.dateJoined,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? dateJoined;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      phone: json['phone'] as String?,
      dateJoined: json['date_joined'] as String?,
    );
  }
}
