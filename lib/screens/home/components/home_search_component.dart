import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/api/core_apis.dart';
import 'package:kivicare_patient/screens/clinic/clinics_list_screen.dart';
import 'package:kivicare_patient/screens/clinic/model/clinics_res_model.dart';
import 'package:kivicare_patient/screens/doctor/doctor_list_screen.dart';
import 'package:kivicare_patient/screens/doctor/model/doctor_list_res.dart';
import 'package:kivicare_patient/screens/service/model/service_list_model.dart';
import 'package:kivicare_patient/screens/service/services_list_screen.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../components/loader_widget.dart';
import '../../../main.dart';
import '../../../utils/colors.dart';

class HomeSearchComponent extends StatelessWidget {
  const HomeSearchComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => ClinicListScreen(),
                arguments: {'isFromSearch': true}),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: boxDecorationDefault(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: context.themePrimary, size: 24),
                  12.width,
                  Text(
                    locale.value.searchDoctorClinicService,
                    style: secondaryTextStyle(size: 14),
                  ).expand(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: boxDecorationDefault(
                      color: appColorPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tune, color: context.themePrimary, size: 18),
                  ),
                ],
              ),
            ),
          ),
          16.height,
          // Quick Search Chips
          /* Row(
            children: [
              _buildSearchChip(
                context,
                icon: Assets.iconsIcDoctor,
                label: locale.value.doctors,
                onTap: () {
                  log('Doctors tapped');
                  Get.to(() => DoctorsListScreen());
                },
              ),
              12.width,
              _buildSearchChip(
                context,
                icon: Assets.iconsIcClinic,
                label: locale.value.clinics,
                onTap: () {
                  log('Clinics tapped');
                  Get.to(() => ClinicListScreen());
                },
              ),
              12.width,
              _buildSearchChip(
                context,
                icon: Assets.iconsIcServices,
                label: locale.value.services,
                onTap: () {
                  log('Services tapped');
                  Get.to(() => ServiceListScreen());
                },
              ),
            ],
          ),*/
        ],
      ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  const _SearchBottomSheet();

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController searchController = TextEditingController();
  RxInt selectedTab = 0.obs; // 0: All, 1: Doctors, 2: Clinics, 3: Services

  // Search results
  RxList<Doctor> doctors = <Doctor>[].obs;
  RxList<Clinic> clinics = <Clinic>[].obs;
  RxList<ServiceElement> services = <ServiceElement>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasSearched = false.obs;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (searchController.text.trim().length >= 2) {
      _performSearch();
    } else {
      doctors.clear();
      clinics.clear();
      services.clear();
      hasSearched.value = false;
    }
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    isLoading.value = true;
    hasSearched.value = true;

    try {
      // Search based on selected tab
      if (selectedTab.value == 0 || selectedTab.value == 1) {
        // Search Doctors
        await CoreServiceApis.getDoctors(
          doctors: doctors,
          search: query,
          page: 1,
        );
      }

      if (selectedTab.value == 0 || selectedTab.value == 2) {
        // Search Clinics
        await CoreServiceApis.getClinics(
          clinics: clinics,
          search: query,
          page: 1,
        );
      }

      if (selectedTab.value == 0 || selectedTab.value == 3) {
        // Search Services
        await CoreServiceApis.getServiceList(
          serviceList: services,
          search: query,
          page: 1,
        );
      }
    } catch (e) {
      log('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.85,
      decoration: boxDecorationDefault(
        color: context.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: boxDecorationDefault(
              color: context.themeBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          16.height,
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: locale.value.searchDoctorClinicService,
                prefixIcon: Icon(Icons.search, color: context.themePrimary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                      doctors.clear();
                      clinics.clear();
                      services.clear();
                      hasSearched.value = false;
                    } else {
                      Get.back();
                    }
                  },
                ),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          16.height,
          // Tab Chips
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabChip(0, locale.value.all),
                  8.width,
                  _buildTabChip(1, locale.value.doctors),
                  8.width,
                  _buildTabChip(2, locale.value.clinics),
                  8.width,
                  _buildTabChip(3, locale.value.services),
                ],
              ),
            ),
          ),
          16.height,
          // Results Area
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const LoaderWidget();
              }

              if (!hasSearched.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: context.themeMuted),
                      16.height,
                      Text(
                        locale.value.searchForDoctorsClinicsServices,
                        style: secondaryTextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return _buildSearchResults();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final hasDoctors = (selectedTab.value == 0 || selectedTab.value == 1) &&
        doctors.isNotEmpty;
    final hasClinics = (selectedTab.value == 0 || selectedTab.value == 2) &&
        clinics.isNotEmpty;
    final hasServices = (selectedTab.value == 0 || selectedTab.value == 3) &&
        services.isNotEmpty;

    if (!hasDoctors && !hasClinics && !hasServices) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.themeMuted),
            16.height,
            Text(
              locale.value.noDataFound,
              style: secondaryTextStyle(),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Doctors Section
        if (hasDoctors) ...[
          _buildSectionHeader(locale.value.doctors, doctors.length),
          8.height,
          ...doctors.take(5).map((doctor) => _buildDoctorItem(doctor)),
          if (doctors.length > 5)
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => DoctorsListScreen(),
                    arguments: {'search': searchController.text});
              },
              child: Text('${locale.value.viewAll} (${doctors.length})'),
            ),
          16.height,
        ],

        // Clinics Section
        if (hasClinics) ...[
          _buildSectionHeader(locale.value.clinics, clinics.length),
          8.height,
          ...clinics.take(5).map((clinic) => _buildClinicItem(clinic)),
          if (clinics.length > 5)
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => ClinicListScreen());
              },
              child: Text('${locale.value.viewAll} (${clinics.length})'),
            ),
          16.height,
        ],

        // Services Section
        if (hasServices) ...[
          _buildSectionHeader(locale.value.services, services.length),
          8.height,
          ...services.take(5).map((service) => _buildServiceItem(service)),
          if (services.length > 5)
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => ServiceListScreen());
              },
              child: Text('${locale.value.viewAll} (${services.length})'),
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: boldTextStyle(size: 16)),
        8.width,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: boxDecorationDefault(
            color: appColorPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count',
              style: boldTextStyle(size: 12, color: context.themePrimary)),
        ),
      ],
    );
  }

  Widget _buildDoctorItem(Doctor doctor) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.to(() => DoctorsListScreen(), arguments: doctor.doctorId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImageWidget(
                url: doctor.profileImage,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.fullName, style: boldTextStyle(size: 14)),
                  4.height,
                  if (doctor.expert.isNotEmpty)
                    Text(doctor.expert, style: secondaryTextStyle(size: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.themeMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicItem(Clinic clinic) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.to(() => ClinicListScreen(), arguments: clinic.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImageWidget(
                url: clinic.clinicImage,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clinic.name, style: boldTextStyle(size: 14)),
                  4.height,
                  if (clinic.address.isNotEmpty)
                    Text(
                      clinic.address,
                      style: secondaryTextStyle(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.themeMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(ServiceElement service) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.to(() => ServiceListScreen(), arguments: service.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImageWidget(
                url: service.serviceImage,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: boldTextStyle(size: 14)),
                  4.height,
                  Text(
                    '${service.charges} ${appCurrency.value}',
                    style: boldTextStyle(size: 12, color: context.themePrimary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.themeMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = selectedTab.value == index;
    return GestureDetector(
      onTap: () {
        selectedTab.value = index;
        if (searchController.text.trim().isNotEmpty) {
          _performSearch();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: boxDecorationDefault(
          color: isSelected ? appColorPrimary : context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: boldTextStyle(
            size: 13,
            color: isSelected ? Colors.white : textPrimaryColorGlobal,
          ),
        ),
      ),
    );
  }
}
