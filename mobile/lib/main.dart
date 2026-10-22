import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/upload_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/review_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fallback if .env missing
  }
  ApiService().init();

  runApp(const ReceiptLedgerApp());
}

class ReceiptLedgerApp extends StatelessWidget {
  const ReceiptLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReceiptLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      UploadScreen(onOpenDrawer: _openDrawer),
      LedgerScreen(onOpenDrawer: _openDrawer),
      ReviewScreen(onOpenDrawer: _openDrawer),
      SettingsScreen(onOpenDrawer: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: const AppProfileDrawer(),
      body: Stack(
        children: [
          // Current active screen
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Floating Pill Bottom Navigation Bar matching mockups
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: ApiService().reviewCountNotifier,
              builder: (ctx, badgeCount, _) {
                return AppBottomNav(
                  currentIndex: _currentIndex,
                  reviewBadgeCount: badgeCount,
                  onTabSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
