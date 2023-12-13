import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vpool/home.dart';
import 'package:vpool/onboarding.dart';
import 'package:vpool/personal.details.dart';
import 'package:vpool/login.dart';
import 'package:vpool/splash.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: "https://tcuvywwvcumjwjnywinx.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjdXZ5d3d2Y3Vtandqbnl3aW54Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDI0OTMxMDAsImV4cCI6MjAxODA2OTEwMH0.YVVGHEu80oENGVARGehwPauoGLNia9jh6YZWYxDiqwQ",
      debug: true,
      authOptions:
          const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce));
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Rideshare",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow.shade600),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnBoarding(),
        '/login': (context) => const LoginPage(),
        '/personalDet': (context) => const PersonalDetailsPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
