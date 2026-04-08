import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
    return const Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: LiqraLogo(
          fontSize: 52,
          showTagline: true,
          centered: true,
          showRing: true,
        ),
      ),
    );
  }
}
