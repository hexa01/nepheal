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

  //payments
  static const String payments = '$baseUrl/payments';

  // Messages
  static const String messages = '$baseUrl/messages';
  static const String completedAppointments = '$baseUrl/messages/completed-appointments';
  static const String sendMessage = '$baseUrl/messages/send';
  static const String patientMessages = '$baseUrl/messages/patient-messages';


}
