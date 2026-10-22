import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../generated/assets.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import '../booking/model/save_booking_res.dart';

class BookingSuccessScreen extends StatelessWidget {
  BookingSuccessScreen({super.key});

  final RxBool isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hideAppBar: true,
      isLoading: isLoading,
      body: Container(
        constraints: BoxConstraints(minHeight: Get.height * 0.7),
        decoration: boxDecorationDefault(color: context.cardColor),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: boxDecorationDefault(
                        color: appColorPrimary, shape: BoxShape.circle),
                    child: Image.asset(Assets.imagesConfirm, scale: 1),
                  ),
                  24.height,
                  Text(locale.value.great,
                      style: boldTextStyle(color: context.themePrimary),
                      textAlign: TextAlign.center),
                  8.height,
                  Text(locale.value.bookingSuccessful,
                      style: boldTextStyle(size: 20, color: context.themePrimary),
                      textAlign: TextAlign.center),
                  12.height,
                  Text(locale.value.yourAppointmentHasBeenBookedSuccessfully,
                      textAlign: TextAlign.center,
                      style: secondaryTextStyle(size: 14)),
                  20.height,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: boxDecorationDefault(
                      color: appColorPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: context.themePrimary, size: 18),
                        8.width,
                        Text(
                          '${locale.value.appointmentStatus}: ${locale.value.pending}',
                          textAlign: TextAlign.center,
                          style: boldTextStyle(color: context.themePrimary),
                        ),
                      ],
                    ),
                  ),
                  14.height,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: boxDecorationDefault(
                      color: context.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(defaultRadius),
                      border: Border.all(
                        color: appColorPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: context.themePrimary, size: 18),
                        10.width,
                        Expanded(
                          child: Text(
                            locale.value
                                .pleaseWaitForAppointmentConfirmationOrCancellation,
                            textAlign: TextAlign.start,
                            style: secondaryTextStyle(size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  28.height,
                  Wrap(
                    runSpacing: 8,
                    spacing: 4,
                    children: List.generate(
                        Get.width ~/ 16,
                        (index) => Container(
                            width: 8,
                            height: 2,
                            decoration: boxDecorationDefault(
                                color: context.dividerColor
                                    .withValues(alpha: 0.3)))),
                  ),
                ],
              ),
            ).paddingBottom(80),
            Positioned(
              bottom: 22,
              left: 16,
              right: 16,
              child: AppButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                text: locale.value.goToAppointments,
                color: appColorSecondary,
                textStyle: appButtonTextStyleWhite,
                onTap: () {
                  /// To Clear Value
                  saveBookingRes(
                      SaveBookingRes(saveBookingResData: SaveBookingResData()));
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ).paddingSymmetric(horizontal: 16).center(),
    );
  }
}
