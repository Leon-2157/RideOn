/// Model data satu destinasi wisata di section Rekomendasi Wisata.
///
/// Saat ini diisi dengan mock data statis.
/// Nanti saat integrasi API: gunakan [WisataItemModel.fromJson] dan
/// panggil dari repository — widget [WisataCardItem] tidak perlu diubah.
class WisataItemModel {
  final String title;
  final String description;
  final String imageAsset; // sementara: path asset lokal
  final bool isBestseller;

  const WisataItemModel({
    required this.title,
    required this.description,
    required this.imageAsset,
    this.isBestseller = false,
  });

  /// TODO(backend): ganti dengan factory ini saat API sudah siap.
  /// factory WisataItemModel.fromJson(Map<String, dynamic> json) => WisataItemModel(
  ///   title: json['name'] as String,
  ///   description: json['description'] as String,
  ///   imageAsset: json['image_url'] as String,
  ///   isBestseller: json['is_bestseller'] as bool? ?? false,
  /// );
}
