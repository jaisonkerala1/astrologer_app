/// Base repository interface for common repository operations
/// All repositories should implement error handling and data transformation
abstract class BaseRepository {
  /// Handle API errors and convert to domain-friendly error messages
  String handleError(dynamic error) {
    if (error.toString().contains('Connection refused')) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('404')) {
      return 'Resource not found.';
    } else if (error.toString().contains('401') || error.toString().contains('403')) {
      return 'Unauthorized. Please login again.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}


