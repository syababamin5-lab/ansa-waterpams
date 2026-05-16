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
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
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
  final _pageController = PageController(initialPage: 0);
  final NotchBottomBarController _notchController = NotchBottomBarController(index: 0);

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PelangganListScreen(),
    const CatatMeterScreen(),
    const TagihanScreen(),
    const RiwayatScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _notchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchController,
        color: Colors.white,
        showLabel: true,
        textOverflow: TextOverflow.visible,
        maxLine: 1,
        shadowElevation: 5,
        kBottomRadius: 28.0,
        notchColor: AppTheme.primaryColor,
        removeMargins: false,
        bottomBarWidth: 500,
        showShadow: true,
        durationInMilliSeconds: 300,
        itemLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
        elevation: 1,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(Icons.dashboard_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.dashboard_rounded, color: Colors.white),
            itemLabel: 'Beranda',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.people_alt_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.people_alt_rounded, color: Colors.white),
            itemLabel: 'Pelanggan',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.speed_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.speed_rounded, color: Colors.white),
            itemLabel: 'Catat',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.payment_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.payment_rounded, color: Colors.white),
            itemLabel: 'Tagihan',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.history_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.history_rounded, color: Colors.white),
            itemLabel: 'Riwayat',
          ),
        ],
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
        kIconSize: 24.0,
      ),
    );
  }
}

