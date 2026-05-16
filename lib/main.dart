import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/secrets.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/pelanggan/pelanggan_list_screen.dart';
import 'features/transaksi/catat_meter_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/riwayat/riwayat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );
  
  runApp(
    DevicePreview(
      enabled: true,
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
      locale: const Locale('id', 'ID'),
      builder: DevicePreview.appBuilder,
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
    const RiwayatScreen(),
    const SettingsScreen(),
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
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Pelanggan'),
            BottomNavigationBarItem(icon: Icon(Icons.speed_rounded), label: 'Catat'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Biaya'),
          ],
        ),
      ),
    );
  }
}
