import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'auth_provider.dart';
import 'settings_service.dart';
import 'locale_service.dart';
import 'auth_service.dart';
import '../pages/start_screen.dart';
import '../pages/authorization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
//
  await Supabase.initialize(
    url: 'https://urtwjptaraefxhmwqoqr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVydHdqcHRhcmFlZnhobXdxb3FyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMTAsImV4cCI6MjA5MDIyMTAxMH0.pVchk5Uv3WzdaYEoTCBLuujb6MsuXFNP0oO2l1vMUPo',
  );

  await AuthService.initCache();

  final authProvider = AuthProvider();
  await authProvider.loadSession();

  await SettingsService.loadSettings();
  await LocaleService.loadLanguage();

  runApp(
    ChangeNotifierProvider.value(value: authProvider, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Basketball Training',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(),
      routes: {'/register': (context) => const AuthorizationPage()},
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterNativeSplash.remove();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/basketball_fon.jpg', fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withOpacity(0.3)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/basketball_ico.png', width: 120, height: 120),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Color(0xFFFFA500),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
