import 'package:flutter/material.dart';
import 'pin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;

  int _currentPage = 0;

  static const Color _primaryGreen = Color(0xFF0A8E48);
  static const Color _lightGreen = Color(0xFF1DB854);
  static const Color _brightGreen = Color(0xFF2DD473);

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Track Your Money',
      subtitle: 'Without the extra work.',
      description:
          'MEKENET turns supported payment messages into a simple daily money record, so you can focus on running your business.',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: _lightGreen,
      features: [
        'Automatic transaction records',
        'Income and expense tracking',
        'Simple daily money overview',
      ],
    ),
    _OnboardingPage(
      title: 'Smart SMS Reading',
      subtitle: 'Automatic logging.',
      description:
          'MEKENET reads supported payment SMS messages and extracts the information needed to record your transactions.',
      icon: Icons.sms_rounded,
      accentColor: _brightGreen,
      features: [
        'Payment messages only',
        'Automatic transaction detection',
        'Personal conversations stay untouched',
      ],
    ),
    _OnboardingPage(
      title: 'Private by Design',
      subtitle: 'Your financial data stays with you.',
      description:
          'Your records are designed to be processed and stored locally on your device, giving you control over your financial information.',
      icon: Icons.shield_rounded,
      accentColor: _primaryGreen,
      features: [
        'Local-first data storage',
        'Protected financial records',
        'No unnecessary data sharing',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToPin();
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToPin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PinScreen(),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    _animationController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'MEKENET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double illustrationHeight =
            constraints.maxHeight < 600 ? 220 : 280;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              children: [
                SizedBox(
                  height: illustrationHeight,
                  child: _buildIllustration(
                    page,
                    illustrationHeight,
                  ),
                ),
                const SizedBox(height: 28),
                _buildTextContent(page),
                const SizedBox(height: 24),
                _buildFeatureList(page.features),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIllustration(
    _OnboardingPage page,
    double height,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final curvedValue = Curves.easeOutBack.transform(
          _animationController.value,
        );

        return Transform.scale(
          scale: 0.82 + (curvedValue * 0.18),
          child: Opacity(
            opacity: _animationController.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: height * 0.68,
            height: height * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          Container(
            width: height * 0.48,
            height: height * 0.48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: height * 0.22,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: height * 0.12,
            left: height * 0.10,
            child: _buildFloatingCircle(
              size: 34,
              opacity: 0.20,
            ),
          ),
          Positioned(
            top: height * 0.20,
            right: height * 0.08,
            child: _buildFloatingCircle(
              size: 24,
              opacity: 0.16,
            ),
          ),
          Positioned(
            bottom: height * 0.10,
            left: height * 0.16,
            child: _buildFloatingCircle(
              size: 18,
              opacity: 0.18,
            ),
          ),
          Positioned(
            bottom: height * 0.14,
            right: height * 0.13,
            child: _buildFloatingCircle(
              size: 30,
              opacity: 0.14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCircle({
    required double size,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTextContent(_OnboardingPage page) {
    return Column(
      children: [
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          page.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 390,
          ),
          child: Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final bool isLastPage = _currentPage == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) {
                final bool active = index == _currentPage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 26 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastPage
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_currentPage + 1} of ${_pages.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> features;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.features,
  });
}