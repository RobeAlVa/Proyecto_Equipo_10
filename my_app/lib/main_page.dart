import 'dart:convert';
import 'dart:typed_data';
import 'package:my_app/widgets/button.dart';
import 'package:my_app/chart_line.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  String times = '0';

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _receiveData() {
    const splitter = LineSplitter();

    _connection?.input?.listen((Uint8List data) {
      if (data.length > 2) {
        debugPrint('Raw data: $data');
        debugPrint('ascii data: ${ascii.decode(data)}');
        debugPrint('String data: ${String.fromCharCodes(data)}');
        var stringList = splitter.convert(String.fromCharCodes(data));
        debugPrint(
          'Splitter string data: $stringList');
        var largestVal = int.parse(stringList[0]);
        for (var i = 0; i < stringList.length ; i++) {
          var stringListInt = int.parse(stringList[i]);
          if (stringListInt > largestVal) {
            largestVal = stringListInt;
          }
        }
        debugPrint('Unique value: $largestVal');
        debugPrint('--------------------------------');
        setState(() =>
            times = largestVal.toString());
      }
    });
  }

  void _sendData(String data) {
    if (_connection?.isConnected ?? false) {
      _connection?.output.add(ascii.encode(data));
    }
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }


  @override
  void initState() {
    super.initState();
    _requestPermission();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        centerTitle: true,
        backgroundColor: Colors.yellow,
        title: const Text('MuscleMov Bluetooth'),
      ),
      body: Column(
        children: [
          _infoDevice(),
          Image(
            image: AssetImage('assets/LogoNegro.jpeg')
          ),
          Expanded(child: _listDevices()),
          _inputSerial(),
          LiveLineChart(times),
        ],)
    );
  }

  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      tileColor: Colors.indigo.shade900,
      title: Text(
        _bluetoothState ? "Bluetooth enabled" : "Bluetooth disabled",
      )
    );
  }


  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.blue,
      title: Text("Connected to: ${_deviceConnected?.name ?? "None"}"),
      trailing: _connection?.isConnected ?? false
          ? TextButton(
            onPressed: () async {
              await _connection?.finish();
              setState(() => _deviceConnected = null);
            },
            child: const Text("Disconnect"),
          )
        : TextButton(
          onPressed: _getDevices,
          child: const Text('See devices'),
        )
    );
  }

  Widget _listDevices() {
    return _isConnecting
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
      child: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            ...[
              for (final device in _devices)
              ListTile(
                title: Text(device.name ?? device.address),
                trailing: TextButton(
                  child: const Text('Connect'),
                  onPressed: () async {
                    setState(() => _isConnecting = true);

                    _connection = await BluetoothConnection.toAddress(
                        device.address);
                    _deviceConnected = device;
                    _devices = [];
                    _isConnecting = false;

                    _receiveData();

                    setState(() {});
                  },
                )
              )
            ]
          ]
        )
      )
    );
  }

  Widget _inputSerial() {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity(vertical: -3),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "Value = $times",
          style: const TextStyle(fontSize: 18.0),
        )
      )
    );
  }



}