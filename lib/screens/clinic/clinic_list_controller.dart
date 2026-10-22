import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:kivicare_patient/api/core_apis.dart';
import '../service/model/service_list_model.dart';
import 'model/clinic_detail_model.dart';
import 'model/clinics_res_model.dart';

class ClinicListController extends GetxController {
  Rx<Future<RxList<Clinic>>> clinicsFuture = Future(() => RxList<Clinic>()).obs;
  RxBool isLoading = false.obs;
  RxList<Clinic> clinics = RxList();
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;
  Rx<ServiceElement> service = ServiceElement().obs;
  RxList selectedServicesId = RxList();
  Rx<Clinic> selectedClinic = Clinic(clinicSession: ClinicSession()).obs;

  ///Search
  TextEditingController searchClinicCont = TextEditingController();
  RxBool isSearchClinicText = false.obs;
  StreamController<String> searchClinicStream = StreamController<String>();
  final _scrollController = ScrollController();
  RxBool isSearchText = false.obs;
  RxInt isPopular = (-1).obs;
  RxString serviceType = "".obs;
  RxString priceMin = ''.obs;
  RxString priceMax = ''.obs;
  RxInt clinicId = (-1).obs;
  RxBool isFromSearch = false.obs;

  /// Typing fires overlapping requests; only the newest one may touch the list.
  int _latestRequest = 0;

  @override
  void onInit() {
    _scrollController.addListener(() => Get.context != null ? hideKeyboard(Get.context) : null);
    searchClinicStream.stream.debounce(const Duration(milliseconds: 400)).listen((s) {
      // A new query starts over from the first page.
      page(1);
      getClinicList();
    });
    if (Get.arguments is ServiceElement) {
      service(Get.arguments);
    } else if (Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args['isFromSearch'] == true) {
        isFromSearch(true);
        // Don't auto-load clinics; wait for user to search
        super.onInit();
        return;
      }
    } else if (Get.arguments is int) {
      clinicId(Get.arguments as int);
      log('clinicId==== $clinicId');
    }
    getClinicList();
    super.onInit();
  }

  Future<void> getClinicList({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }
    final int request = ++_latestRequest;
    final List<Clinic> loaded = page.value == 1 ? <Clinic>[] : clinics.toList();
    await clinicsFuture(
      CoreServiceApis.getClinics(
        page: page.value,
        clinics: loaded,
        serviceId: service.value.id,
        search: searchClinicCont.text.trim(),
        servicePriceMin: priceMin.value,
        servicePriceMax: priceMax.value,
        clinicId: clinicId.value,
        isPopulars: isPopular.value,
        lastPageCallBack: (p0) {
          if (request == _latestRequest) isLastPage(p0);
        },
      ).then((value) {
        if (request == _latestRequest) clinics.assignAll(value);
        return clinics;
      }),
    ).then((value) {
      log('value.length ==> ${value.length}');
    }).catchError((e) {
      log("getClinics error $e");
    }).whenComplete(() {
      if (request == _latestRequest) isLoading(false);
    });
  }

  @override
  void onClose() {
    searchClinicStream.close();
    if (Get.context != null) {
      _scrollController.removeListener(() => hideKeyboard(Get.context));
    }
    super.onClose();
  }
}
