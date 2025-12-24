package com.example.eagles

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.nio.charset.Charset
import java.util.regex.Pattern
import java.util.zip.ZipFile
import kotlin.math.log2

class MainActivity: FlutterActivity() {

    private val CHANNEL = "shizuku_apk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractApk" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val path = extractApk(packageName)
                            if (path != null) result.success(path) 
                            else result.error("ERROR", "Couldn't copy the app", null)
                        } catch (e: Exception) {
                            result.error("EXCEPTION", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Empty package name", null)
                    }
                }
                "getApkDetails" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val info = getApkDetails(filePath)
                        if (info != null) {
                            result.success(info)
                        } else {
                            result.error("INVALID_APK", "Could not parse APK file", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                "getApkUrls" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        Thread {
                            val urls = findUrlsInApk(filePath)
                            runOnUiThread {
                                result.success(urls)
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                "getEntropyDetails" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        Thread {
                            val analysis = analyzeApkEntropy(filePath)
                            runOnUiThread {
                                result.success(analysis)
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractApk(packageName: String): String? {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val sourceFile = File(appInfo.sourceDir)
            val fileName = "$packageName.apk"
            val destFile = File(cacheDir, fileName)

            if (destFile.exists()) {
                destFile.delete() 
            }

            FileInputStream(sourceFile).use { inputStream ->
                FileOutputStream(destFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            destFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun getApkDetails(filePath: String): Map<String, Any>? {
        return try {
            val file = File(filePath)
            if (!file.exists()) return null
            
            val packageInfo = packageManager.getPackageArchiveInfo(filePath, PackageManager.GET_PERMISSIONS) ?: return null
            val appInfo = packageInfo.applicationInfo ?: return null 
            
            appInfo.sourceDir = filePath
            appInfo.publicSourceDir = filePath
            
            val label = appInfo.loadLabel(packageManager).toString()
            val packageName = packageInfo.packageName
            val versionName = packageInfo.versionName ?: "Unknown"
            val permissions = packageInfo.requestedPermissions?.toList() ?: emptyList<String>()

            mapOf(
                "appName" to label,
                "packageName" to packageName,
                "version" to versionName,
                "path" to filePath,
                "permissions" to permissions
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun findUrlsInApk(apkPath: String): List<String> {
        val urlList = mutableSetOf<String>()
        try {
            val zipFile = ZipFile(apkPath)
            val entries = zipFile.entries()
            val urlPattern = Pattern.compile("https?://[a-zA-Z0-9._~:/?#\\[\\]@!$&'()*+,;=%-]+")
            
            while (entries.hasMoreElements()) {
                val entry = entries.nextElement()
                val name = entry.name.lowercase()
                if (name.endsWith(".dex") || name == "resources.arsc" || name.endsWith(".xml")) {
                    zipFile.getInputStream(entry).use { stream ->
                        val content = stream.bufferedReader(Charset.forName("ISO-8859-1")).readText()
                        val matcher = urlPattern.matcher(content)
                        while (matcher.find()) {
                            val foundUrl = matcher.group()
                            if (foundUrl.length > 8 && !foundUrl.contains("schemas.android.com")) {
                                urlList.add(foundUrl)
                            }
                        }
                    }
                }
            }
            zipFile.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return urlList.toList()
    }

    private fun analyzeApkEntropy(apkPath: String): Map<String, Any> {
        val file = File(apkPath)
        val totalEntropy = calculateStreamEntropy(FileInputStream(file))
        var dexEntropy = 0.0
        try {
            val zipFile = ZipFile(file)
            val dexEntry = zipFile.getEntry("classes.dex")
            if (dexEntry != null) {
                dexEntropy = calculateStreamEntropy(zipFile.getInputStream(dexEntry))
            }
            zipFile.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        val isObfuscated = dexEntropy > 6.8
        return mapOf(
            "totalEntropy" to totalEntropy,
            "dexEntropy" to dexEntropy,
            "isObfuscated" to isObfuscated
        )
    }

    private fun calculateStreamEntropy(inputStream: InputStream): Double {
        val frequencies = IntArray(256)
        var totalBytes = 0
        val buffer = ByteArray(8192) 
        var bytesRead: Int
        try {
            BufferedInputStream(inputStream).use { bufferedInput ->
                while (bufferedInput.read(buffer).also { bytesRead = it } != -1) {
                    for (i in 0 until bytesRead) {
                        val unsignedByte = buffer[i].toInt() and 0xFF
                        frequencies[unsignedByte]++
                        totalBytes++
                    }
                }
            }
        } catch (e: Exception) {
            return 0.0
        }
        if (totalBytes == 0) return 0.0
        var entropy = 0.0
        for (count in frequencies) {
            if (count > 0) {
                val probability = count.toDouble() / totalBytes
                entropy -= probability * log2(probability)
            }
        }
        return entropy
    }
}
