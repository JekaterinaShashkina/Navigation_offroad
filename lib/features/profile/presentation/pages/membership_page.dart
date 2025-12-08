// lib/pages/profile/membership_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/pages/payment/payment_options_page.dart';

// сервис профиля
import 'package:offroad_nav/services/user_profile_service.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar:
          NewAppBar(title: 'Membership', onPressed: () => Navigator.pop(context)),
      body: StreamBuilder<UserProfile?>(
        stream: UserProfileService.instance.watchProfile(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snap.data;
          final name = profile?.name.isNotEmpty == true
              ? profile!.name
              : 'Friend';

          final until = profile?.premiumUntil;
          final isPremium =
              until != null && until.isAfter(DateTime.now());

          return ListView(
            padding: const EdgeInsets.all(padding16),
            children: [
              Text('Hi $name', style: head1TextStyle),
              const SizedBox(height: height8),
              Text(
                isPremium
                    ? 'You have Premium'
                    : "You don’t have a premium membership.",
                style: hintTextStyle,
              ),
              const SizedBox(height: height16),

              // карточка статуса
              Container(
                padding: const EdgeInsets.all(padding16),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFFFFE082) : surfaceColor,
                  borderRadius: BorderRadius.circular(radius16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Premium membership' : 'Non-member',
                      style: const TextStyle(
                        fontSize: fontSize20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: height8),
                    if (isPremium && until != null)
                      Text('Member until ${_fmt(until)}')
                    else
                      const Text('Buy a membership'),
                    const SizedBox(height: height12),
                    if (!isPremium)
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentOptionsPage(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: textMainColor,
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFDDE3EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Choose payment'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: height24),
              const Text(
                'Benefits',
                style: TextStyle(
                  fontSize: fontSize18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: height12),

              const _BenefitCard(
                title: 'Unlimited routes',
                subtitle:
                    'Lorem ipsum is simply dummy text of the printing …',
              ),
              const SizedBox(height: height12),
              const _BenefitCard(
                title: 'Unlimited waypoints',
                subtitle:
                    'Lorem ipsum is simply dummy text of the printing …',
              ),
              const SizedBox(height: height12),
              const _BenefitCard(
                title: 'Lorem ipsum',
                subtitle:
                    'Lorem ipsum is simply dummy text of the printing …',
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _BenefitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _BenefitCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(padding16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A1A1A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: height8),
          Text(subtitle, style: hintTextStyle),
        ],
      ),
    );
  }
}
