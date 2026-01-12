import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/controllers/bluetooth_controller.dart';

class BluetoothDevicesPage extends StatelessWidget {
  const BluetoothDevicesPage({super.key});

  Color _statusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.red;
    }
  }

  String _statusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING';
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BluetoothController(), permanent: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth (HC-05)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: controller.enableBluetooth,
                  child: const Text('Enable Bluetooth'),
                ),
                ElevatedButton(
                  onPressed: controller.loadPairedDevices,
                  child: const Text('Refresh Paired Devices'),
                ),
                Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.status.value == ConnectionStatus.connected
                            ? controller.disconnect
                            : null,
                    child: const Text('Disconnect'),
                  ),
                ),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(controller.status.value),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _statusText(controller.status.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    children: [
                      Expanded(
                        flex: isWide ? 2 : 1,
                        child: _PairedDevicesPanel(controller: controller),
                      ),
                      SizedBox(
                        width: isWide ? 12 : 0,
                        height: isWide ? 0 : 12,
                      ),
                      Expanded(
                        flex: isWide ? 3 : 1,
                        child: _LogsPanel(controller: controller),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairedDevicesPanel extends StatelessWidget {
  const _PairedDevicesPanel({required this.controller});

  final BluetoothController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(
        () {
          if (controller.pairedDevices.isEmpty) {
            return const Center(
              child: Text(
                'No paired devices.\nPair HC-05 first in Android Bluetooth settings (PIN 1234/0000).',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: controller.pairedDevices.length,
            itemBuilder: (context, index) {
              final device = controller.pairedDevices[index];
              final name = device.name?.isNotEmpty == true
                  ? device.name!
                  : 'Unknown';
              final isConnected =
                  controller.status.value == ConnectionStatus.connected &&
                      controller.selectedDevice.value?.address ==
                          device.address;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  device.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 96,
                  child: isConnected
                      ? const OutlinedButton(
                          onPressed: null,
                          child: Text(
                            'Connected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => controller.connect(device),
                          child: const Text(
                            'Connect',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LogsPanel extends StatelessWidget {
  const _LogsPanel({required this.controller});

  final BluetoothController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(
        () => ListView.builder(
          itemCount: controller.logs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Text(
                controller.logs[index],
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            );
          },
        ),
      ),
    );
  }
}
