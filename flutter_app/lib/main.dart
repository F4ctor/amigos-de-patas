import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_client.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OngAdocaoApp());
}

class OngAdocaoApp extends StatefulWidget {
  const OngAdocaoApp({super.key});

  @override
  State<OngAdocaoApp> createState() => _OngAdocaoAppState();
}

class _OngAdocaoAppState extends State<OngAdocaoApp> {
  String? _token;
  Map<String, dynamic>? _user;
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ong_auth_token');
    final userText = prefs.getString('ong_auth_user');
    Map<String, dynamic>? user;

    if (userText != null) {
      try {
        final decoded = jsonDecode(userText);
        if (decoded is Map) user = Map<String, dynamic>.from(decoded);
      } catch (_) {
        await prefs.remove('ong_auth_user');
      }
    }

    if (token != null && user != null) {
      try {
        final profile = await ApiClient(token: token).get('/auth/perfil');
        if (profile is Map) {
          user = Map<String, dynamic>.from(profile);
          await prefs.setString('ong_auth_user', jsonEncode(user));
        }
      } on ApiException {
        await prefs.remove('ong_auth_token');
        await prefs.remove('ong_auth_user');
        user = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _token = user == null ? null : token;
      _user = user;
      _restoringSession = false;
    });
  }

  Future<void> _authenticate(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ong_auth_token', token);
    await prefs.setString('ong_auth_user', jsonEncode(user));
    if (!mounted) return;
    setState(() {
      _token = token;
      _user = user;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ong_auth_token');
    await prefs.remove('ong_auth_user');
    if (!mounted) return;
    setState(() {
      _token = null;
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF146C43),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ONG Adoção',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
        ),
      ),
      home: _restoringSession
          ? const _SplashScreen()
          : _token == null || _user == null
              ? LoginScreen(onAuthenticated: _authenticate)
              : HomeShell(token: _token!, user: _user!, onLogout: _logout),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFE8F5EE),
              child: Icon(Icons.pets, size: 46, color: Color(0xFF146C43)),
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
