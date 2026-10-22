import 'package:flutter_test/flutter_test.dart';
import 'package:kivicare_patient/api/home_apis.dart';
import 'package:kivicare_patient/screens/home/model/banner_list_response.dart';
import 'package:kivicare_patient/screens/home/model/dashboard_res_model.dart';

BannerListResponse feed(List<Map<String, dynamic>> banners) =>
    BannerListResponse.fromJson({'status': true, 'data': banners});

void main() {
  test('clinic feed maps its image and navigation to the owning clinic', () {
    final banner = BannerModel.fromJson({
      'id': 11,
      'clinic_id': 42,
      'clinic_name': 'عيادة الاختبار',
      'banner_image': 'https://clinic.test/storage/banner.png',
      'type': 'clinic',
      'link_id': 42,
    });
    expect(banner.sliderImage, 'https://clinic.test/storage/banner.png');
    expect(banner.name, 'عيادة الاختبار');
    expect(banner.linkId, 42);
    expect(banner.opensClinic, isTrue);
    expect(banner.status, 1);
  });

  test(
      'regular banner fields stay compatible and invalid clinic links are ignored',
      () {
    final regular = BannerModel.fromJson({
      'id': 11,
      'name': 'Regular banner',
      'slider_image': 'https://clinic.test/regular.png',
      'type': 'service',
      'status': 1
    });
    expect(regular.sliderImage, 'https://clinic.test/regular.png');
    expect(regular.opensClinic, isFalse);
    expect(
        BannerModel.fromJson({'type': 'clinic', 'clinic_id': -1}).opensClinic,
        isFalse);
  });

  test('home combines approved clinic banners with regular site banners',
      () async {
    final banners = await HomeServiceApis.getHomeBanners(
      clinicFeed: () async => feed([
        {
          'id': 1,
          'clinic_id': 42,
          'type': 'clinic',
          'banner_image': 'https://clinic.test/ad.png'
        }
      ]),
      regularFeed: () async => feed([
        {
          'id': 1,
          'type': 'service',
          'slider_image': 'https://clinic.test/regular.png'
        }
      ]),
    );
    expect(banners, hasLength(2));
    expect(banners.first.opensClinic, isTrue);
    expect(banners.last.type, 'service');
  });

  test('an unavailable clinic feed does not hide regular banners', () async {
    final banners = await HomeServiceApis.getHomeBanners(
      clinicFeed: () async => throw Exception('Clinic feed unavailable'),
      regularFeed: () async => feed([
        {'slider_image': 'https://clinic.test/regular.png'}
      ]),
    );
    expect(banners.single.sliderImage, 'https://clinic.test/regular.png');
  });

  test(
      'clinic banners survive a failed regular feed and empty images are ignored',
      () async {
    final banners = await HomeServiceApis.getHomeBanners(
      clinicFeed: () async => feed([
        {
          'type': 'clinic',
          'clinic_id': 42,
          'banner_image': 'https://clinic.test/ad.png'
        },
        {'banner_image': ''}
      ]),
      regularFeed: () async => throw Exception('Regular feed unavailable'),
    );
    expect(banners, hasLength(1));
    expect(banners.single.opensClinic, isTrue);
  });
}
