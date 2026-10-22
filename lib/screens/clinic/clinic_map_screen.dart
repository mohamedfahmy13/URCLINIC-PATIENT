import '../../utils/map_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/components/cached_image_widget.dart';
import 'package:kivicare_patient/components/loader_widget.dart';
import 'package:kivicare_patient/main.dart';
import 'package:kivicare_patient/utils/colors.dart';

import 'clinic_detail_screen.dart';
import 'clinic_map_controller.dart';
import 'model/clinics_res_model.dart';

class ClinicMapScreen extends StatelessWidget {
  ClinicMapScreen({super.key});

  final ClinicMapController controller = Get.put(ClinicMapController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value && controller.clinics.isEmpty) {
          return const LoaderWidget();
        }

        return Stack(
          children: [
            // ─── Google Map (full screen) ───
            Obx(() => GoogleMap(
              style: context.themeIsDark ? darkMapStyle : null,
                  initialCameraPosition: controller.initialCameraPosition,
                  onMapCreated: controller.onMapCreated,
                  markers: controller.markers.toSet(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  onTap: controller.onMapTap,
                )),

            // ─── Top bar: Back + Search ───
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: boxDecorationDefault(
                              color: context.themeSurface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: context.themePrimary),
                          ),
                        ),
                        12.width,

                        // Search bar
                        Expanded(
                          child: Container(
                            decoration: boxDecorationDefault(
                              color: context.themeSurface,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: controller.searchTextController,
                              decoration: InputDecoration(
                                hintText:
                                    locale.value.searchForDoctorsClinicsServices,
                                hintStyle: secondaryTextStyle(size: 13),
                                prefixIcon: Icon(Icons.search,
                                    color: context.themePrimary, size: 20),
                                suffixIcon: Obx(
                                    () => controller.searchQuery.value.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              controller.searchTextController.clear();
                                              controller.updateSearch('');
                                            },
                                            icon: Icon(Icons.close,
                                                size: 18, color: context.themeMuted),
                                          )
                                        : const SizedBox.shrink()),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onChanged: controller.updateSearch,
                              onSubmitted: controller.onSearchSubmitted,
                              style: primaryTextStyle(size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Dropdown for predictions
                    Obx(() {
                      if (controller.placePredictions.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(top: 8, left: 45),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: boxDecorationDefault(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: controller.placePredictions.length,
                            separatorBuilder: (context, index) => const Divider(height: 0),
                            itemBuilder: (context, index) {
                              final prediction = controller.placePredictions[index];
                              final description = prediction['description'] as String;

                              return ListTile(
                                leading: Icon(Icons.location_on_outlined, color: context.themeMuted),
                                title: Text(description, style: primaryTextStyle(size: 14)),
                                onTap: () {
                                  final placeId = prediction['place_id'] as String;
                                  controller.onPlaceSelected(placeId, description);
                                },
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ─── Current Location Button ───
            Positioned(
              right: 16,
              bottom: 200,
              child: FloatingActionButton.small(
                heroTag: 'current_location',
                backgroundColor: context.themeSurface,
                onPressed: controller.goToCurrentLocation,
                child: Icon(Icons.my_location, color: context.themePrimary),
              ),
            ),

            // ─── Selected Clinic Bottom Card ───
            Obx(() {
              final clinic = controller.selectedClinic.value;
              if (clinic == null) return const SizedBox.shrink();
              return _SelectedClinicCard(
                clinic: clinic,
                distance: controller.getDistanceToClinic(clinic),
                onTap: () {
                  Get.to(() => ClinicDetailScreen(), arguments: clinic);
                },
              );
            }),
          ],
        );
      }),
    );
  }
}

/// Bottom card that appears when a marker is tapped.
class _SelectedClinicCard extends StatelessWidget {
  final Clinic clinic;
  final String distance;
  final VoidCallback onTap;

  const _SelectedClinicCard({
    required this.clinic,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: boxDecorationDefault(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Clinic Image with Favorite icon ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedImageWidget(
                      url: clinic.clinicImage.isNotEmpty
                          ? clinic.clinicImage
                          : clinic.logo,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),

              // ── Clinic Info ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.name,
                            style: boldTextStyle(size: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          6.height,
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              8.width,
                              Expanded(
                                child: Text(
                                  clinic.address.isNotEmpty
                                      ? clinic.address
                                      : clinic.cityName,
                                  style: secondaryTextStyle(size: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distance.isNotEmpty) ...[
                                8.width,
                                Text(
                                  distance,
                                  style: secondaryTextStyle(
                                      size: 11, color: context.themePrimary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    12.width,

                    // ── Navigate arrow ──
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: appColorPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: context.themePrimary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
