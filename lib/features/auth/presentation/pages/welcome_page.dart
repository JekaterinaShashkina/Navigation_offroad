import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/onboard_card.dart';

class _Slide {
  final String title;
  final String subtitle;
  const _Slide(this.title, this.subtitle);
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
      'Welcome to\nMap Navigation',
      'Reference site about Lorem Ipsum,\ngiving information origins',
    ),
    _Slide('Explore routes', 'Find, create and share off-road tracks'),
    _Slide('Track progress', 'Record distance and time, sync with cloud'),
  ];

  void _goNext() {
    final isLast = _page == _slides.length - 1;
    if (isLast) {
      Navigator.pushReplacementNamed(context, '/welcomelogin');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, '/login');
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: backgroundMainColor,
    body: SafeArea(
      child: Column(
        children: [
          // убираем Spacer()
          Expanded(                                // ⟵ занимаем доступную высоту
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final s = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SizedBox.expand(
                  child:  OnboardCard(                  
                    title: s.title,
                    subtitle: s.subtitle,
                    button: AppButton(
                      width: width238,
                      text: _page == _slides.length - 1 ? 'Start' : 'Get Started',
                      onPressed: _goNext,
                    ),
                  ),
                  )
                );
              },
            ),
          ),

            // const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: active ? 28 : 10,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? surfaceColor : surfaceColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
          const SizedBox(height: height20),

          Padding(
            padding: const EdgeInsets.only(bottom: padding24),
            child: SizedBox(
              width: 105,
              child: ElevatedButton(
                onPressed: _skip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonSecondBackgroundColor,
                  foregroundColor: surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius24),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: fontSize20),
                ),
              ),
            ),
          ),
          const SizedBox(height: height20),
        ],
      ),
    ),
  );
}
}