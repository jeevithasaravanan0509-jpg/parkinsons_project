import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  bool isScanning = false;
  bool isConnecting = false;

  BluetoothDevice? connectedDevice;

  final List<BluetoothDevice> discoveredDevices = [];

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  void initState() {
    super.initState();

    _listenForScanResults();
  }

  void _listenForScanResults() {
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        if (!mounted) return;

        setState(() {
          for (final result in results) {
            final device = result.device;

            final alreadyExists = discoveredDevices.any(
              (existingDevice) =>
                  existingDevice.remoteId == device.remoteId,
            );

            if (!alreadyExists) {
              discoveredDevices.add(device);
            }
          }
        });
      },
      onError: (error) {
        if (!mounted) return;

        _showMessage(
          'Bluetooth scanning error: $error',
        );
      },
    );
  }

  Future<void> toggleHardwareMode(bool value) async {
    setState(() {
      hardwareMode = value;
    });

    if (!value) {
      await _disconnectDevice();
    }
  }

  Future<void> _scanForDevices() async {
    if (isScanning) return;

    try {
      final bluetoothState = await FlutterBluePlus.adapterState.first;

      if (bluetoothState != BluetoothAdapterState.on) {
        _showMessage(
          'Please turn on Bluetooth and try again.',
        );
        return;
      }

      setState(() {
        discoveredDevices.clear();
        isScanning = true;
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
      );

      if (!mounted) return;

      setState(() {
        isScanning = false;
      });

      if (discoveredDevices.isEmpty) {
        _showMessage(
          'No BLE devices found. Make sure your ESP32 is powered on and advertising.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isScanning = false;
      });

      _showMessage(
        'Unable to scan for Bluetooth devices: $e',
      );
    }
  }

  Future<void> _connectToDevice(
    BluetoothDevice device,
  ) async {
    if (isConnecting) return;

    try {
      setState(() {
        isConnecting = true;
      });

      await FlutterBluePlus.stopScan();

      await _connectionSubscription?.cancel();

      _connectionSubscription =
          device.connectionState.listen((state) {
        if (!mounted) return;

        if (state == BluetoothConnectionState.connected) {
          setState(() {
            connected = true;
            isConnecting = false;
            connectedDevice = device;
          });
        } else if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            connected = false;
            isConnecting = false;
            connectedDevice = null;
          });
        }
      });

      await device.connect(
        timeout: const Duration(seconds: 15),
      );

      if (!mounted) return;

      setState(() {
        connected = true;
        isConnecting = false;
        connectedDevice = device;
      });

      _showMessage(
        '${_deviceName(device)} connected successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        connected = false;
        isConnecting = false;
        connectedDevice = null;
      });

      _showMessage(
        'Could not connect to the device: $e',
      );
    }
  }

  Future<void> _disconnectDevice() async {
    final device = connectedDevice;

    if (device == null) {
      setState(() {
        connected = false;
      });
      return;
    }

    try {
      await device.disconnect();
    } catch (_) {
      // Device may already be disconnected.
    }

    if (!mounted) return;

    setState(() {
      connected = false;
      connectedDevice = null;
    });

    _showMessage('Wristband disconnected.');
  }

  Future<void> _handleConnectionButton() async {
    if (connected) {
      await _disconnectDevice();
    } else {
      await _scanForDevices();
    }
  }

  String _deviceName(BluetoothDevice device) {
    final name = device.platformName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Unknown BLE Device';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();

    if (isScanning) {
      FlutterBluePlus.stopScan();
    }

    super.dispose();
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
            _buildModeHeader(),

            const SizedBox(height: 25),

            _buildModeSwitch(),

            const SizedBox(height: 20),

            if (hardwareMode)
              _buildHardwareSection()
            else
              _buildSoftwareSection(),

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
                      'Hardware integration uses Bluetooth Low Energy (BLE) to communicate with the ESP32-based wristband. Sensor readings will be connected after the ESP32 BLE protocol is configured.',
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

  Widget _buildModeHeader() {
    return Container(
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
            hardwareMode ? Icons.watch : Icons.phone_android,
            color: Colors.white,
            size: 45,
          ),

          const SizedBox(height: 15),

          Text(
            hardwareMode ? 'Hardware Mode' : 'Software Mode',
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
    );
  }

  Widget _buildModeSwitch() {
    return Card(
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
    );
  }

  Widget _buildHardwareSection() {
    return Column(
      children: [
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
                  connected && connectedDevice != null
                      ? _deviceName(connectedDevice!)
                      : 'Scan for your Parkinson Care wristband.',
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
                    onPressed: isConnecting
                        ? null
                        : _handleConnectionButton,
                    icon: isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            connected
                                ? Icons.bluetooth_disabled
                                : Icons.bluetooth_searching,
                          ),
                    label: Text(
                      isConnecting
                          ? 'Connecting...'
                          : connected
                              ? 'Disconnect'
                              : isScanning
                                  ? 'Scanning...'
                                  : 'Scan for Wristband',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (discoveredDevices.isNotEmpty) ...[
          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available BLE Devices',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          ...discoveredDevices.map(
            (device) => _buildDeviceTile(device),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(BluetoothDevice device) {
    final isThisDeviceConnected =
        connectedDevice?.remoteId == device.remoteId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            isThisDeviceConnected
                ? Icons.bluetooth_connected
                : Icons.bluetooth,
            color: isThisDeviceConnected
                ? Colors.green
                : Colors.blue,
          ),
        ),
        title: Text(
          _deviceName(device),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          device.remoteId.toString(),
        ),
        trailing: ElevatedButton(
          onPressed: isThisDeviceConnected || isConnecting
              ? null
              : () => _connectToDevice(device),
          child: Text(
            isThisDeviceConnected ? 'Connected' : 'Connect',
          ),
        ),
      ),
    );
  }

  Widget _buildSoftwareSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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