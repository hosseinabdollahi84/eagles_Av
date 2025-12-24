import 'dart:io';
import 'package:eagles/pages/analysispage.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:file_picker/file_picker.dart';

class AppListController extends GetxController {
  static const platform = MethodChannel('shizuku_apk');

  final allApps = <AppInfo>[].obs;
  final groupedApps = <String, List<AppInfo>>{}.obs;

  final isLoading = true.obs;
  final isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchApps();
  }

  Future<void> fetchApps() async {
    isLoading.value = true;
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      ); // ✅ درست
      apps.sort(
        (a, b) => (a.name ?? "").toLowerCase().compareTo(
          (b.name ?? "").toLowerCase(),
        ),
      );

      allApps.assignAll(apps);
      groupApps("");
    } catch (e) {
      print("Error fetching apps: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void groupApps(String query) {
    final filtered = allApps.where((app) {
      return (app.name ?? "").toLowerCase().contains(query.toLowerCase()) ||
          (app.packageName ?? "").toLowerCase().contains(query.toLowerCase());
    }).toList();

    final Map<String, List<AppInfo>> groups = {};

    for (var app in filtered) {
      String letter = (app.name ?? "#").trim();
      if (letter.isNotEmpty) {
        letter = letter[0].toUpperCase();
      } else {
        letter = "#";
      }

      if (!RegExp(r'[A-Z]').hasMatch(letter)) letter = "#";
      groups.putIfAbsent(letter, () => []).add(app);
    }

    groupedApps.value = groups;
    isLoading.value = false;
  }

  Future<void> extractApk(AppInfo app) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      final path = await platform.invokeMethod<String>('extractApk', {
        'packageName': app.packageName,
      });

      if (path != null && path.isNotEmpty) {
        if (await File(path).exists()) {
          Get.to(
            () => Analysispage(
              apkPath: path,
              packageName: app.packageName,
              appName: app.name,
            ),
          );
        } else {
          Get.snackbar("Error", "Extracted file not found.");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to extract APK: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> pickExternalApk() async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;

        if (await File(path).exists()) {
          Get.to(
            () =>
                Analysispage(apkPath: path, appName: result.files.single.name),
          );
        } else {
          Get.snackbar(
            "Error",
            "Selected file does not exist or is not accessible.",
          );
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick file: $e");
    } finally {
      isProcessing.value = false;
    }
  }
}
