import 'package:flutter/material.dart';

import 'auth_screen.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, i) {
            final slide = _slides[i];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(slide['image']!, height: 240),
                const SizedBox(height: 24),
                Text(slide['title']!,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(slide['subtitle']!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ),
              ],
            );
          },
        ),
        // Dots & button
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 12 : 8,
                  height: _currentPage == i ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, AuthScreen.routeName);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  _currentPage == _slides.length - 1
                      ? 'Get Started'
                      : 'Next',
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
