import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';

final SvgPicture checkIcon = SvgPicture.asset(
  'assets/images/check.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
);

final SvgPicture closeIcon = SvgPicture.asset(
  'assets/images/close.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
);

final SvgPicture deleteIcon = SvgPicture.asset(
  'assets/images/delete.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
);

final SvgPicture cancelIcon = SvgPicture.asset(
  'assets/images/cancel.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
);

final SvgPicture blockIcon = SvgPicture.asset(
  'assets/images/block.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
);

final SvgPicture personAddIcon = SvgPicture.asset(
  'assets/images/person_add.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
  colorFilter: const ColorFilter.mode(
    textMainColor, // или другой нужный
    BlendMode.srcIn,
  ),
);

final SvgPicture searchIcon = SvgPicture.asset(
  'assets/images/search.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
);

final SvgPicture routesImage = SvgPicture.asset(
  'assets/images/route.svg',
  width: 40,
  height: 40,
  fit: BoxFit.cover,
);
final SvgPicture eyeImage = SvgPicture.asset(
  'assets/images/eye_icon.svg',
  width: 24,
  height: 24,
);
final SvgPicture hideEyeImage = SvgPicture.asset(
  'assets/images/hide_eye_icon.svg',
  width: 24,
  height: 24,
);
final SvgPicture lockImage = SvgPicture.asset(
  'assets/images/lock_icon.svg',
  width: 24,
  height: 24,
  colorFilter: const ColorFilter.mode(
    textMainColor, // или другой нужный
    BlendMode.srcIn,
  ),
);
final SvgPicture fbImage = SvgPicture.asset(
  'assets/images/fb_logo.svg',
  width: 24,
  height: 24,
);
final SvgPicture googleImage = SvgPicture.asset(
  'assets/images/google_logo.svg',
  width: 24,
  height: 24,
);
final SvgPicture appleImage = SvgPicture.asset(
  'assets/images/apple_logo.svg',
  width: 24,
  height: 24,
);
final SvgPicture emailImage = SvgPicture.asset(
  'assets/images/email-logo.svg',
    colorFilter: const ColorFilter.mode(
    textMainColor, // или другой нужный
    BlendMode.srcIn,
  ),
  width: 24,
  height: 24,
);
final SvgPicture phoneImage = SvgPicture.asset(
  'assets/images/icon_phone.svg',
  width: 24,
  height: 24,
);
final SvgPicture photoImage = SvgPicture.asset(
  'assets/images/icon_photo.svg',
        width: 24,
        height: 24,
        );
final SvgPicture accountIcon = SvgPicture.asset(
  'assets/images/icon_account_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture carIcon = SvgPicture.asset(
  'assets/images/icon_car_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture helpIcon = SvgPicture.asset(
  'assets/images/icon_help_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture logoutIcon = SvgPicture.asset(
  'assets/images/icon_logout_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture mapIcon = SvgPicture.asset(
  'assets/images/icon_map_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture membershipIcon = SvgPicture.asset(
  'assets/images/icon_membership_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture navigationIcon = SvgPicture.asset(
  'assets/images/icon_navigation_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture settingIcon = SvgPicture.asset(
  'assets/images/icon_setting_profile.svg',
  width: 36,
  height: 36,
  fit: BoxFit.cover,
);

final SvgPicture arrowForwardIcon = SvgPicture.asset(
  'assets/images/icon_arrow_forward.svg',
  width: 8.84,
  height: 15.36,
  fit: BoxFit.cover,
);

final socialSuffix = Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    fbImage,
    const SizedBox(width: 2),
    googleImage,
    const SizedBox(width: 2),
    appleImage,
    const SizedBox(width: 2),
    emailImage,
  ],
);

final SvgPicture arrowBackImage = SvgPicture.asset(
  'assets/images/arrow-back.svg',
  colorFilter: const ColorFilter.mode(
    textMainColor, // или другой нужный
    BlendMode.srcIn,
  ),
);

final SvgPicture arrowDownImage = SvgPicture.asset(
  'assets/images/arrow-down.svg',
  colorFilter: const ColorFilter.mode(
    textMainColor, // или другой нужный
    BlendMode.srcIn,
  ),
);

// final SvgPicture logoutImage = SvgPicture.asset(
//   'assets/images/icon_logout.svg',
//   width: 24,
//   height: 24,
//   fit: BoxFit.cover,
//   colorFilter: const ColorFilter.mode(
//     primaryColor, // или другой нужный
//     BlendMode.srcIn,
//   ),
// );

final SvgPicture settingsImage = SvgPicture.asset(
  'assets/images/icon_setting.svg',
  width: 24,
  height: 24,
  fit: BoxFit.cover,
  colorFilter: const ColorFilter.mode(
    buttonSecondBackgroundColor, // или другой нужный
    BlendMode.srcIn,
  ),
);

SvgPicture splashLogo({double width = 300}) {
  return SvgPicture.asset(
    'assets/images/splash.svg',
    width: width,
    fit: BoxFit.contain,
  );
}

final SvgPicture logoImageWhiteTheme =  SvgPicture.asset(
    'assets/images/eeWAY/eeWay_favicon_must.svg',

    fit: BoxFit.contain,
  );

final SvgPicture logoImageBlackTheme =  SvgPicture.asset(
    'assets/images/eeWAY/eeWay_favicon_valge.svg',

    fit: BoxFit.contain,
  );
class AppIcons {
  static const String home = 'assets/images/icon_home.svg';
  static const String routes = 'assets/images/icon_route.svg';
  static const String friends = 'assets/images/icon_friends2.svg';
  static const String profile = 'assets/images/icon_profile.svg';
}

SvgPicture buildColoredIcon(String assetPath, bool isSelected) {
  return SvgPicture.asset(
    assetPath,
    width: 24,
    height: 24,
    fit: BoxFit.cover,
    color: isSelected ? backgroundSecondColor : textCustomColor
  );
}

// Аватар мальчики
final SvgPicture avatarBoy01 = SvgPicture.asset(
  'assets/images/avatar_boy_01.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarBoy02 = SvgPicture.asset(
  'assets/images/avatar_boy_02.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarBoy03 = SvgPicture.asset(
  'assets/images/avatar_boy_03.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarBoy04 = SvgPicture.asset(
  'assets/images/avatar_boy_04.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarBoy05 = SvgPicture.asset(
  'assets/images/avatar_boy_05.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

// Аватар девочки
final SvgPicture avatarGirl01 = SvgPicture.asset(
  'assets/images/avatar_girl_01.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarGirl02 = SvgPicture.asset(
  'assets/images/avatar_girl_02.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarGirl03 = SvgPicture.asset(
  'assets/images/avatar_girl_03.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarGirl04 = SvgPicture.asset(
  'assets/images/avatar_girl_04.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

final SvgPicture avatarGirl05 = SvgPicture.asset(
  'assets/images/avatar_girl_05.svg',
  width: 88,
  height: 88,
  fit: BoxFit.cover,
);

// Иконки главного меню
final SvgPicture routesMenuIcon = SvgPicture.asset(
  'assets/images/routes_menu.svg',
  width: 63,
  height: 79,
  fit: BoxFit.cover,
);

final SvgPicture competitionsMenuIcon = SvgPicture.asset(
  'assets/images/competitions_menu.svg',
  width: 77,
  height: 74,
  fit: BoxFit.cover,
);

final SvgPicture friendsMenuIcon = SvgPicture.asset(
  'assets/images/friends_menu.svg',
  width: 74,
  height: 57,
  fit: BoxFit.cover,
);

final SvgPicture groupsMenuIcon = SvgPicture.asset(
  'assets/images/groups_menu.svg',
  width: 106,
  height: 57,
  fit: BoxFit.cover,
);

// Иконки нижней панели навигации
final SvgPicture saveIconNavigation = SvgPicture.asset(
  'assets/images/save_icon_navigation.svg',
  width: 17.04,
  height: 20,
  fit: BoxFit.contain,
);

final SvgPicture pauseIconNavigation = SvgPicture.asset(
  'assets/images/pause_icon_navigation.svg',
  width: 19,
  height: 21.26,
  fit: BoxFit.contain,
);

final SvgPicture deleteIconNavigation = SvgPicture.asset(
  'assets/images/delete_icon_navigation.svg',
  width: 20,
  height: 20,
  fit: BoxFit.contain,
);

final SvgPicture goIconNavigation = SvgPicture.asset(
  'assets/images/go_icon_navigation.svg',
  width: 21,
  height: 21,
  fit: BoxFit.contain,
);

final SvgPicture settingsIconNavigation = SvgPicture.asset(
  'assets/images/settings_icon.svg',
  width: 21,
  height: 21,
  fit: BoxFit.contain,
);

final SvgPicture motoIcon = SvgPicture.asset(
  'assets/images/moto_icon.svg',
  width: 56,
  fit: BoxFit.contain,
);

final SvgPicture jeepIcon = SvgPicture.asset(
  'assets/images/Jeep_icon.svg',
  width: 64,
  fit: BoxFit.contain,
);

final SvgPicture truckIcon = SvgPicture.asset(
  'assets/images/small_truck_icon.svg',
  width: 64,
  fit: BoxFit.contain,
);

final SvgPicture locationArrow = SvgPicture.asset(
  'assets/images/location-arrow.svg',
  width: 21,
  height: 21,
  fit: BoxFit.contain,
);

const motoIconPath  = 'assets/images/moto_icon.svg';
const jeepIconPath  = 'assets/images/Jeep_icon.svg';
const truckIconPath = 'assets/images/small_truck_icon.svg';