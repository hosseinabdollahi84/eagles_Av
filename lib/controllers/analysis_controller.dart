import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import 'package:eagles/pages/resultscreen.dart';
import 'package:eagles/data/models/services/gemini_service.dart';
import 'package:eagles/utils/VTextract.dart';
import 'package:eagles/data/models/services/vt.dart';
import 'package:eagles/utils/shaparak_guard.dart';

Future<String> calculateApkSha256(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw Exception("File not found at path: $filePath");
  }
  try {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  } catch (e) {
    throw Exception("Hashing failed: $e");
  }
}

class AnalysisController extends GetxController {
  final String apkPath;
  final String? packageName;
  final String? appName;

  AnalysisController({required this.apkPath, this.packageName, this.appName});

  final progressValue = 0.0.obs;
  final currentStatus = "Initializing...".obs;
  final consoleLog = "".obs;
  final isScanComplete = false.obs;

  final isCancelled = false.obs;

  bool _cancelled = false;
  final Completer<void> _abort = Completer<void>();

  CancelToken _uploadCancelToken = CancelToken();

  String? _finalSha256;
  double _apkEntropy = 0.0;
  double _dexEntropy = 0.0;
  bool _isObfuscated = false;

  Map<String, dynamic> behaveInfo = {};
  Map<String, dynamic> netInfo = {};
  bool _isShaparakSafe = true;
  bool _isXmlSafe = true;
  bool _isEntropySafe = true;
  String _xmlRiskReport = "";

  final GeminiService? gAIsrv = GeminiService();
  static const platform = MethodChannel('shizuku_apk');
  final String _virusTotalApiKey = "your_api_key";

  final Map<String, String> _dangerousPermissionsMap = {
    "android.permission.BIND_ACCESSIBILITY_SERVICE":
        "CRITICAL: 'God Mode' (Bankers/Keyloggers)",
    "android.permission.BIND_DEVICE_ADMIN": "CRITICAL: Prevents uninstallation",
    "android.permission.SYSTEM_ALERT_WINDOW": "HIGH: Overlay Attack / Cloaking",
    "android.permission.READ_SMS": "HIGH: Spyware / 2FA Stealer",
    "android.permission.SEND_SMS": "HIGH: Cost mechanism / Spreading malware",
    "android.permission.RECEIVE_BOOT_COMPLETED":
        "MED: Persistence (Starts on boot)",
    "android.permission.INSTALL_PACKAGES": "HIGH: Dropper behavior",
    "android.permission.REQUEST_INSTALL_PACKAGES": "HIGH: Dropper behavior",
    "android.permission.READ_CONTACTS": "MED: Spyware",
    "android.permission.RECORD_AUDIO": "MED: Spyware",
  };

  @override
  void onInit() {
    super.onInit();
    if (_uploadCancelToken.isCancelled) {
      _uploadCancelToken = CancelToken();
    }
    _startFullAnalysis();
  }

  @override
  void onClose() {
    cancelScan(silent: true);
    super.onClose();
  }

  void cancelScan({bool silent = false}) {
    if (_cancelled) return;

    _cancelled = true;
    isCancelled.value = true;

    if (!_uploadCancelToken.isCancelled) {
      _uploadCancelToken.cancel("User cancelled the scan.");
    }

    if (!_abort.isCompleted) {
      _abort.complete();
    }

    if (!silent) {
      _appendToLog("[!] Scan cancelled by user.");
      currentStatus.value = "Cancelled";
    }
  }

  bool get cancelled => _cancelled;

  Future<T?> _runCancellable<T>(Future<T> future) async {
    if (_cancelled) return null;
    try {
      final result = await Future.any([future, _abort.future]);
      if (_cancelled) return null;
      return result as T?;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _delayCancellable(Duration d) async {
    await _runCancellable(Future.delayed(d));
  }

  void _updateStatus(String status, double progress) {
    if (_cancelled) return;
    currentStatus.value = status;
    progressValue.value = progress;
  }

  void _appendToLog(String message) {
    if (_cancelled) return;
    consoleLog.value += "$message\n";
  }

  String cleanJsonString(String input) {
    final regExp = RegExp(r'^\s*```json\s*([\s\S]*?)\s*```\s*$');
    final match = regExp.firstMatch(input);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    return input;
  }

  Future<void> _startFullAnalysis() async {
    if (_cancelled) return;

    try {
      _updateStatus("Calculating SHA-256...", 0.1);

      final hash = await _runCancellable(calculateApkSha256(apkPath));
      if (_cancelled) return;
      if (hash == null) throw Exception("Hash failed");

      _finalSha256 = hash;

      _updateStatus("Extracting Data...", 0.2);

      final results = await _runCancellable(
        Future.wait([
          platform.invokeMethod('getApkDetails', {'filePath': apkPath}),
          platform.invokeMethod('getApkUrls', {'filePath': apkPath}),
          platform.invokeMethod('getEntropyDetails', {'filePath': apkPath}),
        ]),
      );
      if (_cancelled || results == null) return;

      final apkDetails = results[0] as Map<dynamic, dynamic>;
      final urlsRaw = results[1] as List<dynamic>;
      final entropyRaw = results[2] as Map<dynamic, dynamic>;

      final extractedUrls = urlsRaw.map((e) => e.toString()).toList();

      final permissions = (apkDetails['permissions'] as List? ?? [])
          .map((e) => e.toString())
          .toList();

      _apkEntropy = (entropyRaw['totalEntropy'] ?? 0.0).toDouble();
      _dexEntropy = (entropyRaw['dexEntropy'] ?? 0.0).toDouble();
      _isObfuscated = (entropyRaw['isObfuscated'] ?? false) == true;

      _updateStatus("Checking Security...", 0.4);
      _appendToLog(">> Running Shaparak Guard...");

      if (_cancelled) return;

      if (extractedUrls.isNotEmpty) {
        final allReports = ShaparakGuard.analyzeLinks(extractedUrls);
        if (_cancelled) return;

        final threats = allReports.where((r) => !r.isSafe).toList();

        if (threats.isNotEmpty) {
          _isShaparakSafe = false;
          _appendToLog("⚠️ THREATS DETECTED:");
          for (final report in threats) {
            if (_cancelled) return;
            _appendToLog("❌ ${report.url}");
            _appendToLog("   Type: ${report.threatType}");
          }
        } else {
          _isShaparakSafe = true;
          _appendToLog("✅ No Phishing Links Found.");
        }
      } else {
        _appendToLog("ℹ️ No URLs found to scan.");
      }

      await _delayCancellable(const Duration(milliseconds: 300));
      if (_cancelled) return;

      _appendToLog("\n>> Analyzing Permissions (XML)...");
      final foundRisks = <String>[];

      for (final perm in permissions) {
        if (_cancelled) return;

        if (_dangerousPermissionsMap.containsKey(perm)) {
          final shortName = perm.split('.').last;
          final warning = _dangerousPermissionsMap[perm]!;
          foundRisks.add("$shortName\n      └ $warning");
        }
      }

      if (foundRisks.isNotEmpty) {
        _isXmlSafe = false;
        _xmlRiskReport = foundRisks.join("\n");
        _appendToLog("⚠️ DANGEROUS PERMISSIONS FOUND:");
        for (final risk in foundRisks) {
          if (_cancelled) return;
          _appendToLog("   • $risk");
        }
      } else {
        _isXmlSafe = true;
        _xmlRiskReport = "";
        _appendToLog("✅ Permissions: Safe");
      }

      await _delayCancellable(const Duration(milliseconds: 300));
      if (_cancelled) return;

      _appendToLog("\n>> Analyzing Code Structure...");
      _appendToLog(
        "Entropy: ${_apkEntropy.toStringAsFixed(2)} | DEX: ${_dexEntropy.toStringAsFixed(2)}",
      );

      if (_isObfuscated) {
        _isEntropySafe = false;
        _appendToLog("Obfuscation: DETECTED (Packed/Protected) ⚠️");
      } else {
        _isEntropySafe = true;
        _appendToLog("Obfuscation: Not Detected (Standard) ✅");
      }

      if (_cancelled) return;

      _updateStatus("VirusTotal Cloud Scan...", 0.6);

      final vtScanner = VirusTotalScanner(
        apiKey: _virusTotalApiKey,
        onProgressUpdate: (stage, percent, message) {
          if (_cancelled) return;
          currentStatus.value = message;
          progressValue.value = 0.6 + ((percent / 100) * 0.3);
        },
      );

      final vtResult = await _runCancellable(
        vtScanner.scanFileForBehaviour(
          apkPath,
          _finalSha256!,
          cancelToken: _uploadCancelToken,
        ),
      );

      if (_cancelled) return;
      if (vtResult == null) return;

      final vtEx = VTExtractor(vtResult);
      final behave = vtEx.extractBehaviorContext();
      final net = vtEx.extractNetworkContext();

      if (_cancelled) return;

      final nairRaw = await _runCancellable(
        gAIsrv?.GetVT_NetworkResult(jsonEncode(net)) ?? Future.value(""),
      );
      if (_cancelled) return;

      final bairRaw = await _runCancellable(
        gAIsrv?.GetVT_BehaviorResult(jsonEncode(net), _dexEntropy) ??
            Future.value(""),
      );
      if (_cancelled) return;

      final nair = cleanJsonString(nairRaw ?? "");
      final bair = cleanJsonString(bairRaw ?? "");

      if (_cancelled) return;

      netInfo = nair.trim().isEmpty ? {} : jsonDecode(nair);
      behaveInfo = bair.trim().isEmpty ? {} : jsonDecode(bair);

      if (_cancelled) return;

      _updateStatus("Analysis Complete", 1.0);
      isScanComplete.value = true;
    } catch (e) {
      if (_cancelled) return;
      _appendToLog("SYSTEM ERROR: $e");
      currentStatus.value = "Error";
      progressValue.value = 0.0;
    }
  }

  void goToResultPage() {
    if (_cancelled) return;

    Get.to(
      () => ResultScreen(
        behaveInfo: behaveInfo,
        netInfo: netInfo,
        xmlRiskReport: _xmlRiskReport,
        shaparakReports: [],
      ),
    );
  }
}
