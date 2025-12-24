import 'dart:io';
import 'package:crypto/crypto.dart';

Future<String?> calculateApkSha256(String filePath) async {
  final file = File(filePath);

  if (!await file.exists()) {
    print('File does not exists !');
    return null;
  }

  try {
    final stream = file.openRead();

    final digest = await sha256.bind(stream).first;

    return digest.toString();
  } catch (e) {
    print('Exception: $e');
    return null;
  }
}
