import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
//import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/onboard_card.dart';

class WelcomeLoginPage extends StatelessWidget {
  const WelcomeLoginPage({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }

  void _goToRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: backgroundMainColor,
      body: 
      SafeArea(
        child:       
        LayoutBuilder(
          builder: (context, c) {
          // «карточная» ширина: чуть уже экрана, но не больше 420
            final cardWidth = math.min(c.maxWidth - 40, 420.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 48),
                child: Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: OnboardCard(
                      // width: screenWidth-40,
                        title: 'Welcome to\nMap Navigation',
                        subtitle: "Reference site about Lorem Ipsum, giving information origins",
                        button: Column(
                          children: [
                            AppButton(                    
                              text: 'Login',
                              onPressed: () => _goToLogin(context),
                              width: cardWidth - 40,
                              ),
                            const SizedBox(height: 16),
                            AppButton(                    
                              text: 'Register',
                              onPressed: () => _goToRegister(context),
                              width: cardWidth - 40,
                              backgroundColor: buttonSecondBackgroundColor,
                              foregroundColor: surfaceColor,
                              )
                          ],
                        ),
                      ),
                  ),
                ),
              ),
              );
          },
      ),
      )

    );
  }
}
