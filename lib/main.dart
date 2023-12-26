import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vpool/constants/keys.dart';
import 'package:vpool/home.dart';
import 'package:vpool/onboarding.dart';
import 'package:vpool/personal.details.dart';
import 'package:vpool/login.dart';
import 'package:vpool/splash.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: ANON_KEY,
      debug: true,
      authOptions:
          const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce));
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "VPool",
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
