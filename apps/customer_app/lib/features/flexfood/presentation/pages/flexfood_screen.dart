import 'package:flutter/material.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../modules/customization/food_customization_sheet.dart';
import '../modules/food_grid/food_grid_view.dart';
import '../modules/restaurant/restaurant_view.dart';
import '../modules/checkout/checkout_view.dart';
import '../modules/tracking/food_tracking_view.dart';

/// Halaman FlexFood strictly matching Figma designs in figma/HalamanFlexFood:
/// - masuk flex food.png: 3-column food grid with search/header and favorites
/// - milih makanan.png: Banku City restaurant menu and floating cart
/// - lihat keranjang.png: Food customization bottom sheet
/// - konfirmasi pesanan.png: Checkout & payment confirmation
/// - driver menuju resto.png / pesanan sampai.png: Driver tracking lifecycle
class FlexFoodScreen extends StatefulWidget {
  final FlexFoodState initialState;
  final Map<String, dynamic>? initialFood;
  final String? initialRestaurantName;

  const FlexFoodScreen({
    super.key,
    this.initialState = FlexFoodState.grid,
    this.initialFood,
    this.initialRestaurantName,
  });

  @override
  State<FlexFoodScreen> createState() => _FlexFoodScreenState();
}

enum FlexFoodState {
  grid, // masuk flex food.png
  restaurant, // milih makanan.png
  checkout, // konfirmasi pesanan.png
  tracking, // driver menuju resto.png -> pesanan sampai.png
}

class _FlexFoodScreenState extends State<FlexFoodScreen> {
  late FlexFoodState _currentState;
  FlexFoodState _previousState = FlexFoodState.grid;

  // Customization & Cart state
  int _cartQuantity = 1;
  int? _spicyLevel; // null saat belum dipilih (wajib pilih 1)
  bool _extraEgg = false;
  bool _extraCrackers = false;
  final TextEditingController _kitchenNotesController =
      TextEditingController();

  String _currentFoodTitle = 'Nasi Goreng Spesial';
  String _currentFoodDesc = 'Nasi goreng + telur mata sapi';
  String _currentFoodImage = AppAssets.foodNasiGoreng;
  String _currentRestaurantName = 'Banku City Resto & Cafe';
  int _itemPrice = 10000;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    if (widget.initialRestaurantName != null) {
      _currentRestaurantName = widget.initialRestaurantName!;
    }
    if (widget.initialFood != null) {
      final food = widget.initialFood!;
      _currentFoodTitle = food['title'] as String? ?? _currentFoodTitle;
      _currentFoodDesc = food['desc'] as String? ?? _currentFoodDesc;
      _currentFoodImage = food['image'] as String? ?? _currentFoodImage;
      _currentRestaurantName = food['resto'] as String? ?? _currentRestaurantName;
      _itemPrice = food['priceInt'] as int? ??
          (int.tryParse((food['price'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 10000);
      
      // Jika dari favorite user memilih makanan, langsung tampilkan bottomsheet kustomisasi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentState == FlexFoodState.grid) {
          _openCustomizationSheet(food: food);
        }
      });
    }
  }

  // Delivery Address State
  String _deliveryLabel = 'Rumah';
  String _deliveryAddress = 'Jl. Brawl No. 77';
  String _deliveryNotes = 'Pagar hitam depan pos satpam';

  @override
  void dispose() {
    _kitchenNotesController.dispose();
    super.dispose();
  }

  int get _addonsPrice => (_extraEgg ? 4000 : 0) + (_extraCrackers ? 2000 : 0);
  int get _subtotalPrice => (_itemPrice * _cartQuantity) + _addonsPrice;
  int get _deliveryFee => 8000;
  int get _serviceFee => 2000;
  int get _totalPrice => _subtotalPrice + _deliveryFee + _serviceFee;

  void _openCustomizationSheet({Map<String, dynamic>? food}) {
    if (food != null) {
      _currentFoodTitle = food['title'] as String? ?? _currentFoodTitle;
      _currentFoodDesc = food['desc'] as String? ?? _currentFoodDesc;
      _currentFoodImage = food['image'] as String? ?? _currentFoodImage;
      _currentRestaurantName = food['resto'] as String? ?? _currentRestaurantName;
      _itemPrice = food['priceInt'] as int? ??
          (int.tryParse((food['price'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 10000);
      
      // Reset pilihan ke kondisi awal untuk item menu yang baru dipilih
      _cartQuantity = 1;
      _spicyLevel = null;
      _extraEgg = false;
      _extraCrackers = false;
      _kitchenNotesController.clear();
    }

    showFoodCustomizationSheet(
      context: context,
      initialCartQuantity: _cartQuantity,
      initialSpicyLevel: _spicyLevel,
      initialExtraEgg: _extraEgg,
      initialExtraCrackers: _extraCrackers,
      kitchenNotesController: _kitchenNotesController,
      foodTitle: _currentFoodTitle,
      foodDesc: _currentFoodDesc,
      foodImage: _currentFoodImage,
      foodPrice: _itemPrice,
      onConfirmOrder: ({
        required int quantity,
        required int spicyLevel,
        required bool extraEgg,
        required bool extraCrackers,
      }) {
        setState(() {
          _previousState = _currentState;
          _cartQuantity = quantity;
          _spicyLevel = spicyLevel;
          _extraEgg = extraEgg;
          _extraCrackers = extraCrackers;
          _currentState = FlexFoodState.checkout;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case FlexFoodState.grid:
        return FoodGridView(
          onBack: () => Navigator.of(context).maybePop(),
          onSelectFood: (food) {
            _openCustomizationSheet(food: food);
          },
          onSelectResto: () {
            setState(() {
              _currentState = FlexFoodState.restaurant;
            });
          },
        );

      case FlexFoodState.restaurant:
        return RestaurantView(
          onBack: () => setState(() => _currentState = FlexFoodState.grid),
          onOpenCustomization: _openCustomizationSheet,
          onGoToCheckout: () {
            setState(() {
              _previousState = FlexFoodState.restaurant;
              _currentState = FlexFoodState.checkout;
            });
          },
          restaurantName: _currentRestaurantName,
          cartQuantity: _cartQuantity,
          subtotalPrice: _subtotalPrice,
        );

      case FlexFoodState.checkout:
        return CheckoutView(
          onBack: () =>
              setState(() => _currentState = _previousState),
          onAddMoreItems: () =>
              setState(() => _currentState = FlexFoodState.restaurant),
          onPlaceOrder: () {
            setState(() {
              _currentState = FlexFoodState.tracking;
            });
          },
          restaurantName: _currentRestaurantName,
          foodTitle: _currentFoodTitle,
          deliveryLabel: _deliveryLabel,
          deliveryAddress: _deliveryAddress,
          deliveryNotes: _deliveryNotes,
          onChangeAddress: (label, address, notes) {
            setState(() {
              _deliveryLabel = label;
              _deliveryAddress = address;
              _deliveryNotes = notes;
            });
          },
          cartQuantity: _cartQuantity,
          subtotalPrice: _subtotalPrice,
          spicyLevel: _spicyLevel ?? 1,
          extraEgg: _extraEgg,
          kitchenNotes: _kitchenNotesController.text,
          deliveryFee: _deliveryFee,
          serviceFee: _serviceFee,
          totalPrice: _totalPrice,
        );

      case FlexFoodState.tracking:
        return FoodTrackingView(
          onBack: () =>
              setState(() => _currentState = FlexFoodState.checkout),
          restaurantName: _currentRestaurantName,
          foodTitle: _currentFoodTitle,
          cartQuantity: _cartQuantity,
          totalPrice: _totalPrice,
          deliveryLabel: _deliveryLabel,
          deliveryAddress: _deliveryAddress,
          onFinish: () {
            setState(() {
              _currentState = FlexFoodState.grid;
            });
          },
        );
    }
  }
}
