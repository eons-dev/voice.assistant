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

		// Initialize logging
		Logger.root.level = Level.ALL;
		Logger.root.onRecord.listen((record) {
			print(record.message);
			setState(() {
				_logText += "\n${record.message}";
			});
		});

		// Start listening for wakeword
		_startWakewordDetection();
	}

	void _startWakewordDetection() {
		Eva.platform.setMethodCallHandler((call) async {
			if (call.method == "wakewordDetected") {
				_log.info("Wakeword detected!");
				await _handleWakewordDetection();
			}
		});

		_toggleWakeword(true);
	}

	// Handles wakeword detection, stopping the wakeword service and starting the recording
	Future<void> _handleWakewordDetection() async {
		await _toggleWakeword(false); // Stop wakeword detection to free up the mic
		await _recordAndUpload(); // Start recording and upload the audio
		_toggleWakeword(true); // Restart wakeword detection after upload
	}

	Future<void> _toggleWakeword(bool start) async {
		if (start) {
			try {
				final String result =
						await Eva.platform.invokeMethod('initializeWakeword', {
					'accessKey': _accessKey,
				});
				_log.info(result);
				setState(() {
					isListening = true;
				});
			} on PlatformException catch (e) {
				_log.info("Failed to initialize wakeword: '${e.message}'.");
			}
		} else {
			try {
				await Eva.platform.invokeMethod('stopWakeword');
				_log.info("Wakeword detection stopped.");
				setState(() {
					isListening = false;
				});
			} on PlatformException catch (e) {
				_log.info("Failed to stop wakeword detection: '${e.message}'.");
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
				const RecordConfig(
						encoder: AudioEncoder.wav, sampleRate: 44100, bitRate: 128000),
				path: audioFilePath,
			);

			_log.info("Listening for silence...");
			await _monitorSilence(audioFilePath); // Now synchronous
		} catch (e) {
			_log.info("Recording error: $e");
		}
	}

	// Synchronously waits for silence before stopping recording and uploading
	Future<void> _monitorSilence(String filePath) async {
		_silenceTimer?.cancel();

		Completer<void> completer = Completer();

		_silenceTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
			final amplitude = await _audioRecorder.getAmplitude();

			if (amplitude.current < -80) {
				_log.info("Silence detected.");
				await _audioRecorder.stop(); // Stop recording
				await _uploadAudio(filePath); // Upload file synchronously
				_silenceTimer?.cancel(); // Cancel timer after upload
				completer.complete(); // Complete the future to exit the loop
			}
		});

		// Wait for the timer to complete the recording/upload process
		return completer.future;
	}

	Future<void> _uploadAudio(String audioFilePath) async {
		// Validate and upload to server
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
						onPressed: () => _toggleWakeword(!isListening),
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
