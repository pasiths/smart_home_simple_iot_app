import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: IoTControlScreen(),
    );
  }
}

class IoTControlScreen extends StatefulWidget {
  @override
  _IoTControlScreenState createState() => _IoTControlScreenState();
}

class _IoTControlScreenState extends State<IoTControlScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool mode = true; // Default to Auto Mode
  bool systemActive = false;
  bool fanState = false;
  bool ldr1LEDState = false;
  double temperature = 0.0; // Variable to store temperature

  @override
  void initState() {
    super.initState();
    _fetchInitialState();
    _listenToDatabase(); // Start listening for real-time updates
  }

  Future<void> _fetchInitialState() async {
    final modeSnapshot = await _dbRef.child('mode').get();
    final systemSnapshot = await _dbRef.child('systemActive').get();
    final fanSnapshot = await _dbRef.child('fanState').get();
    final ldr1LEDSnapshot = await _dbRef.child('ldr1LEDState').get();
    final temperatureSnapshot = await _dbRef.child('temperature').get(); // Fetch temperature

    setState(() {
      mode = (modeSnapshot.value as bool) ?? true;
      systemActive = (systemSnapshot.value as bool) ?? false;
      fanState = (fanSnapshot.value as bool) ?? false;
      ldr1LEDState = (ldr1LEDSnapshot.value as bool) ?? false;
      temperature = (temperatureSnapshot.value as double) ?? 0.0; // Set temperature
    });
  }

  void _listenToDatabase() {
    _dbRef.child('temperature').onValue.listen((event) {
      setState(() {
        temperature = (event.snapshot.value as double) ?? 0.0; // Update temperature in real time
      });
    });
  }

  void _updateDatabase(String key, dynamic value) {
    _dbRef.child(key).set(value);
    setState(() {
      if (key == 'mode') mode = value;
      if (key == 'systemActive') systemActive = value;
      if (key == 'fanState') fanState = value;
      if (key == 'ldr1LEDState') ldr1LEDState = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Controller'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Temperature: ${temperature.toStringAsFixed(1)} °C', // Display temperature
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text('System: ${systemActive ? "ON" : "OFF"}'),
              value: systemActive,
              onChanged: (value) {
                _updateDatabase('systemActive', value);
                if (systemActive) {
                  _updateDatabase('mode', true);
                }
              },
            ),
            if (systemActive) ...[
              SwitchListTile(
                title: Text('Mode: ${mode ? "Auto" : "Manual"}'),
                value: mode,
                onChanged: (value) {
                  _updateDatabase('mode', value);
                  if (!mode) {
                    _updateDatabase('fanState', false);
                    _updateDatabase('ldr1LEDState', false);
                  }
                },
              ),
              if (!mode) ...[
                SwitchListTile(
                  title: const Text('Fan State'),
                  value: fanState,
                  onChanged: systemActive
                      ? (value) => _updateDatabase('fanState', value)
                      : null,
                ),
                SwitchListTile(
                  title: const Text('LDR LED State'),
                  value: ldr1LEDState,
                  onChanged: systemActive
                      ? (value) => _updateDatabase('ldr1LEDState', value)
                      : null,
                ),
              ] else
                const Text(
                  'Auto Mode is active. Sensor-based control in progress.',
                  style: TextStyle(color: Colors.grey),
                ),
            ] else
              const Text(
                'System is inactive. Please turn it on to control devices.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
