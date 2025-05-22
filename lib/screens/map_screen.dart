// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/mongo_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MongoService db = MongoService();
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> connections = [];
  List<Marker> markers = [];
  List<Polyline> polylines = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await db.connect();
      final cityList = await db.fetchCities();
      final connectionList = await db.fetchConnections();
      
      setState(() {
        cities = cityList;
        connections = connectionList;
        
        // Şehir işaretleyicilerini oluştur
        markers = [];
        for (var city in cities) {
          // Null kontrolü yap
          double lat = 0.0;
          double lng = 0.0;
          
          if (city.containsKey('latitude') && city['latitude'] != null) {
            lat = double.parse(city['latitude'].toString());
          }
          
          if (city.containsKey('longitude') && city['longitude'] != null) {
            lng = double.parse(city['longitude'].toString());
          }
          
          markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(lat, lng),
              child: Column(
                children: [
                  const Icon(Icons.location_city, color: Colors.red),
                  Text(city['name'] ?? city['_id'] ?? 'Bilinmeyen', 
                       style: const TextStyle(fontSize: 12)),
                ],
              ),
            )
          );
        }
        
        // Bağlantı çizgilerini oluştur
        polylines = [];
        for (var connection in connections) {
          // Şehirleri bul
          final fromCityName = connection['from'];
          final toCityName = connection['to'];
          
          final fromCity = cities.firstWhere(
            (city) => (city['name'] == fromCityName || city['_id'] == fromCityName),
            orElse: () => {'latitude': 0.0, 'longitude': 0.0},
          );
          
          final toCity = cities.firstWhere(
            (city) => (city['name'] == toCityName || city['_id'] == toCityName),
            orElse: () => {'latitude': 0.0, 'longitude': 0.0},
          );
          
          // Koordinatları al
          double fromLat = 0.0;
          double fromLng = 0.0;
          double toLat = 0.0;
          double toLng = 0.0;
          
          if (fromCity.containsKey('latitude') && fromCity['latitude'] != null) {
            fromLat = double.parse(fromCity['latitude'].toString());
          }
          
          if (fromCity.containsKey('longitude') && fromCity['longitude'] != null) {
            fromLng = double.parse(fromCity['longitude'].toString());
          }
          
          if (toCity.containsKey('latitude') && toCity['latitude'] != null) {
            toLat = double.parse(toCity['latitude'].toString());
          }
          
          if (toCity.containsKey('longitude') && toCity['longitude'] != null) {
            toLng = double.parse(toCity['longitude'].toString());
          }
          
          // Geçerli koordinatlar varsa polyline ekle
          if (fromLat != 0.0 && fromLng != 0.0 && toLat != 0.0 && toLng != 0.0) {
            polylines.add(
              Polyline(
                points: [
                  LatLng(fromLat, fromLng),
                  LatLng(toLat, toLng),
                ],
                strokeWidth: 2.0,
                color: Colors.blue,
              ),
            );
            
            // Maliyet etiketini ekle
            final midLat = (fromLat + toLat) / 2;
            final midLng = (fromLng + toLng) / 2;
            
            markers.add(
              Marker(
                width: 80.0,
                height: 30.0,
                point: LatLng(midLat, midLng),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.white.withOpacity(0.7),
                  child: Text(
                    "${connection['cost']} km",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      print("Veri yükleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veri yüklenirken hata oluştu: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şehir Haritası")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(39.9334, 32.8597), // Türkiye merkezi
          initialZoom: 6.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}