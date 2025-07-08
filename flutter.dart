import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindWave EEG Reader',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const EEGHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EEGHomePage extends StatefulWidget {
  const EEGHomePage({super.key});

  @override
  State<EEGHomePage> createState() => _EEGHomePageState();
}

class _EEGHomePageState extends State<EEGHomePage> {
  BluetoothConnection? _connection;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int attention = 0;
  int meditation = 0;
  int blink = 0;
  String lastCommand = '';

  final String espIP = "http://192.168.4.1"; // Change if different

  Map<String, int> brainWaves = {
    'delta': 0,
    'theta': 0,
    'lowAlpha': 0,
    'highAlpha': 0,
    'lowBeta': 0,
    'highBeta': 0,
    'lowGamma': 0,
    'midGamma': 0,
  };

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> connectToMindWave() async {
    final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();

    final mindWaveDevice = bondedDevices.firstWhere(
      (d) => d.name?.toLowerCase() == "mindwave mobile",
      orElse: () => BluetoothDevice(address: '', name: 'invalid'),
    );

    if (mindWaveDevice.address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("MindWave Mobile not paired.")),
      );
      return;
    }

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(mindWaveDevice.address);
      if (!mounted) return;
      setState(() => _connection = connection);

      connection.input?.listen(_onDataReceived).onDone(() {
        if (mounted) {
          setState(() => _connection = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Disconnected from MindWave")),
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connected to ${mindWaveDevice.name}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection failed: $e")),
        );
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    for (var b in data) {
      if (b == 0x04 && data.length > data.indexOf(b) + 1) {
        attention = data[data.indexOf(b) + 1];
      } else if (b == 0x05 && data.length > data.indexOf(b) + 1) {
        meditation = data[data.indexOf(b) + 1];
      } else if (b == 0x16 && data.length > data.indexOf(b) + 1) {
        blink = data[data.indexOf(b) + 1];
      } else if (b == 0x83 && data.length >= 32) {
        final i = data.indexOf(b) + 3;
        try {
          brainWaves['delta'] = _toInt(data.sublist(i, i + 3));
          brainWaves['theta'] = _toInt(data.sublist(i + 3, i + 6));
          brainWaves['lowAlpha'] = _toInt(data.sublist(i + 6, i + 9));
          brainWaves['highAlpha'] = _toInt(data.sublist(i + 9, i + 12));
          brainWaves['lowBeta'] = _toInt(data.sublist(i + 12, i + 15));
          brainWaves['highBeta'] = _toInt(data.sublist(i + 15, i + 18));
          brainWaves['lowGamma'] = _toInt(data.sublist(i + 18, i + 21));
          brainWaves['midGamma'] = _toInt(data.sublist(i + 21, i + 24));
        } catch (_) {
          // Ignore malformed
        }
      }
    }

    // EEG-based decision logic
    String commandToSend = "stop";

    if (attention > 70) {
      commandToSend = "forward";
    } else if (meditation > 60) {
      commandToSend = "reverse";
    } else if (blink > 50) {
      commandToSend = "left";
    }

    if (commandToSend != lastCommand) {
      lastCommand = commandToSend;
      sendCommandToESP(commandToSend);
    }

    if (mounted) setState(() {});
  }

  int _toInt(List<int> bytes) {
    return (bytes[0] << 16) | (bytes[1] << 8) | bytes[2];
  }

  Future<void> sendCommandToESP(String command) async {
    final url = Uri.parse("$espIP/control?cmd=$command");

    try {
      await http.get(url);
      debugPrint("Sent: $command");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("HTTP Error: $e")),
        );
      }
    }
  }

  Future<void> playMusic() async {
    try {
      await _audioPlayer.setAsset('assets/music.mp3');
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio error: $e')),
        );
      }
    }
  }

  Future<void> stopMusic() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _connection?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _dataBlock(String label, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(value.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MindWave EEG Monitor")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: connectToMindWave,
              icon: const Icon(Icons.bluetooth_connected),
              label: const Text("Connect to MindWave"),
            ),
            const SizedBox(height: 10),
            _dataBlock("Attention", attention),
            _dataBlock("Meditation", meditation),
            _dataBlock("Blink Strength", blink),
            const Divider(),
            ...brainWaves.entries.map((e) => _dataBlock(e.key, e.value)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play Music"),
                  onPressed: playMusic,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop Music"),
                  onPressed: stopMusic,
                ),
              ],
            ),
            const Divider(),
            Text("Last Command Sent: $lastCommand",
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
