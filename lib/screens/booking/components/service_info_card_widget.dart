import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../utils/app_common.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../model/appointments_res_model.dart';

class ServiceInfoCardWidget extends StatelessWidget {
  final AppointmentData appointmentDet;

  const ServiceInfoCardWidget({super.key, required this.appointmentDet});

  @override
  Widget build(BuildContext context) {
    return appointmentDet.billingItems.isEmpty
        ? Container(
            decoration: boxDecorationDefault(color: context.cardColor),
            child: Column(
              children: [
                16.height,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: boxDecorationDefault(),
                      child: CachedImageWidget(
                        url: appointmentDet.serviceImage,
                        fit: BoxFit.cover,
                        radius: 6,
                      ),
                    ),
                    16.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: boxDecorationDefault(
                            color: isDarkMode.value
                                ? Colors.grey.withValues(alpha: 0.1)
                                : lightSecondaryColor,
                            borderRadius: radius(8),
                          ),
                          child: Text(
                            appointmentDet.categoryName,
                            style: boldTextStyle(
                                size: 10,
                                fontFamily: fontFamilyWeight700,
                                color: context.themePrimary),
                          ),
                        ).visible(appointmentDet.categoryName.isNotEmpty),
                        8.height,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(appointmentDet.serviceName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: boldTextStyle(size: 16))
                                    .expand(),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ).expand(),
                  ],
                ),
                16.height,
              ],
            ).paddingSymmetric(horizontal: 16),
          )
        : AnimatedListView(
            shrinkWrap: true,
            itemCount: appointmentDet.billingItems.length,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            listAnimationType: ListAnimationType.None,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.only(
                    bottom: index == appointmentDet.billingItems.length - 1
                        ? 0
                        : 16),
                decoration: boxDecorationDefault(
                    borderRadius: BorderRadius.circular(6),
                    color: context.cardColor),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: boxDecorationDefault(),
                      child: CachedImageWidget(
                        url: appointmentDet.billingItems[index].serviceDetail !=
                                null
                            ? appointmentDet
                                .billingItems[index].serviceDetail!.serviceImage
                            : "",
                        fit: BoxFit.cover,
                        radius: 6,
                      ),
                    ).paddingRight(16).visible(
                        appointmentDet.billingItems[index].serviceDetail !=
                            null),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(appointmentDet.billingItems[index].itemName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: boldTextStyle(size: 14))
                                .expand(),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (appointmentDet.billingItems[index].quantity > 1)
                              Text(
                                'x ${appointmentDet.billingItems[index].quantity}',
                                style: secondaryTextStyle(
                                    size: 12, color: dividerColor),
                              ),
                          ],
                        ),
                      ],
                    ).flexible(),
                  ],
                ),
              );
            },
          );
  }

  bool isAppointmentService(int index) =>
      appointmentDet.billingItems[index].serviceDetail != null &&
      appointmentDet.billingItems[index].serviceDetail!.id ==
          appointmentDet.serviceId;
}
