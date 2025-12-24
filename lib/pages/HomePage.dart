import 'dart:ui';
import 'package:eagles/controllers/home_controller.dart';
import 'package:eagles/pages/app_list_page.dart';
import 'package:eagles/widgets/security_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double circleSize = MediaQuery.of(context).size.width * 0.35;

    return Scaffold(
      backgroundColor: const Color(0xFF081C3A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Deagles Av',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: "Montserrat",
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  Obx(
                    () => SizedBox(
                      width: circleSize * 1.8,
                      height: circleSize * 1.8,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SecuritySegmentRing(
                            animation: controller.pulseAnimation,
                            color: controller.statusColor.value,
                            size: circleSize * 1.5,
                          ),
                          SecurityEnergyGlow(
                            color: controller.statusColor.value,
                            size: circleSize * 1.2,
                          ),
                          SecurityReactorCore(
                            size: circleSize,
                            color: controller.statusColor.value,
                            icon: controller.statusIcon.value,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1F33).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: controller.statusColor.value.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: controller.statusColor.value,
                            size: 10,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'System: ${controller.status.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Updated: ${controller.lastScanText.value}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          onPressed: controller.loadScanData,
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.cyanAccent,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Obx(
                    () => Column(
                      children: [
                        _buildHorizontalInfoBox(
                          icon: Icons.history,
                          title: 'Last Scan',
                          subtitle: '${controller.lastScanText.value} ',
                        ),
                        const SizedBox(height: 14),
                        _buildHorizontalInfoBox(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Total Scans',
                          subtitle:
                              '${controller.scanCount.value}  •  Version V1.0.0',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildScanButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(192, 130, 241, 130),
              Color.fromARGB(214, 90, 206, 221),
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: () =>
              Get.to(() => AppListPage(), transition: Transition.rightToLeft),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            'Run Smart Scan',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalInfoBox({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
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
          colors: [color.withOpacity(0.8), color.withOpacity(0.0)],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
