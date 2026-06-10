import 'package:flutter/material.dart';
import 'search_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeIn)));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)));
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => const HomeShell(),
          transitionsBuilder: (ctx, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[700],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20, spreadRadius: 2,
                    )],
                  ),
                  child: const Icon(Icons.analytics, size: 60, color: Colors.indigo),
                ),
                const SizedBox(height: 24),
                const Text('Journal Trend Analyzer',
                  style: TextStyle(
                    color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5,
                  )),
                const SizedBox(height: 8),
                Text('Powered by OpenAlex',
                  style: TextStyle(color: Colors.indigo[200], fontSize: 14)),
                const SizedBox(height: 40),
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.indigo[500],
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
