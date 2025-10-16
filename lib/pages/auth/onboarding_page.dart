// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _pages = [
    {
      // 'image': 'assets/images/onboard1.png',
      'title': 'Campus Marketplace',
      'desc': 'Buy and sell with fellow students in your campus community',
      'color': const Color(0xFF6C63FF),
    },
    {
      // 'image': 'assets/images/onboard2.png',
      'title': 'Post in Seconds',
      'desc': 'Snap, price, and share your items instantly from your phone',
      'color': const Color(0xFF4ECDC4),
    },
    {
      // 'image': 'assets/images/onboard3.png',
      'title': 'Start Trading',
      'desc': 'Connect with students and make deals happen effortlessly',
      'color': const Color(0xFFFF6B6B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animationController.reset();
    _animationController.forward();
  }

  void _onNextPressed() async {
    if (_currentPage == _pages.length - 1) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      if (context.mounted) {
        context.go('/login');
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPageData = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Image container
                      // Container(
                      //   width: 250,
                      //   height: 250,
                      //   decoration: BoxDecoration(
                      //     // ignore: deprecated_member_use
                      //     color: (page['color'] as Color).withOpacity(0.05),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   padding: const EdgeInsets.all(20),
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(16),
                      //     child: Image.asset(
                      //       page['image'] as String,
                      //       fit: BoxFit.contain,
                      //     ),
                      //   ),
                      // ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                      ),
                      const SizedBox(height: 60),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Title
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 50,
                                  left: 10,
                                  right: 10,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      page['title'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 15),

                                    // Description
                                    Text(
                                      page['desc'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              // Bottom section
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 50,
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              final prefs =
                                                  await SharedPreferences.getInstance();
                                              await prefs.setBool(
                                                'seenOnboarding',
                                                true,
                                              );
                                              if (context.mounted) {
                                                context.go('/signup');
                                              }
                                            },
                                            child: Text(
                                              'Skip',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Page indicators
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(_pages.length, (
                                          index,
                                        ) {
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            width: _currentPage == index
                                                ? 24
                                                : 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _currentPage == index
                                                  ? currentPageData['color']
                                                        as Color
                                                  : Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          );
                                        }),
                                      ),

                                      // Next button
                                      ElevatedButton(
                                        onPressed: _onNextPressed,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              currentPageData['color'] as Color,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: const CircleBorder(),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _currentPage == _pages.length - 1
                                                  ? Icons.arrow_forward
                                                  : Icons.arrow_forward,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
