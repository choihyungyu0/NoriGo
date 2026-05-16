class ServiceResult<T> {
  const ServiceResult._({required this.isSuccess, this.data, this.userMessage});

  factory ServiceResult.success(T data) {
    return ServiceResult._(isSuccess: true, data: data);
  }

  factory ServiceResult.failure(String userMessage) {
    return ServiceResult._(isSuccess: false, userMessage: userMessage);
  }

  final bool isSuccess;
  final T? data;
  final String? userMessage;
}
