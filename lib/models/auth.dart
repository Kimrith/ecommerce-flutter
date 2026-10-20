class UserPayload {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;

  const UserPayload({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
  });

  static String? _parsePhone(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is Map) {
      final phoneVal = value['number'] ?? value['phone'] ?? value['value'];
      return phoneVal?.toString();
    }
    return value.toString();
  }

  factory UserPayload.fromJson(Map<String, dynamic> json) {
    return UserPayload(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: _parsePhone(json['phone']),
      role: (json['role'] ?? 'USER').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }

  UserPayload copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
  }) {
    return UserPayload(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserPayload user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Handle both wrapped NestJS response {"data": {...}} and raw payload
    final target = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return AuthResponse(
      accessToken: (target['accessToken'] ?? '').toString(),
      refreshToken: (target['refreshToken'] ?? '').toString(),
      user: UserPayload.fromJson(
        (target['user'] is Map<String, dynamic>)
            ? target['user'] as Map<String, dynamic>
            : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}

class LoginDto {
  final String email;
  final String password;

  const LoginDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'password': password,
    };
  }
}

class RegisterDto {
  final String email;
  final String password;
  final String name;
  final String? phone;
  final String role;

  const RegisterDto({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    this.role = 'USER',
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'role': role,
    };
    if (phone != null && phone!.trim().isNotEmpty) {
      map['phone'] = phone!.trim();
    }
    return map;
  }
}

class RefreshTokenDto {
  final String refreshToken;

  const RefreshTokenDto({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}
