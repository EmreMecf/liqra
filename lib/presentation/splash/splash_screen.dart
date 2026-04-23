import 'package:flutter/material.dart';
import '../widgets/liqra_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.4),
            radius: 0.9,
            colors: [Color(0xFF0C1E30), Color(0xFF05080F)],
          ),
        ),
        child: const Center(
          child: LiqraLogo(
            fontSize: 52,
            showTagline: true,
            centered: true,
          ),
        ),
      ),
    );
  }
}
