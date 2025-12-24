import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../controllers/app_list_controller.dart';

final AppListController _controller = Get.put(AppListController());

class AppListPage extends GetView<AppListController> {
  const AppListPage({super.key});

  @override
  AppListController get controller => _controller;

  final Color neonGreen = const Color(0xFF00E676);
  final Color subText = const Color(0xFF71877C);
  final Color bgColor = const Color(0xFF09203F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'APK Manager',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: "Montserrat",
          ),
        ),
      ),
      body: Stack(
        children: [
          const RepaintBoundary(child: _StaticBackground()),

          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildSearch(),
                    Expanded(child: _buildList()),
                  ],
                ),

                Obx(
                  () => controller.isProcessing.value
                      ? Container(
                          color: Colors.black54,
                          child: Center(
                            child: CircularProgressIndicator(color: neonGreen),
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildGlassButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: TextField(
        onChanged: controller.groupApps,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: neonGreen.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator(color: neonGreen));
      }
      return ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
        children: controller.groupedApps.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...entry.value.map(_buildAppItem).toList(),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildAppItem(AppInfo app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => controller.extractApk(app),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FutureBuilder<AppInfo?>(
                      future: InstalledApps.getAppInfo(app.packageName ?? ""),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data?.icon != null) {
                          return Image.memory(
                            snapshot.data!.icon!,
                            fit: BoxFit.cover,
                          );
                        }
                        return const Icon(Icons.android, color: Colors.white24);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "v${app.versionName}",
                        style: TextStyle(color: subText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: subText.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: neonGreen.withOpacity(0.1),
              border: Border.all(color: neonGreen.withOpacity(0.3)),
            ),
            child: ElevatedButton.icon(
              onPressed: controller.pickExternalApk,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.folder_open, color: Colors.white),
              label: const Text(
                'Select APK from Storage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
          child: _bgCircle(300, const Color(0xFF581FC4)),
        ),
        Positioned(
          top: 250,
          left: 50,
          right: 50,
          child: Center(child: _bgCircle(250, const Color(0xFF212264))),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child: _bgCircle(350, const Color(0xFF5E1FC4)),
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
