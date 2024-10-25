import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(Eva());

class Eva extends StatelessWidget {
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
  String _serverUrl = "";

  @override
  void initState() {
    super.initState();

    Eva.platform.setMethodCallHandler((call) async {
      if (call.method == "wakewordDetected") {
        setState(() {
          _log = "Wakeword detected!";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Server URL'),
          onChanged: (value) => _serverUrl = value,
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
