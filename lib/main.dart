import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'splash_screen.dart';
import 'intro_screen.dart';
import 'email_sent_screen.dart';
import 'home_screen.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(const NexTrackApp());
}

class NexTrackApp extends StatelessWidget {
  const NexTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexTrack',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D28D9),
          primary: const Color(0xFF4B0AAA),
          secondary: const Color(0xFFEADDFF),
          surface: const Color(0xFFFCF8FB),
        ),

      ),

      // app routing
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/email_sent': (context) => const EmailSentScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
