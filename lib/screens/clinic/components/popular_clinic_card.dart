import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../generated/assets.dart';
import '../../../main.dart';
import '../../../utils/app_common.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../clinic_detail_screen.dart';
import '../model/clinics_res_model.dart';
import '../../service/service_list_controller.dart';

class PopularClinicCard extends StatelessWidget {
  final Clinic clinicElement;
  final double? width;
  final bool showLogo;

  const PopularClinicCard({
    super.key,
    required this.clinicElement,
    this.width,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationDefault(
          color: context.cardColor, borderRadius: radius(8)),
      width: width ?? Get.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CachedImageWidget(
                url: clinicElement.clinicImage,
                width: Get.width,
                fit: BoxFit.cover,
                topLeftRadius: 8,
                topRightRadius: 8,
                height: Get.height * 0.24,
              ).onTap(() {
                currentSelectedClinic(clinicElement);
                Get.delete<ServiceListController>();
                Get.to(() => ClinicDetailScreen(), arguments: clinicElement);
              }),
              // Clinic Logo
              if (showLogo && clinicElement.logo.isNotEmpty)
                Positioned(
                  bottom: -16,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedImageWidget(
                        url: clinicElement.logo,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    clinicElement.name,
                    style: boldTextStyle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).expand(),
                ],
              ).paddingTop(16),
              GestureDetector(
                onTap: () {
                  launchMap(clinicElement.address);
                },
                behavior: HitTestBehavior.translucent,
                child: Row(
                  children: [
                    const CachedImageWidget(
                        url: Assets.iconsIcLocation,
                        color: iconColor,
                        width: 16,
                        height: 16),
                    12.width,
                    Text(
                      clinicElement.address,
                      style: secondaryTextStyle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ).expand(),
                  ],
                ),
              ).paddingTop(12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.translucent,
                    child: Row(
                      children: [
                        const CachedImageWidget(
                            url: Assets.iconsIcCall,
                            color: iconColor,
                            width: 14,
                            height: 14),
                        12.width,
                        GestureDetector(
                          onTap: () {
                            launchCall(clinicElement.contactNumber);
                          },
                          child: Text(clinicElement.contactNumber,
                              style: primaryTextStyle(color: context.themePrimary)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: boxDecorationDefault(
                            color: getClinicStatusLightColor(
                                clinicStatus:
                                    clinicElement.clinicStatus.toLowerCase()),
                            borderRadius: radius(22),
                          ),
                          child: Text(
                            getClinicStatus(
                                status:
                                    clinicElement.clinicStatus.toLowerCase()),
                            style: boldTextStyle(
                                size: 10,
                                color: getClinicStatusColor(
                                    clinicStatus: clinicElement.clinicStatus
                                        .toLowerCase())),
                          ),
                        ),
                      ],
                    ),
                  ).expand(),
                ],
              ).paddingTop(8),
              TextButton(
                onPressed: () {
                  currentSelectedClinic(clinicElement);
                  Get.delete<ServiceListController>();
                  Get.to(() => ClinicDetailScreen(), arguments: clinicElement);
                },
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  overlayColor: WidgetStatePropertyAll(lightSecondaryColor),
                ),
                child: Text(locale.value.viewDetail,
                    style: boldTextStyle(color: context.themePrimary, size: 12)),
              ),
              8.height,
            ],
          ).paddingSymmetric(horizontal: 16),
        ],
      ),
    );
  }
}
