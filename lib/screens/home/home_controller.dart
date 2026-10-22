import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../api/core_apis.dart';
import '../../api/home_apis.dart';
import '../../utils/app_common.dart';
import '../clinic/model/clinics_res_model.dart';
import '../dashboard/dashboard_controller.dart';
import '../service/model/service_list_model.dart';
import 'model/dashboard_res_model.dart';

class HomeController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  late PackageInfoData info;
  TextEditingController searchCont = TextEditingController();
  Rx<Future<DashboardRes>> getDashboardDetailFuture =
      Future(() => DashboardRes(data: DashboardData())).obs;
  Rx<DashboardData> dashboardData = DashboardData().obs;
  PageController pageController = PageController();
  RxInt currentPage = 0.obs;

  ///Slider
  PageController sliderPageController = PageController();
  RxInt sliderCurrentPage = 0.obs;

  /// Banners
  RxList<BannerModel> bannerList = <BannerModel>[].obs;
  RxBool isBannersLoading = false.obs;

  /// Clinic discount cache keyed by clinic id.
  RxMap<int, bool> clinicDiscountAvailability = <int, bool>{}.obs;
  RxSet<int> clinicDiscountLoadingIds = <int>{}.obs;

  @override
  void onReady() {
    init();
    super.onReady();
  }

  Future<void> init() async {
    getDashboardDetail();
    getBannersList();
    info = await getPackageInfo();
    // _checkAndShowDialog(getContext, getValueFromLocal(AutoUpdateConst.isAutoUpdateOn) ?? false);
  }

  /// Get Banners List
  Future<void> getBannersList() async {
    isBannersLoading(true);
    try {
      final banners = await HomeServiceApis.getHomeBanners();
      sliderCurrentPage(0);
      if (sliderPageController.hasClients) sliderPageController.jumpToPage(0);
      bannerList(banners);
    } finally {
      isBannersLoading(false);
    }
  }

  ///Get ChooseService List
  Future<void> getDashboardDetail({bool isFromSwipeRefresh = false}) async {
    if (!isFromSwipeRefresh) {
      isLoading(true);
    }
    getAppConfigurations();
    await getDashboardDetailFuture(
      HomeServiceApis.getDashboard(),
    ).then((value) async {
      await handleDashboardRes(value);
    }).whenComplete(() => isLoading(false));
  }

  Future<void> handleDashboardRes(DashboardRes value) async {
    if (kDebugMode) {
      debugPrint('Dashboard payload processed');
    }

    // Keep current Home clinics until clinic-list API sync completes to
    // prevent showing transient dashboard-only clinics during refresh.
    final List<Clinic> currentHomeClinics =
        List<Clinic>.from(dashboardData.value.nearByClinic);

    value.data.nearByClinic = _filterVisibleClinics(value.data.nearByClinic);
    value.data.popularClinic.selectedClinic =
        _filterVisibleClinics(value.data.popularClinic.selectedClinic);
    value.data.nearByClinic = currentHomeClinics;

    dashboardData(value.data);
    unreadNotificationCount(value.data.unReadCount);
    // Home clinic rows should follow the primary clinic-list endpoint.
    await _syncHomeClinicsFromClinicListApi();
    //More Logic....
  }

  Future<void> _syncHomeClinicsFromClinicListApi() async {
    try {
      final List<Clinic> clinicsFromApi = <Clinic>[];
      int page = 1;
      bool isLastPage = false;

      while (!isLastPage) {
        await CoreServiceApis.getClinics(
          page: page,
          perPage: 50,
          clinics: clinicsFromApi,
          lastPageCallBack: (isLast) {
            isLastPage = isLast;
          },
        );
        page++;
      }

      final List<Clinic> visibleClinics = _filterVisibleClinics(clinicsFromApi);

      dashboardData.update((data) {
        if (data == null) return;
        data.nearByClinic = visibleClinics;
      });

      prefetchClinicDiscountAvailability(visibleClinics);
    } catch (_) {
      // Fallback to dashboard payload when clinic-list API is unavailable.
      prefetchClinicDiscountAvailability(
          _collectUniqueClinics(dashboardData.value));
    }
  }

  List<Clinic> _filterVisibleClinics(List<Clinic> source) {
    return source.where((clinic) {
      return clinic.id > 0 &&
          clinic.name.trim().isNotEmpty &&
          clinic.status == 1;
    }).toList();
  }

  List<Clinic> _collectUniqueClinics(DashboardData data) {
    final Map<int, Clinic> uniqueClinicMap = <int, Clinic>{};

    for (final clinic in [
      ...data.nearByClinic,
      ...data.popularClinic.selectedClinic,
    ]) {
      if (clinic.id > 0) {
        uniqueClinicMap[clinic.id] = clinic;
      }
    }

    return uniqueClinicMap.values.toList();
  }

  void prefetchClinicDiscountAvailability(List<Clinic> clinics) {
    for (final clinic in clinics) {
      final int clinicId = clinic.id;

      if (clinicId <= 0) continue;
      if (clinicDiscountAvailability.containsKey(clinicId)) continue;
      if (clinicDiscountLoadingIds.contains(clinicId)) continue;

      _fetchClinicDiscountAvailability(clinicId);
    }
  }

  Future<void> _fetchClinicDiscountAvailability(int clinicId) async {
    clinicDiscountLoadingIds.add(clinicId);

    try {
      final List<ServiceElement> services = <ServiceElement>[];

      await CoreServiceApis.getServiceList(
        serviceList: services,
        clinicId: clinicId,
        allServices: 'all',
      );

      final List<ServiceElement> activeServices =
          services.where((service) => service.status == 1).toList();

      if (activeServices.isEmpty) {
        // Keep clinic visible on Home even when it has no active services.
        clinicDiscountAvailability[clinicId] = false;
        return;
      }

      clinicDiscountAvailability[clinicId] = activeServices.hasAnyDiscount;
    } catch (_) {
      if (kDebugMode) {
        log('Error loading clinic discount status');
      }
      clinicDiscountAvailability[clinicId] = false;
    } finally {
      clinicDiscountLoadingIds.remove(clinicId);
    }
  }

  bool hasDiscountForClinic(int clinicId) {
    return clinicDiscountAvailability[clinicId] ?? false;
  }

  bool isClinicDiscountLoading(int clinicId) {
    return clinicDiscountLoadingIds.contains(clinicId);
  }

/*  Future<void> _checkAndShowDialog(BuildContext context, bool isAutoUpdateOn) async {
    if (!isAutoUpdateOn) {
      debugPrint('Update dialog suppressed by flag.');
      return;
    }

    final result = await PlayxVersionUpdate.showUpdateDialog(
      context: context,
      options: PlayxUpdateOptions(
        androidPackageName: 'com.wellness.customer',
        iosBundleId: 'com.Innoquad Technologies LLP.id6743613222',
        minVersion: info.versionName,
        forceUpdate: true,
      ),
      uiOptions: PlayxUpdateUIOptions(
        displayType: PlayxUpdateDisplayType.dialog,
        title: (info) => '${locale.value.updateTo} v${info.newVersion} ${locale.value.available}',
        titleTextStyle: primaryTextStyle(),
        description: (info) => locale.value.aVertionUpdateIsAvailable,
        descriptionTextStyle: secondaryTextStyle(),
        updateButtonText: locale.value.updateNow,
        dismissButtonText: locale.value.later,
        showReleaseNotes: true,
        releaseNotesTitleTextStyle: primaryTextStyle(),
        releaseNotesTextStyle: secondaryTextStyle(),
      ),
    );

    result.when(
      success: (isShown) {
        debugPrint(isShown ? 'Update prompt displayed' : 'No update needed or user chose later.');
      },
      error: (error) {
        debugPrint('Version check failed: ${error.message}');
      },
    );
  }*/
}
