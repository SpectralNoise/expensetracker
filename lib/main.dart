import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Asegúrate de que este archivo esté en tu proyecto
import 'screens/login.dart';
import 'screens/dashboard_screen.dart'; // Asegúrate de importar tu archivo de Dashboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Finanzas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Pantalla de inicio
      routes: {
        '/dashboard': (context) => Dashboard(
              toggleTheme: () {}, // Provide a function for toggling the theme
              isDarkTheme: true, // Provide a boolean value for the theme state
            ), // Define la ruta al Dashboard
      },
    );
  }
}
