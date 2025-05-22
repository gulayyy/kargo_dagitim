# Kargo Yönlendirme Uygulaması

## 📋 Proje Hakkında

Kargo Yönlendirme Uygulaması, Türkiye'deki şehirler arasında en uygun kargo rotalarını hesaplamak için geliştirilmiş bir mobil uygulamadır. Uygulama, gerçek coğrafi koordinatlar kullanarak şehirler arasındaki mesafeleri hesaplar ve farklı algoritmaları kullanarak en uygun rotayı belirler.

## ✨ Özellikler

- **Gerçek Türkiye Şehirleri**: Türkiye'nin 81 ilinin gerçek koordinatlarıyla çalışır
- **Otomatik Mesafe Hesaplama**: Şehirler arasındaki mesafeleri coğrafi koordinatlar kullanarak otomatik hesaplar
- **Çoklu Rota Algoritmaları**:
  - En Hızlı Rota (BFS)
  - Alternatif Rota (DFS)
  - En Kısa Mesafe (UCS)
- **Harita Görselleştirmesi**: Bulunan rotaları harita üzerinde görselleştirir
- **Şehir Yönetimi**: Şehir ekleme, listeleme ve silme özellikleri
- **Rota Geçmişi**: Önceki rota hesaplamalarını kaydeder ve görüntüler

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (2.0.0 veya üzeri)
- Dart SDK (2.12.0 veya üzeri)
- MongoDB hesabı

### Adımlar

1. Projeyi klonlayın:
   ```bash
   git clone https://github.com/kullanici/kargo-yonlendirme.git
   cd kargo-yonlendirme
