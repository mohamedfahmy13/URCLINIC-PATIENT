import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/api/auth_apis.dart';
import 'package:kivicare_patient/main.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import '../booking/appointments_controller.dart';
import '../home/home_controller.dart';
import '../../utils/secure_storage.dart';
import 'dashboard_controller.dart';
import 'components/menu.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController dashboardController =
      Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return DoublePressBackWidget(
      message: locale.value.pressBackAgainToExitApp,
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          child: Obx(() => dashboardController
              .screen[dashboardController.currentIndex.value]),
        ),
        bottomNavigationBar: Obx(
          () => Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: dashboardController.currentIndex.value,
              backgroundColor: context.cardColor,
              selectedItemColor: context.themePrimary,
              unselectedItemColor:
                  isDarkMode.value ? Colors.white54 : Colors.grey.shade400,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              onTap: (index) {
                if (!isLoggedIn.value && index == 1) {
                  doIfLoggedIn(() {
                    handleChangeTabIndex(index);
                  });
                } else {
                  handleChangeTabIndex(index);
                }
              },
              items: bottomNavItems
                  .map(
                    (navBar) => BottomNavigationBarItem(
                      icon: Image.asset(
                        navBar.icon,
                        height: 24,
                        width: 24,
                        color: isDarkMode.value
                            ? Colors.white54
                            : Colors.grey.shade400,
                      ),
                      activeIcon: Image.asset(
                        navBar.activeIcon,
                        height: 24,
                        width: 24,
                        color: context.themePrimary,
                      ),
                      label: '',
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void handleChangeTabIndex(int index) {
    dashboardController.selectedBottomNav(bottomNavItems[index]);
    dashboardController.currentIndex(index);
    try {
      if (index == 0 || (index == 2 && isLoggedIn.value)) {
        final HomeController hCont = Get.find();
        hCont.getDashboardDetail(isFromSwipeRefresh: true);
      } else if (isLoggedIn.value && index == 1) {
        final AppointmentsController aCont = Get.find();
        aCont.getAppointmentList(showLoader: false);
      }
      if (index == 2 && isLoggedIn.value) {
        AuthServiceApis.viewProfile().then((data) {
          loginUserData(
            UserData(
              id: loginUserData.value.id,
              firstName: data.userData.firstName,
              lastName: data.userData.lastName,
              userName: "${data.userData.firstName} ${data.userData.lastName}",
              mobile: data.userData.mobile,
              email: data.userData.email,
              userRole: loginUserData.value.userRole,
              gender: data.userData.gender,
              dateOfBirth: data.userData.dateOfBirth,
              address: data.userData.address,
              apiToken: loginUserData.value.apiToken,
              profileImage: data.userData.profileImage,
              loginType: loginUserData.value.loginType,
            ),
          );
          saveUserDataSecure(loginUserData.value);
        }).catchError((e) {
          toast(e.toString());
        });
      }
    } catch (e) {
      log('onItemSelected Err: $e');
    }
  }
}
