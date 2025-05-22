// lib/screens/simulation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/mongo_service.dart';
import '../services/city_service.dart';
import '../models/graph.dart';
import '../algorithms/bfs.dart';
import '../algorithms/dfs.dart';
import '../algorithms/ucs.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  String? fromCity;
  String? toCity;
  String result = "";
  String selectedRouteType = "En Hızlı Rota";
  List<String> cities = [];
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  bool isLoading = false;
  bool showMap = false;
  int totalDistance = 0;

  final Map<String, String> routeTypes = {
    "En Hızlı Rota": "BFS",
    "Alternatif Rota": "DFS",
    "En Kısa Mesafe": "UCS",
  };

  final MongoService db = MongoService();

  @override
  void initState() {
    super.initState();
    _loadCities();

    // Argümanları kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          if (args.containsKey('fromCity')) {
            fromCity = args['fromCity'];
          }
          if (args.containsKey('toCity')) {
            toCity = args['toCity'];
          }
        });
      }
    });
  }

  Future<void> _loadCities() async {
    setState(() {
      isLoading = true;
    });

    try {
      await db.connect();
      final cityList = await db.fetchCities();
      setState(() {
        cities =
            cityList.map<String>((city) => city['name'] as String).toList()
              ..sort();
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

  Future<void> _findRoute() async {
    if (fromCity == null || toCity == null) {
      setState(
        () => result = "⚠️ Lütfen başlangıç ve varış şehirlerini seçin.",
      );
      return;
    }

    if (fromCity == toCity) {
      setState(() => result = "⚠️ Başlangıç ve varış şehirleri aynı olamaz.");
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
      showMap = false;
      markers = [];
      polylines = [];
    });

    try {
      await db.connect();
      final cityList = await db.fetchCities();

      // Koordinat tabanlı graf oluştur
      final graph = Graph();

      // Tüm şehirleri ve koordinatlarını ekle
      for (var city in cityList) {
        final name = city['name'] as String;
        double lat = 0.0;
        double lng = 0.0;

        if (city.containsKey('latitude') && city['latitude'] != null) {
          lat = double.parse(city['latitude'].toString());
        }

        if (city.containsKey('longitude') && city['longitude'] != null) {
          lng = double.parse(city['longitude'].toString());
        }

        graph.addCity(name, LatLng(lat, lng));
      }

      // Tüm şehirler arasında otomatik bağlantılar oluştur
      graph.generateAllConnections();

      final from = fromCity!;
      final to = toCity!;
      List<String> path = [];
      String algorithm = routeTypes[selectedRouteType] ?? "BFS";

      if (!graph.cities.containsKey(from)) {
        setState(() => result = "❌ Başlangıç şehri bulunamadı.");
        return;
      }

      if (!graph.cities.containsKey(to)) {
        setState(() => result = "❌ Varış şehri bulunamadı.");
        return;
      }

      if (algorithm == "BFS") {
        path = bfs(graph, from, to);
      } else if (algorithm == "DFS") {
        path = dfs(graph, from, to);
      } else if (algorithm == "UCS") {
        path = ucs(graph, from, to);
      }

      if (path.isEmpty) {
        setState(() => result = "❌ Bu şehirler arasında rota bulunamadı.");
        return;
      }

      // Toplam mesafeyi hesapla
      totalDistance = _pathCost(graph, path);

      // Harita için işaretleyicileri ve çizgileri oluştur
      _createMapVisualization(path);

      setState(() {
        result =
            "✅ Rota bulundu: ${path.join(' → ')}\n\nToplam Mesafe: $totalDistance km";
        showMap = true;
      });

      // Simülasyon kaydı
      await db.saveSimulationLog(
        from: from,
        to: to,
        algorithm: algorithm,
        result: path,
        totalDistance: totalDistance,
      );
    } catch (e) {
      print("Rota bulma hatası: $e");
      setState(() => result = "❌ Rota hesaplanırken bir hata oluştu: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _createMapVisualization(List<String> path) {
    markers = [];
    polylines = [];

    // Rota üzerindeki her şehir için işaretleyici ekle
    for (int i = 0; i < path.length; i++) {
      final cityName = path[i];
      final coordinates = CityService.getCityCoordinates(cityName);

      if (coordinates != null) {
        // Başlangıç, ara ve bitiş noktaları için farklı renkler
        Color markerColor;
        double markerSize;

        if (i == 0) {
          markerColor = Colors.green;
          markerSize = 20.0;
        } else if (i == path.length - 1) {
          markerColor = Colors.red;
          markerSize = 20.0;
        } else {
          markerColor = Colors.blue;
          markerSize = 15.0;
        }

        markers.add(
          Marker(
            width: markerSize,
            height: markerSize,
            point: coordinates,
            child: Container(
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  i == 0 || i == path.length - 1
                      ? Icon(
                        i == 0 ? Icons.trip_origin : Icons.place,
                        color: Colors.white,
                        size: 12,
                      )
                      : null,
            ),
          ),
        );

        // Şehir adı etiketleri
        markers.add(
          Marker(
            width: 80.0,
            height: 20.0,
            point: LatLng(coordinates.latitude, coordinates.longitude + 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cityName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      i == 0 || i == path.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }

    // Rota çizgilerini ekle
    for (int i = 0; i < path.length - 1; i++) {
      final fromCoordinates = CityService.getCityCoordinates(path[i]);
      final toCoordinates = CityService.getCityCoordinates(path[i + 1]);

      if (fromCoordinates != null && toCoordinates != null) {
        polylines.add(
          Polyline(
            points: [fromCoordinates, toCoordinates],
            strokeWidth: 4.0,
            color: Colors.blue,
          ),
        );

        // Mesafe etiketleri
        final midLat = (fromCoordinates.latitude + toCoordinates.latitude) / 2;
        final midLng =
            (fromCoordinates.longitude + toCoordinates.longitude) / 2;
        final distance =
            CityService.calculateDistance(path[i], path[i + 1]).round();

        markers.add(
          Marker(
            width: 60.0,
            height: 25.0,
            point: LatLng(midLat, midLng),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                "$distance km",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }
  }

  int _pathCost(Graph graph, List<String> path) {
    int total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      total += graph.cities[path[i]]?[path[i + 1]] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rota Planlama")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Rota Bilgileri",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: fromCity,
                                decoration: const InputDecoration(
                                  labelText: "Başlangıç Şehri",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.trip_origin),
                                ),
                                items:
                                    cities.map((city) {
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
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: toCity,
                                decoration: const InputDecoration(
                                  labelText: "Varış Şehri",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.place),
                                ),
                                items:
                                    cities.map((city) {
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
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedRouteType,
                                decoration: const InputDecoration(
                                  labelText: "Rota Tipi",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.route),
                                ),
                                items:
                                    routeTypes.keys.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedRouteType = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _findRoute,
                                  icon: const Icon(Icons.search),
                                  label: const Text("Rota Bul"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (result.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Sonuç",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  result,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (showMap) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  "Rota Haritası",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 400,
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter:
                                        markers.isNotEmpty
                                            ? markers.first.point
                                            : LatLng(39.0, 35.0),
                                    initialZoom: 6.0,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
