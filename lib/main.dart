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
      debugShowCheckedModeBanner: false,
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
  double temperature = 0.0;

  @override
  void initState() {
    super.initState();
    _listenToRealTimeUpdates(); // Setup real-time listeners
  }

  void _listenToRealTimeUpdates() {
    // Listen for systemActive changes
    _dbRef.child('systemActive').onValue.listen((event) {
      setState(() {
        systemActive = (event.snapshot.value as bool) ?? false;
      });
    });

    // Listen for mode changes
    _dbRef.child('mode').onValue.listen((event) {
      setState(() {
        mode = (event.snapshot.value as bool) ?? true;
      });
    });

    // Listen for fanState changes
    _dbRef.child('fanState').onValue.listen((event) {
      setState(() {
        fanState = (event.snapshot.value as bool) ?? false;
      });
    });

    // Listen for ldr1LEDState changes
    _dbRef.child('ldr1LEDState').onValue.listen((event) {
      setState(() {
        ldr1LEDState = (event.snapshot.value as bool) ?? false;
      });
    });

    // Listen for temperature changes
    _dbRef.child('temperature').onValue.listen((event) {
      setState(() {
        temperature = (event.snapshot.value as double) ?? 0.0;
      });
    });
  }

  void _updateDatabase(String key, dynamic value) {
    _dbRef.child(key).set(value);
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
                  onChanged: (value) {
                    _updateDatabase('fanState', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Light State'),
                  value: ldr1LEDState,
                  onChanged: (value) {
                    _updateDatabase('ldr1LEDState', value);
                  },
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
