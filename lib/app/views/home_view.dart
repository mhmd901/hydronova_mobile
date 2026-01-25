import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/controllers/bluetooth_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BluetoothController>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Sensor Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _DataCard(
                      label: 'Temp',
                      unit: '?C',
                      accent: const Color(0xFFF4A261),
                      icon: Icons.thermostat_outlined,
                      valueBuilder: () => controller.temperature.value,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DataCard(
                      label: 'Humidity',
                      unit: '%',
                      accent: const Color(0xFF4D9DE0),
                      icon: Icons.water_drop_outlined,
                      valueBuilder: () => controller.humidity.value,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DataCard(
                      label: 'Water Level',
                      unit: '%',
                      accent: const Color(0xFF2A9D8F),
                      icon: Icons.waves_outlined,
                      valueBuilder: () => controller.waterLevel.value,
                      showProgress: true,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DataCard(
                      label: 'pH',
                      unit: 'pH',
                      accent: const Color(0xFF8E6BBF),
                      icon: Icons.science_outlined,
                      valueBuilder: () => controller.ph.value,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DataCard(
                      label: 'Nutrient',
                      unit: 'ppm',
                      accent: const Color(0xFFF4D35E),
                      icon: Icons.bubble_chart_outlined,
                      valueBuilder: () => controller.nutrient.value,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final lastUpdate = controller.lastUpdate.value;
              return Text(
                lastUpdate == null
                    ? 'Updated: No data yet'
                    : 'Updated: ${_formatTime(lastUpdate)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.label,
    required this.unit,
    required this.accent,
    required this.valueBuilder,
    this.icon,
    this.showProgress = false,
  });

  final String label;
  final String unit;
  final Color accent;
  final double? Function() valueBuilder;
  final IconData? icon;
  final bool showProgress;

  String _displayValue(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final value = valueBuilder();
        final progressValue = value == null
            ? null
            : (value / 100).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                  children: [
                    TextSpan(text: _displayValue(value)),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 14,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showProgress) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: accent.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

String _formatTime(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}
