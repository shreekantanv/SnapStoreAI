import 'package:flutter/material.dart';

import '../utils/onboarding_storage.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _slides = const [
    {
      'title': 'Welcome to SnapStoreAI',
      'subtitle':
          'Discover a world of AI-powered tools to simplify your life and boost your productivity.',
      'image': 'assets/images/logo.png',
    },
    {
      'title': 'Explore AI Tools',
      'subtitle':
          'Browse a curated collection of AI tools, from trip planners to resume optimizers.',
      'image': 'assets/images/explore.png',
    },
    {
      'title': 'Get Started',
      'subtitle':
          'Purchase credits and start using AI tools to enhance your daily tasks and projects.',
      'image': 'assets/images/get_started.png',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoHome() async {
    await OnboardingStorage.markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      HomeScreen.routeName,
      (route) => false,
    );
  }

  Future<void> _next() async {
    if (_currentPage == _slides.length - 1) {
      await _completeAndGoHome();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
          color: Colors.white,
        );
    final body = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.5,
          color: Colors.white.withOpacity(.85),
        );

    return Scaffold(
      // Soft dark gradient like the mock
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E1116), Color(0xFF131826)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return LayoutBuilder(
                    builder: (_, c) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            // Bigger, centered image/logo
                            Image.asset(
                              slide['image']!,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 28),
                            Text(slide['title']!, style: headline, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(slide['subtitle']!, style: body, textAlign: TextAlign.center),
                            const SizedBox(height: 120), // space for dots + button area
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Bottom controls (dots + pill gradient button)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Column(
                  children: [
                    // Animated dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 10,
                          width: active ? 22 : 10,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF7F5AF0) : Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Gradient "Next / Get Started" button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => _next(),
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(Colors.white10),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                            backgroundColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7F5AF0), Color(0xFF5A7FF0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55315BFB),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional skip button (top-right)
              Positioned(
                right: 8,
                top: 8,
                child: TextButton(
                  onPressed: () => _completeAndGoHome(),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
