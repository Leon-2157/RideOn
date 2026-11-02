import 'package:rideon/core/constants/app_assets.dart';
import 'wisata_item_model.dart';

/// Logika & data provider untuk section Rekomendasi Wisata di Beranda.
class WisataSectionLogic {
  static const List<WisataItemModel> defaultWisata = [
    WisataItemModel(
      title: 'Gunung Rinjani',
      description:
          'Jangan salah, kami sedia Ojek Gunung! Hemat waktu dan tenaga dari basecamp ke POS 2. Pesan sekarang dan nikmati perjalanan aman bersama driver profesional kami.',
      imageAsset: AppAssets.wisataRinjani,
      isBestseller: true,
    ),
    WisataItemModel(
      title: 'Ranu Kumbolo',
      description:
          'Pesona magis Ranu Kumbolo menantimu! Bebaskan penatmu dan nikmati syahdunya berkemah di surga Semeru. Siapkan ranselmu dan rencanakan pendakianmu sekarang',
      imageAsset: AppAssets.wisataRanuKumbolo,
      isBestseller: true,
    ),
    WisataItemModel(
      title: 'Banda Neira',
      description:
          'Banda Neira, kepingan surga di Maluku! Nikmati pesona bawah laut eksotis dan kekayaan sejarah yang mendunia. Wujudkan liburan impianmu sekarang',
      imageAsset: AppAssets.wisataBandaNeira,
      isBestseller: true,
    ),
  ];

  static Future<List<WisataItemModel>> fetchWisataRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return defaultWisata;
  }
}

