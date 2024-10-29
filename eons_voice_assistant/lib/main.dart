import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger("EVA");

void main() async {
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
	String _logText = "Logs will appear here";
	String _serverUrl = "";
	String _accessKey = dotenv.env['PICOVOICE_ACCESS_KEY'] ?? '';
	final AudioRecorder _audioRecorder = AudioRecorder();
	Timer? _silenceTimer;
	bool isListening = false;

	@override
	void initState() {
		super.initState();

		// Initialize the logging package with a custom handler
		Logger.root.level = Level.ALL;
		Logger.root.onRecord.listen((record) {
			// Custom formatting for 'EVA' tag and message
			print(record.message);

			// Update the UI log text
			setState(() {
				_logText += "\n${record.message}"; // Append to the visual log
			});
		});

		Eva.platform.setMethodCallHandler((call) async {
			if (call.method == "wakewordDetected") {
				_log.info("Wakeword detected!");
				await _recordAndUpload();
			}
		});
	}

	Future<void> _toggleWakeword() async {
		if (isListening) {
			try {
				await Eva.platform.invokeMethod('stopWakeword');
				_log.info("Wakeword detection stopped.");
				setState(() {
					isListening = false;
				});
			} on PlatformException catch (e) {
				_log.info("Failed to stop wakeword detection: '${e.message}'.");
			}
		} else {
			try {
				final String result = await Eva.platform.invokeMethod('initializeWakeword', {
					'accessKey': _accessKey,
				});
				_log.info(result);
				setState(() {
					isListening = true;
				});
			} on PlatformException catch (e) {
				_log.info("Failed to initialize wakeword: '${e.message}'.");
			}
		}
	}

	Future<void> _recordAndUpload() async {
		if (!await _audioRecorder.hasPermission()) {
			_log.info("Permission denied for audio recording.");
			return;
		}

		_log.info("Recording started...");
		final directory = await getTemporaryDirectory();
		final audioFilePath = "${directory.path}/recorded_audio.wav";

		try {
			await _audioRecorder.start(
				const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, bitRate: 128000),
				path: audioFilePath,
			);

			_log.info("Listening for silence...");
			_monitorSilence(audioFilePath);
		} catch (e) {
			_log.info("Recording error: $e");
		}
	}

	Future<void> _monitorSilence(String filePath) async {
		_silenceTimer?.cancel();

		_silenceTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
			final amplitude = await _audioRecorder.getAmplitude();

			if (amplitude.current < -80) {
				await _audioRecorder.stop();
				await _uploadAudio(filePath);
			}
		});
	}

	Future<void> _uploadAudio(String audioFilePath) async {

		_log.info("Silence detected. Stopping recording...");

		// Check if server URL is set and valid
		if (_serverUrl.isEmpty) {
			_log.info("Server URL is empty. Cannot upload.");
			return;
		}

		final url = Uri.tryParse(_serverUrl);
		if (url == null || !url.hasScheme || !url.hasAuthority) {
			_log.info("Invalid server URL. Please check the format.");
			return;
		}

		_log.info("Uploading to $url...");
		final request = http.MultipartRequest('POST', url);
		request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

		final response = await request.send();
		if (response.statusCode == 200) {
			_log.info("Upload successful!");
		} else {
			_log.info("Upload failed: ${response.reasonPhrase}");
		}

		// Cancel the silence timer after uploading
		_silenceTimer?.cancel();
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
							child: Text(_logText), // Display cumulative log text here
						),
					),
				],
			),
		);
	}
}
