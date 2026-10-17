import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'loader_widget.dart';

class Body extends StatelessWidget {
  final Widget child;
  final RxBool isLoading;

  const Body({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      height: Get.height,
      child: Obx(() => isLoading.value ? const LoaderWidget() : child),
    );
  }
}
