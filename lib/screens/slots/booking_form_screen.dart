import 'dart:math' as math;

import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/utils/colors.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/app_scaffold.dart';
import '../../components/add_files_widget.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';
import '../../utils/empty_error_state_widget.dart';
import '../../utils/view_all_label_component.dart';
import '../auth/model/login_response.dart';
import '../clinic/model/clinic_detail_model.dart';
import '../clinic/model/clinics_res_model.dart';
import '../doctor/model/doctor_list_res.dart';
import '../other_patient/add_other_patient_screen.dart';
import '../service/model/service_list_model.dart';
import 'booking_form_controller.dart';
import 'components/clinic_selection_card_widget.dart';

import 'components/doctor_selection_card_widget.dart';
import 'components/service_selection_card_widget.dart';

class BookingFormScreen extends StatelessWidget {
  BookingFormScreen({super.key});

  final BookingFormController timeSlotsCont = Get.put(BookingFormController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.bookingForm,
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: timeSlotsCont.isLoading,
      body: RefreshIndicator(
        onRefresh: () async => timeSlotsCont.init(showLoader: false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Obx(
              () => AnimatedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 90,
                ),
                children: [
                  16.height,
                  ViewAllLabel(label: locale.value.chooseDate, isShowAll: false)
                      .paddingOnly(right: 8),
                  Container(
                    decoration: boxDecorationDefault(color: context.cardColor),
                    child: DatePicker(
                      dateTextStyle: boldTextStyle(size: 18),
                      dayTextStyle: secondaryTextStyle(size: 14),
                      monthTextStyle: secondaryTextStyle(size: 14),
                      DateTime.now(),
                      initialSelectedDate: DateTime.now(),
                      selectionColor: context.themeSoftPrimary,
                      selectedTextColor: appColorPrimary,
                      height: 100,
                      onDateChange: (date) {
                        timeSlotsCont.selectedDate(date.formatDateYYYYmmdd());
                        timeSlotsCont.selectedSlot("");
                        timeSlotsCont.getTimeSlot();
                        timeSlotsCont.onDateTimeChange();
                      },
                    ),
                  ),
                  16.height,
                  Obx(
                    () {
                      return SnapHelperWidget(
                        future: timeSlotsCont.slotsFuture.value,
                        errorBuilder: (error) {
                          return NoDataWidget(
                            title: error,
                            retryText: locale.value.reload,
                            imageWidget: const ErrorStateWidget(),
                            onRetry: () {
                              timeSlotsCont.getTimeSlot();
                            },
                          ).paddingSymmetric(horizontal: 32);
                        },
                        loadingWidget: const LoaderWidget(),
                        onSuccess: (p0) {
                          if (timeSlotsCont.slots.isEmpty &&
                              !timeSlotsCont.isLoading.value) {
                            return Center(
                                child: Text(
                                    timeSlotsCont.timeSlotsMessage.value,
                                    style: secondaryTextStyle(
                                        color: context.themeDanger, size: 14)));
                          }

                          return Obx(
                            () {
                              final double slotItemWidth = math
                                  .max(88, ((Get.width - 80) / 3))
                                  .toDouble();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ViewAllLabel(
                                          label: locale.value.chooseTime,
                                          isShowAll: false)
                                      .paddingOnly(right: 8),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    width: Get.width,
                                    alignment: Alignment.center,
                                    decoration: boxDecorationDefault(
                                        color: context.cardColor),
                                    child: AnimatedWrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      children: List.generate(
                                        timeSlotsCont.slots.length,
                                        (i) {
                                          final String slot =
                                              timeSlotsCont.slots[i];
                                          return Obx(
                                            () => GestureDetector(
                                              onTap: () {
                                                timeSlotsCont
                                                    .selectedSlot(slot);
                                                timeSlotsCont
                                                    .onDateTimeChange();
                                              },
                                              child: Container(
                                                width: slotItemWidth,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                decoration:
                                                    boxDecorationWithRoundedCorners(
                                                  backgroundColor: timeSlotsCont
                                                              .selectedSlot
                                                              .value ==
                                                          slot
                                                      ? appColorPrimary
                                                      : context
                                                          .scaffoldBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          defaultRadius / 2),
                                                ),
                                                child: Text(
                                                  slot,
                                                  textAlign: TextAlign.center,
                                                  style: primaryTextStyle(
                                                    size: 12,
                                                    color: (timeSlotsCont
                                                                .selectedSlot
                                                                .value ==
                                                            slot)
                                                        ? Colors.white
                                                        : context.themePrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  16.height,
                  ViewAllLabel(
                    label: locale.value.bookingFor,
                    trailingText: locale.value.addOtherPatient,
                    onTap: () {
                      Get.to(() => AddOtherPatientScreen(
                          titleText: locale.value.addPatient,
                          memberData: UserData()))?.then(
                        (value) {
                          if (value == true) {
                            timeSlotsCont.manageOtherPatientController
                                .getOtherPatientList();
                          }
                        },
                      );
                    },
                  ),
                  SnapHelperWidget(
                    future: timeSlotsCont.manageOtherPatientController
                        .otherPatientListFuture.value,
                    loadingWidget: SizedBox(),
                    errorBuilder: (error) {
                      return NoDataWidget(
                        title: error,
                        retryText: locale.value.reload,
                        imageWidget: const ErrorStateWidget(),
                        onRetry: () async {
                          await timeSlotsCont.manageOtherPatientController
                              .onRefresh();
                        },
                      ).paddingSymmetric(horizontal: 32);
                    },
                    onSuccess: (data) {
                      if (data.isEmpty) return const Offstage();
                      return AnimatedWrap(
                        listAnimationType: ListAnimationType.None,
                        spacing: 16,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: data.map((userData) {
                          return Obx(() {
                            return GestureDetector(
                              onTap: () {
                                if (timeSlotsCont.selectedMember.value.id ==
                                    userData.id) {
                                  timeSlotsCont.selectedMember(UserData());
                                } else {
                                  timeSlotsCont.selectedMember(userData);
                                }
                              },
                              child: AnimatedOpacity(
                                opacity: 1,
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  width: Get.width / 3 - 24,
                                  decoration: boxDecorationDefault(
                                    color:
                                        timeSlotsCont.selectedMember.value.id ==
                                                userData.id
                                            ? appColorPrimary
                                            : context.cardColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  child: Row(
                                    spacing: 12,
                                    children: [
                                      CachedImageWidget(
                                        url: userData.profileImage,
                                        circle: true,
                                        height: 28,
                                        width: 28,
                                        fit: BoxFit.cover,
                                      ),
                                      Text(
                                        userData.firstName,
                                        style: boldTextStyle(
                                          size: 14,
                                          color: timeSlotsCont.selectedMember
                                                      .value.id ==
                                                  userData.id
                                              ? Colors.white
                                              : isDarkMode.value
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ).expand(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                        }).toList(),
                      );
                    },
                  ),
                  16.height,
                  Text(locale.value.addMedicalHistory,
                      style: boldTextStyle(size: Constants.labelTextSize)),
                  8.height,
                  AppTextField(
                    textStyle: primaryTextStyle(size: 12),
                    textFieldType: TextFieldType.MULTILINE,
                    isValidationRequired: false,
                    minLines: 5,
                    maxLength: 250,
                    controller: timeSlotsCont.medicalReportCont,
                    decoration: inputDecoration(context,
                        labelText: locale.value.addMedicalHistory,
                        fillColor: context.cardColor,
                        filled: true),
                  ),
                  8.height,
                  Text(locale.value.addMedicalReport,
                      style: boldTextStyle(size: Constants.labelTextSize)),
                  8.height,
                  AddFilesWidget(
                    width: Get.width * 0.9,
                    fileList: timeSlotsCont.medicalReportFiles,
                    onFilePick: timeSlotsCont.handleFilesPickerClick,
                    onFilePathRemove: (index) {
                      timeSlotsCont.medicalReportFiles
                          .remove(timeSlotsCont.medicalReportFiles[index]);
                    },
                  ),

                  /// Price section hidden from patient view
                  const SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              height: 50,
              child: Obx(
                () {
                  return AppButton(
                    width: Get.width,
                    color: timeSlotsCont.nextBtnVisible.value
                        ? appColorSecondary
                        : null,
                    enabled: timeSlotsCont.nextBtnVisible.value ? true : false,
                    disabledColor: timeSlotsCont.nextBtnVisible.value
                        ? null
                        : appColorSecondary.withValues(alpha: 0.5),
                    shapeBorder: RoundedRectangleBorder(
                        borderRadius: radius(defaultAppButtonRadius / 2)),
                    onTap: () {
                      if (timeSlotsCont.nextBtnVisible.value) {
                        doIfLoggedIn(() {
                          timeSlotsCont.handleNextClick(context);
                        });
                      }
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        locale.value.next,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: boldTextStyle(
                            color: timeSlotsCont.nextBtnVisible.value
                                ? Colors.white
                                : Colors.white70,
                            size: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget serviceListWid(List<ServiceElement> list) {
    final List<ServiceElement> displayList = List.from(list);

    // Ensure selected service is always at the top
    if (timeSlotsCont.selectedService.value.id > 0) {
      // Remove if already in list
      displayList
          .removeWhere((e) => e.id == timeSlotsCont.selectedService.value.id);
      // Add at the beginning
      displayList.insert(0, timeSlotsCont.selectedService.value);
    }

    return AnimatedListView(
      itemCount: displayList.length,
      shrinkWrap: true,
      listAnimationType: ListAnimationType.FadeIn,
      itemBuilder: (context, index) {
        return ServiceSelectionCardWidget(
          serviceElement: displayList[index],
          isSelected:
              displayList[index].id == timeSlotsCont.selectedService.value.id,
          onTap: () {
            timeSlotsCont.selectedService(displayList[index]);
            timeSlotsCont
                .serviceNameText(timeSlotsCont.selectedService.value.name);
            timeSlotsCont.serviceValidationError("");
            currentSelectedService.value.payableAmount =
                timeSlotsCont.selectedService.value.payableAmount.toDouble();

            // Only clear clinic and doctor if they are not pre-selected values
            if (currentSelectedClinic.value.id.isNegative) {
              timeSlotsCont.clinicNameText("");
              timeSlotsCont.selectedClinic =
                  Clinic(clinicSession: ClinicSession()).obs;
            }
            if (currentSelectedDoctor.value.doctorId.isNegative) {
              timeSlotsCont.doctorNameText("");
              timeSlotsCont.selectedDoctor = Doctor().obs;
            }

            timeSlotsCont.doctorList.clear();
            timeSlotsCont.selectedSlot("");
            timeSlotsCont.slots.clear();
            timeSlotsCont.nextBtnVisible(false);
            timeSlotsCont.getClinicList();
            timeSlotsCont.getServiceList();
            Get.back();
          },
        ).paddingBottom(16);
      },
      onNextPage: () {
        if (!timeSlotsCont.isLastPage.value) {
          timeSlotsCont.servicePage(timeSlotsCont.servicePage.value + 1);
          timeSlotsCont.getServiceList();
        }
      },
      onSwipeRefresh: () async {
        timeSlotsCont.servicePage(1);
        return timeSlotsCont.getServiceList();
      },
    );
  }

  Widget clinicListWid(List<Clinic> list) {
    final List<Clinic> displayList = List.from(list);

    // Ensure selected clinic is always at the top
    if (timeSlotsCont.selectedClinic.value.id > 0) {
      // Remove if already in list
      displayList
          .removeWhere((e) => e.id == timeSlotsCont.selectedClinic.value.id);
      // Add at the beginning
      displayList.insert(0, timeSlotsCont.selectedClinic.value);
    }

    return AnimatedListView(
      itemCount: displayList.length,
      shrinkWrap: true,
      listAnimationType: ListAnimationType.FadeIn,
      itemBuilder: (context, index) {
        return ClinicSelectionCardWidget(
          clinicData: displayList[index],
          isSelected:
              displayList[index].id == timeSlotsCont.selectedClinic.value.id,
          onTap: () {
            timeSlotsCont.selectedClinic(displayList[index]);
            timeSlotsCont
                .clinicNameText(timeSlotsCont.selectedClinic.value.name);
            timeSlotsCont.clinicValidationError("");

            // Only clear doctor if it's not a pre-selected value
            if (currentSelectedDoctor.value.doctorId.isNegative) {
              timeSlotsCont.clearDoctorSelection();
            }

            timeSlotsCont.getDoctorList();
            timeSlotsCont.nextBtnVisible(false);
            timeSlotsCont.getClinicList();
            Get.back();
          },
        ).paddingBottom(16);
      },
      onNextPage: () {
        if (!timeSlotsCont.isLastPage.value) {
          timeSlotsCont.clinicPage(timeSlotsCont.clinicPage.value + 1);
          timeSlotsCont.getClinicList();
        }
      },
      onSwipeRefresh: () async {
        timeSlotsCont.clinicPage(1);
        return timeSlotsCont.getClinicList();
      },
    );
  }

  Widget doctorListWid(List<Doctor> list) {
    final List<Doctor> displayList = List.from(list);

    // Ensure selected doctor is always at the top
    if (timeSlotsCont.selectedDoctor.value.doctorId > 0) {
      // Remove if already in list
      displayList.removeWhere(
          (e) => e.doctorId == timeSlotsCont.selectedDoctor.value.doctorId);
      // Add at the beginning
      displayList.insert(0, timeSlotsCont.selectedDoctor.value);
    }

    return AnimatedListView(
      itemCount: displayList.length,
      shrinkWrap: true,
      listAnimationType: ListAnimationType.FadeIn,
      itemBuilder: (context, index) {
        return DoctorSelectionCardWidget(
          doctorData: displayList[index],
          isSelected: displayList[index].doctorId ==
              timeSlotsCont.selectedDoctor.value.doctorId,
          onTap: () {
            timeSlotsCont.selectedDoctor(displayList[index]);
            timeSlotsCont
                .doctorNameText(timeSlotsCont.selectedDoctor.value.fullName);
            timeSlotsCont.doctorValidationError("");
            timeSlotsCont.getTimeSlot();
            timeSlotsCont.getDoctorList();
            Get.back();
          },
        ).paddingBottom(16);
      },
      onNextPage: () {
        if (!timeSlotsCont.isLastPage.value) {
          timeSlotsCont.doctorPage(timeSlotsCont.doctorPage.value + 1);
          timeSlotsCont.getDoctorList();
        }
      },
      onSwipeRefresh: () async {
        timeSlotsCont.doctorPage(1);
        return timeSlotsCont.getDoctorList();
      },
    );
  }
}
