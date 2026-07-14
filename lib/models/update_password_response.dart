class UpdatePasswordResponse {
  final bool success;
  final String message;
  final int userId;
  final int clienteId;

  UpdatePasswordResponse({
    required this.success,
    required this.message,
    required this.userId,
    required this.clienteId,
  });

  factory UpdatePasswordResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      userId: json['user_id'] ?? 0,
      clienteId: json['cliente_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user_id': userId,
      'cliente_id': clienteId,
    };
  }
}
