// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../main.dart';
import '../../../utils/push_notification_service.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../home/home_controller.dart';
import '../model/login_response.dart';
import '../../../api/auth_apis.dart';
import '../../../utils/app_common.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../../utils/local_storage.dart';
import '../../../utils/notification_controller.dart';
import '../../../utils/secure_storage.dart';
import '../../../utils/session_guard.dart';
import '../services/social_logins.dart';

class SignInController extends GetxController {
  RxBool isNavigateToDashboard = false.obs;
  RxBool loginSucessfull = false.obs;
  RxBool tryToAnother = false.obs;
  final GlobalKey<FormState> signInformKey = GlobalKey();

  RxBool isRememberMe = true.obs;
  RxBool isLoading = false.obs;
  RxString userName = "".obs;
  RxInt isGoogleAuthentication = (-1).obs;
  String mfaChallengeToken = "";

  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController otpCont = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode otpFocus = FocusNode();

  final RxInt remainingSeconds = 600.obs; // 10 minutes
  final DashboardController dashcont = Get.put(DashboardController());
  Timer? _timer;

  void toggleSwitch() {
    isRememberMe.value = !isRememberMe.value;
  }

  @override
  void onInit() {
    if (appConfigs.value.isDummyCredential != 1) {
      emailCont.text = '';
      passwordCont.text = '';
      isRememberMe.value = false;
    } else {
      emailCont.text = Constants.DEFAULT_EMAIL;
      passwordCont.text = Constants.DEFAULT_PASS;
    }
    if (Get.arguments is bool) {
      isNavigateToDashboard(Get.arguments == true);
    }
    final userIsRemeberMe =
        getValueFromLocal(SharedPreferenceConst.IS_REMEMBER_ME);
    final userNameFromLocal =
        getValueFromLocal(SharedPreferenceConst.USER_NAME);
    if (userNameFromLocal is String) {
      userName(userNameFromLocal);
    }
    if (userIsRemeberMe == true) {
      final userEmail = getValueFromLocal(SharedPreferenceConst.USER_EMAIL);
      if (userEmail is String) {
        emailCont.text = userEmail;
      }
    }
    super.onInit();
  }

  void startTimer() {
    _timer?.cancel();
    remainingSeconds.value = 600;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void resetTimer() {
    _timer?.cancel();
    remainingSeconds.value = 60;
  }

  @override
  void onClose() {
    _timer?.cancel();
    emailCont.dispose();
    passwordCont.dispose();
    otpCont.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    otpFocus.dispose();
    super.onClose();
  }

  String get formattedTime {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @protected
  Future<UserResponse> loginUserRequest({
    required Map<String, dynamic> request,
    bool isSocialLogin = false,
  }) {
    return AuthServiceApis.loginUser(
      request: request,
      isSocialLogin: isSocialLogin,
    );
  }

  @protected
  Future<UserResponse> verifyUserRequest({
    required Map<String, dynamic> request,
  }) {
    return AuthServiceApis.verifyUser(request: request);
  }

  @protected
  Future<UserData> socialAppleSignInRequest() {
    return AppleSignInAuthService.signInWithApple();
  }

  Future<void> saveForm() async {
    isLoading(true);
    hideKeyBoardWithoutContext();
    await callLoginApi();
  }

  Future<void> callLoginApi() async {
    final Map<String, dynamic> req = {
      'email': emailCont.text.trim(),
      'password': passwordCont.text.trim(),
      UserKeys.userType: LoginTypeConst.LOGIN_TYPE_USER,
    };

    if (emailCont.text == Constants.DEFAULT_EMAIL &&
        passwordCont.text == Constants.DEFAULT_PASS) {
      otpCont.text = Constants.DEFAULT_PASS;
    }

    await loginUserRequest(request: req).then((value) async {
      if (value.status == true) {
        startTimer();
        mfaChallengeToken = value.mfaChallengeToken;
        setValueToLocal(
            SharedPreferenceConst.USER_ID, value.userData.id.toString());
        setValueToLocal(SharedPreferenceConst.IS_GOOGLE_AUTHENTICATION,
            value.userData.isGoogleAuthentication.toString());
        setValueToLocal(SharedPreferenceConst.GOOGLE_AUTHENTICATION_TYPE,
            value.userData.googleAuthenticationType);
        loginSucessfull.value = true;
      } else {
        isLoading(false);
        log(value.message);
        return;
      }

      loginUserData(value.userData);
      isGoogleAuthentication.value = int.tryParse(
              getValueFromLocal(SharedPreferenceConst.IS_GOOGLE_AUTHENTICATION)
                  .toString()) ??
          0;
      if (isRememberMe.value) {
        setValueToLocal(
            SharedPreferenceConst.USER_EMAIL, emailCont.text.trim());
        setValueToLocal(SharedPreferenceConst.USER_NAME, userName.value);
      } else {
        setValueToLocal(SharedPreferenceConst.USER_EMAIL, "");
        setValueToLocal(SharedPreferenceConst.USER_NAME, "");
      }

      await handleLoginResponse(loginResponse: value);
      setValueToLocal(SharedPreferenceConst.USER_ID, value.userData.id);
      // setValueToLocal(
      //     SharedPreferenceConst.ONE_TIME_PASSWORD, value.userData.mobile);
    }).catchError((e) {
      isLoading(false);
      toast(_resolveLoginErrorMessage(e), print: true);
    });
  }

  String _resolveLoginErrorMessage(dynamic error) {
    final String rawMessage = error.toString().trim();
    final String normalizedMessage = rawMessage.toLowerCase();

    final bool isInvalidCredentialsMessage =
        normalizedMessage.contains('provided credentials do not match') ||
            normalizedMessage.contains('invalid credentials') ||
            normalizedMessage.contains('unauthorised') ||
            normalizedMessage.contains('unauthorized');

    return isInvalidCredentialsMessage
        ? locale.value.invalidEmailOrPassword
        : rawMessage;
  }

  Future verifyUser({String? authentication}) async {
    isLoading(true);
    hideKeyBoardWithoutContext();
    final int userId = getValueFromLocal(SharedPreferenceConst.USER_ID);
    final Map<String, dynamic> req = {
      'id': userId,
      'one_time_password': otpCont.text,
      'google_authentication_type': authentication,
      'mfa_challenge_token': mfaChallengeToken,
    };

    await verifyUserRequest(request: req).then((value) async {
      if (value.status == true) {
        isNavigateToDashboard.value = true;
      }
      await handleLoginResponse(loginResponse: value, isVerifyOTP: true);
    }).catchError((e) {
      isLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> appleSignIn() async {
    isLoading(true);
    await socialAppleSignInRequest().then((value) async {
      final Map<String, dynamic> request = {
        UserKeys.contactNumber: value.mobile,
        UserKeys.email: value.email,
        UserKeys.firstName: value.firstName,
        UserKeys.lastName: value.lastName,
        UserKeys.username: value.userName,
        UserKeys.profileImage: value.profileImage,
        UserKeys.userType: LoginTypeConst.LOGIN_TYPE_USER,
        UserKeys.loginType: LoginTypeConst.LOGIN_TYPE_APPLE,
      };

      /// Social Login Api
      await loginUserRequest(request: request, isSocialLogin: true)
          .then((value) async {
        await handleLoginResponse(loginResponse: value, isSocialLogin: true);
        setValueToLocal(SharedPreferenceConst.LOGIN_SUCCESSFULL, true);
      }).catchError((e) {
        isLoading(false);
        toast(e.toString(), print: true);
      });
    }).catchError((e) {
      isLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> handleLoginResponse(
      {required UserResponse loginResponse,
      bool isVerifyOTP = false,
      bool isSocialLogin = false}) async {
    if (loginResponse.userData.userRole
        .contains(LoginTypeConst.LOGIN_TYPE_USER)) {
      loginUserData(loginResponse.userData);
      loginUserData.value.isSocialLogin = isSocialLogin;
      await saveUserDataSecure(loginUserData.value);
      isLoggedIn(true);
      setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, true);
      setValueToLocal(SharedPreferenceConst.IS_REMEMBER_ME, isRememberMe.value);
      markSessionActivity();

      isLoading(false);

      PushNotificationService().registerFCMAndTopics();
      unawaited(NotificationController.to.fetchUnreadCount());

      if (isNavigateToDashboard.value) {
        Get.offAll(
          () => DashboardScreen(),
          binding: BindingsBuilder(() {
            Get.put(HomeController());
          }),
        );
      } else {
        try {
          final DashboardController dashboardController = Get.find();
          dashboardController.reloadBottomTabs();
        } catch (e) {
          if (!kReleaseMode) log('dashboardController Get.find E: $e');
        }
        try {
          final HomeController homeScreenController = Get.find();
          homeScreenController.init();
        } catch (e) {
          if (!kReleaseMode) log('homeScreenController Get.find E: $e');
        }
        Get.back(result: true);
      }
    } else {
      isLoading(false);
      toast(
        loginResponse.message.trim().isEmpty
            ? isVerifyOTP
                ? locale.value.sorryUserCannotSignin
                : locale.value.otpSentToEmail
            : loginResponse.message,
      );
    }
  }
}
