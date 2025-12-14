import 'package:flutter/material.dart';
import 'features/resources/presentation/resources_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'features/notifications/data/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (Requiere google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    // Inicializar servicio de notificaciones
    await NotificationService().initialize();
  } catch (e) {
    print(
      "Error inicializando Firebase: $e\n¿Agregaste el archivo google-services.json?",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ResourcesScreen(),
    );
  }
}
