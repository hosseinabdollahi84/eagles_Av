import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eagles/utils/shaparak_guard.dart';
import 'package:eagles/controllers/home_controller.dart';

class ResultController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final Map<String, dynamic> behaveInfo;
  final Map<String, dynamic> netInfo;
  final String xmlRiskReport;
  final List<SecurityReport> shaparakReports;

  ResultController({
    required this.behaveInfo,
    required this.netInfo,
    required this.xmlRiskReport,
    required this.shaparakReports,
  });

  late AnimationController animationController;
  late Animation<double> gaugeAnimation;
  var isInitialized = false.obs;

  late List<String> networkDetails;
  late String verdict;

  @override
  void onInit() {
    super.onInit();

    print("--------------------------------------------------");
    print(" DEBUGGING DATA:");
    print(" XML Report: $xmlRiskReport");
    print(" RAW Net Info: $netInfo");
    print(" RAW Behave Info: $behaveInfo");
    print("--------------------------------------------------");

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _prepareData();
    _initializePage();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void _prepareData() {
    verdict = "${behaveInfo['verdict'] ?? netInfo['verdict'] ?? 'Unknown'}";

    networkDetails = [];
    final networkSummary =
        netInfo['summary'] ?? 'No network summary available.';
    networkDetails.add(breakStringByWords(networkSummary, 5));

    final shaparakThreats = shaparakReports.where((r) => !r.isSafe).toList();

    if (shaparakThreats.isNotEmpty) {
      networkDetails.add('');
      networkDetails.add('--- Shaparak Phishing Alert ---');
      for (var threat in shaparakThreats) {
        networkDetails.add("URL: ${threat.url}");
        networkDetails.add("   └ Reason: ${threat.threatType}");
      }
    } else {
      networkDetails.add('');
      networkDetails.add("✅ No Shaparak-related phishing threats found.");
    }
  }

  Future<void> _initializePage() async {
    final threatScore = await _calculateScore();

    final normalizedValue = (100 - threatScore) / 100.0;

    gaugeAnimation = Tween<double>(begin: 0, end: normalizedValue).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );

    isInitialized.value = true;
    animationController.forward();
  }

  Future<double> _calculateScore() async {
    double extractScore(Map<String, dynamic> data) {
      dynamic value;
      if (data.containsKey('threat_score')) {
        value = data['threat_score'];
      } else if (data.containsKey('network_score')) {
        value = data['network_score'];
      } else if (data.containsKey('score')) {
        value = data['score'];
      }

      if (value == null) return 0.0;

      double score = 0.0;
      if (value is num) {
        score = value.toDouble();
      } else if (value is String) {
        score =
            double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }

      if (score > 0 && score <= 10) {
        return score * 10.0;
      }

      return score;
    }

    double behaveScore = extractScore(behaveInfo);
    double netScore = extractScore(netInfo);

    print("Final Adjusted Behave Score: $behaveScore");
    print("Final Adjusted Net Score: $netScore");

    double finalThreatScore = max(behaveScore, netScore);

    double finalSecurityScore = 100 - finalThreatScore;
    if (finalSecurityScore < 0) finalSecurityScore = 0;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('finalScore', finalSecurityScore);

    try {
      int currentScans = prefs.getInt('global_scan_count') ?? 0;
      await prefs.setInt('global_scan_count', currentScans + 1);

      await prefs.setInt(
        'global_last_scan_ts',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadScanData();
      }
    } catch (e) {
      print("Error updating home stats: $e");
    }

    return finalThreatScore;
  }

  String breakStringByWords(String input, int wordsPerLine) {
    if (input.isEmpty) return "";
    List<String> words = input.trim().split(RegExp(r'\s+'));
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i == words.length - 1) continue;
      if ((i + 1) % wordsPerLine == 0) {
        buffer.write('\n');
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
