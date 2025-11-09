// lib/pages/friends/invite_friend_page.dart
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'send_invite_page.dart';

class InviteFriendPage extends StatelessWidget {
  const InviteFriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textMainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Invite Friend', style: head1TextStyle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Белая карточка с текстом из макета
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    // мягкая тень как в фигме
                    BoxShadow(
                      color: Color(0x141A1A1A), // 8% черный 
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Invite Friend',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textMainColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        )),
                    SizedBox(height: 10),
                    Text(
                      "Tell your friends about the app so that they'll\nsee your messages faster\n\n50  of your friends are already join us",
                      textAlign: TextAlign.center,
                      style: hintSmallTextStyle,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка "Add from Contacts"
              _PrimaryPillButton(
                label: 'Add from Contacts',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SendInvitePage()),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Кнопка "Add from Facebook"
              _PrimaryPillButton(
                label: 'Add from Facebook',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SendInvitePage()),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Пилюля-кнопка в цветах из токенов
class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryPillButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonSecondBackgroundColor, // как в макете
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: surfaceColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
