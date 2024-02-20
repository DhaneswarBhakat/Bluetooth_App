import 'package:flutter/material.dart'
    show
        AppBar,
        BorderRadius,
        BoxDecoration,
        BoxShadow,
        BuildContext,
        Colors,
        Container,
        DecoratedBox,
        EdgeInsets,
        ListTile,
        ListView,
        MaterialApp,
        RoundedRectangleBorder,
        Scaffold,
        State,
        StatefulWidget,
        StatelessWidget,
        Text,
        Widget,
        runApp;
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];
  final Map<BluetoothDevice, bool> rssiAvailable =
      {}; // Track RSSI availability

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check for location permission (required for Bluetooth scanning on Android)
    var status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      // Handle permission denial (e.g., show a message to the user)
      print('Location permission denied');
      return;
    }

    // Check for Bluetooth scanning permission
    status = await Permission.bluetoothScan.request();
    if (status != PermissionStatus.granted) {
      // Handle permission denial (e.g., show a message to the user)
      print('Bluetooth scanning permission denied');
      return;
    }

    _connectToDevice();
  }

  void _connectToDevice() async {
    // Proceed with Bluetooth scanning
    flutterBlue.startScan();
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        setState(() {
          devices.add(r.device);
          // Check for specific service/characteristic (if known)
          //if (/* some condition using service/characteristic UUID */) {
          rssiAvailable[r.device] = true;
        });
      }
    });

    // Optionally listen for connected devices to handle dynamic service discovery
    /*
    flutterBlue.connectedDevices.listen((connectedDevices) {
      for (BluetoothDevice device in connectedDevices) {
        device.discoverServices().then((services) {
          // Find a service that supports RSSI readings (optional)
          for (BluetoothService service in services) {
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              if (characteristic.uuid.toString().startsWith('00002a04')) {
                // Characteristic found for RSSI, subscribe to updates
                rssiAvailable[device] = true;
                // ... (handle characteristic subscription)
                break;
              }
            }
          }
        });
      }
    });
    */

    // Register for state changes of discovered devices
    for (BluetoothDevice device in devices) {
      device.state.listen((state) {
        if (state == BluetoothDeviceState.connected) {
          // Device is connected, potentially update service discovery if not handled before
          /*
          if (!rssiAvailable[device]) {
            device.discoverServices().then((services) {
              // ... (check for RSSI service/characteristic and update rssiAvailable)
            });
          }
          */
        } else {
          setState(() {
            rssiAvailable
                .remove(device); // Clear availability when disconnected
          });
        }
      });
    }
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.contains(r.device)) {
          // Check if device is already in the list
          setState(() {
            devices.add(r.device);
            rssiAvailable[r.device] =
                true; // Assume RSSI is available initially
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Device Connecting'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.blue[200],
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(color: Colors.blue, blurRadius: 2.0, spreadRadius: 0.5),
          ],
        ),
        child: ListView.separated(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            BluetoothDevice device = devices[index];
            String subtitle = '${device.id.toString()} (';

            if (rssiAvailable[device] ?? false) {
              subtitle += 'RSSI Available)';
            } else {
              subtitle += 'RSSI Unavailable)';
            }

            return ListTile(
              title: Text(device.name),
              subtitle: Text(subtitle),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0)),
              // Customize colors based on your preference
              tileColor: Colors.blue,
              textColor: Colors.black,
              // ... other ListTile properties
            );
          },
          separatorBuilder: (context, index) => Container(
            height: 1.0,
            color: Colors.grey[300],
            margin: EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
      ),
    );
  }
}
