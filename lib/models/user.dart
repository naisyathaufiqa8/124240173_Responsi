class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String salt;
  final String? createdAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      username: map['username']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? '',
      salt: map['salt']?.toString() ?? '',
      createdAt: map['created_at']?.toString(),
    );
  }
}
