class FlexSendItem {
  final String name;
  final int qty;
  final int price;
  final String? notes;

  FlexSendItem({
    required this.name,
    required this.qty,
    required this.price,
    this.notes,
  });
}
