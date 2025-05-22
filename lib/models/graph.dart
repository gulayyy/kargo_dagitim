// lib/models/graph.dart
import 'package:latlong2/latlong.dart';

class Graph {
  // Şehir adı -> Komşu şehirler ve mesafeler
  final Map<String, Map<String, int>> cities = {};
  
  // Şehir adı -> Koordinatlar
  final Map<String, LatLng> coordinates = {};

  void addCity(String name, LatLng coordinates) {
    if (!cities.containsKey(name)) {
      cities[name] = {};
    }
    this.coordinates[name] = coordinates;
  }

  void addConnection(String from, String to, int cost) {
    if (!cities.containsKey(from)) {
      cities[from] = {};
    }
    if (!cities.containsKey(to)) {
      cities[to] = {};
    }
    cities[from]![to] = cost;
  }

  // Koordinatlar arasındaki mesafeyi hesapla (km)
  int calculateDistance(String from, String to) {
    if (!coordinates.containsKey(from) || !coordinates.containsKey(to)) {
      return 0;
    }
    
    final Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer, 
      coordinates[from]!, 
      coordinates[to]!
    ).round();
  }

  // Tüm şehirler arasında otomatik bağlantılar oluştur
  void generateAllConnections() {
    final cityNames = coordinates.keys.toList();
    
    for (int i = 0; i < cityNames.length; i++) {
      for (int j = i + 1; j < cityNames.length; j++) {
        final from = cityNames[i];
        final to = cityNames[j];
        
        final distance = calculateDistance(from, to);
        
        // Çift yönlü bağlantı ekle
        addConnection(from, to, distance);
        addConnection(to, from, distance);
      }
    }
  }
}