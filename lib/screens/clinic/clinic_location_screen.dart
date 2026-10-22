import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import 'model/clinics_res_model.dart';

class ClinicLocationScreen extends StatelessWidget {
  final Clinic clinic;

  const ClinicLocationScreen({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.selectBranch,
      appBarVerticalSize: Get.height * 0.12,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic Info Header
            _buildClinicHeader(context),

            24.height,

            // Main Branch
            _buildBranchCard(
              context: context,
              address: clinic.address,
              cityName: clinic.cityName,
              stateName: clinic.stateName,
              countryName: clinic.countryName,
              pincode: clinic.pincode,
              latitude: clinic.latitude,
              longitude: clinic.longitude,
              googleMapLink: clinic.googleMapLink,
              isMain: true,
            ),

            // Additional Addresses
            if (clinic.additionalAddresses.isNotEmpty) ...[
              24.height,
              Text(
                locale.value.otherBranches,
                style: boldTextStyle(size: 16),
              ),
              12.height,
              ...clinic.additionalAddresses.map((addr) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildBranchCard(
                    context: context,
                    address: addr.address,
                    cityName: addr.cityName,
                    stateName: addr.stateName,
                    countryName: addr.countryName,
                    pincode: addr.pincode,
                    latitude: addr.latitude,
                    longitude: addr.longitude,
                    googleMapLink: addr.googleMapLink.isNotEmpty
                        ? addr.googleMapLink
                        : clinic.googleMapLink,
                    isMain: false,
                  ),
                );
              }),
            ],

            24.height,
          ],
        ),
      ),
    );
  }

  Widget _buildClinicHeader(BuildContext context) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        borderRadius: radius(16),
      ),
      child: Row(
        children: [
          // Clinic Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: appColorPrimary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: CachedImageWidget(
                url: clinic.logo.isNotEmpty ? clinic.logo : clinic.clinicImage,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
              ),
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinic.name,
                  style: boldTextStyle(size: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (clinic.localizedSpecialty.isNotEmpty) ...[
                  4.height,
                  Text(
                    clinic.localizedSpecialty,
                    style: secondaryTextStyle(size: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard({
    required BuildContext context,
    required String address,
    required String cityName,
    required String stateName,
    required String countryName,
    required String pincode,
    required String latitude,
    required String longitude,
    required String googleMapLink,
    required bool isMain,
  }) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        borderRadius: radius(16),
        border: isMain
            ? Border.all(color: appColorPrimary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMain
                      ? appColorPrimary.withOpacity(0.1)
                      : appColorSecondary.withOpacity(0.1),
                  borderRadius: radius(10),
                ),
                child: Icon(
                  isMain ? Icons.location_on : Icons.location_on_outlined,
                  color: isMain ? context.themePrimary : appColorSecondary,
                  size: 24,
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: boxDecorationDefault(
                          color: appColorPrimary.withOpacity(0.1),
                          borderRadius: radius(6),
                        ),
                        child: Text(
                          locale.value.mainBranch,
                          style:
                              boldTextStyle(size: 10, color: context.themePrimary),
                        ),
                      ),
                    Text(
                      address,
                      style: primaryTextStyle(size: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          16.height,

          // Location details
          Container(
            width: Get.width,
            padding: const EdgeInsets.all(12),
            decoration: boxDecorationDefault(
              color: context.scaffoldBackgroundColor,
              borderRadius: radius(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City, State, Country
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_city_outlined,
                      color: context.themePrimary,
                      size: 18,
                    ),
                    10.width,
                    Expanded(
                      child: Text(
                        _buildLocationString(cityName, stateName, countryName),
                        style: secondaryTextStyle(size: 13),
                      ),
                    ),
                  ],
                ),

                // Pincode
                if (pincode.isNotEmpty) ...[
                  10.height,
                  Row(
                    children: [
                      Icon(
                        Icons.markunread_mailbox_outlined,
                        color: iconColor,
                        size: 18,
                      ),
                      10.width,
                      Text(
                        "${locale.value.pincode}: $pincode",
                        style: secondaryTextStyle(size: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          16.height,

          // Open in Maps Button
          AppButton(
            width: Get.width,
            color: isMain ? appColorPrimary : appColorSecondary,
            elevation: 0,
            shapeBorder: RoundedRectangleBorder(borderRadius: radius(12)),
            onTap: () {
              _openInMaps(
                latitude: latitude,
                longitude: longitude,
                googleMapLink: googleMapLink,
                address: address,
                location:
                    _buildLocationString(cityName, stateName, countryName),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                12.width,
                Text(
                  locale.value.openInMaps,
                  style: boldTextStyle(color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildLocationString(
      String cityName, String stateName, String countryName) {
    List<String> parts = [];
    if (cityName.isNotEmpty) parts.add(cityName);
    if (stateName.isNotEmpty) parts.add(stateName);
    if (countryName.isNotEmpty) parts.add(countryName);
    return parts.join(', ');
  }

  void _openInMaps({
    required String latitude,
    required String longitude,
    required String googleMapLink,
    required String address,
    required String location,
  }) {
    final String lat = latitude.trim();
    final String lng = longitude.trim();
    final String mapLink = _extractLaunchableMapLink(googleMapLink);
    final String addr = address.trim();
    final String loc = location.trim();

    // Priority: coordinates -> google map link -> address/location text
    if (_hasValidCoordinates(lat, lng)) {
      launchMap('$lat,$lng');
    } else if (mapLink.isNotEmpty && _isLaunchableMapUrl(mapLink)) {
      commonLaunchUrl(mapLink);
    } else if (addr.isNotEmpty) {
      launchMap(addr);
    } else {
      launchMap(loc);
    }
  }

  bool _hasValidCoordinates(String latitude, String longitude) {
    return double.tryParse(latitude) != null &&
        double.tryParse(longitude) != null;
  }

  String _extractLaunchableMapLink(String rawLink) {
    final String value = rawLink.trim();
    if (value.isEmpty) return '';

    // Some APIs may return an iframe markup instead of a direct URL.
    if (value.toLowerCase().contains('<iframe')) {
      final RegExp srcRegex = RegExp(
        r'''src\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
      );
      final Match? match = srcRegex.firstMatch(value);
      return match?.group(1)?.trim() ?? '';
    }

    return value;
  }

  bool _isLaunchableMapUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }

    // Google embed URLs require iframe context and cannot be opened directly.
    final String loweredPath = uri.path.toLowerCase();
    if (loweredPath.contains('/maps/embed')) {
      return false;
    }

    return true;
  }
}
