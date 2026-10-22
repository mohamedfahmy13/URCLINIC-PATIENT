import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/screens/clinic/search_clinic_widget.dart';
import 'package:kivicare_patient/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../network/location_service.dart';
import '../../utils/empty_error_state_widget.dart';
import '../doctor/doctor_list_screen.dart';
import 'clinic_detail_screen.dart';
import 'clinic_list_controller.dart';
import 'model/clinics_res_model.dart';

enum ClinicSortOption { none, nameAZ, nameZA, ratingHigh, ratingLow, nearest }

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final ClinicListController clinicListCont = Get.put(ClinicListController());

  ClinicSortOption _currentSort = ClinicSortOption.none;
  Position? _userPosition;
  bool _loadingLocation = false;

  String _getSortLabel(ClinicSortOption option) {
    switch (option) {
      case ClinicSortOption.none:
        return locale.value.sortBy;
      case ClinicSortOption.nameAZ:
        return locale.value.nameAZ;
      case ClinicSortOption.nameZA:
        return locale.value.nameZA;
      case ClinicSortOption.ratingHigh:
        return locale.value.ratingHighToLow;
      case ClinicSortOption.ratingLow:
        return locale.value.ratingLowToHigh;
      case ClinicSortOption.nearest:
        return locale.value.nearestClinics;
    }
  }

  IconData _getSortIcon(ClinicSortOption option) {
    switch (option) {
      case ClinicSortOption.none:
        return Icons.sort_rounded;
      case ClinicSortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case ClinicSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case ClinicSortOption.ratingHigh:
        return Icons.star_rounded;
      case ClinicSortOption.ratingLow:
        return Icons.star_outline_rounded;
      case ClinicSortOption.nearest:
        return Icons.near_me_rounded;
    }
  }

  Future<void> _onSortChanged(ClinicSortOption option) async {
    if (option == ClinicSortOption.nearest && _userPosition == null) {
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

  double _distanceTo(Clinic clinic) {
    if (_userPosition == null) return double.infinity;
    final lat = double.tryParse(clinic.latitude) ?? 0;
    final lng = double.tryParse(clinic.longitude) ?? 0;
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

  List<Clinic> _getFilteredClinics() {
    final sorted = List<Clinic>.from(clinicListCont.clinics);
    switch (_currentSort) {
      case ClinicSortOption.none:
        break;
      case ClinicSortOption.nameAZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ClinicSortOption.nameZA:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ClinicSortOption.ratingHigh:
        sorted.sort((a, b) => b.satisfactionPercentage.compareTo(a.satisfactionPercentage));
        break;
      case ClinicSortOption.ratingLow:
        sorted.sort((a, b) => a.satisfactionPercentage.compareTo(b.satisfactionPercentage));
        break;
      case ClinicSortOption.nearest:
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
              ...ClinicSortOption.values.where((o) => o != ClinicSortOption.none).map(
                (option) => ListTile(
                  leading: Icon(
                    _getSortIcon(option),
                    color: _currentSort == option ? appColorPrimary : iconColor,
                  ),
                  title: Text(
                    _getSortLabel(option),
                    style: _currentSort == option
                        ? boldTextStyle(color: appColorPrimary)
                        : primaryTextStyle(),
                  ),
                  trailing: _currentSort == option
                      ? const Icon(Icons.check_circle, color: appColorPrimary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _onSortChanged(option);
                  },
                ),
              ),
              if (_currentSort != ClinicSortOption.none)
                ListTile(
                  leading: const Icon(Icons.clear_rounded, color: cancelStatusColor),
                  title: Text(
                    locale.value.clearAll,
                    style: primaryTextStyle(color: cancelStatusColor),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentSort = ClinicSortOption.none);
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
      appBartitleText: locale.value.searchHere,
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: clinicListCont.isLoading,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          SearchClinicWidget(
            clinicListController: clinicListCont,
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
                  locale.value.clinics,
                  style: boldTextStyle(size: 18),
                ).expand(),
                GestureDetector(
                  onTap: () => _showSortBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: boxDecorationDefault(
                      color: _currentSort != ClinicSortOption.none
                          ? appColorPrimary.withValues(alpha: 0.1)
                          : context.cardColor,
                      borderRadius: radius(20),
                      border: Border.all(
                        color: _currentSort != ClinicSortOption.none
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
                          color: _currentSort != ClinicSortOption.none
                              ? appColorPrimary
                              : iconColor,
                        ),
                        6.width,
                        Text(
                          _currentSort == ClinicSortOption.none
                              ? locale.value.sortBy
                              : _getSortLabel(_currentSort),
                          style: boldTextStyle(
                            size: 12,
                            color: _currentSort != ClinicSortOption.none
                                ? appColorPrimary
                                : null,
                          ),
                        ),
                        4.width,
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: _currentSort != ClinicSortOption.none
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

          // Clinics Grid
          Obx(() {
            // Show empty search state when coming from search and no search performed yet
            if (clinicListCont.isFromSearch.value &&
                clinicListCont.clinics.isEmpty &&
                !clinicListCont.isLoading.value &&
                clinicListCont.searchClinicCont.text.trim().isEmpty) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      16.height,
                      Text(
                        locale.value.searchClinicHere,
                        style: secondaryTextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SnapHelperWidget(
              future: clinicListCont.clinicsFuture.value,
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  retryText: locale.value.reload,
                  imageWidget: const ErrorStateWidget(),
                  onRetry: () {
                    clinicListCont.page(1);
                    clinicListCont.getClinicList();
                  },
                ).paddingSymmetric(horizontal: 32);
              },
              loadingWidget: clinicListCont.isLoading.value
                  ? const Offstage()
                  : const LoaderWidget(),
              onSuccess: (p0) {
                final clinics = _getFilteredClinics();

                if (clinics.isEmpty && !clinicListCont.isLoading.value) {
                  return SingleChildScrollView(
                    child: NoDataWidget(
                      title: locale.value.noClinicsFoundAtAMoment,
                      subTitle: locale
                          .value.looksLikeThereIsNoClinicForThisServiceWellKee,
                      titleTextStyle: primaryTextStyle(),
                      imageWidget: const EmptyStateWidget(),
                      retryText: locale.value.reload,
                      onRetry: () {
                        clinicListCont.page(1);
                        clinicListCont.getClinicList();
                      },
                    ).paddingSymmetric(horizontal: 25),
                  ).center();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    clinicListCont.page(1);
                    return clinicListCont.getClinicList(showLoader: false);
                  },
                  child: AnimatedListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    listAnimationType: ListAnimationType.FadeIn,
                    itemCount: clinics.length,
                    itemBuilder: (context, index) {
                      final clinic = clinics[index];
                      // Re-use the card locally without passing distance to avoid editing card code too much,
                      // we can leave the card as it was in Clinics list (no distance shown for simplicity as it's not requested).
                      return _buildClinicListCard(clinic)
                          .paddingOnly(bottom: 12);
                    },
                  ),
                );
              },
            ).expand();
          }),
        ],
      ),
      fabWidget: Obx(
        () => FloatingActionButton(
          backgroundColor: appColorSecondary,
          onPressed: () {
            if (!clinicListCont.selectedClinic.value.id.isNegative) {
              Get.to(() => DoctorsListScreen(),
                  arguments: clinicListCont.selectedClinic.value.id);
            }
          },
          child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ).visible(clinicListCont.clinics.isNotEmpty &&
            (!clinicListCont.selectedClinic.value.id.isNegative)),
      ),
    );
  }

  Widget _buildClinicListCard(Clinic clinic) {
    return GestureDetector(
      onTap: () => Get.to(() => ClinicDetailScreen(), arguments: clinic),
      child: Container(
        height: 100,
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Clinic Image - wider and takes good space
            CachedImageWidget(
              url: clinic.clinicImage,
              fit: BoxFit.cover,
              width: 120,
              height: 100,
            ),
            // Clinic Name centered
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  clinic.name,
                  style: boldTextStyle(size: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Arrow indicator
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
