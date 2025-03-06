import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _liquidFillAnimation;
  late Animation<Color?> _backgroundColorAnimation;

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
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.5, curve: Curves.easeIn),
      ),
    );

    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFF004D40),
      end: Colors.white,
    ).animate(_controller);

    _liquidFillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.25 && _currentLogoIndex == 0) {
        setState(() => _currentLogoIndex = 1);
      }
      if (_controller.value >= 0.5 && !_showLoadingBar) {
        setState(() => _showLoadingBar = true);
      }
    });

    _controller.forward().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 500), () {
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
    return AnimatedBuilder(
      animation: _backgroundColorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColorAnimation.value,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedOpacity(
                    opacity: _fadeAnimation.value,
                    duration: const Duration(milliseconds: 600),
                    child: Image.asset(_logos[_currentLogoIndex], width: 200, height: 200),
                  ),
                ),
                if (_showLoadingBar)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      Shimmer.fromColors(
                        baseColor: Colors.teal[600]!,
                        highlightColor: Colors.teal[300]!,
                        child: Container(
                          width: 150,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedOpacity(
                        opacity: _showLoadingBar ? 1.0 : 0.0,
                        duration: const Duration(seconds: 2),
                        child: const Text(
                          "Your safety, Their survival...",
                          style: TextStyle(fontSize: 18, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
