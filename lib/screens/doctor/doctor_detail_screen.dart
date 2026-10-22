import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../components/social_media_element.dart';
import '../../generated/assets.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import '../../utils/empty_error_state_widget.dart';
import 'components/doctor_detail_btm_comp.dart';
import 'doctor_detail_controller.dart';

class DoctorDetailScreen extends StatelessWidget {
  DoctorDetailScreen({super.key});

  final DoctorDetailController doctorDetailCont = Get.put(DoctorDetailController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.doctorDetail,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: doctorDetailCont.isLoading,
      body: RefreshIndicator(
        onRefresh: () {
          return doctorDetailCont.init(showLoader: false);
        },
        child: Obx(
          () => SnapHelperWidget(
            future: doctorDetailCont.getDoctorDetail.value,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: () {
                  doctorDetailCont.init();
                },
              ).paddingSymmetric(horizontal: 16);
            },
            loadingWidget: const LoaderWidget(),
            onSuccess: (data) {
              return AnimatedScrollView(
                listAnimationType: ListAnimationType.FadeIn,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    color: context.cardColor,
                    child: Column(
                      children: [
                        CachedImageWidget(
                          url: doctorDetailCont.doctorData.value.profileImage,
                          fit: BoxFit.cover,
                          width: Get.width,
                          height: Get.height * 0.3,
                          topLeftRadius: (defaultRadius * 2).toInt(),
                          topRightRadius: (defaultRadius * 2).toInt(),
                        ),
                        Column(
                          children: [
                            16.height,
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: doctorDetailCont.doctorData.value.fullName.isNotEmpty ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              doctorDetailCont.doctorData.value.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: boldTextStyle(size: 18),
                                            ),
                                            const CachedImageWidget(url: Assets.iconsIcVerified, width: 14, height: 14).paddingLeft(8),
                                          ],
                                        ).paddingRight(16).flexible().visible(doctorDetailCont.doctorData.value.fullName.isNotEmpty),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          doctorDetailCont.doctorData.value.expert,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: primaryTextStyle(color: context.themePrimary),
                                        ).flexible(),
                                      ],
                                    ).paddingTop(6).visible(doctorDetailCont.doctorData.value.expert.isNotEmpty),
                                  ],
                                ).flexible(),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  locale.value.socialMedia,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: secondaryTextStyle(size: 12),
                                ),
                                12.width,
                                SocialMediaElement(
                                  iconPath: Assets.socialMediaIcX,
                                  onPressed: () {
                                    commonLaunchUrl(doctorDetailCont.doctorData.value.twitterLink, launchMode: LaunchMode.externalApplication);
                                  },
                                ).paddingRight(8).visible(doctorDetailCont.doctorData.value.twitterLink.isNotEmpty),
                                SocialMediaElement(
                                  iconPath: Assets.socialMediaIcDribble,
                                  onPressed: () {
                                    commonLaunchUrl(doctorDetailCont.doctorData.value.dribbbleLink, launchMode: LaunchMode.externalApplication);
                                  },
                                ).paddingRight(8).visible(doctorDetailCont.doctorData.value.dribbbleLink.isNotEmpty),
                                SocialMediaElement(
                                  iconPath: Assets.socialMediaIcFb,
                                  onPressed: () {
                                    commonLaunchUrl(doctorDetailCont.doctorData.value.facebookLink, launchMode: LaunchMode.externalApplication);
                                  },
                                ).paddingRight(8).visible(doctorDetailCont.doctorData.value.facebookLink.isNotEmpty),
                                SocialMediaElement(
                                  iconPath: Assets.socialMediaIcInsta,
                                  onPressed: () {
                                    commonLaunchUrl(doctorDetailCont.doctorData.value.instagramLink, launchMode: LaunchMode.externalApplication);
                                  },
                                ).visible(doctorDetailCont.doctorData.value.instagramLink.isNotEmpty),
                              ],
                            ).paddingTop(16).visible(
                                  doctorDetailCont.doctorData.value.twitterLink.isNotEmpty ||
                                      doctorDetailCont.doctorData.value.dribbbleLink.isNotEmpty ||
                                      doctorDetailCont.doctorData.value.facebookLink.isNotEmpty ||
                                      doctorDetailCont.doctorData.value.instagramLink.isNotEmpty,
                                ),
                          ],
                        ).paddingSymmetric(horizontal: 16),
                        16.height,
                      ],
                    ),
                  ),
                  16.height,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReadMoreText(
                        parseHtmlString(doctorDetailCont.doctorData.value.aboutSelf),
                        trimLines: 4,
                        style: secondaryTextStyle(size: 14, color: context.themeMuted),
                        colorClickableText: appColorPrimary,
                        trimMode: TrimMode.Line,
                        trimCollapsedText: " ...${locale.value.readMore}",
                        trimExpandedText: locale.value.readLess,
                        locale: Localizations.localeOf(context),
                      ).paddingBottom(16).visible(doctorDetailCont.doctorData.value.aboutSelf.isNotEmpty),
                      DoctorDetailBtmComp(doctorDetailCont: doctorDetailCont),
                      24.height,
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
