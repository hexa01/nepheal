import 'package:flutter/material.dart';
import '../screens/my_appointments_screen.dart';
import '../screens/doctors_list_screen.dart';
import '../screens/patient_profile_screen.dart';
import '../screens/patient_messages_screen.dart';
import '../screens/patient_dashboard.dart'; // Contains PatientHomeScreen
import '../../../shared/widgets/exit_wrapper_widget.dart';

class PatientDashboardWithTab extends StatefulWidget {
  final int initialTab;

  const PatientDashboardWithTab({super.key, this.initialTab = 0});

  @override
  State<PatientDashboardWithTab> createState() => _PatientDashboardWithTabState();
}

class _PatientDashboardWithTabState extends State<PatientDashboardWithTab> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _screens => [
        PatientHomeScreen(onNavigate: _changeTab),
        const DoctorsListScreen(),
        const MyAppointmentsScreen(),
        const PatientMessagesScreen(),
        const PatientProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return ExitWrapper(
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _changeTab,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          iconSize: 20,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Doctors'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
