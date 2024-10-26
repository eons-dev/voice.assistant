import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  runApp(Eva());
}

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
  String _accessKey = dotenv.env['PICOVOICE_ACCESS_KEY'] ?? ''; // Load default from .env

  bool isListening = false;

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

  Future<void> _toggleWakeword() async {
	if (isListening) {
	  // Stop wakeword detection
	  try {
		await Eva.platform.invokeMethod('stopWakeword');
		setState(() {
		  _log = "Wakeword detection stopped.";
		  isListening = false;
		});
	  } on PlatformException catch (e) {
		setState(() {
		  _log = "Failed to stop wakeword detection: '${e.message}'.";
		});
	  }
	} else {
	  // Start wakeword detection
	  try {
		final String result = await Eva.platform.invokeMethod('initializeWakeword', {
		  'accessKey': _accessKey
		});
		setState(() {
		  _log = result;
		  isListening = true;
		});
	  } on PlatformException catch (e) {
		setState(() {
		  _log = "Failed to initialize wakeword: '${e.message}'.";
		});
	  }
	}
  }

  @override
  Widget build(BuildContext context) {
	return Padding(
	  padding: const EdgeInsets.all(16.0),
	  child: Column(
		children: [
		  TextField(
			decoration: InputDecoration(labelText: 'Access Key'),
			onChanged: (value) => _accessKey = value,
			controller: TextEditingController(text: _accessKey),
		  ),
		  TextField(
			decoration: InputDecoration(labelText: 'Server URL'),
			onChanged: (value) => _serverUrl = value,
		  ),
		  SizedBox(height: 20),
		  ElevatedButton(
			onPressed: _toggleWakeword,
			child: Text(isListening ? 'Stop' : 'Start'),
		  ),
		  Expanded(
			child: SingleChildScrollView(
			  child: Text(_log),
			),
		  ),
		],
	  ),
	);
  }
}
