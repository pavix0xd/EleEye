import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _liquidFillAnimation;

  int _currentLogoIndex = 0;
  bool _showLoadingBar = false;

  final List<String> _logos = [
    'assets/logo2-removebg-preview.png',
    'assets/LEYo__1_-removebg-preview.png', 
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _liquidFillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeInOut),
      ),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.5 && !_showLoadingBar) {
        setState(() {
          _showLoadingBar = true;
        });
      }
      if (_controller.value >= 0.25 && _currentLogoIndex == 0) {
        setState(() {
          _currentLogoIndex = 1;
        });
      }
    });

    _controller.forward().whenComplete(() {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentLogoIndex == 0 ? const Color(0xFF004D40) : Colors.white, // Teal Shade 900 for first screen, then white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: Image.asset(
                _logos[_currentLogoIndex],
                width: 200,
                height: 200,
              ),
            ),
            if (_showLoadingBar)
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: 150,
                height: 10,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00332E), width: 2), // Dark Green border
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _liquidFillAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 150 * _liquidFillAnimation.value,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF004D40), // Teal Shade 900
                                  Color(0xFF00695C), // A slightly lighter shade
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
