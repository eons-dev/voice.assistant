import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(EVA());

class EVA extends StatelessWidget {
  static const platform = MethodChannel('picovoice_wakeword_channel');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Picovoice Wakeword App'),
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

  Future<void> _startWakewordService() async {
    try {
      final String result = await EVA.platform.invokeMethod('startWakewordService');
      setState(() {
        _log = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _log = "Failed to start service: '${e.message}'.";
      });
    }
  }

  Future<void> _stopWakewordService() async {
    try {
      final String result = await EVA.platform.invokeMethod('stopWakewordService');
      setState(() {
        _log = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _log = "Failed to stop service: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _startWakewordService,
          child: Text('Start Wakeword Service'),
        ),
        ElevatedButton(
          onPressed: _stopWakewordService,
          child: Text('Stop Wakeword Service'),
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
