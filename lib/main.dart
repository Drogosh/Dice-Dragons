import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/item.dart';
import 'screens/auth/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase (защищаемся от повторной инициализации)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Firebase уже инициализирован нативной конфигурацией
      debugPrint('⚠️ Firebase уже инициализирован - пропускаем повторную инициализацию');
    }
  } catch (e) {
    debugPrint('⚠️ Ошибка инициализации Firebase: $e');
  }

  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрация адаптеров для Hive для enum'ов
  Hive.registerAdapter(ItemTypeAdapter());
  Hive.registerAdapter(DamageTypeAdapter());
  Hive.registerAdapter(ArmorTypeAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice & Dragons',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

