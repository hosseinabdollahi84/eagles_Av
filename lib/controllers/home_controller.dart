import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var status = 'Secure'.obs;
  var statusColor = const Color(0xff4bc082).obs;
  var statusIcon = Icons.security.obs;

  var lastScanText = "Never".obs;
  var scanCount = 0.obs;

  late AnimationController rippleController;
  late Animation<double> pulseAnimation;

  @override
  void onInit() {
    super.onInit();

    rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    pulseAnimation = CurvedAnimation(
      parent: rippleController,
      curve: Curves.easeInOutSine,
    );

    rippleController.repeat(reverse: true);

    loadScanData();
  }

  @override
  void onClose() {
    rippleController.dispose();
    super.onClose();
  }

  String _formatTimeAgo(int timestamp) {
    if (timestamp == 0) return "Never";

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hour(s) ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} day(s) ago";
    } else {
      return "${date.year}/${date.month}/${date.day}";
    }
  }

  Future<void> loadScanData() async {
    final prefs = await SharedPreferences.getInstance();

    int lastTimestamp = prefs.getInt('global_last_scan_ts') ?? 0;
    int scans = prefs.getInt('global_scan_count') ?? 0;

    double score = prefs.getDouble('finalScore') ?? 100.0;

    lastScanText.value = _formatTimeAgo(lastTimestamp);
    scanCount.value = scans;

    _updateStatus(score);
  }

  void _updateStatus(double score) {
    if (score >= 80) {
      status.value = 'Secure';
      statusColor.value = const Color(0xff4bc082);
      statusIcon.value = Icons.security;
    } else if (score >= 50) {
      status.value = 'Warning';
      statusColor.value = Colors.orange;
      statusIcon.value = Icons.warning_amber_rounded;
    } else {
      status.value = 'Critical';
      statusColor.value = Colors.red;
      statusIcon.value = Icons.error_outline;
    }
  }
}
