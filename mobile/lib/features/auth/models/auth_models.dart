class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? licenseNumber;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.licenseNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      licenseNumber: json['license_number'] as String?,
    );
  }

  bool get isDoctor => role == 'doctor';
  bool get isAssistant => role == 'assistant';
}

class AuthResponse {
  final String accessToken;
  final UserModel user;

  const AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}