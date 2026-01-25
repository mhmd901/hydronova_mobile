import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/controllers/bluetooth_controller.dart';

class BluetoothView extends StatelessWidget {
  const BluetoothView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BluetoothController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: controller.enableBluetooth,
                    child: const Text('Enable Bluetooth'),
                  ),
                  ElevatedButton(
                    onPressed: controller.loadPairedDevices,
                    child: const Text('Refresh Paired Devices'),
                  ),
                  ElevatedButton(
                    onPressed: controller.status.value ==
                            ConnectionStatus.connected
                        ? controller.disconnect
                        : null,
                    child: const Text('Disconnect'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: controller.statusColor(),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      controller.statusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paired Devices',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Obx(
                        () => controller.pairedDevices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No paired devices.\nPair HC-05 first in Android Bluetooth settings (PIN 1234/0000).',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                itemCount: controller.pairedDevices.length,
                                itemBuilder: (context, index) {
                                  final device =
                                      controller.pairedDevices[index];
                                  final name = device.name?.isNotEmpty == true
                                      ? device.name!
                                      : 'Unknown';
                                  final isConnected = controller.status.value ==
                                          ConnectionStatus.connected &&
                                      controller.selectedDevice.value?.address ==
                                          device.address;
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
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
                                              onPressed: () =>
                                                  controller.connect(device),
                                              child: const Text(
                                                'Connect',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
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
                              child: Text(controller.logs[index]),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
