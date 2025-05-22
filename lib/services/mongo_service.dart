// lib/services/mongo_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'city_service.dart';

class MongoService {
  late Db db;
  bool isConnected = false;

  Future<void> connect() async {
    if (isConnected) return;

    db = await Db.create(
      "mongodb+srv://gulayyuceer2004:ClEcuntJRorOy3QS@cluster0.1b9nbyy.mongodb.net/",
    );
    await db.open();
    isConnected = true;
  }

  Future<void> addCity(
    String name, {
    required double latitude,
    required double longitude,
  }) async {
    final collection = db.collection('cities');
    await collection.insertOne({
      "_id": name,
      "name": name,
      "latitude": latitude,
      "longitude": longitude,
    });
  }

  // Bağlantı ekle (mesafe otomatik hesaplanır)
  Future<void> addConnection(String from, String to, int parse) async {
    final cost = CityService.calculateDistance(from, to).round();

    final collection = db.collection('connections');

    // Önceki bağlantıyı kontrol et
    final existingConnection = await collection.findOne(
      where.eq('from', from).eq('to', to),
    );

    if (existingConnection != null) {
      return; // Bağlantı zaten var
    }

    // Çift yönlü bağlantı ekle
    await collection.insertOne({"from": from, "to": to, "cost": cost});
    await collection.insertOne({"from": to, "to": from, "cost": cost});
  }

  // Şehirleri getir
  Future<List<Map<String, dynamic>>> fetchCities() async {
    final collection = db.collection('cities');
    return await collection.find().toList();
  }

  // Bağlantıları getir
  Future<List<Map<String, dynamic>>> fetchConnections() async {
    final collection = db.collection('connections');
    return await collection.find().toList();
  }

  Future<void> saveSimulationLog({
    required String from,
    required String to,
    required String algorithm,
    required List<String> result,
    required int totalDistance,
  }) async {
    final collection = db.collection('simulations');
    await collection.insertOne({
      "from": from,
      "to": to,
      "algorithm": algorithm,
      "result": result,
      "totalDistance": totalDistance,
      "date": DateTime.now().toIso8601String(),
    });
  }

  // Veritabanını başlat (ilk kez çalıştırıldığında)
  Future<void> initializeDatabase() async {
    await connect();

    // Şehirleri kontrol et
    final citiesCollection = db.collection('cities');
    final cityCount = await citiesCollection.count();

    // Eğer şehir yoksa, tüm Türkiye şehirlerini ekle
    if (cityCount == 0) {
      for (String city in CityService.getAllCities()) {
        final coordinates = CityService.getCityCoordinates(city)!;
        await citiesCollection.insertOne({
          "_id": city,
          "name": city,
          "latitude": coordinates.latitude,
          "longitude": coordinates.longitude,
        });
      }
    }
  }

  Future<void> deleteCity(String cityName) async {
    final citiesCollection = db.collection('cities');
    final connectionsCollection = db.collection('connections');

    // Şehri sil
    await citiesCollection.deleteOne(where.eq('_id', cityName));

    // Tüm bağlantıları al
    final connections = await connectionsCollection.find().toList();

    // İlgili şehrin bağlantılarını bellek içinde filtrele
    final connectionsToDelete =
        connections
            .where((conn) => conn['from'] == cityName || conn['to'] == cityName)
            .toList();

    // Her bir bağlantıyı tek tek sil
    for (var conn in connectionsToDelete) {
      await connectionsCollection.deleteOne(where.eq('_id', conn['_id']));
    }
  }
}
