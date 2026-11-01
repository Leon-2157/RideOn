import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';

class LocationPickerModule extends StatefulWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final Function(String address) onSelectSavedAddress;
  final VoidCallback onPickViaMap;
  final VoidCallback onProceedToVehicles;

  const LocationPickerModule({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.onSelectSavedAddress,
    required this.onPickViaMap,
    required this.onProceedToVehicles,
  });

  @override
  State<LocationPickerModule> createState() => _LocationPickerModuleState();
}

class _LocationPickerModuleState extends State<LocationPickerModule> {
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  bool _isSearchingPickup = false;
  bool _isSearchingDestination = false;

  static const List<Map<String, dynamic>> savedAddresses = [
    {
      'label': 'Rumah',
      'dist': '0 km',
      'addr': 'Jl. Brawl No. 77, Lnad of down II',
      'asset': 'assets/icons/places/ic_place_rumah.png',
      'icon': Icons.home_rounded,
    },
    {
      'label': 'Kantor',
      'dist': '8,9 km',
      'addr': 'Jl. Brawl No. 77, Lnad of down II',
      'asset': 'assets/icons/places/ic_place_kantor.png',
      'icon': Icons.business_center_rounded,
    },
    {
      'label': 'Mall Centre',
      'dist': '5,7 km',
      'addr': 'Jl. Brawl No. 77, Lnad of down II',
      'asset': 'assets/icons/places/ic_place_mall.png',
      'icon': Icons.shopping_bag_rounded,
    },
  ];

  static const List<String> pickupSuggestions = [
    'Jl. Brawl No. 77, Land of down II',
    'Jl. Brawl No. 12, Land of down II',
    'Jl. Brawl No. 1, Land of down',
  ];

  static const List<String> destinationSuggestions = [
    'Jl.Ranked No. 133, Land of down IV',
    'Jl.Ranked No. 100, Land of down I',
    'Jl.Ranked No. 1, Land of down',
  ];

  @override
  void initState() {
    super.initState();
    _pickupFocusNode.addListener(() {
      setState(() {
        _isSearchingPickup = _pickupFocusNode.hasFocus;
      });
    });
    _destinationFocusNode.addListener(() {
      setState(() {
        _isSearchingDestination = _destinationFocusNode.hasFocus;
      });
    });
    widget.pickupController.addListener(_onTextChanged);
    widget.destinationController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.pickupController.removeListener(_onTextChanged);
    widget.destinationController.removeListener(_onTextChanged);
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Character Illustration Header with Blob matching Figma node [1:2948]
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 125,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // 1. Abstrak Blob ungu muda di belakang orang
                      Positioned(
                        top: 4,
                        left: -10,
                        width: 125,
                        height: 120,
                        child: Image.asset(
                          AppAssets.abstractBlob,
                          fit: BoxFit.contain,
                          color: const Color(0xFFC6BCFF).withValues(alpha: 0.75),
                        ),
                      ),

                      // 2. Ilustrasi Orang Bingung
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Image.asset(
                          AppAssets.flexrideManHeader,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Image.asset(
                    AppAssets.flexrideSpeechBubble,
                    height: 40,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),

          // Pickup & Destination Inputs Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC7BCFE).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6B48FC).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Pickup Input
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOKASI JEMPUT',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextField(
                              controller: widget.pickupController,
                              focusNode: _pickupFocusNode,
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Ketik lokasi penjemputanmu...',
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Dotted Connector
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 16,
                      color: const Color(0xFF6B48FC).withValues(alpha: 0.4),
                    ),
                  ),
                ),
                // Destination Input
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B48FC),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TUJUAN PERJALANAN',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextField(
                              controller: widget.destinationController,
                              focusNode: _destinationFocusNode,
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Ketik tujuan perjalananmu...',
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isSearchingDestination) ...[
                  const SizedBox(height: 12),
                  // Dua tombol: + Pilih Lewat Peta Langsung & + Tambah Tujuan presisi Figma masuk flex ride-1.png
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onPickViaMap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '+ Pilih Lewat Peta Langsung',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '+ Tambah Tujuan',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tampilan Suggestion saat mengetik Lokasi Jemput
          if (_isSearchingPickup) ...[
            ...pickupSuggestions.map((sugg) {
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      widget.pickupController.text = sugg;
                      _pickupFocusNode.unfocus();
                      setState(() {
                        _isSearchingPickup = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF22C55E),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF17152B),
                                ),
                                children: [
                                  TextSpan(
                                    text: sugg.substring(0, 8),
                                    style: const TextStyle(
                                        color: Color(0xFF22C55E)),
                                  ),
                                  TextSpan(text: sugg.substring(8)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F0F5)),
                ],
              );
            }),
          ] else if (_isSearchingDestination) ...[
            // Tampilan Suggestion saat mengetik tujuan (masuk flex ride-1.png)
            ...destinationSuggestions.map((sugg) {
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      widget.destinationController.text = sugg;
                      _destinationFocusNode.unfocus();
                      setState(() {
                        _isSearchingDestination = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFE83535),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF17152B),
                                ),
                                children: [
                                  TextSpan(
                                    text: sugg.substring(0, 10),
                                    style: const TextStyle(
                                        color: Color(0xFF22C55E)),
                                  ),
                                  TextSpan(text: sugg.substring(10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F0F5)),
                ],
              );
            }),
          ] else ...[
            // Section Title
            Text(
              'Alamat Favorit & Riwayat Cepat',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 12),

            // Saved Addresses List
            ...savedAddresses.map((addr) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE1DAFE),
                      Color(0xFFE1DAFE),
                      Colors.white,
                    ],
                    stops: [0.0, 0.45, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC7BCFE),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: const Color(0xFF6B48FC).withValues(alpha: 0.12),
                    highlightColor: const Color(0xFF6B48FC).withValues(alpha: 0.08),
                    onTap: () {
                      widget.pickupController.text = addr['addr'] as String;
                      widget.onSelectSavedAddress(addr['addr'] as String);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 12.0),
                      child: Row(
                        children: [
                          // Standalone clean icon (tanpa border ungu / box latar) sesuai desain Figma
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, right: 6.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: addr['asset'] != null
                                    ? Image.asset(
                                        addr['asset'] as String,
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          addr['icon'] as IconData,
                                          size: 20,
                                          color: const Color(0xFF17152B),
                                        ),
                                      )
                                    : Icon(
                                        addr['icon'] as IconData,
                                        size: 20,
                                        color: const Color(0xFF17152B),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr['label'] as String,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  addr['addr'] as String,
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: const Color(0xFF6B6680),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            addr['dist'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),

            // Tombol Lanjut Pilih Kendaraan
            Builder(
              builder: (context) {
                final bool isReady = widget.pickupController.text.trim().isNotEmpty &&
                    widget.destinationController.text.trim().isNotEmpty;
                return Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: isReady ? widget.onProceedToVehicles : null,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: isReady
                            ? const Color(0xFF17152B)
                            : const Color(0xFFC4C2CF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isReady
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lanjut Pilih Kendaraan',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isReady ? Colors.white : const Color(0xFF7E7B8E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
