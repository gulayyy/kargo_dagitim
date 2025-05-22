// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/mongo_service.dart';
import '../services/city_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MongoService db = MongoService();
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> connections = [];
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Veritabanını başlat
      await db.initializeDatabase();
      await _loadData();
    } catch (e) {
      print("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veri yüklenirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    await db.connect();
    final cityList = await db.fetchCities();
    final connectionList = await db.fetchConnections();

    setState(() {
      cities = cityList;
      connections = connectionList;

      // Şehir işaretleyicilerini oluştur
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

        markers.add(
          Marker(
            width: 15.0,
            height: 15.0,
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () {
                _showCityInfo(city['name']);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        );
      }

      // Bağlantı çizgilerini oluştur
      polylines = [];
      for (var connection in connections) {
        final fromCityName = connection['from'];
        final toCityName = connection['to'];

        final fromCity = cities.firstWhere(
          (city) =>
              (city['name'] == fromCityName || city['_id'] == fromCityName),
          orElse: () => {'latitude': 0.0, 'longitude': 0.0},
        );

        final toCity = cities.firstWhere(
          (city) => (city['name'] == toCityName || city['_id'] == toCityName),
          orElse: () => {'latitude': 0.0, 'longitude': 0.0},
        );

        double fromLat = 0.0;
        double fromLng = 0.0;
        double toLat = 0.0;
        double toLng = 0.0;

        if (fromCity.containsKey('latitude') && fromCity['latitude'] != null) {
          fromLat = double.parse(fromCity['latitude'].toString());
        }

        if (fromCity.containsKey('longitude') &&
            fromCity['longitude'] != null) {
          fromLng = double.parse(fromCity['longitude'].toString());
        }

        if (toCity.containsKey('latitude') && toCity['latitude'] != null) {
          toLat = double.parse(toCity['latitude'].toString());
        }

        if (toCity.containsKey('longitude') && toCity['longitude'] != null) {
          toLng = double.parse(toCity['longitude'].toString());
        }

        if (fromLat != 0.0 && fromLng != 0.0 && toLat != 0.0 && toLng != 0.0) {
          polylines.add(
            Polyline(
              points: [LatLng(fromLat, fromLng), LatLng(toLat, toLng)],
              strokeWidth: 1.5,
              color: Colors.blue.withOpacity(0.5),
            ),
          );
        }
      }
    });
  }

  void _showCityInfo(String cityName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cityName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        "/simulate",
                        arguments: {"fromCity": cityName},
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text("Buradan Başla"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        "/simulate",
                        arguments: {"toCity": cityName},
                      );
                    },
                    icon: const Icon(Icons.place),
                    label: const Text("Buraya Varış"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kargo Yönlendirme"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, "/history"),
            tooltip: "Geçmiş Rotalar",
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(39.0, 35.0), // Türkiye merkezi
                  initialZoom: 5.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, "/addCity"),
            heroTag: "addCity",
            child: const Icon(Icons.add_location_alt),
            tooltip: "Şehir Ekle",
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, "/cityList"),
            heroTag: "cityList",
            child: const Icon(Icons.list),
            tooltip: "Şehir Listesi",
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, "/simulate"),
            heroTag: "simulate",
            child: const Icon(Icons.route),
            tooltip: "Rota Planla",
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, "/history"),
            heroTag: "history",
            child: const Icon(Icons.history),
            tooltip: "Geçmiş Rotalar",
          ),
        ],
      ),
    );
  }
}
