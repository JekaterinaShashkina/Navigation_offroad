import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';

class OnboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget button;
  final double? width;

  const OnboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.button,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
return LayoutBuilder(
      builder: (context, c) {
        final media = MediaQuery.of(context);

        // Если карточка не получила явной высоты — возьмём половину экрана
        final availableH = c.maxHeight.isFinite
            ? c.maxHeight
            : media.size.height * 0.5;

        final gap   = (availableH * 0.04).clamp(12.0, 28.0);
        final logoH = (availableH * 0.25).clamp(80.0, 180.0);

        // ---- Расчёт высот боксов строго от типографики ----
        // (чтобы не было overflow, учитываем fontSize * lineHeight * maxLines + 2px запаса)

        final titleFs    = (titleTextStyle.fontSize ?? 28) * (titleTextStyle.height ?? 1.2);
        final subtitleFs = (subtitleTextStyle.fontSize ?? 16) * (subtitleTextStyle.height ?? 1.3);

        const titleLines    = 2;
        const subtitleLines = 3;

        final titleBoxH    = titleFs * titleLines + 2;     // +2 px запас от округления
        final subtitleBoxH = subtitleFs * subtitleLines + 2;

        // Общая «текстовая зона» (title-box + spacer + subtitle-box)
        final spacerH   = gap * 0.6;
        final textZoneH = titleBoxH + spacerH + subtitleBoxH;

        // Зафиксируем текстовое масштабирование внутри карточки (чтобы системный scale не ломал уровни)
        final mq = media.copyWith(textScaler: const TextScaler.linear(1.0));

        return MediaQuery(
          data: mq,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: gap, horizontal: 25),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(radius24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Верхняя часть (лого + текстовая зона)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: gap),

                      SizedBox(
                        height: logoH,
                        child: Image.asset("assets/images/eeWAY/eeWay_favicon_must.png"),
                      ),

                      SizedBox(height: gap),

                      // ===== ТЕКСТОВАЯ ЗОНА ФИКС. ВЫСОТЫ =====
                      SizedBox(
                        height: textZoneH,
                        child: Column(
                          children: [
                            // 1) Бокс заголовка (фикс. высота), текст прижат к НИЗУ
                            ConstrainedBox(
                              constraints: BoxConstraints.tightFor(height: titleBoxH),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: titleTextStyle,
                                  maxLines: titleLines,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            SizedBox(height: spacerH),

                            // 2) Бокс подзаголовка (фикс. высота), текст прижат к ВЕРХУ
                            ConstrainedBox(
                              constraints: BoxConstraints.tightFor(height: subtitleBoxH),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: subtitleTextStyle,
                                  maxLines: subtitleLines,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ===== / текстовая зона =====
                    ],
                  ),
                ),

                SizedBox(height: gap * 0.6),

                // Кнопка прибита к низу карточки
                SizedBox(width: width ?? 238, child: button),

                SizedBox(height: media.padding.bottom * 0.5),
              ],
            ),
          ),
        );
      },
    );
  }
}
