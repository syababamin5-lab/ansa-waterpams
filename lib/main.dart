import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/pelanggan/pelanggan_list_screen.dart';
import 'features/transaksi/catat_meter_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: true, // Aktifkan Device Preview
      builder: (context) => const AnsaWaterApp(),
    ),
  );
}

class AnsaWaterApp extends StatelessWidget {
  const AnsaWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ansa Water',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context), // Penting untuk Device Preview
      builder: DevicePreview.appBuilder, // Penting untuk Device Preview
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PelangganListScreen(),
    const CatatMeterScreen(),
    const Center(child: Text('Riwayat & Laporan')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex].animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.withOpacity(0.5),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Pelanggan'),
            BottomNavigationBarItem(icon: Icon(Icons.speed_rounded), label: 'Catat Meter'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
          ],
        ),
      ),
    );
  }
}
