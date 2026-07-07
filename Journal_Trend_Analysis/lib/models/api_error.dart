class ApiError implements Exception {
  final String message;
  final int? statusCode;

  const ApiError(this.message, {this.statusCode});

  @override
  String toString() => 'ApiError(${statusCode ?? "unknown"}): $message';
}
