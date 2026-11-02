class FlexSendLocation {
  String name;
  String address;
  List<FlexSendItem> items;

  FlexSendLocation({
    required this.name,
    required this.address,
    List<FlexSendItem>? items,
  }) : items = items ?? [];

  int get subtotal => items.fold(0, (sum, item) => sum + (item.price * item.qty));
}

class FlexSendItem {
  final String name;
  final int qty;
  final String unit;
  final int price;
  final String? notes;

  FlexSendItem({
    required this.name,
    required this.qty,
    this.unit = 'pcs',
    this.price = 0,
    this.notes,
  });
}
