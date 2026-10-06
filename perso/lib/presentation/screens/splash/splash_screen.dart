import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/circle_icon_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAppAccent.withOpacity(0.15),
                border: Border.all(color: kAppAccent.withOpacity(0.4)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'UR',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PERSO',
              style: TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 6, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 8),
            Text(
              'LECTURE PRIVÉE',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 3),
            ),
          ],
        ),
      ),
    );
  }
}
