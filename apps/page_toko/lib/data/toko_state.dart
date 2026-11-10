import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TokoState {
  static final ValueNotifier<bool> isStoreOpen = ValueNotifier<bool>(true);
  static final ValueNotifier<int> balance = ValueNotifier<int>(12450000);
  static final ValueNotifier<String> activeBank = ValueNotifier<String>('BCA •••• 4912');
  static final ValueNotifier<String> storeName = ValueNotifier<String>('Warung Taufiq');
  static final ValueNotifier<String> ownerName = ValueNotifier<String>('Muhammad Taufiq');
  static final ValueNotifier<String> storeCategory = ValueNotifier<String>('Katering & Masakan Nusantara');
  static final ValueNotifier<String> operationalDays = ValueNotifier<String>('Senin - Jumat');
  static final ValueNotifier<String> openHour = ValueNotifier<String>('08.00');
  static final ValueNotifier<String> closeHour = ValueNotifier<String>('21.00');
  static final ValueNotifier<String> storeAddress = ValueNotifier<String>('Meunasah Pinto, Kec. Muara Batu, Kabupaten Aceh Utara, Aceh');
  static final ValueNotifier<String> storePostal = ValueNotifier<String>('24374');
  static final ValueNotifier<String> storeCountry = ValueNotifier<String>('Indonesia');
  static final ValueNotifier<String> ownerAvatar = ValueNotifier<String>('assets/images/avatar_owner.png');
  static const String securityPin = '123456';

  static List<Map<String, dynamic>> _defaultOrders() => [
    {
      'id': '#FD-8822',
      'tab': 'baru',
      'status': 'Perlu Diterima',
      'statusColor': const Color(0xFFC2410C),
      'statusBg': const Color(0xFFFFEDD5),
      'items': '2× Nasi Goreng Spesial',
      'itemDetails': [
        {
          'name': '2× Nasi Goreng Spesial',
          'price': 'Rp 50.000',
          'basePrice': 'Rp 25.000',
          'tags': ['Level: Sedang', 'Telur Dadar'],
          'image': 'assets/images/food_nasgor.png',
        },
      ],
      'price': 'Rp 50.000',
      'driverStatus': 'Konfirmasi dalam 04:31',
      'customerName': 'Rian Pratama',
      'pin': '8822',
      'buyerNote': 'Sambal dipisah ya min',
      'payment': 'Tunai / COD',
    },
    {
      'id': '#FD-8821',
      'tab': 'diproses',
      'status': 'Sedang Dimasak',
      'statusColor': AppColors.primary,
      'statusBg': AppColors.primarySoft,
      'items': '1× Ayam Bakar Madu + Es Teh',
      'itemDetails': [
        {
          'name': '1× Ayam Bakar Madu',
          'price': 'Rp 30.000',
          'basePrice': 'Rp 30.000',
          'tags': ['Paha', 'Manis Gurih'],
        },
        {
          'name': '1× Es Teh Manis',
          'price': 'Rp 6.000',
          'basePrice': 'Rp 6.000',
          'tags': ['Gula Normal'],
        },
      ],
      'price': 'Rp 36.000',
      'driverStatus': 'Driver menunggu pesanan (5 mnt)',
      'customerName': 'Ahmad Fauzi',
      'pin': '8821',
      'buyerNote': 'Ayamnya dibakar agak garing',
      'payment': 'Saldo Digital',
      'driverName': 'Joni Utama',
      'driverPlat': 'Plat B 1234 XYZ',
    },
    {
      'id': '#FD-8921',
      'tab': 'diproses',
      'status': 'Perjalanan Ke Toko',
      'statusColor': AppColors.info,
      'statusBg': AppColors.infoLight,
      'items': '1× Ayam Bakar Madu',
      'itemDetails': [
        {
          'name': '1× Ayam Bakar Madu',
          'price': 'Rp 30.000',
          'basePrice': 'Rp 30.000',
          'tags': ['Dada'],
        },
      ],
      'price': 'Rp 30.000',
      'driverStatus': 'Driver menuju resto (14 mnt)',
      'customerName': 'Siti Rahma',
      'pin': '8921',
      'buyerNote': 'Jangan terlalu pedas sambalnya',
      'payment': 'Tunai / COD',
      'driverName': 'Bambang Sudiro',
      'driverPlat': 'Plat B 5678 KLM',
    },
    {
      'id': '#FD-7821',
      'tab': 'diproses',
      'status': 'Sedang Dimasak',
      'statusColor': AppColors.primary,
      'statusBg': AppColors.primarySoft,
      'items': 'Es Teh Manis',
      'itemDetails': [
        {
          'name': '1× Es Teh Manis',
          'price': 'Rp 6.000',
          'basePrice': 'Rp 6.000',
          'tags': ['Es Sedang'],
        },
      ],
      'price': 'Rp 6.000',
      'driverStatus': 'Driver menuju toko (9 mnt)',
      'customerName': 'Budi Santoso',
      'pin': '7821',
      'buyerNote': 'Esnya dipisah',
      'payment': 'Saldo Digital',
      'driverName': 'Dedi Prasetyo',
      'driverPlat': 'Plat B 9012 QWE',
    },
  ];

  static final ValueNotifier<List<Map<String, dynamic>>> orders =
      ValueNotifier<List<Map<String, dynamic>>>(_defaultOrders());

  static List<Map<String, dynamic>> _defaultTransactions() => [
    {
      'title': 'Tarik Saldo Berhasil',
      'subtitle': 'Senin, 05 Okt • 10:15 WIB',
      'target': 'Ke BCA',
      'amount': '-Rp 1.500.000',
      'isNegative': true,
    },
    {
      'title': 'Pendapatan Hari Ini',
      'subtitle': 'Order #FD-8819 • 13:20 WIB',
      'target': 'Sukses',
      'amount': '+Rp 845.000',
      'isNegative': false,
    },
    {
      'title': 'Pendapatan Pesanan',
      'subtitle': 'Order #FD-8810 • 04 Okt',
      'target': 'Sukses',
      'amount': '+Rp 120.000',
      'isNegative': false,
    },
  ];

  static final ValueNotifier<List<Map<String, dynamic>>> transactions =
      ValueNotifier<List<Map<String, dynamic>>>(_defaultTransactions());

  static void resetForTest() {
    isStoreOpen.value = true;
    balance.value = 12450000;
    activeBank.value = 'BCA •••• 4912';
    storeName.value = 'Warung Taufiq';
    ownerName.value = 'Muhammad Taufiq';
    storeCategory.value = 'Katering & Masakan Nusantara';
    operationalDays.value = 'Senin - Jumat';
    openHour.value = '08.00';
    closeHour.value = '21.00';
    storeAddress.value = 'Meunasah Pinto, Kec. Muara Batu, Kabupaten Aceh Utara, Aceh';
    storePostal.value = '24374';
    storeCountry.value = 'Indonesia';
    ownerAvatar.value = 'assets/images/avatar_owner.png';
    orders.value = _defaultOrders();
    transactions.value = _defaultTransactions();
  }

  static void acceptOrder(String orderId, [int cookingMinutes = 35]) {
    final list = List<Map<String, dynamic>>.from(orders.value);
    final idx = list.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx]);
      list[idx]['tab'] = 'diproses';
      list[idx]['status'] = 'Sedang Dimasak';
      list[idx]['statusColor'] = AppColors.primary;
      list[idx]['statusBg'] = AppColors.primarySoft;
      list[idx]['driverStatus'] = 'Driver menunggu pesanan ($cookingMinutes mnt)';
      list[idx]['driverName'] ??= 'Agus Salim';
      list[idx]['driverPlat'] ??= 'Plat BL 4512 AA';
      orders.value = list;
    }
  }

  static void rejectOrder(String orderId) {
    final list = List<Map<String, dynamic>>.from(orders.value);
    final idx = list.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx]);
      list[idx]['tab'] = 'batal';
      list[idx]['status'] = 'Dibatalkan';
      list[idx]['statusColor'] = AppColors.danger;
      list[idx]['statusBg'] = AppColors.dangerLight;
      list[idx]['driverStatus'] = 'Pesanan dibatalkan oleh toko';
      orders.value = list;
    }
  }

  static int parsePrice(String? priceStr) {
    if (priceStr == null) return 0;
    return int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  static void completeOrder(String orderId) {
    final list = List<Map<String, dynamic>>.from(orders.value);
    final idx = list.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      list[idx] = Map<String, dynamic>.from(list[idx]);
      final alreadyDone = list[idx]['tab'] == 'selesai';
      list[idx]['tab'] = 'selesai';
      list[idx]['status'] = 'Pesanan Selesai';
      list[idx]['statusColor'] = AppColors.success;
      list[idx]['statusBg'] = AppColors.successLight;
      list[idx]['driverStatus'] = 'Pesanan telah diambil oleh kurir';
      orders.value = list;

      if (!alreadyDone) {
        final priceVal = parsePrice(list[idx]['price'] as String?);
        if (priceVal > 0) {
          final isCod = (list[idx]['payment'] as String?) == 'Tunai / COD';
          if (!isCod) {
            balance.value += priceVal;
          }
          final now = DateTime.now();
          final hh = now.hour.toString().padLeft(2, '0');
          final mm = now.minute.toString().padLeft(2, '0');
          transactions.value = [
            {
              'title': 'Pendapatan Pesanan',
              'subtitle': 'Order $orderId • $hh:$mm WIB',
              'target': isCod ? 'Tunai' : 'Saldo',
              'amount': '+${list[idx]['price']}',
              'isNegative': false,
            },
            ...transactions.value,
          ];
        }
      }
    }
  }
}
