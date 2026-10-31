/// Model data satu banner promo di Beranda.
class PromoItemModel {
  final String imageAsset;
  final String? title;
  final String? voucherCode;

  const PromoItemModel({
    required this.imageAsset,
    this.title,
    this.voucherCode,
  });

  factory PromoItemModel.fromJson(Map<String, dynamic> json) => PromoItemModel(
        imageAsset: json['image_url'] as String? ?? '',
        title: json['title'] as String?,
        voucherCode: json['voucher_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'image_url': imageAsset,
        'title': title,
        'voucher_code': voucherCode,
      };
}
