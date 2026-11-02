import 'package:rideon/core/constants/app_assets.dart';
import 'service_item_model.dart';

/// Logika & data provider untuk baris layanan di Beranda.
class ServicesHeaderLogic {
  static const List<ServiceItemModel> defaultServices = [
    ServiceItemModel(
      title: 'FlexRide',
      iconAsset: AppAssets.icFlexRide,
      iconWhiteAsset: AppAssets.icFlexRideWhite,
      routeKey: 'flexride',
    ),
    ServiceItemModel(
      title: 'FlexFood',
      iconAsset: AppAssets.icFlexFood,
      iconWhiteAsset: AppAssets.icFlexFoodWhite,
      routeKey: 'flexfood',
    ),
    ServiceItemModel(
      title: 'FlexSend',
      iconAsset: AppAssets.icFlexSend,
      iconWhiteAsset: AppAssets.icFlexSendWhite,
      routeKey: 'flexsend',
    ),
  ];
}

