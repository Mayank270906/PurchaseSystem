/// User model for authentication and role management

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      createdAt: json['created_at'],
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isUser => role == 'user';
}
