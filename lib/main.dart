import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () => InitializationStatus({}),
      );

      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));

      FlutterNativeSplash.remove();
      runApp(const TileMateApp());
    },
    (error, stack) {
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF0F0F0F),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TileMate — Startup Error',
                      style: TextStyle(
                        color: Color(0xFFF5A623),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Color(0xFFE05252), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stack.toString(),
                      style: const TextStyle(color: Color(0xFF9A9590), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class TileMateApp extends StatelessWidget {
  const TileMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TileMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}