import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../api/core_apis.dart';
import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/empty_error_state_widget.dart';
import '../clinic/model/clinics_res_model.dart';
import '../doctor/doctor_detail_screen.dart';
import '../doctor/model/doctor_list_res.dart';
import '../service/model/service_list_model.dart';
import '../slots/booking_form_screen.dart';

/// Screen that shows doctors available for a specific service in a clinic.
/// Arguments: Map with 'service' (ServiceElement), 'clinic' (Clinic)
class ServiceDoctorsScreen extends StatefulWidget {
  const ServiceDoctorsScreen({super.key});

  @override
  State<ServiceDoctorsScreen> createState() => _ServiceDoctorsScreenState();
}

class _ServiceDoctorsScreenState extends State<ServiceDoctorsScreen> {
  late ServiceElement service;
  late Clinic clinic;

  RxBool isLoading = false.obs;
  RxList<Doctor> doctors = RxList();
  Rx<Future<RxList<Doctor>>> doctorsFuture = Future(() => RxList<Doctor>()).obs;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    service = args['service'] as ServiceElement;
    clinic = args['clinic'] as Clinic;
    _loadDoctors();
  }

  Future<void> _loadDoctors({bool showLoader = true}) async {
    if (showLoader) isLoading(true);
    await doctorsFuture(
      CoreServiceApis.getDoctors(
        doctors: doctors,
        clinicId: clinic.id,
        selectedServices: [service.id],
        lastPageCallBack: (p0) {},
      ),
    ).then((value) {
      log('Service doctors loaded: ${value.length}');
    }).catchError((e) {
      log('Error loading service doctors: $e');
    }).whenComplete(() => isLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: service.localizedName,
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: isLoading,
      body: RefreshIndicator(
        onRefresh: () => _loadDoctors(showLoader: false),
        child: Obx(
          () => SnapHelperWidget(
            future: doctorsFuture.value,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: () => _loadDoctors(),
              ).paddingSymmetric(horizontal: 32);
            },
            loadingWidget:
                isLoading.value ? const Offstage() : const LoaderWidget(),
            onSuccess: (p0) {
              if (doctors.isEmpty && !isLoading.value) {
                return NoDataWidget(
                  title: locale.value.noDoctorsFoundAtAMoment,
                  titleTextStyle: primaryTextStyle(),
                  imageWidget: const EmptyStateWidget(),
                  retryText: locale.value.reload,
                  onRetry: () => _loadDoctors(),
                ).paddingSymmetric(horizontal: 32);
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      locale.value.chooseDoctor,
                      style: boldTextStyle(size: 16),
                    ),
                    4.height,
                    Text(
                      '${doctors.length} ${locale.value.doctors}',
                      style: secondaryTextStyle(size: 12),
                    ),
                    16.height,

                    // Doctors list
                    ...doctors.map(
                      (doctor) => _buildDoctorTile(context, doctor),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorTile(BuildContext context, Doctor doctor) {
    return GestureDetector(
      onTap: () {
        // Set globals and navigate to booking
        currentSelectedClinic(clinic);
        currentSelectedService(service);
        currentSelectedDoctor(doctor);
        Get.to(() => BookingFormScreen());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: radius(14),
        ),
        child: Row(
          children: [
            // Doctor avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedImageWidget(
                url: doctor.profileImage,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              ),
            ),
            14.width,
            // Doctor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: boldTextStyle(size: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (doctor.expert.isNotEmpty) ...[
                    6.height,
                    Text(
                      doctor.expert,
                      style: secondaryTextStyle(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  8.height,
                  // Book button
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: boxDecorationDefault(
                      color: appColorPrimary,
                      borderRadius: radius(18),
                    ),
                    child: Text(
                      locale.value.bookNow,
                      style: boldTextStyle(size: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Info icon to go to doctor detail
            GestureDetector(
              onTap: () =>
                  Get.to(() => DoctorDetailScreen(), arguments: doctor),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.themeSubtleSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline,
                    size: 20, color: context.themeMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
