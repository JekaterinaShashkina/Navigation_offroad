import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';

class PaymentOptionsPage extends StatelessWidget {
  const PaymentOptionsPage({super.key});

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
        title: const Text('Payment', style: head1TextStyle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(padding16),
        children: [
          const SizedBox(height: height8),
          const Text('Choose Payment option', style: TextStyle(fontSize: fontSize20, fontWeight: FontWeight.w700)),
          const SizedBox(height: height16),
          _OptionTile(
            leading: Image.asset('assets/images/debit_card_icon.png', width: 28, height: 28),
            title: 'Debit/ Credit card',
            onTap: () {/* TODO: открываем форму оплаты */},
          ),
          _OptionTile(
            leading: Image.asset('assets/images/bank_icon.png', width: 28, height: 28),
            title: 'Internet banking',
            onTap: () {},
          ),
          _OptionTile(
            leading: Image.asset('assets/images/pay_icon.png', width: 28, height: 28),
            title: 'Google Pay',
            onTap: () {},
          ),
          _OptionTile(
            leading: SvgPicture.asset('assets/images/apple_logo.svg', width: 28, height: 28),
            title: 'Apple Pay',
            onTap: () {},
          ),
          _OptionTile(
            leading: Image.asset('assets/images/paypal_icon.png', width: 28, height: 28),
            title: 'PayPal',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final VoidCallback onTap;
  const _OptionTile({required this.leading, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: height12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: leading,
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
