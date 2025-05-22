// lib/screens/simulation_history_screen.dart
import 'package:flutter/material.dart';
import '../services/mongo_service.dart';
import 'package:intl/intl.dart';

class SimulationHistoryScreen extends StatefulWidget {
  const SimulationHistoryScreen({super.key});

  @override
  State<SimulationHistoryScreen> createState() =>
      _SimulationHistoryScreenState();
}

class _SimulationHistoryScreenState extends State<SimulationHistoryScreen> {
  List<Map<String, dynamic>> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final db = MongoService();
      await db.connect();
      final collection = db.db.collection('simulations');

      // Önce tüm verileri al
      final result = await collection.find().toList();

      // Sonra bellek içinde sırala
      result.sort((a, b) {
        final dateA = a['date'] as String;
        final dateB = b['date'] as String;
        return dateB.compareTo(dateA); // Azalan sıralama için
      });

      setState(() {
        logs = result;
      });
    } catch (e) {
      print("Geçmiş yükleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Geçmiş yüklenirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getAlgorithmName(String algorithm) {
    switch (algorithm) {
      case "BFS":
        return "En Hızlı Rota";
      case "DFS":
        return "Alternatif Rota";
      case "UCS":
        return "En Kısa Mesafe";
      default:
        return algorithm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geçmiş Rotalar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: "Yenile",
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : logs.isEmpty
              ? const Center(
                child: Text(
                  "Henüz kaydedilmiş rota bulunmuyor.",
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final totalDistance = log['totalDistance'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          log['algorithm'] == "UCS"
                              ? Icons.directions_car
                              : Icons.route,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "${log['from']} → ${log['to']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rota Tipi: ${_getAlgorithmName(log['algorithm'])}",
                          ),
                          Text("Mesafe: $totalDistance km"),
                          Text("Tarih: ${_formatDate(log['date'])}"),
                          Text(
                            "Güzergah: ${(log['result'] as List).join(' → ')}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/simulate",
                          arguments: {
                            "fromCity": log['from'],
                            "toCity": log['to'],
                          },
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
