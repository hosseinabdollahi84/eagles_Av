import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eagles/utils/shaparak_guard.dart';
import 'package:eagles/controllers/result_controller.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> behaveInfo;
  final Map<String, dynamic> netInfo;
  final String xmlRiskReport;
  final List<SecurityReport> shaparakReports;

  const ResultScreen({
    super.key,
    required this.behaveInfo,
    required this.netInfo,
    required this.xmlRiskReport,
    required this.shaparakReports,
  });

  @override
  Widget build(BuildContext context) {
    final String uniqueTag = DateTime.now().millisecondsSinceEpoch.toString();

    final controller = Get.put(
      ResultController(
        behaveInfo: behaveInfo,
        netInfo: netInfo,
        xmlRiskReport: xmlRiskReport,
        shaparakReports: shaparakReports,
      ),
      tag: uniqueTag,
    );

    const Color mainBgColor = Color.fromARGB(255, 9, 32, 63);

    return Scaffold(
      backgroundColor: mainBgColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _bgCircle(
              300,
              const Color.fromARGB(255, 88, 31, 196).withOpacity(0.6),
            ),
          ),
          Positioned(
            top: 250,
            left: 70,
            right: 70,
            child: _bgCircle(
              250,
              const Color.fromARGB(255, 33, 34, 100).withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: _bgCircle(
              350,
              const Color.fromARGB(255, 94, 31, 196).withOpacity(0.6),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.shrink(),
          ),

          Column(
            children: [
              _buildAppBar(context),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Center(
                      child: Obx(() {
                        if (!controller.isInitialized.value) {
                          return const SizedBox(
                            height: 140,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        return AnimatedBuilder(
                          animation: controller.gaugeAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(220, 140),
                              painter: GaugePainter(
                                value: controller.gaugeAnimation.value,
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      controller.verdict,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 5),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ExpandableScrollCard(
                        title: "App Permissions",
                        icon: Icons.app_settings_alt_outlined,
                        accentColor: Colors.orangeAccent,
                        details: xmlRiskReport.isNotEmpty
                            ? xmlRiskReport.split('\n')
                            : ["No dangerous permissions detected"],
                      ),
                      const SizedBox(height: 15),
                      ExpandableScrollCard(
                        title: "Malware Analysis",
                        icon: Icons.biotech_outlined,
                        accentColor: Colors.greenAccent,
                        details: [
                          ...List.from(
                            behaveInfo['key_indicators']?['positives'] ?? [],
                          ),
                          ...List.from(
                            behaveInfo['key_indicators']?['negatives'] ?? [],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ExpandableScrollCard(
                        title: "Network Security",
                        icon: Icons.language_outlined,
                        accentColor: Colors.blueAccent,
                        details: controller.networkDetails,
                      ),
                      const SizedBox(height: 15),
                      ExpandableScrollCard(
                        title: "Advanced Threats",
                        icon: Icons.radar_outlined,
                        accentColor: Colors.redAccent,
                        details: [
                          controller.breakStringByWords(
                            behaveInfo['analysis_summary'] ?? '',
                            200,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bgCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Analysis Result',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Montserrat',
        ),
      ),
      centerTitle: true,
    );
  }
}

class ExpandableScrollCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<String> details;
  final Color accentColor;

  const ExpandableScrollCard({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
    required this.accentColor,
  });

  @override
  State<ExpandableScrollCard> createState() => _ExpandableScrollCardState();
}

class _ExpandableScrollCardState extends State<ExpandableScrollCard> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails = widget.details
        .where((d) => d.trim().isNotEmpty)
        .isNotEmpty;

    return GestureDetector(
      onTap: hasDetails
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(minHeight: _isExpanded ? 220 : 80),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 250, 250, 250).withOpacity(0.06),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: widget.accentColor.withOpacity(_isExpanded ? 0.6 : 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (hasDetails)
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
              ],
            ),
            if (_isExpanded && hasDetails)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  height: 120,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.details.length,
                      itemBuilder: (context, index) {
                        if (widget.details[index].trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Icon(
                                  Icons.circle,
                                  color: widget.accentColor,
                                  size: 6,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.details[index],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;

  GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * 0.55;
    final strokeWidth = 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = Colors.redAccent.shade400;
    canvas.drawArc(rect, pi, pi / 3, false, paint);

    paint.color = Colors.orangeAccent.shade400;
    canvas.drawArc(rect, pi + (pi / 3), pi / 3, false, paint);

    paint.color = const Color(0xff00E676);
    canvas.drawArc(rect, pi + (2 * pi / 3), pi / 3, false, paint);

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final angle = pi + (value * pi);

    final needleEnd = Offset(
      center.dx + (radius - 5) * cos(angle),
      center.dy + (radius - 5) * sin(angle),
    );

    canvas.drawCircle(center, 7, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      12,
      Paint()..color = Colors.white.withOpacity(0.1),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
