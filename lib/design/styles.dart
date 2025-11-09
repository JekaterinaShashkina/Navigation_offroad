import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

const TextStyle head1TextStyle = TextStyle(
  color: textMainColor,
  fontSize: fontSize22,
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w700,
);

const TextStyle titleTextStyle = TextStyle(
              fontSize: fontSize30, 
              fontWeight: FontWeight.w700,
              color: textMainColor, 
              height: 1.2,
);
const TextStyle subtitleTextStyle = TextStyle(
  fontSize: fontSize18, 
  color: textMainColor,
  fontWeight: FontWeight.w400,
  );

const TextStyle primaryTextStyle = TextStyle(
  color: textMainColor,
  fontSize: fontSize16,
  fontWeight: FontWeight.w500,
);

const TextStyle descriptionDialogTextStyle = TextStyle(
  color: textCustomColor,
  fontSize: fontSize16,
  fontWeight: FontWeight.w400,
);

const TextStyle accentButtonTextStyle = TextStyle(
  color: surfaceColor,
  fontSize: fontSize14,
  fontWeight: FontWeight.w600,
);

const TextStyle bodyTextStyle = TextStyle(
  fontFamily: 'Roboto',
  color: textMainColor,
  fontSize: fontSize16,
  fontWeight: FontWeight.w400,
);
const TextStyle bodySmallTextStyle = TextStyle(
  color: textMainColor,
  fontSize: fontSize14,
  fontWeight: FontWeight.w400,
);

const TextStyle hintTextStyle = TextStyle(
  color: textHintColor,
  fontSize: fontSize16,
  fontWeight: FontWeight.w500,
);

const TextStyle hintSmallTextStyle = TextStyle(
  color: textHintColor,
  fontSize: fontSize14,
  fontWeight: FontWeight.w400,
);

const BoxDecoration mainBackgroundDecoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundMainColor, backgroundSecondColor],
          ),
        );

// Новый стиль текста для profile_page.dart
const TextStyle robotoRegular16TextStyle = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w400,
  fontSize: 16,
  color: textCustomColor,
);

// Новый стиль текста для имени пользователя profile_page.dart
const TextStyle robotoRegular18TextStyle = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w400,
  fontSize: 18,
  color: textMainColor,
);

// Новый стиль текста Roboto Regular 14 с цветом rgba(171, 184, 203, 1)
const TextStyle robotoRegular14TextStyle = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w400,
  fontSize: 14,
  color: backgroundSecondColor ,
);