import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/screens/doctor/components/doctor_card.dart';
import 'package:kivicare_patient/screens/doctor/search_doctor_widget.dart';

import '../../../components/app_scaffold.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../network/location_service.dart';
import '../../utils/colors.dart';
import '../../utils/empty_error_state_widget.dart';
import '../slots/booking_form_screen.dart';
import 'doctor_list_controller.dart';
import 'model/doctor_list_res.dart';

enum DoctorSortOption { none, nameAZ, nameZA, nearest }

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final DoctorListController doctorsListCont = Get.put(DoctorListController());

  DoctorSortOption _currentSort = DoctorSortOption.none;
  Position? _userPosition;
  bool _loadingLocation = false;

  String _getSortLabel(DoctorSortOption option) {
    switch (option) {
      case DoctorSortOption.none:
        return locale.value.sortBy;
      case DoctorSortOption.nameAZ:
        return locale.value.nameAZ;
      case DoctorSortOption.nameZA:
        return locale.value.nameZA;
      case DoctorSortOption.nearest:
        return locale.value
            .nearestClinics; // Actually nearest doctors, but using same string
    }
  }

  IconData _getSortIcon(DoctorSortOption option) {
    switch (option) {
      case DoctorSortOption.none:
        return Icons.sort_rounded;
      case DoctorSortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case DoctorSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case DoctorSortOption.nearest:
        return Icons.near_me_rounded;
    }
  }

  Future<void> _onSortChanged(DoctorSortOption option) async {
    if (option == DoctorSortOption.nearest && _userPosition == null) {
      setState(() => _loadingLocation = true);
      try {
        _userPosition = await getUserLocationPosition();
      } catch (e) {
        toast(e.toString());
        setState(() => _loadingLocation = false);
        return;
      }
      setState(() => _loadingLocation = false);
    }
    setState(() => _currentSort = option);
  }

  double _distanceTo(Doctor doctor) {
    if (_userPosition == null) return double.infinity;
    final lat = double.tryParse(doctor.latitude) ?? 0;
    final lng = double.tryParse(doctor.longitude) ?? 0;
    if (lat == 0 && lng == 0) return double.infinity;
    const R = 6371.0;
    final dLat = (lat - _userPosition!.latitude) * pi / 180;
    final dLon = (lng - _userPosition!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_userPosition!.latitude * pi / 180) *
            cos(lat * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  List<Doctor> _getFilteredDoctors() {
    final sorted = List<Doctor>.from(doctorsListCont.doctors);
    switch (_currentSort) {
      case DoctorSortOption.none:
        break;
      case DoctorSortOption.nameAZ:
        sorted.sort((a, b) =>
            a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
        break;
      case DoctorSortOption.nameZA:
        sorted.sort((a, b) =>
            b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()));
        break;
      case DoctorSortOption.nearest:
        if (_userPosition != null) {
          sorted.sort((a, b) {
            final distA = _distanceTo(a);
            final distB = _distanceTo(b);
            return distA.compareTo(distB);
          });
        }
        break;
    }
    return sorted;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: radius(2),
                ),
              ),
              16.height,
              Text(locale.value.sortBy, style: boldTextStyle(size: 18)),
              16.height,
              ...DoctorSortOption.values
                  .where((o) => o != DoctorSortOption.none)
                  .map(
                    (option) => ListTile(
                      leading: Icon(
                        _getSortIcon(option),
                        color: _currentSort == option
                            ? appColorPrimary
                            : iconColor,
                      ),
                      title: Text(
                        _getSortLabel(option),
                        style: _currentSort == option
                            ? boldTextStyle(color: appColorPrimary)
                            : primaryTextStyle(),
                      ),
                      trailing: _currentSort == option
                          ? const Icon(Icons.check_circle,
                              color: appColorPrimary)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _onSortChanged(option);
                      },
                    ),
                  ),
              if (_currentSort != DoctorSortOption.none)
                ListTile(
                  leading:
                      const Icon(Icons.clear_rounded, color: cancelStatusColor),
                  title: Text(
                    locale.value.clearAll,
                    style: primaryTextStyle(color: cancelStatusColor),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentSort = DoctorSortOption.none);
                  },
                ),
              16.height,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.chooseDoctor,
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: doctorsListCont.isLoading,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchDoctorWidget(
            doctorListController: doctorsListCont,
            onFieldSubmitted: (p0) {
              hideKeyboard(context);
            },
          ).paddingAll(16),

          // Title & Sort Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  locale.value.doctors,
                  style: boldTextStyle(size: 18),
                ).expand(),
                GestureDetector(
                  onTap: () => _showSortBottomSheet(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: boxDecorationDefault(
                      color: _currentSort != DoctorSortOption.none
                          ? appColorPrimary.withValues(alpha: 0.1)
                          : context.cardColor,
                      borderRadius: radius(20),
                      border: Border.all(
                        color: _currentSort != DoctorSortOption.none
                            ? appColorPrimary
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSortIcon(_currentSort),
                          size: 16,
                          color: _currentSort != DoctorSortOption.none
                              ? appColorPrimary
                              : iconColor,
                        ),
                        6.width,
                        Text(
                          _currentSort == DoctorSortOption.none
                              ? locale.value.sortBy
                              : _getSortLabel(_currentSort),
                          style: boldTextStyle(
                            size: 12,
                            color: _currentSort != DoctorSortOption.none
                                ? appColorPrimary
                                : null,
                          ),
                        ),
                        4.width,
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: _currentSort != DoctorSortOption.none
                              ? appColorPrimary
                              : iconColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          8.height,

          if (_loadingLocation) const LoaderWidget(),

          Obx(
            () => SnapHelperWidget(
              future: doctorsListCont.doctorsFuture.value,
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  retryText: locale.value.reload,
                  imageWidget: const ErrorStateWidget(),
                  onRetry: () {
                    doctorsListCont.page(1);
                    doctorsListCont.getDoctors();
                  },
                ).paddingSymmetric(horizontal: 32);
              },
              loadingWidget: doctorsListCont.isLoading.value
                  ? const Offstage()
                  : const LoaderWidget(),
              onSuccess: (p0) {
                final doctors = _getFilteredDoctors();

                if (doctors.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AnimatedScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  children: [
                    16.height,
                    AnimatedWrap(
                      spacing: 16,
                      runSpacing: 16,
                      listAnimationType: ListAnimationType.FadeIn,
                      children: List.generate(
                        doctors.length,
                        (index) {
                          final Doctor doctorData = doctors[index];
                          return DoctorCard(doctorData: doctorData);
                        },
                      ),
                    ),
                  ],
                  onNextPage: () async {
                    if (!doctorsListCont.isLastPage.value) {
                      doctorsListCont.page(doctorsListCont.page.value + 1);
                      doctorsListCont.getDoctors();
                    }
                  },
                  onSwipeRefresh: () async {
                    doctorsListCont.page(1);
                    return doctorsListCont.getDoctors(showLoader: false);
                  },
                ).paddingSymmetric(horizontal: 16);
              },
            ),
          ).expand(),
        ],
      ),
      fabWidget: Obx(
        () => FloatingActionButton(
          backgroundColor: appColorSecondary,
          onPressed: () {
            if (!doctorsListCont.selectedDoctor.value.doctorId.isNegative) {
              Get.to(() => BookingFormScreen());
            }
          },
          child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ).visible(doctorsListCont.doctors.isNotEmpty &&
            (!doctorsListCont.selectedDoctor.value.doctorId.isNegative)),
      ),
    );
  }
}
