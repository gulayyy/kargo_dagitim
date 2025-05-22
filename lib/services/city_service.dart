import 'package:latlong2/latlong.dart';

class CityService {
  static final Map<String, LatLng> turkishCities = {
    "Adana": LatLng(37.0000, 35.3213),
    "Adıyaman": LatLng(37.7648, 38.2786),
    "Afyonkarahisar": LatLng(38.7507, 30.5567),
    "Ağrı": LatLng(39.7191, 43.0503),
    "Amasya": LatLng(40.6499, 35.8353),
    "Ankara": LatLng(39.9334, 32.8597),
    "Antalya": LatLng(36.8841, 30.7056),
    "Artvin": LatLng(41.1828, 41.8183),
    "Aydın": LatLng(37.8560, 27.8416),
    "Balıkesir": LatLng(39.6484, 27.8826),
    "Bilecik": LatLng(40.1506, 29.9792),
    "Bingöl": LatLng(39.0626, 40.7696),
    "Bitlis": LatLng(38.4006, 42.1095),
    "Bolu": LatLng(40.7392, 31.6089),
    "Burdur": LatLng(37.7765, 30.2886),
    "Bursa": LatLng(40.1885, 29.0610),
    "Çanakkale": LatLng(40.1553, 26.4142),
    "Çankırı": LatLng(40.6013, 33.6134),
    "Çorum": LatLng(40.5506, 34.9556),
    "Denizli": LatLng(37.7765, 29.0864),
    "Diyarbakır": LatLng(37.9144, 40.2306),
    "Edirne": LatLng(41.6818, 26.5623),
    "Elazığ": LatLng(38.6810, 39.2264),
    "Erzincan": LatLng(39.7500, 39.5000),
    "Erzurum": LatLng(39.9000, 41.2700),
    "Eskişehir": LatLng(39.7767, 30.5206),
    "Gaziantep": LatLng(37.0662, 37.3833),
    "Giresun": LatLng(40.9128, 38.3895),
    "Gümüşhane": LatLng(40.4603, 39.4814),
    "Hakkari": LatLng(37.5833, 43.7333),
    "Hatay": LatLng(36.2025, 36.1606),
    "Isparta": LatLng(37.7648, 30.5566),
    "Mersin": LatLng(36.8000, 34.6333),
    "İstanbul": LatLng(41.0082, 28.9784),
    "İzmir": LatLng(38.4192, 27.1287),
    "Kars": LatLng(40.6013, 43.0975),
    "Kastamonu": LatLng(41.3887, 33.7827),
    "Kayseri": LatLng(38.7312, 35.4787),
    "Kırklareli": LatLng(41.7333, 27.2167),
    "Kırşehir": LatLng(39.1425, 34.1709),
    "Kocaeli": LatLng(40.8533, 29.8815),
    "Konya": LatLng(37.8667, 32.4833),
    "Kütahya": LatLng(39.4167, 29.9833),
    "Malatya": LatLng(38.3552, 38.3095),
    "Manisa": LatLng(38.6191, 27.4289),
    "Kahramanmaraş": LatLng(37.5858, 36.9371),
    "Mardin": LatLng(37.3212, 40.7245),
    "Muğla": LatLng(37.2153, 28.3636),
    "Muş": LatLng(38.7432, 41.5064),
    "Nevşehir": LatLng(38.6939, 34.6857),
    "Niğde": LatLng(37.9667, 34.6833),
    "Ordu": LatLng(40.9839, 37.8764),
    "Rize": LatLng(41.0201, 40.5234),
    "Sakarya": LatLng(40.7569, 30.3781),
    "Samsun": LatLng(41.2867, 36.3300),
    "Siirt": LatLng(37.9333, 41.9500),
    "Sinop": LatLng(42.0231, 35.1531),
    "Sivas": LatLng(39.7477, 37.0179),
    "Tekirdağ": LatLng(40.9833, 27.5167),
    "Tokat": LatLng(40.3167, 36.5500),
    "Trabzon": LatLng(41.0015, 39.7178),
    "Tunceli": LatLng(39.1079, 39.5401),
    "Şanlıurfa": LatLng(37.1591, 38.7969),
    "Uşak": LatLng(38.6823, 29.4082),
    "Van": LatLng(38.4891, 43.4089),
    "Yozgat": LatLng(39.8181, 34.8147),
    "Zonguldak": LatLng(41.4564, 31.7987),
    "Aksaray": LatLng(38.3687, 34.0370),
    "Bayburt": LatLng(40.2552, 40.2249),
    "Karaman": LatLng(37.1759, 33.2287),
    "Kırıkkale": LatLng(39.8468, 33.5153),
    "Batman": LatLng(37.8812, 41.1351),
    "Şırnak": LatLng(37.5164, 42.4611),
    "Bartın": LatLng(41.6344, 32.3375),
    "Ardahan": LatLng(41.1105, 42.7022),
    "Iğdır": LatLng(39.9167, 44.0333),
    "Yalova": LatLng(40.6500, 29.2667),
    "Karabük": LatLng(41.2061, 32.6204),
    "Kilis": LatLng(36.7184, 37.1212),
    "Osmaniye": LatLng(37.0742, 36.2478),
    "Düzce": LatLng(40.8438, 31.1565),
  };

  static double calculateDistance(String city1, String city2) {
    if (!turkishCities.containsKey(city1) || !turkishCities.containsKey(city2)) {
      return 0;
    }
    
    final Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer, 
      turkishCities[city1]!, 
      turkishCities[city2]!
    );
  }
  
  static List<String> getAllCities() {
    return turkishCities.keys.toList()..sort();
  }
  
  static LatLng? getCityCoordinates(String cityName) {
    return turkishCities[cityName];
  }
}