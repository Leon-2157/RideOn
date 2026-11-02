import 'package:rideon/core/constants/app_assets.dart';
import 'promo_item_model.dart';

/// Logika & data provider untuk section Cek Promo Sekarang.
class PromoLogic {
  static const List<PromoItemModel> defaultPromos = [
    PromoItemModel(
      imageAsset: AppAssets.promo1,
      title: 'Diskon FlexFood s/d 50%',
      voucherCode: 'FLEXFOOD50',
    ),
    PromoItemModel(
      imageAsset: AppAssets.promo2,
      title: 'Gratis Ongkir FlexRide',
      voucherCode: 'FLEXRIDEFREE',
    ),
    PromoItemModel(
      imageAsset: AppAssets.promo3,
      title: 'Cashback Belanja FlexSend',
      voucherCode: 'FLEXSENDHEMAT',
    ),
  ];

  static Future<List<PromoItemModel>> fetchPromos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return defaultPromos;
  }
}

