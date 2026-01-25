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
          Row(
            children: [
              Expanded(
                child: _DataCard(
                  label: 'Temp',
                  unit: '°C',
                  accent: const Color(0xFFF4A261),
                  valueBuilder: () => controller.temperature.value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DataCard(
                  label: 'Humidity',
                  unit: '%',
                  accent: const Color(0xFF4D9DE0),
                  valueBuilder: () => controller.humidity.value,
                ),
              ),
            ],
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
  });

  final String label;
  final String unit;
  final Color accent;
  final double? Function() valueBuilder;

  String _displayValue(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final value = valueBuilder();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
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
