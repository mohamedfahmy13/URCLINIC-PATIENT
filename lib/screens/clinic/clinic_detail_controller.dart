// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../api/core_apis.dart';
import '../../main.dart';
import '../doctor/model/doctor_list_res.dart';
import '../service/model/service_list_model.dart';
import 'model/clinic_detail_model.dart';
import 'model/clinics_res_model.dart';

class ClinicDetailController extends GetxController {
  RxBool isLoading = false.obs;
  RxString clinicFetchError = ''.obs;

  Rx<Future<ClinicDetailModel>> getClinicDetail = Future(
          () => ClinicDetailModel(data: Clinic(clinicSession: ClinicSession())))
      .obs;
  Rx<Clinic> clinicData = Clinic(clinicSession: ClinicSession()).obs;

  //Services
  Rx<Future<RxList<ServiceElement>>> serviceListFuture =
      Future(() => RxList<ServiceElement>()).obs;
  RxBool isServicesLoading = false.obs;
  RxList<ServiceElement> serviceList = RxList();
  RxBool isServicesLastPage = false.obs;
  RxInt servicesPage = 1.obs;
  RxInt activeServicesCount = 0.obs;

  //Doctors
  Rx<Future<RxList<Doctor>>> doctorsFuture = Future(() => RxList<Doctor>()).obs;
  RxBool isDoctorsLoading = false.obs;
  RxList<Doctor> doctors = RxList();
  RxBool isDoctorsLastPage = false.obs;
  RxInt doctorsPage = 1.obs;
  RxInt activeDoctorsCount = 0.obs;

  @override
  void onInit() {
    if (Get.arguments is Clinic) {
      clinicData(Get.arguments);
    }
    init(showLoader: false);
    super.onInit();
  }

  ///Get Clinic Detail
  Future<void> init({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }

    clinicFetchError('');

    if (clinicData.value.id <= 0) {
      clinicFetchError(locale.value.pageNotFound);
      isLoading(false);
      return;
    }

    // The details and the service list don't depend on each other, so request
    // them together instead of one after the other.
    final Future<ClinicDetailModel> requestFuture =
        CoreServiceApis.getClinicDetails(clinicId: clinicData.value.id);
    // Awaited further down; until then, don't report an early failure as uncaught.
    requestFuture.ignore();

    isServicesLoading(true);
    final List<ServiceElement>? allServices =
        await _getAllServices(clinicData.value.id);
    isServicesLoading(false);

    if (allServices != null &&
        !allServices.any((service) => service.status == 1)) {
      clinicFetchError(locale.value.noServicesAvailable);
      isLoading(false);
      return;
    }

    if (allServices != null) {
      // Same list getServiceList() + getAllServicesForCount() would fetch again.
      servicesPage(1);
      serviceList.assignAll(allServices);
      isServicesLastPage(true);
      activeServicesCount(
          allServices.where((service) => service.status == 1).length);
    }

    try {
      getClinicDetail(requestFuture);
      final ClinicDetailModel value = await requestFuture;

      clinicData(value.data);

      if (allServices == null) {
        getServiceList(showLoader: false);
      }
      // Load doctors after clinic details are loaded to calculate active count
      getDoctors(showLoader: false);
    } catch (e, st) {
      final String message = _friendlyClinicError(e);
      clinicFetchError(message);
      log('ClinicDetail getClinicDetail err ==> $message');
      _reportClinicDetailFetchFailure(error: e, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }

  /// All of the clinic's services, or null when the request fails.
  Future<List<ServiceElement>?> _getAllServices(int clinicId) async {
    try {
      final List<ServiceElement> allServices = <ServiceElement>[];

      await CoreServiceApis.getServiceList(
        serviceList: allServices,
        clinicId: clinicId,
        allServices: 'all',
      );

      return allServices;
    } catch (_) {
      // Do not block detail fetch on a failed service request.
      return null;
    }
  }

  String _friendlyClinicError(Object error) {
    final String raw = error.toString();
    final String lower = raw.toLowerCase();
    if (lower.contains('500') || lower.contains('internal server')) {
      return locale.value.internalServerError;
    }
    return raw;
  }

  void _reportClinicDetailFetchFailure({
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!kReleaseMode) return;

    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'clinic_detail_fetch_failed',
        information: <String>['clinic_id=${clinicData.value.id}'],
      );
    } catch (_) {
      if (kDebugMode) {
        log('ClinicDetail crash report skipped');
      }
    }
  }

  Future<void> getServiceList({bool showLoader = true}) async {
    if (showLoader) {
      isServicesLoading(true);
    }
    await serviceListFuture(
      CoreServiceApis.getServiceList(
        page: servicesPage.value,
        serviceList: serviceList,
        clinicId: clinicData.value.id,
        lastPageCallBack: (p0) {
          isServicesLastPage(p0);
        },
      ),
    ).then((value) {
      log('value.length ==> ${value.length}');
      // Load all services to get accurate count
      getAllServicesForCount();
    }).catchError((e) {
      log('Clinic detail getServiceList err ==> $e');
    }).whenComplete(() => isServicesLoading(false));
  }

  /// Load all services for counting active services
  Future<void> getAllServicesForCount() async {
    try {
      final RxList<ServiceElement> allServicesList = RxList();
      await CoreServiceApis.getServiceList(
        serviceList: allServicesList,
        clinicId: clinicData.value.id,
        allServices: 'all',
        lastPageCallBack: (p0) {},
      );
      activeServicesCount(
          allServicesList.where((service) => service.status == 1).length);
    } catch (e) {
      log('Error loading all services for count: $e');
      activeServicesCount(
          serviceList.where((service) => service.status == 1).length);
    }
  }

  /// Load all doctors for counting active doctors
  Future<void> getAllDoctorsForCount() async {
    try {
      final RxList<Doctor> allDoctorsList = RxList();
      await CoreServiceApis.getDoctors(
        perPage: 1000,
        doctors: allDoctorsList,
        clinicId: clinicData.value.id,
        lastPageCallBack: (p0) {},
      );
      activeDoctorsCount(
          allDoctorsList.where((doctor) => doctor.status == 1).length);
    } catch (e) {
      activeDoctorsCount(doctors.where((doctor) => doctor.status == 1).length);
    }
  }

  Future<void> getDoctors({bool showLoader = true}) async {
    if (showLoader) {
      isDoctorsLoading(true);
    }
    await doctorsFuture(
      CoreServiceApis.getDoctors(
        page: doctorsPage.value,
        doctors: doctors,
        clinicId: clinicData.value.id,
        lastPageCallBack: (p0) {
          isDoctorsLastPage(p0);
        },
      ),
    ).then((value) {
      log('value.length ==> ${value.length}');
      // Load all doctors to get accurate count
      getAllDoctorsForCount();
    }).catchError((e) {
      log("getDoctors error $e");
    }).whenComplete(() => isDoctorsLoading(false));
  }
}
