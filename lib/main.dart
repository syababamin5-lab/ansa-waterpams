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
import 'features/tagihan/tagihan_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
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
    const TagihanScreen(),
    const RiwayatScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _screens[_currentIndex].animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.08),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: AppTheme.primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              color: Colors.grey,
              tabs: const [
                GButton(
                  icon: Icons.dashboard_rounded,
                  text: 'Beranda',
                ),
                GButton(
                  icon: Icons.people_alt_rounded,
                  text: 'Pelanggan',
                ),
                GButton(
                  icon: Icons.speed_rounded,
                  text: 'Catat',
                ),
                GButton(
                  icon: Icons.payment_rounded,
                  text: 'Tagihan',
                ),
                GButton(
                  icon: Icons.history_rounded,
                  text: 'Riwayat',
                ),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
