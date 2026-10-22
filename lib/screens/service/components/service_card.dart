import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/utils/colors.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../components/discount_badge_widget.dart';
import '../../../components/app_custom_dialog.dart';
import '../../../generated/assets.dart';
import '../../../main.dart';
import '../../../utils/app_common.dart';
import '../../../utils/price_widget.dart';
import '../../clinic/clinics_list_screen.dart';
import '../../doctor/doctor_list_screen.dart';
import '../model/service_list_model.dart';
import '../service_detail_screen.dart';

class ServiceCard extends StatelessWidget {
  final ServiceElement serviceElement;
  final bool isFromClinicDetail;

  const ServiceCard(
      {super.key,
      required this.serviceElement,
      this.isFromClinicDetail = false});

  void _handleBookNowTap(BuildContext context) {
    if (isFromClinicDetail) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        builder: (context) {
          return AppCustomDialog(
            title: locale.value.doYouWantToReplaceThePreviousServiceWithTheCu,
            negativeText: locale.value.no,
            positiveText: locale.value.yes,
            onTap: () {
              currentSelectedService(serviceElement);
              Get.back();
              Get.to(() => DoctorsListScreen(),
                  arguments: currentSelectedClinic.value.id);
            },
          );
        },
      );
    } else {
      /// Store select service in global variable
      currentSelectedService(serviceElement);
      Get.to(() => ClinicListScreen(), arguments: serviceElement);
    }
  }

  void _handleCardTap(BuildContext context) {
    if (isFromClinicDetail) {
      // In clinic booking flow, tapping service image should behave as Book Now.
      _handleBookNowTap(context);
      return;
    }

    Get.to(() => ServiceDetailScreen(isFromClinicDetail: isFromClinicDetail),
        arguments: serviceElement);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleCardTap(context),
      child: Container(
        decoration: boxDecorationDefault(
            color: context.cardColor, borderRadius: radius(8)),
        width: Get.width / 2 - 24,
        child: Column(
          children: [
            Hero(
              tag: serviceElement.serviceImage.trim().isNotEmpty
                  ? "${serviceElement.id}${serviceElement.serviceImage}"
                  : UniqueKey(),
              child: Stack(
                children: [
                  CachedImageWidget(
                    url: serviceElement.serviceImage,
                    fit: BoxFit.cover,
                    width: Get.width / 2 - 24,
                    height: Get.height * 0.15,
                    topLeftRadius: 8,
                    topRightRadius: 8,
                    bottomRightRadius:
                        serviceElement.isVideoConsultancy ? 6 : 0,
                  ),
                  if (serviceElement.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DiscountBadgeWidget.circular(
                        label: serviceElement.discountBadgeText,
                      ),
                    ),
                  if (serviceElement.isVideoConsultancy)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: boxDecorationDefault(
                          color: completedStatusColor,
                          borderRadius: BorderRadius.only(
                              topLeft: radiusCircular(),
                              bottomRight: radiusCircular(6)),
                          border: Border(
                              left: BorderSide(
                                  color: context.cardColor, width: 6),
                              top: BorderSide(
                                  color: context.cardColor, width: 6)),
                        ),
                        child: CachedImageWidget(
                          url: Assets.imagesVideoCamera,
                          fit: BoxFit.fitHeight,
                          height: 10,
                          color: context.cardColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      serviceElement.localizedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: boldTextStyle(size: 16),
                    ).flexible(),
                  ],
                ),
                8.height,
                Marquee(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 6,
                    children: [
                      // Main price: discounted payableAmount when discount applied, else charges
                      PriceWidget(
                        price: serviceElement.finalPrice,
                        size: 18,
                      ),
                      // Original price with strikethrough when discounted
                      if (serviceElement.hasDiscount)
                        PriceWidget(
                          price: serviceElement.basePrice,
                          isLineThroughEnabled: true,
                          size: 14,
                          color: textSecondaryColorGlobal,
                        ),
                      if (serviceElement.isInclusiveTaxesAvailable) ...[
                        Text(
                          locale.value.includesInclusiveTax,
                          style: secondaryTextStyle(
                            color: context.themePrimary,
                            size: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                6.height,
                AppButton(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  margin: EdgeInsets.zero,
                  width: Get.width,
                  elevation: 0,
                  color: appColorSecondary,
                  onTap: () => _handleBookNowTap(context),
                  child: Text(locale.value.bookNow,
                      style: boldTextStyle(
                          size: 12,
                          color: whiteTextColor,
                          weight: FontWeight.w400)),
                ),
                // const Spacer()
              ],
            ).paddingSymmetric(horizontal: 12, vertical: 12),
          ],
        ),
      ),
    );
  }

/*  Future<void> checkAndNavigateToBookingForm(ServiceElement serviceElement) async {
    try {
      // Get clinics for this service
      final RxList<Clinic> clinics = RxList();
      await CoreServiceApis.getClinics(
        clinics: clinics,
        serviceId: serviceElement.id,
        lastPageCallBack: (p) {},
      );

      if (clinics.length == 1) {
        // Only one clinic available - auto-select and navigate directly to booking form
        currentSelectedClinic(clinics[0]);
        log('Auto-selected clinic: ${clinics[0].name}');
        Get.to(() => BookingFormScreen());
      } else {
        // Multiple clinics available - show clinic selection screen
        Get.to(() => ClinicListScreen(), arguments: serviceElement);
      }
    } catch (e) {
      log('Error checking clinics: $e');
      // Fallback to clinic selection screen
      Get.to(() => ClinicListScreen(), arguments: serviceElement);
    }
  }*/
}
