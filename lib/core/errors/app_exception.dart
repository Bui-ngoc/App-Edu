class AppException implements Exception {
  final String message;
  final String? technicalDetail;

  AppException(this.message, [this.technicalDetail]);

  @override
  String toString() => message;
}

class NetworkTimeoutException extends AppException {
  NetworkTimeoutException([super.message = 'Yêu cầu kết nối quá thời gian chờ (Timeout). Vui lòng kiểm tra lại mạng!']);
}

class CorruptedDataException extends AppException {
  CorruptedDataException([super.message = 'Dữ liệu không đúng định dạng. Hệ thống đã khôi phục bản mặc định.']);
}

class NotFoundException extends AppException {
  NotFoundException([super.message = 'Không tìm thấy dữ liệu yêu cầu.']);
}
