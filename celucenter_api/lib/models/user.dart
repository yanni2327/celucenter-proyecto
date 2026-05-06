class User {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String? phone;
  final bool isAdmin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.phone,
    this.isAdmin = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id':        id,
        'name':      name,
        'email':     email,
        if (phone != null) 'phone': phone,
        'isAdmin':   isAdmin,
        'createdAt': createdAt.toIso8601String(),
      };
}
