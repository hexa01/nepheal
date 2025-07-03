import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage/storage_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/doctor_service.dart';
import 'features/auth/screens/login_screen.dart';
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
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => DoctorService()),
      ],
      child: ExitWrapper(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            final doctorService =
                Provider.of<DoctorService>(context, listen: false);
            authService.setDoctorService(doctorService);

            return MaterialApp(
              title: 'Nepheal',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
              ),
              home: const LoginScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
