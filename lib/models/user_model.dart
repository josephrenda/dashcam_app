class UserModel {
  final String id;
  final String email;
  final String username;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? map['user_id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      accessToken: map['accessToken'] ?? map['access_token'],
      refreshToken: map['refreshToken'] ?? map['refresh_token'],
      tokenExpiry: map['tokenExpiry'] != null
          ? DateTime.parse(map['tokenExpiry'])
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
  
  bool get isTokenExpired {
    if (tokenExpiry == null) return true;
    return DateTime.now().isAfter(tokenExpiry!);
  }
}
