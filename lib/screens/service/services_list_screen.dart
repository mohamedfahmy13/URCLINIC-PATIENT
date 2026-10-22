import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/empty_error_state_widget.dart';

import 'components/service_card.dart';
import 'model/service_list_model.dart';
import 'search_service_widget.dart';
import 'service_list_controller.dart';

enum ServiceSortOption { none, nameAZ, nameZA, priceHigh, priceLow }

class ServiceListScreen extends StatefulWidget {
  final String? title;
  final bool isFromClinicDetail;
  final bool isFromDashboard;

  const ServiceListScreen({
    super.key,
    this.title,
    this.isFromClinicDetail = false,
    this.isFromDashboard = false,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final ServiceListController serviceListCont =
      Get.put(ServiceListController());

  ServiceSortOption _currentSort = ServiceSortOption.none;

  String _getSortLabel(ServiceSortOption option) {
    switch (option) {
      case ServiceSortOption.none:
        return locale.value.sortBy;
      case ServiceSortOption.nameAZ:
        return locale.value.nameAZ;
      case ServiceSortOption.nameZA:
        return locale.value.nameZA;
      case ServiceSortOption.priceHigh:
        return 'Price - High to Low';
      case ServiceSortOption.priceLow:
        return 'Price - Low to High';
    }
  }

  IconData _getSortIcon(ServiceSortOption option) {
    switch (option) {
      case ServiceSortOption.none:
        return Icons.sort_rounded;
      case ServiceSortOption.nameAZ:
      case ServiceSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case ServiceSortOption.priceHigh:
      case ServiceSortOption.priceLow:
        return Icons.attach_money_rounded;
    }
  }

  void _onSortChanged(ServiceSortOption option) {
    setState(() => _currentSort = option);
  }

  List<ServiceElement> _getFilteredServices() {
    final sorted = List<ServiceElement>.from(serviceListCont.serviceList);
    switch (_currentSort) {
      case ServiceSortOption.none:
        break;
      case ServiceSortOption.nameAZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ServiceSortOption.nameZA:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ServiceSortOption.priceHigh:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ServiceSortOption.priceLow:
        sorted.sort((a, b) => a.price.compareTo(b.price));
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
                  color: context.themeBorder,
                  borderRadius: radius(2),
                ),
              ),
              16.height,
              Text(locale.value.sortBy, style: boldTextStyle(size: 18)),
              16.height,
              ...ServiceSortOption.values.where((o) => o != ServiceSortOption.none).map(
                (option) => ListTile(
                  leading: Icon(
                    _getSortIcon(option),
                    color: _currentSort == option ? context.themePrimary : iconColor,
                  ),
                  title: Text(
                    _getSortLabel(option),
                    style: _currentSort == option
                        ? boldTextStyle(color: context.themePrimary)
                        : primaryTextStyle(),
                  ),
                  trailing: _currentSort == option
                      ? Icon(Icons.check_circle, color: context.themePrimary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _onSortChanged(option);
                  },
                ),
              ),
              if (_currentSort != ServiceSortOption.none)
                ListTile(
                  leading: const Icon(Icons.clear_rounded, color: cancelStatusColor),
                  title: Text(
                    locale.value.clearAll,
                    style: primaryTextStyle(color: cancelStatusColor),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentSort = ServiceSortOption.none);
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
      appBartitleText: widget.title ?? appbarTitle,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: serviceListCont.isLoading,
      body: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchServiceWidget(
              servicesController: serviceListCont,
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
                    locale.value.services,
                    style: boldTextStyle(size: 18),
                  ).expand(),
                  GestureDetector(
                    onTap: () => _showSortBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: boxDecorationDefault(
                        color: _currentSort != ServiceSortOption.none
                            ? appColorPrimary.withValues(alpha: 0.1)
                            : context.cardColor,
                        borderRadius: radius(20),
                        border: Border.all(
                          color: _currentSort != ServiceSortOption.none
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
                            color: _currentSort != ServiceSortOption.none
                                ? context.themePrimary
                                : iconColor,
                          ),
                          6.width,
                          Text(
                            _currentSort == ServiceSortOption.none
                                ? locale.value.sortBy
                                : _getSortLabel(_currentSort),
                            style: boldTextStyle(
                              size: 12,
                              color: _currentSort != ServiceSortOption.none
                                  ? context.themePrimary
                                  : null,
                            ),
                          ),
                          4.width,
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: _currentSort != ServiceSortOption.none
                                ? context.themePrimary
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

            SnapHelperWidget(
              future: serviceListCont.serviceListFuture.value,
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  retryText: locale.value.reload,
                  imageWidget: const ErrorStateWidget(),
                  onRetry: () {
                    serviceListCont.page(1);
                    serviceListCont.getServiceList();
                  },
                ).paddingSymmetric(horizontal: 32);
              },
              loadingWidget: serviceListCont.isLoading.value
                  ? const Offstage()
                  : const LoaderWidget(),
              onSuccess: (p0) {
                final services = _getFilteredServices();

                if (services.isEmpty) {
                  return NoDataWidget(
                    title: locale.value.noServicesFoundAtAMoment,
                    subTitle:
                        '${locale.value.looksLikeThereIsNoServicesForThis}${widget.title ?? appbarTitle}, ${locale.value.wellKeepYouPostedWhenTheresAnUpdate}',
                    titleTextStyle: primaryTextStyle(),
                    imageWidget: const EmptyStateWidget(),
                    retryText: locale.value.reload,
                    onRetry: () {
                      serviceListCont.page(1);
                      serviceListCont.getServiceList();
                    },
                  ).paddingSymmetric(horizontal: 32);
                }

                return AnimatedScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  onSwipeRefresh: () async {
                    serviceListCont.page(1);
                    return serviceListCont.getServiceList(showLoader: false);
                  },
                  onNextPage: () async {
                    if (!serviceListCont.isLastPage.value) {
                      serviceListCont.page(serviceListCont.page.value + 1);
                      serviceListCont.getServiceList();
                    }
                  },
                  children: [
                    AnimatedWrap(
                      runSpacing: 16,
                      spacing: 16,
                      itemCount: services.length,
                      listAnimationType: ListAnimationType.FadeIn,
                      itemBuilder: (ctx, index) {
                        final ServiceElement serviceElement =
                            services[index];
                        return ServiceCard(
                            serviceElement: serviceElement,
                            isFromClinicDetail: widget.isFromClinicDetail);
                      },
                    ),
                  ],
                );
              },
            ).expand(),
          ],
        ),
      ),
    );
  }

  String get appbarTitle => widget.isFromDashboard
      ? ''
      : serviceListCont.category.value.name.isNotEmpty
          ? " ${serviceListCont.category.value.name}"
          : " ${selectedSysService.value.name} ${locale.value.services}";
}
