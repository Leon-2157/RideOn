import 'package:flutter/material.dart';
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
  const FlexFoodScreen({super.key});

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
  FlexFoodState _currentState = FlexFoodState.grid;

  // Customization & Cart state
  int _cartQuantity = 2;
  int _spicyLevel = 3; // 1: Tidak Pedas, 2: Pedas Sedang, 3: Pedas Banget
  bool _extraEgg = true;
  bool _extraCrackers = false;
  final TextEditingController _kitchenNotesController =
      TextEditingController(text: 'Jangan pakai seledri ya mas');

  // Tracking state (0: driver menuju resto, 1: driver menunggu, 2: driver mengantar, 3: pesanan sampai)
  int _trackingStep = 0;

  @override
  void dispose() {
    _kitchenNotesController.dispose();
    super.dispose();
  }

  int get _itemPrice => 10000;
  int get _addonsPrice => (_extraEgg ? 4000 : 0) + (_extraCrackers ? 2000 : 0);
  int get _subtotalPrice => (_itemPrice * _cartQuantity) + _addonsPrice;
  int get _deliveryFee => 8000;
  int get _serviceFee => 2000;
  int get _totalPrice => _subtotalPrice + _deliveryFee + _serviceFee;

  void _openCustomizationSheet() {
    showFoodCustomizationSheet(
      context: context,
      initialCartQuantity: _cartQuantity,
      initialSpicyLevel: _spicyLevel,
      initialExtraEgg: _extraEgg,
      initialExtraCrackers: _extraCrackers,
      kitchenNotesController: _kitchenNotesController,
      onConfirmOrder: ({
        required int quantity,
        required int spicyLevel,
        required bool extraEgg,
        required bool extraCrackers,
      }) {
        setState(() {
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
          onSelectFood: () {
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
              _currentState = FlexFoodState.checkout;
            });
          },
          cartQuantity: _cartQuantity,
          subtotalPrice: _subtotalPrice,
        );

      case FlexFoodState.checkout:
        return CheckoutView(
          onBack: () =>
              setState(() => _currentState = FlexFoodState.restaurant),
          onAddMoreItems: () =>
              setState(() => _currentState = FlexFoodState.restaurant),
          onPlaceOrder: () {
            setState(() {
              _currentState = FlexFoodState.tracking;
              _trackingStep = 0;
            });
          },
          cartQuantity: _cartQuantity,
          subtotalPrice: _subtotalPrice,
          spicyLevel: _spicyLevel,
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
          trackingStep: _trackingStep,
          onAdvanceStep: () {
            setState(() {
              _trackingStep = (_trackingStep + 1) % 4;
            });
          },
          onFinish: () {
            setState(() {
              _currentState = FlexFoodState.grid;
            });
          },
        );
    }
  }
}
