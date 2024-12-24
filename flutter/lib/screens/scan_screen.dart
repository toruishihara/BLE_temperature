import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';
import '../model/sqlite_data.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  static int _periodSecond = 5*60;
  bool _timerActive = false;
  late Timer _timer;
  bool _connecting = false;
  DateTime _connectingDate = DateTime.now().subtract(Duration(seconds: _periodSecond));

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      debugPrint("_scanResultsSubscription listen mounted=$mounted results.length=${results.length}");
      try {
        for (int i = 0; i < results.length; i++) {
          ScanResult item = results[i];
          Duration diff = DateTime.now().difference(_connectingDate);
          if (item.device.advName.startsWith("ESP32_") && _connecting == false && diff.inSeconds > _periodSecond) {
            _connecting = true;
            _connectingDate = DateTime.now();
            //Future.delayed(Duration(seconds: 1), () {
              connectAndReadTemperature(item.device);
            //});
            break;
          }
        }
      } catch (e, stack) {
        debugPrint("Exception in loop: $e\n$stack");
      }
      _scanResults = results;
      if (mounted) {
        setState(() {
        });
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {
          debugPrint("in _isScanningSubscription setState");
        });
      }
    });

    // Start the periodic timer
    if (_timerActive == false) {
      _timerActive = true;
      _timer = Timer.periodic(Duration(seconds: _periodSecond), (timer) {
        if (!_isScanning) {
          debugPrint("TNI ${DateTime.now()}: Scanning is inactive. Restarting scan...");
          onScanPressed();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("TNI didUpdateWidget: Widget updated");
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _timer.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      // `withServices` is required on iOS for privacy purposes, ignored on android.
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
      print(e);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
      print(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
      print(e);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
    });
    MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device), settings: RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context).push(route);
  }

  double listToFloat32(List<int> bytes, {bool isLittleEndian = true}) {
    if (bytes.length != 4) {
      throw ArgumentError("The input list must have exactly 4 bytes.");
    }

    // Convert the List<int> to a Uint8List
    Uint8List uint8List = Uint8List.fromList(bytes);

    // Wrap the Uint8List in a ByteData object
    ByteData byteData = ByteData.sublistView(uint8List);

    // Read the float value
    return byteData.getFloat32(0, isLittleEndian ? Endian.little : Endian.big);
  }

  Future<void> connectAndReadTemperature(BluetoothDevice device) async {
    try {
      // Step 1: Connect to the device
      print('Connecting to device: ${device.advName}');
      await device.connect();
      print('Connected to device');

      // Step 2: Discover services
      print('Discovering services...');
      List<BluetoothService> services = await device.discoverServices();
      print('Services discovered: ${services.length}');

      // Step 3: Find the temperature service and characteristic
      BluetoothCharacteristic? tempCharacteristic;

      for (BluetoothService service in services) {
        print('Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print('Characteristic UUID: ${characteristic.uuid}');
          if (characteristic.uuid.toString() == "2a1c") {
            tempCharacteristic = characteristic;
            break;
          }
        }
        if (tempCharacteristic != null) break;
      }

      if (tempCharacteristic == null) {
        print('Temperature characteristic not found.');
        return;
      }

      // Step 4: Read the characteristic value
      print('Reading temperature characteristic...');
      List<int> value = await tempCharacteristic.read();
      print('Raw value: $value');

      // Convert the raw value to a meaningful temperature (example: Celsius)
      double temperature = listToFloat32(value); // Adjust this based on your device protocol
      debugPrint('TNI Room temperature: $temperature°C');

      // Get the current time
      DateTime now = DateTime.now();
      String formattedTime = now.toIso8601String();

      // Access the database
      final db = await DatabaseHelper.instance.database;

      // Insert data
      await db.insert('temperature', {'timestamp': formattedTime, 'temp_value': temperature.toStringAsFixed(1)});

      // Retrieve data
      final results = await db.query('temperature');
      debugPrint('TNI Database Results: $results');

    } catch (e) {
      debugPrint('TNI Error: $e');
    } finally {
      // Disconnect the device
      debugPrint('TNI Disconnecting from device...');
      await device.disconnect();
      _connecting = false;
      debugPrint('TNI Disconnected');
    }
  }

  Future onRefresh() {
    print("TNI onRefresh");
    debugPrint("TNI2 onRefresh");
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(child: const Text("SCAN"), onPressed: onScanPressed);
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: d),
                settings: RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices(scan_screen)', style: TextStyle(fontSize: 10.0),),
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
