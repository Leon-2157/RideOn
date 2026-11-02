import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';

void showFoodCustomizationSheet({
  required BuildContext context,
  required int initialCartQuantity,
  int? initialSpicyLevel,
  required bool initialExtraEgg,
  required bool initialExtraCrackers,
  required TextEditingController kitchenNotesController,
  String foodTitle = 'Nasi Goreng Spesial',
  String foodDesc = 'Nasi goreng + telur mata sapi',
  String foodImage = AppAssets.foodNasiGoreng,
  int foodPrice = 10000,
  required Function({
    required int quantity,
    required int spicyLevel,
    required bool extraEgg,
    required bool extraCrackers,
  }) onConfirmOrder,
}) {
  int cartQuantity = initialCartQuantity;
  int? spicyLevel = initialSpicyLevel;
  bool extraEgg = initialExtraEgg;
  bool extraCrackers = initialExtraCrackers;
  final int itemPrice = foodPrice;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final int addonsPrice =
              (extraEgg ? 4000 : 0) + (extraCrackers ? 2000 : 0);
          final int calculatedTotal = (itemPrice * cartQuantity) + addonsPrice;
          final bool isFormValid = spicyLevel != null;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Item info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        foodImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            foodDesc,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${itemPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2DCFE)),
                const SizedBox(height: 14),

                // Tingkat Kepedasan (Wajib pilih 1)
                Row(
                  children: [
                    Text(
                      'Tingkat Kepedasan ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    Text(
                      '(Wajib pilih 1)',
                      style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE83535),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SpicyOptionTile(
                  title: 'Level 1 (Tidak Pedas)',
                  isSelected: spicyLevel == 1,
                  onTap: () => setSheetState(() => spicyLevel = 1),
                ),
                _SpicyOptionTile(
                  title: 'Level 2 (Pedas Sedang)',
                  isSelected: spicyLevel == 2,
                  onTap: () => setSheetState(() => spicyLevel = 2),
                ),
                _SpicyOptionTile(
                  title: 'Level 3 (Pedas Banget)',
                  isSelected: spicyLevel == 3,
                  onTap: () => setSheetState(() => spicyLevel = 3),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2DCFE)),
                const SizedBox(height: 14),

                // Tambahan Topping (Opsional)
                Row(
                  children: [
                    Text(
                      'Tambahan Topping ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    Text(
                      '(Opsional)',
                      style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        color: const Color(0xFF6B6680),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ToppingCheckboxTile(
                  title: 'Tambah Telur Dadar',
                  price: '+Rp 4.000',
                  isSelected: extraEgg,
                  onChanged: (val) =>
                      setSheetState(() => extraEgg = val ?? false),
                ),
                _ToppingCheckboxTile(
                  title: 'Ekstra Kerupuk Kaleng',
                  price: '+Rp 2.000',
                  isSelected: extraCrackers,
                  onChanged: (val) =>
                      setSheetState(() => extraCrackers = val ?? false),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2DCFE)),
                const SizedBox(height: 14),

                // Catatan Khusus untuk Dapur
                Text(
                  'Catatan Khusus untuk Dapur',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2DCFE)),
                  ),
                  child: TextField(
                    controller: kitchenNotesController,
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: const Color(0xFF17152B)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Contoh: Jangan pakai seledri ya mas',
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFFA6A3B3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Counter & Confirmation Button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EEFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DCFE)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              if (cartQuantity > 1) {
                                setSheetState(() => cartQuantity--);
                              }
                            },
                          ),
                          Text(
                            '$cartQuantity',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add,
                                size: 18, color: AppColors.primary),
                            onPressed: () {
                              setSheetState(() => cartQuantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isFormValid
                            ? () {
                                Navigator.of(context).pop();
                                onConfirmOrder(
                                  quantity: cartQuantity,
                                  spicyLevel: spicyLevel!,
                                  extraEgg: extraEgg,
                                  extraCrackers: extraCrackers,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B1832),
                          disabledBackgroundColor: const Color(0xFFE2E0EA),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF8E8A9E),
                          elevation: isFormValid ? 2 : 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isFormValid
                              ? 'Konfirmasi Pesanan Rp $calculatedTotal'
                              : 'Pilih Tingkat Kepedasan',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SpicyOptionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpicyOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFC6BCFF),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFC6BCFF),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF17152B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToppingCheckboxTile extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _ToppingCheckboxTile({
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: AppColors.primary,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF17152B),
              ),
            ),
          ),
          Text(
            price,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
