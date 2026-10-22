import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/utils/common_base.dart';
import '../../../components/notification_bell_badge.dart';
import '../../../utils/colors.dart';
import '../../auth/other/notification_screen.dart';
import '../../clinic/clinic_map_screen.dart';
import '../../clinic/clinics_list_screen.dart';
import 'ai_chat_screen.dart';

class GreetingsComponent extends StatelessWidget {
  const GreetingsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: Row(
        children: [
          // Search icon
          GestureDetector(
            onTap: () {
              Get.to(() => ClinicListScreen(),
                  arguments: {'isFromSearch': true});
            },
            behavior: HitTestBehavior.translucent,
            child: Icon(
              Icons.search,
              color: context.themePrimary,
              size: 24,
            ),
          ),
          12.width,
          // Chat icon (AI Chat)
          GestureDetector(
            onTap: () {
              Get.to(() => AIChatScreen());
            },
            behavior: HitTestBehavior.translucent,
            child: Icon(
              Icons.chat_bubble_outline,
              color: context.themePrimary,
              size: 24,
            ),
          ),
          12.width,
          // Nearby Location icon
          GestureDetector(
            onTap: () {
              Get.to(() => ClinicMapScreen());
            },
            behavior: HitTestBehavior.translucent,
            child: Icon(
              Icons.near_me_outlined,
              color: context.themePrimary,
              size: 24,
            ),
          ),
          const Spacer(),
          // Right side: App name
          Text(
            'UrClinic',
            style: boldTextStyle(size: 20, color: context.themePrimary),
          ),
          10.width,
          NotificationBellBadge(
            onTap: () {
              doIfLoggedIn(() {
                Get.to(() => NotificationScreen());
              });
            },
          ),
        ],
      ).paddingSymmetric(horizontal: 16),
    );
  }
}
