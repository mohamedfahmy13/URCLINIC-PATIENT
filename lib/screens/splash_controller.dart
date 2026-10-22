// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/screens/home/home_controller.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/local_storage.dart';
import '../main.dart';
import '../api/auth_apis.dart';
import '../screens/auth/model/login_response.dart';
import '../utils/common_base.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreenController extends GetxController {
  // Navigation is gated behind two conditions so the splash video isn't cut
  // off: backend config must be ready AND the video must have finished.
  bool _configReady = false;
  bool _videoFinished = false;
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void onInit() {
    super.onInit();
    //Get Package Info
    getPackageInfo().then((value) => currentPackageinfo(value));
    migrateLegacySensitiveData();
    getAppConfigurations();

    // Safety fallback: never trap the user on the splash if the video fails
    // to load or never reports completion.
    _fallbackTimer = Timer(const Duration(seconds: 10), onVideoFinished);
  }

  @override
  void onClose() {
    _fallbackTimer?.cancel();
    super.onClose();
  }

  /// Called by the splash screen once the video finishes (or fails to load).
  void onVideoFinished() {
    _videoFinished = true;
    _tryNavigate();
  }

  void _onConfigReady() {
    _configReady = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_navigated || !_configReady || !_videoFinished) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    navigationLogic();
  }

  @override
  void onReady() {
    try {
      final getThemeFromLocal =
          getValueFromLocal(SettingsLocalConst.THEME_MODE);
      if (getThemeFromLocal is int) {
        toggleThemeMode(themeId: getThemeFromLocal);
      } else {
        toggleThemeMode(themeId: THEME_MODE_LIGHT);
      }
    } catch (e) {
      log('getThemeFromLocal from cache E: $e');
    }
    super.onReady();
  }

  ///Get ChooseService List
  Future<void> getAppConfigurations() async {
    await AuthServiceApis.getAppConfigurations().then((value) {
      appCurrency(value.currency);
      appConfigs(value);

      // Only apply backend language on first launch (when no user preference is saved)
      final savedLang = getValueFromLocal(SELECTED_LANGUAGE_CODE);
      if (savedLang == null || savedLang.toString().isEmpty) {
        final adminLang = value.applicationLanguage.trim();
        if (adminLang.isNotEmpty) {
          applyLanguage(adminLang);
        }
      }

      ///Config ready — navigate once the video also finishes
      _onConfigReady();
    }).onError((error, stackTrace) {
      toast(error.toString());

      ///Config ready — navigate once the video also finishes
      _onConfigReady();
    });
  }

  void navigationLogic() {
    if (getValueFromLocal(SharedPreferenceConst.IS_LOGGED_IN) == true) {
      getUserDataSecure().then((userData) async {
        if (userData != null) {
          // Signed in stays signed in until the user logs out.
          isLoggedIn(true);
          loginUserData(userData);
          // Re-persist the login flag to ensure it survives app crashes
          setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, true);
        } else {
          // User data not found in secure storage, clear the login flag
          isLoggedIn(false);
          setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, false);
          loginUserData(UserData());
        }

        _openDashboard();
      }).catchError((error) {
        // Handle any errors during session restoration
        if (kDebugMode) log('Session restoration error: $error');
        isLoggedIn(false);
        setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, false);
        _openDashboard();
      });
    } else {
      _openDashboard();
    }
  }

  void _openDashboard() {
    Get.offAll(
      () => DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    );
  }
}
