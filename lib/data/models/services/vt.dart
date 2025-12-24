import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';

enum ScanStage {
  idle,
  uploading,
  queued,
  analyzing,
  finishing,
  finished,
  error,
  cancelled,
}

class VirusTotalScanner {
  final String apiKey;
  final Dio _dio = Dio();
  ScanStage currentStage = ScanStage.idle;
  final Function(ScanStage stage, int percent, String message) onProgressUpdate;

  VirusTotalScanner({required this.apiKey, required this.onProgressUpdate}) {
    _dio.options.headers = {'x-apikey': apiKey};
  }

  Future<List<dynamic>?> scanFileForBehaviour(
    String filePath,
    String fileHash, {
    CancelToken? cancelToken,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception("File not found");

      _updateStatus(ScanStage.analyzing, 0, "Checking database...");
      var existingBehaviour = await _getSandboxBehaviour(
        fileHash,
        cancelToken: cancelToken,
      );

      if (cancelToken?.isCancelled ?? false) throw _createCancelException();

      if (existingBehaviour != null && existingBehaviour.isNotEmpty) {
        _updateStatus(ScanStage.finished, 100, "Report found!");
        if (existingBehaviour is Map && existingBehaviour.containsKey('data')) {
          return existingBehaviour['data'] as List<dynamic>?;
        }
        return existingBehaviour as List<dynamic>?;
      }

      _updateStatus(ScanStage.uploading, 0, "Uploading file...");
      String? analysisId = await _uploadFile(file, cancelToken: cancelToken);

      if (cancelToken?.isCancelled ?? false) throw _createCancelException();
      if (analysisId == null) throw Exception("Upload failed");

      _updateStatus(ScanStage.queued, 0, "Waiting for Analysis...");

      var behaviours;
      while (true) {
        if (cancelToken?.isCancelled ?? false) throw _createCancelException();

        behaviours = await _getSandboxBehaviour(
          fileHash,
          cancelToken: cancelToken,
        );

        if (behaviours != null &&
            behaviours is Map &&
            behaviours['data'] != null &&
            (behaviours['data'] as List).isNotEmpty) {
          _updateStatus(ScanStage.finished, 100, "Sandbox Data Received!");
          return behaviours['data'];
        }

        if (behaviours != null &&
            behaviours is Map &&
            behaviours.containsKey('meta')) {
          Map<String, dynamic> meta = behaviours['meta'];
          if (meta.containsKey('in_progress_percent')) {
            Map<String, dynamic> progressMap = meta['in_progress_percent'];
            int maxProgress = 0;
            if (progressMap.isNotEmpty) {
              maxProgress = progressMap.values
                  .map((e) => e as int)
                  .reduce((a, b) => a > b ? a : b);
            }
            print("Max Progress: $maxProgress");
            _updateStatus(
              ScanStage.finishing,
              maxProgress,
              "% SandBox is analysing the apk....",
            );
          }
        }

        await Future.delayed(const Duration(seconds: 2));
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        print(" Operation Cancelled by user.");
        _updateStatus(ScanStage.cancelled, 0, "Scan cancelled.");
        return null;
      }
      print(" VT Error (Dio): ${e.message}");
      _updateStatus(ScanStage.error, 0, "Network Error: ${e.message}");
      return null;
    } catch (e) {
      print(" VT Error: $e");
      _updateStatus(ScanStage.error, 0, "Error: $e");
      return null;
    }
  }

  void _updateStatus(ScanStage stage, int percent, String msg) {
    currentStage = stage;
    onProgressUpdate(stage, percent, msg);
  }

  DioException _createCancelException() {
    return DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.cancel,
    );
  }

  Future<dynamic?> _getSandboxBehaviour(
    String hash, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        'https://www.virustotal.com/api/v3/files/$hash/behaviours',
        cancelToken: cancelToken,
      );
      print("🔹 Behaviour API Status Code: ${response.statusCode}");
      return response.data;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;

      print("🔻 Behaviour API Error Code: ${e.response?.statusCode}");
      if (e.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  Future<String?> _uploadFile(File file, {CancelToken? cancelToken}) async {
    try {
      String fileName = file.path.split('/').last;
      int fileSize = await file.length();
      String uploadUrl;

      if (fileSize < 32 * 1024 * 1024) {
        uploadUrl = 'https://www.virustotal.com/api/v3/files';
      } else {
        print("📦 File > 32MB. Fetching large upload URL...");
        uploadUrl = await _getLargeFileUploadUrl(cancelToken: cancelToken);
      }

      if (cancelToken?.isCancelled ?? false) throw _createCancelException();

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        cancelToken: cancelToken,
        options: Options(headers: {'x-apikey': apiKey}),
        onSendProgress: (int sent, int total) {
          if (cancelToken?.isCancelled ?? false) return;

          int percentage = ((sent / total) * 100).toInt();
          print("Upload Progress: $percentage%");
          _updateStatus(
            ScanStage.uploading,
            percentage,
            "Uploading: $percentage%",
          );
        },
      );

      print("🔹 Upload Status Code: ${response.statusCode}");
      return response.data['data']['id'];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) rethrow;
      print("Upload Error: $e");
      return null;
    }
  }

  Future<String> _getLargeFileUploadUrl({CancelToken? cancelToken}) async {
    final response = await _dio.get(
      'https://www.virustotal.com/api/v3/files/upload_url',
      options: Options(headers: {'x-apikey': apiKey}),
      cancelToken: cancelToken,
    );
    return response.data['data'];
  }
}
