// lib/screens/city_list_screen.dart
import 'package:flutter/material.dart';
import '../services/mongo_service.dart';
import 'package:latlong2/latlong.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key});

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  final MongoService db = MongoService();
  List<Map<String, dynamic>> cities = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      await db.connect();
      final cityList = await db.fetchCities();
      setState(() {
        cities = cityList;
      });
    } catch (e) {
      print("Şehirleri yükleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şehirler yüklenirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredCities {
    if (searchQuery.isEmpty) {
      return cities;
    }
    
    return cities.where((city) {
      final name = city['name'] as String;
      return name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteCity(Map<String, dynamic> city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şehri Sil"),
        content: Text("${city['name']} şehrini silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        isLoading = true;
      });
      
      try {
        await db.connect();
        await db.deleteCity(city['name']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${city['name']} şehri silindi")),
        );
        
        await _loadCities();
      } catch (e) {
        print("Şehir silme hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Şehir silinirken hata oluştu: $e")),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şehir Listesi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCities,
            tooltip: "Yenile",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Şehir Ara",
                hintText: "Şehir adı girin",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredCities.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz şehir eklenmemiş veya arama sonucu bulunamadı.",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = filteredCities[index];
                      final lat = double.tryParse(city['latitude'].toString()) ?? 0.0;
                      final lng = double.tryParse(city['longitude'].toString()) ?? 0.0;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: const Icon(
                              Icons.location_city,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            city['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Konum: $lat, $lng"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.map, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context, 
                                    '/map',
                                    arguments: {'focusCity': city['name']},
                                  );
                                },
                                tooltip: "Haritada Göster",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCity(city),
                                tooltip: "Şehri Sil",
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context, 
                              '/simulate',
                              arguments: {'fromCity': city['name']},
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addCity'),
        child: const Icon(Icons.add_location_alt),
        tooltip: "Şehir Ekle",
      ),
    );
  }
}