import 'dart:ui';
import 'package:eagles/controllers/analysis_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class Analysispage extends StatelessWidget {
  final String apkPath;
  final String? packageName;
  final String? appName;

  const Analysispage({
    super.key,
    required this.apkPath,
    this.packageName,
    this.appName,
  });

  final Color neonGreen = const Color(0xFF00E676);
  final Color bgColor = const Color(0xFF09203F);

  @override
  Widget build(BuildContext context) {
    Get.create<AnalysisController>(
      () => AnalysisController(
        apkPath: apkPath,
        packageName: packageName,
        appName: appName,
      ),
    );

    final AnalysisController controller = Get.find<AnalysisController>();
    final String displayName = appName ?? apkPath.split('/').last;

    return WillPopScope(
      onWillPop: () async {
        controller.cancelScan();
        Get.delete<AnalysisController>();
        return true;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(controller),
        body: Stack(
          children: [
            const RepaintBoundary(child: _StaticBackground()),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildMainCircularGauge(controller),
                    const SizedBox(height: 20),
                    _buildPathDisplay(apkPath),
                    const SizedBox(height: 20),
                    Obx(
                      () => Text(
                        controller.currentStatus.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Expanded(child: _buildConsoleBox(controller)),

                    const SizedBox(height: 25),

                    _buildAppProgressCard(controller, displayName),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 25,
              right: 25,
              child: _buildBottomButton(controller),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AnalysisController controller) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () {
          controller.cancelScan();
          Get.delete<AnalysisController>();
          Get.back();
        },
      ),
      title: const Text(
        'System Scan',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  Widget _buildPathDisplay(String path) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        'Target: ...${path.length > 22 ? path.substring(path.length - 22) : path}',
        style: TextStyle(color: neonGreen, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMainCircularGauge(AnalysisController controller) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: Obx(
              () => CircularProgressIndicator(
                value: controller.progressValue.value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: neonGreen.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(neonGreen),
              ),
            ),
          ),
          Container(
            width: 115,
            height: 115,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: neonGreen.withOpacity(0.3), width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: neonGreen.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.isScanComplete.value
                        ? Icons.check_circle_outline
                        : Icons.security,
                    color: neonGreen,
                    size: 28,
                  ),
                  Text(
                    '${(controller.progressValue.value * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleBox(AnalysisController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Obx(() {
            final fullText = controller.consoleLog.value;
            final List<String> logs = fullText
                .split('\n')
                .where((element) => element.trim().isNotEmpty)
                .toList()
                .reversed
                .toList();

            if (logs.isEmpty) return const SizedBox();

            return ListView.builder(
              reverse: true,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final logLine = logs[index];
                final isLatest = (index == 0);

                return _AnimatedLogItem(
                  text: logLine,
                  isLatest: isLatest,
                  key: ValueKey('${logs.length}-$index-$logLine'),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAppProgressCard(
    AnalysisController controller,
    String displayName,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: packageName != null
                ? FutureBuilder<AppInfo?>(
                    future: InstalledApps.getAppInfo(packageName!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data?.icon != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(snapshot.data!.icon!),
                        );
                      }
                      return const Icon(Icons.android, color: Colors.white54);
                    },
                  )
                : const Icon(Icons.folder_zip, color: Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => LinearProgressIndicator(
                    value: controller.progressValue.value,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(neonGreen),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Obx(
            () => controller.isScanComplete.value
                ? Icon(Icons.check_circle, color: neonGreen)
                : SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: neonGreen,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(AnalysisController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: Obx(() {
              final done = controller.isScanComplete.value;
              return ElevatedButton.icon(
                onPressed: () {
                  if (done) {
                    controller.goToResultPage();
                  } else {
                    controller.cancelScan();
                    Get.delete<AnalysisController>();
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: done
                      ? neonGreen
                      : Colors.white.withOpacity(0.1),
                  foregroundColor: done ? Colors.black : Colors.white,
                  side: BorderSide(color: done ? neonGreen : Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: Icon(done ? Icons.arrow_forward : Icons.close),
                label: Text(
                  done ? 'View Report' : 'Cancel Scan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StaticBackground extends StatelessWidget {
  const _StaticBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: _bgCircle(400, const Color(0xFF581FC4)),
        ),
        Positioned(
          top: 250,
          left: 0,
          right: 0,
          child: Center(child: _bgCircle(350, const Color(0xFF212264))),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child: _bgCircle(450, const Color(0xFF5E1FC4)),
        ),
      ],
    );
  }

  Widget _bgCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.6), color.withOpacity(0.0)],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}

class _AnimatedLogItem extends StatelessWidget {
  final String text;
  final bool isLatest;

  const _AnimatedLogItem({
    super.key,
    required this.text,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    const Color neonGreen = Color(0xFF00E676);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                  color: isLatest
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : neonGreen,
                  fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                  shadows: isLatest
                      ? [
                          const BoxShadow(
                            color: Colors.white54,
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
