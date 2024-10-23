import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static const platform = MethodChannel('picovoice_wakeword_channel');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Eons Voice Assistant'),
        ),
        body: WakewordScreen(),
      ),
    );
  }
}

class WakewordScreen extends StatefulWidget {
  @override
  _WakewordScreenState createState() => _WakewordScreenState();
}

class _WakewordScreenState extends State<WakewordScreen> {
  String _log = "Logs will appear here";
  String _apiKey = "";
  String _wakewordFilePath = "";
  String _serverUrl = "";

  Future<void> _initializeWakeword() async {
    try {
      final String result = await MyApp.platform.invokeMethod(
        'initializeWakeword', 
        {
          'apiKey': _apiKey,
          'wakewordPath': _wakewordFilePath,
          'serverUrl': _serverUrl,
        }
      );
      setState(() {
        _log = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _log = "Failed to initialize wakeword: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Picovoice API Key'),
          onChanged: (value) => _apiKey = value,
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Wakeword File Path'),
          onChanged: (value) => _wakewordFilePath = value,
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Server URL'),
          onChanged: (value) => _serverUrl = value,
        ),
        ElevatedButton(
          onPressed: _initializeWakeword,
          child: Text('Initialize Wakeword'),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Text(_log),
          ),
        ),
      ],
    );
  }
}
