class ApiConstants {
  //Laravel backend URL
  static const String baseUrl = 'http://192.168.1.67:8000/api/v1';

  // Auth endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';

  // Main endpoints
  static const String doctors = '$baseUrl/doctors';
  static const String appointments = '$baseUrl/appointments';
  static const String specializations = '$baseUrl/specializations';
  static const String patientView = '$baseUrl/patient-view';
  static const String doctorView = '$baseUrl/doctor-view';

  // Payment endpoints
  static const String payments = '$baseUrl/payments';
  static const String paymentVerify = '$baseUrl/payment/verify';
  static const String paymentFailure = '$baseUrl/payment/failure';

  // Dynamic endpoints (use with string interpolation)
  static String appointmentPaymentInitiate(int appointmentId) =>
      '$baseUrl/appointments/$appointmentId/payment/initiate';

  static String paymentRetry(int paymentId) =>
      '$baseUrl/payments/$paymentId/retry';

  static String paymentDetails(int paymentId) => '$baseUrl/payments/$paymentId';

  // eSewa Payment URL (for web view)
  static const String esewaPaymentUrl = 'https://uat.esewa.com.np/epay/main';
}
