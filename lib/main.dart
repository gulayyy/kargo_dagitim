// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'screens/home_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/simulation_history_screen.dart';
import 'screens/map_screen.dart';
import 'screens/add_city_screen.dart';
import 'screens/city_list_screen.dart';

void main() {
  Intl.defaultLocale = 'tr_TR';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kargo Yönlendirme',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/simulate': (context) => const SimulationScreen(),
        '/history': (context) => const SimulationHistoryScreen(),
        '/map': (context) => const MapScreen(),
        '/addCity': (context) => const AddCityScreen(),
        '/cityList': (context) => const CityListScreen(),
      },
    );
  }
}