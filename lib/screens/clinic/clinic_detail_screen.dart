import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/utils/common_base.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/discount_badge_widget.dart';
import '../../components/loader_widget.dart';
import '../../generated/assets.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/empty_error_state_widget.dart';
import '../service/service_doctors_screen.dart';
import '../service/services_list_screen.dart';
import 'clinic_detail_controller.dart';
import 'clinic_gallery_list_screen.dart';
import 'clinic_location_screen.dart';

class ClinicDetailScreen extends StatelessWidget {
  ClinicDetailScreen({super.key});

  final ClinicDetailController clinicDetailCont =
      Get.put(ClinicDetailController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      isLoading: clinicDetailCont.isLoading,
      appBartitleText: locale.value.clinicDetail,
      appBarVerticalSize: Get.height * 0.12,
      body: RefreshIndicator(
        onRefresh: () {
          return clinicDetailCont.init(showLoader: false);
        },
        child: Obx(
          () => SnapHelperWidget(
            future: clinicDetailCont.getClinicDetail.value,
            errorBuilder: (error) {
              return NoDataWidget(
                title: clinicDetailCont.clinicFetchError.value.isNotEmpty
                    ? clinicDetailCont.clinicFetchError.value
                    : error.toString(),
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: () {
                  clinicDetailCont.init();
                },
              ).paddingSymmetric(horizontal: 16);
            },
            loadingWidget: const LoaderWidget(),
            onSuccess: (clinicDetailRes) {
              return Stack(
                children: [
                  AnimatedScrollView(
                    listAnimationType: ListAnimationType.FadeIn,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      // Cover Image + Overlapping Logo (Twitter-style)
                      _buildCoverWithLogo(context),

                      // Clinic Name + Status + Select Branch
                      _buildClinicInfo(context),

                      // Contact Info
                      _buildContactInfo(context),

                      // Services horizontal list
                      _buildServicesSection(context),

                      // Gallery
                      _buildGalleryCard(context),

                      24.height,
                    ],
                  ),

                  // Floating Book Now Button
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildBookNowButton(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Cover image with overlapping logo (Twitter/X style header)
  Widget _buildCoverWithLogo(BuildContext context) {
    final double coverHeight = Get.height * 0.22;
    const double logoSize = 80.0;
    const double logoBorderWidth = 4.0;

    return SizedBox(
      height: coverHeight + (logoSize / 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover Image
          CachedImageWidget(
            url: clinicDetailCont.clinicData.value.clinicImage,
            fit: BoxFit.cover,
            width: Get.width,
            height: coverHeight,
            topLeftRadius: 0,
            topRightRadius: 0,
          ),

          // Gradient overlay at bottom of cover for smooth transition
          Positioned(
            bottom: logoSize / 2,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.scaffoldBackgroundColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // Status Badge (top right on cover)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: boxDecorationDefault(
                color: getClinicStatusLightColor(
                  clinicStatus: clinicDetailCont.clinicData.value.clinicStatus
                      .toLowerCase(),
                ),
                borderRadius: radius(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: getClinicStatusColor(
                        clinicStatus: clinicDetailCont
                            .clinicData.value.clinicStatus
                            .toLowerCase(),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  6.width,
                  Text(
                    getClinicStatus(
                        status: clinicDetailCont.clinicData.value.clinicStatus
                            .toLowerCase()),
                    style: boldTextStyle(
                      size: 11,
                      color: getClinicStatusColor(
                        clinicStatus: clinicDetailCont
                            .clinicData.value.clinicStatus
                            .toLowerCase(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logo overlapping the cover (bottom-left)
          Positioned(
            bottom: 0,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(logoBorderWidth),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedImageWidget(
                  url: clinicDetailCont.clinicData.value.logo.isNotEmpty
                      ? clinicDetailCont.clinicData.value.logo
                      : clinicDetailCont.clinicData.value.clinicImage,
                  width: logoSize - (logoBorderWidth * 2),
                  height: logoSize - (logoBorderWidth * 2),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clinic name, specialty, and branch selector below the header
  Widget _buildClinicInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicDetailCont.clinicData.value.name,
                      style: boldTextStyle(size: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ).visible(
                        clinicDetailCont.clinicData.value.name.isNotEmpty),
                    if (clinicDetailCont
                        .clinicData.value.localizedSpecialty.isNotEmpty) ...[
                      4.height,
                      Text(
                        clinicDetailCont.clinicData.value.localizedSpecialty,
                        style: secondaryTextStyle(size: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              8.width,
              // Working Hours icon button
              GestureDetector(
                onTap: () => _showWorkingHoursDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: boxDecorationDefault(
                    color: appColorSecondary.withOpacity(0.1),
                    borderRadius: radius(20),
                    border: Border.all(color: appColorSecondary, width: 1),
                  ),
                  child: Icon(Icons.access_time_rounded,
                      color: context.themePrimary, size: 18),
                ),
              ),
              8.width,
              // Select Branch / Location button
              GestureDetector(
                onTap: () {
                  Get.to(() => ClinicLocationScreen(
                        clinic: clinicDetailCont.clinicData.value,
                      ));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: boxDecorationDefault(
                    color: appColorPrimary.withOpacity(0.1),
                    borderRadius: radius(20),
                    border: Border.all(color: appColorPrimary, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: context.themePrimary, size: 16),
                      6.width,
                      Text(
                          clinicDetailCont.clinicData.value.additionalAddresses
                                  .isNotEmpty
                              ? locale.value.selectBranch
                              : locale.value.address,
                          style:
                              boldTextStyle(size: 12, color: context.themePrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          12.height,
        ],
      ),
    );
  }

  /// Services Section - Horizontal scrollable chips
  Widget _buildServicesSection(BuildContext context) {
    return Obx(
      () {
        if (clinicDetailCont.serviceList.isEmpty &&
            !clinicDetailCont.isServicesLoading.value) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                locale.value.services,
                style: boldTextStyle(size: 16),
              ),
            ),
            12.height,
            if (clinicDetailCont.isServicesLoading.value)
              const LoaderWidget()
            else
              SizedBox(
                height: 55,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clinicDetailCont.serviceList.length,
                  separatorBuilder: (_, __) => 10.width,
                  itemBuilder: (context, index) {
                    final service = clinicDetailCont.serviceList[index];
                    return GestureDetector(
                      onTap: () {
                        Get.to(
                          () => const ServiceDoctorsScreen(),
                          arguments: {
                            'service': service,
                            'clinic': clinicDetailCont.clinicData.value,
                          },
                        );
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: Get.width * 0.45,
                          maxWidth: Get.width * 0.62,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: boxDecorationDefault(
                          color: appColorPrimary.withOpacity(0.08),
                          borderRadius: radius(14),
                          border: Border.all(
                              color: appColorPrimary.withOpacity(0.2),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                service.localizedName,
                                style: boldTextStyle(
                                    size: 13, color: context.themePrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (service.hasDiscount)
                              Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(start: 8),
                                child: DiscountBadgeWidget.pill(
                                  label: service.discountBadgeText,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            16.height,
          ],
        );
      },
    );
  }

  /// Contact Info section
  Widget _buildContactInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.value.contactInfo, style: boldTextStyle(size: 16)),
          12.height,
          Row(
            children: [
              // Phone
              Expanded(
                child: GestureDetector(
                  onTap: () => launchCall(
                      clinicDetailCont.clinicData.value.contactNumber),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: boxDecorationDefault(
                      color: context.cardColor,
                      borderRadius: radius(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedImageWidget(
                          url: Assets.iconsIcCall,
                          color: context.themePrimary,
                          height: 18,
                          width: 18,
                        ),
                        8.width,
                        Flexible(
                          child: Text(
                            locale.value.contactNumber,
                            style: boldTextStyle(size: 12, color: context.themeText),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).visible(clinicDetailCont.clinicData.value.contactNumber
                  .trim()
                  .isNotEmpty),

              12.width.visible(clinicDetailCont.clinicData.value.contactNumber
                      .trim()
                      .isNotEmpty &&
                  clinicDetailCont.clinicData.value.email.isNotEmpty),

              // Email
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      launchMail(clinicDetailCont.clinicData.value.email),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: boxDecorationDefault(
                      color: context.cardColor,
                      borderRadius: radius(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedImageWidget(
                          url: Assets.iconsIcMail,
                          color: context.themePrimary,
                          height: 18,
                          width: 18,
                        ),
                        8.width,
                        Flexible(
                          child: Text(
                            locale.value.email,
                            style: boldTextStyle(size: 12, color: context.themeText),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).visible(clinicDetailCont.clinicData.value.email.isNotEmpty),
            ],
          ),
          16.height,
        ],
      ),
    );
  }

  /// Localize day name to Arabic or English
  String _localizeDay(String day) {
    final Map<String, String> arDays = {
      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
    };
    final Map<String, String> enDays = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };
    final key = day.toLowerCase().trim();
    if (selectedLanguageCode.value == 'ar') {
      return arDays[key] ?? day;
    }
    return enDays[key] ?? day;
  }

  /// Show a friendly working hours dialog
  void _showWorkingHoursDialog(BuildContext context) {
    final openDays = clinicDetailCont.clinicData.value.clinicSession.openDays;
    final closeDays = clinicDetailCont.clinicData.value.clinicSession.closeDays;

    // Get the most common schedule
    final String startTime =
        openDays.isNotEmpty ? _formatTime(openDays.first.startTime) : '';
    final String endTime =
        openDays.isNotEmpty ? _formatTime(openDays.first.endTime) : '';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: radius(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: appColorSecondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time_rounded,
                      color: context.themePrimary, size: 32),
                ),
                16.height,
                Text(
                  locale.value.workingHours,
                  style: boldTextStyle(size: 18),
                ),
                16.height,

                // Main schedule
                if (startTime.isNotEmpty && endTime.isNotEmpty)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: primaryTextStyle(size: 15),
                      children: [
                        TextSpan(
                          text: '${locale.value.fromTime} ',
                          style: secondaryTextStyle(size: 15),
                        ),
                        TextSpan(
                          text: startTime,
                          style:
                              boldTextStyle(size: 15, color: context.themePrimary),
                        ),
                        TextSpan(
                          text: ' ${locale.value.toTime} ',
                          style: secondaryTextStyle(size: 15),
                        ),
                        TextSpan(
                          text: endTime,
                          style:
                              boldTextStyle(size: 15, color: context.themePrimary),
                        ),
                      ],
                    ),
                  ),

                // Closed days
                if (closeDays.isNotEmpty) ...[
                  12.height,
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: closeDays.length == 1
                              ? '${locale.value.exceptDay} '
                              : '${locale.value.exceptDays} ',
                          style: secondaryTextStyle(size: 14),
                        ),
                        TextSpan(
                          text:
                              closeDays.map((d) => _localizeDay(d)).join(', '),
                          style:
                              boldTextStyle(size: 14, color: cancelStatusColor),
                        ),
                      ],
                    ),
                  ),
                ],

                20.height,
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    color: appColorPrimary,
                    shapeBorder:
                        RoundedRectangleBorder(borderRadius: radius(12)),
                    onTap: () => Navigator.pop(ctx),
                    text: locale.value.close,
                    textStyle: boldTextStyle(size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Format time from "09:00:00" to "9:00 AM"
  String _formatTime(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  /// Gallery card
  Widget _buildGalleryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          12.height,
          Obx(
            () => GestureDetector(
              onTap: () => Get.to(() => ClinicGalleryListScreen(),
                  arguments: clinicDetailCont.clinicData.value.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: boxDecorationDefault(
                  color: context.cardColor,
                  borderRadius: radius(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ratingColor.withOpacity(0.1),
                        borderRadius: radius(10),
                      ),
                      child: CachedImageWidget(
                        url: Assets.iconsIcGallery,
                        height: 24,
                        width: 24,
                        color: ratingColor,
                      ),
                    ),
                    16.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.value.gallery,
                          style: boldTextStyle(size: 15),
                        ),
                        4.height,
                        Text(
                          clinicDetailCont
                                      .clinicData.value.totalGalleryImages !=
                                  0
                              ? "${locale.value.total} ${clinicDetailCont.clinicData.value.totalGalleryImages} ${locale.value.photosAvailable}"
                              : locale.value.noPhotosAvailable,
                          style: secondaryTextStyle(size: 12),
                        ),
                      ],
                    ).expand(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: darkGray),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating Book Now Button
  Widget _buildBookNowButton(BuildContext context) {
    return Container(
      decoration: boxDecorationDefault(
        borderRadius: radius(16),
        boxShadow: [
          BoxShadow(
            color: appColorPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppButton(
        width: Get.width,
        color: appColorPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shapeBorder: RoundedRectangleBorder(borderRadius: radius(16)),
        onTap: () {
          // Set the current clinic and navigate to booking
          currentSelectedClinic(clinicDetailCont.clinicData.value);
          Get.to(() => ServiceListScreen(isFromClinicDetail: true),
              arguments: clinicDetailCont.clinicData.value.id);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: Colors.white, size: 22),
            12.width,
            Text(
              locale.value.bookNow,
              style: boldTextStyle(size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
