import 'package:flutter/material.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() =>
      _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState
    extends State<DeviceConnectionScreen> {
  bool hardwareMode = false;
  bool connected = false;

  void toggleHardwareMode(bool value) {
    setState(() {
      hardwareMode = value;
    });
  }

  void connectDevice() {
    setState(() {
      connected = !connected;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected
              ? 'Wristband connected successfully'
              : 'Wristband disconnected',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),

      appBar: AppBar(
        title: const Text('Device & Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hardwareMode
                        ? Icons.watch
                        : Icons.phone_android,
                    color: Colors.white,
                    size: 45,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    hardwareMode
                        ? 'Hardware Mode'
                        : 'Software Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    hardwareMode
                        ? 'Using wearable sensor data'
                        : 'Using manual symptom tracking',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile(
                value: hardwareMode,
                onChanged: toggleHardwareMode,
                title: const Text(
                  'Use Wristband',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  hardwareMode
                      ? 'Hardware tracking enabled'
                      : 'Manual tracking enabled',
                ),
                secondary: const Icon(
                  Icons.watch,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (hardwareMode) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 55,
                        color: connected
                            ? Colors.green
                            : Colors.grey,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        connected
                            ? 'Wristband Connected'
                            : 'Wristband Not Connected',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        connected
                            ? 'Sensor data can be received from the wearable.'
                            : 'Connect your Parkinson Care wristband to begin sensor tracking.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: connectDevice,
                          icon: Icon(
                            connected
                                ? Icons.bluetooth_disabled
                                : Icons.bluetooth,
                          ),
                          label: Text(
                            connected
                                ? 'Disconnect'
                                : 'Connect Wristband',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 45,
                        color: Colors.blue,
                      ),

                      SizedBox(height: 15),

                      Text(
                        'Software Tracking Active',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(
                        'You can track symptoms such as tremor, walking difficulty, balance, speech, sleep and mood without any wearable device.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 25),

            const Text(
              'Supported Sensors',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _sensorCard(
              icon: Icons.vibration,
              title: 'Accelerometer',
              subtitle: 'Movement and tremor analysis',
            ),

            _sensorCard(
              icon: Icons.rotate_right,
              title: 'Gyroscope',
              subtitle: 'Rotation and movement stability',
            ),

            _sensorCard(
              icon: Icons.favorite,
              title: 'Heart Rate',
              subtitle: 'Heart rate monitoring',
            ),

            _sensorCard(
              icon: Icons.bloodtype,
              title: 'SpO₂',
              subtitle: 'Blood oxygen monitoring',
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hardware integration will use Bluetooth Low Energy (BLE) to communicate with the ESP32-based wristband.',
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

  Widget _sensorCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}