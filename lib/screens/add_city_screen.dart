// lib/screens/add_city_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/mongo_service.dart';
import '../services/city_service.dart';

class AddCityScreen extends StatefulWidget {
  const AddCityScreen({super.key});

  @override
  State<AddCityScreen> createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> {
  final TextEditingController _controller = TextEditingController();
  final MongoService db = MongoService();
  LatLng? selectedLocation;
  List<Marker> markers = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = false;
  bool isSearching = false;
  List<String> turkishCities = [];
  List<String> filteredCities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
    turkishCities = CityService.getAllCities();
    filteredCities = [];
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
        markers = [];
        
        for (var city in cities) {
          double lat = 0.0;
          double lng = 0.0;
          
          if (city.containsKey('latitude') && city['latitude'] != null) {
            lat = double.parse(city['latitude'].toString());
          }
          
          if (city.containsKey('longitude') && city['longitude'] != null) {
            lng = double.parse(city['longitude'].toString());
          }
          
          if (lat != 0.0 || lng != 0.0) {
            markers.add(
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(lat, lng),
                child: Column(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    Text(city['name'] ?? city['_id'] ?? 'Bilinmeyen', 
                         style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
            );
          }
        }
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

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCities = [];
        isSearching = false;
      } else {
        isSearching = true;
        filteredCities = turkishCities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectCity(String cityName) {
    setState(() {
      _controller.text = cityName;
      isSearching = false;
      filteredCities = [];
      
      // Şehrin koordinatlarını al
      final coordinates = CityService.getCityCoordinates(cityName);
      if (coordinates != null) {
        selectedLocation = coordinates;
        
        // Haritada göster
        List<Marker> updatedMarkers = [...markers];
        
        // Önceki seçilen konumu kaldır
        updatedMarkers.removeWhere((marker) => 
          marker.child is Column && 
          (marker.child as Column).children.any((child) => 
            child is Text && 
            (child.data == "Yeni Şehir" || child.data == cityName)
          )
        );
        
        // Yeni seçilen konumu ekle
        updatedMarkers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: coordinates,
            child: Column(
              children: [
                const Icon(Icons.add_location, color: Colors.green),
                Text(cityName),
              ],
            ),
          ),
        );
        
        markers = updatedMarkers;
      }
    });
  }

  Future<void> _addCity() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir şehir adı girin")),
      );
      return;
    }

    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen haritadan konum seçin veya listeden bir şehir seçin")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await db.connect();
      
      // Şehrin zaten eklenip eklenmediğini kontrol et
      final existingCities = await db.fetchCities();
      final cityExists = existingCities.any((city) => 
        city['name'] == _controller.text || city['_id'] == _controller.text
      );
      
      if (cityExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu şehir zaten eklenmiş!")),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Şehri ekle
      await db.addCity(
        _controller.text.trim(),
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şehir başarıyla eklendi!")),
      );
      
      _controller.clear();
      selectedLocation = null;
      await _loadCities(); // Haritayı güncelle
      
      // Şehir listesi ekranına git
      Navigator.pushNamed(context, '/cityList');
      
    } catch (e) {
      print("Şehir ekleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şehir eklenirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şehir Ekle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.pushNamed(context, '/cityList'),
            tooltip: "Şehir Listesi",
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: "Şehir adı",
                      hintText: "Şehir adı girin veya listeden seçin",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _controller.clear();
                                filteredCities = [];
                                isSearching = false;
                              });
                            },
                          )
                        : null,
                    ),
                    onChanged: _filterCities,
                  ),
                  
                  if (isSearching && filteredCities.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredCities[index]),
                            onTap: () => _selectCity(filteredCities[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(39.9334, 32.8597), // Türkiye merkezi
                  initialZoom: 6.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      selectedLocation = point;
                      // Yeni seçilen konumu göster
                      List<Marker> updatedMarkers = [...markers];
                      
                      // Önceki seçilen konumu kaldır (varsa)
                      updatedMarkers.removeWhere((marker) => 
                        marker.child is Column && 
                        (marker.child as Column).children.any((child) => 
                          child is Text && 
                          (child.data == "Yeni Şehir" || child.data == _controller.text)
                        )
                      );
                      
                      // Yeni seçilen konumu ekle
                      updatedMarkers.add(
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: point,
                          child: Column(
                            children: [
                              const Icon(Icons.add_location, color: Colors.blue),
                              Text(_controller.text.isEmpty ? "Yeni Şehir" : _controller.text),
                            ],
                          ),
                        ),
                      );
                      
                      markers = updatedMarkers;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addCity,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text("Şehri Ekle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}