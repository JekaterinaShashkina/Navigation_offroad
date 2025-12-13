// lib/pages/payment/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  
  static const _kBankPng       = 'assets/images/bank_icon.png';
  static const _kDebitCardPng  = 'assets/images/debit_cart_icon.png';
  static const _kGooglePayPng  = 'assets/images/pay_icon.png';
  static const _kAppleSvg      = 'assets/images/aaple_logo.svg'; 
  static const _kPaypalPng     = 'assets/images/paypal_icon.png'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Payment',
        onPressed: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(padding16, padding16, padding16, padding16),
        children: [
          const SizedBox(height: height8),
          const Text('Choose Payment option', style: head1TextStyle),
          const SizedBox(height: height16),
          

          _PaymentTile(
            title: 'Debit/ Credit card',
            iconPath: _kDebitCardPng,
            onTap: () {/* TODO: перейти на ввод карты */},
          ),
          const SizedBox(height: height12),

          _PaymentTile(
            title: 'Internet banking',
            iconPath: _kBankPng,
            onTap: () {/* TODO: интернет-банкинг */},
          ),
          const SizedBox(height: height12),

          _PaymentTile(
            title: 'Pay',
            iconPath: _kGooglePayPng,
            onTap: () {/* TODO: GPay */},
          ),
          const SizedBox(height: height12),

          _PaymentTile(
            title: 'Pay',
            iconPath: _kAppleSvg,
            onTap: () {/* TODO: Apple Pay */},
          ),
          const SizedBox(height: height12),

          _PaymentTile(
            title: 'PayPal',
            iconPath: _kPaypalPng, 
            onTap: () {/* TODO: PayPal */},
          ),
        ],
      ),
    );
  }
}


class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.title,
    required this.iconPath,
    this.onTap,
  });

  final String title;
  final String iconPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radius16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius16),
        onTap: onTap,
        child: Container(
          height: 56, 
          padding: const EdgeInsets.symmetric(horizontal: padding16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconCircle(path: iconPath),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textMainColor,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: textHintColor),
            ],
          ),
        ),
      ),
    );
  }
}


class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final isSvg = path.toLowerCase().endsWith('.svg');

    final Widget icon = isSvg
        ? SvgPicture.asset(path, width: 20, height: 20, colorFilter: const ColorFilter.mode(textHintColor, BlendMode.srcIn))
        : Image.asset(path, width: 20, height: 20, color: null);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: textHintColor.withOpacity(0.10), 
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }
}
