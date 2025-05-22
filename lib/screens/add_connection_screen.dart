// lib/screens/add_connection_screen.dart
import 'package:flutter/material.dart';
import '../services/mongo_service.dart';

class AddConnectionScreen extends StatefulWidget {
  const AddConnectionScreen({super.key});

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen> {
  String? fromCity;
  String? toCity;
  final costController = TextEditingController();
  final MongoService db = MongoService();
  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    await db.connect();
    final cityList = await db.fetchCities();
    setState(() {
      cities = cityList.map<String>((city) => city['name'] as String).toList();
    });
  }

  void _addConnection() async {
    if (fromCity == null || toCity == null || costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun!")),
      );
      return;
    }

    await db.connect();
    await db.addConnection(
      fromCity!,
      toCity!,
      int.parse(costController.text.trim()),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bağlantı eklendi!")),
    );
    
    setState(() {
      fromCity = null;
      toCity = null;
      costController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bağlantı Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: fromCity,
              decoration: const InputDecoration(labelText: "Nereden"),
              items: cities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  fromCity = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: toCity,
              decoration: const InputDecoration(labelText: "Nereye"),
              items: cities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  toCity = value;
                });
              },
            ),
            TextField(
              controller: costController,
              decoration: const InputDecoration(labelText: "Maliyet (km)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addConnection,
              child: const Text("Bağlantıyı Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}