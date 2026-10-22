import '../network/network_utils.dart';
import '../screens/home/model/banner_list_response.dart';
import '../screens/home/model/dashboard_res_model.dart';
import '../utils/api_end_points.dart';
import '../utils/app_common.dart';

class HomeServiceApis {
  static Future<List<BannerModel>> getHomeBanners({
    Future<BannerListResponse> Function()? clinicFeed,
    Future<BannerListResponse> Function()? regularFeed,
  }) async {
    Future<BannerListResponse> optional(
        Future<BannerListResponse> Function() load) async {
      try {
        return await load().timeout(const Duration(seconds: 15));
      } catch (_) {
        return BannerListResponse();
      }
    }

    final responses = await Future.wait([
      optional(clinicFeed ?? getClinicBanners),
      optional(regularFeed ?? getBannersList),
    ]);
    return responses
        .expand((response) => response.data)
        .where((banner) => banner.sliderImage.trim().isNotEmpty)
        .toList();
  }

  static Future<DashboardRes> getDashboard(
      {String? latitude, String? longitude}) async {
    if (isLoggedIn.value) {
      return DashboardRes.fromJson(
        await handleResponse(
          await buildHttpResponse(
            "${APIEndPoints.getDashboard}?user_id=${loginUserData.value.id}",
          ),
        ),
      );
    } else {
      return DashboardRes.fromJson(
        await handleResponse(
          await buildHttpResponse(APIEndPoints.getDashboard),
        ),
      );
    }
  }

  static Future<BannerListResponse> getBannersList() async {
    return BannerListResponse.fromJson(
      await handleResponse(
        await buildHttpResponse(APIEndPoints.getBannersList),
      ),
    );
  }

  static Future<BannerListResponse> getClinicBanners() async {
    return BannerListResponse.fromJson(await handleResponse(
      await buildHttpResponse(APIEndPoints.getClinicBanners),
    ));
  }
}
