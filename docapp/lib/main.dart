import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage/storage_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/doctor_service.dart';
import 'shared/services/appointment_service.dart';
import 'shared/services/message_service.dart';
import 'shared/services/review_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/patient/screens/patient_dashboard.dart';
import 'features/doctor/screens/doctor_dashboard.dart';
import 'shared/widgets/exit_wrapper_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        ChangeNotifierProvider(create: (context) => AuthService()),
        
        // Data services
        ChangeNotifierProvider(create: (context) => DoctorService()),
        ChangeNotifierProvider(create: (context) => AppointmentService()),
        ChangeNotifierProvider(create: (context) => MessageService()),
        ChangeNotifierProvider(create: (context) => ReviewService()),
      ],
      child: ExitWrapper(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            // 🆕 Connect all services to AuthService
            _connectServices(context, authService);
            
            return MaterialApp(
              title: 'Nepheal',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
              ),
              home: _getHomeScreen(authService),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }

  /// Connect all services to AuthService for coordinated background loading
  void _connectServices(BuildContext context, AuthService authService) {
    final doctorService = Provider.of<DoctorService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final messageService = Provider.of<MessageService>(context, listen: false);
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    
    authService.setDoctorService(doctorService);
    authService.setAppointmentService(appointmentService);
    authService.setMessageService(messageService);
    authService.setReviewService(reviewService);
  }

  /// Determine which screen to show based on auth status and user role
  Widget _getHomeScreen(AuthService authService) {
    // Check if user data exists in storage on app start
    final token = StorageService.getToken();
    final userData = StorageService.getUserData();
    
    if (token != null && userData != null && authService.isAuthenticated) {
      // User is logged in, determine role
      final userRole = authService.user?.role ?? userData['role'] as String?;
      
      if (userRole == 'patient') {
        return const PatientDashboard();
      } else if (userRole == 'doctor') {
        return const DoctorDashboard();
      }
    }
    
    // Default to login screen
    return const LoginScreen();
  }
}