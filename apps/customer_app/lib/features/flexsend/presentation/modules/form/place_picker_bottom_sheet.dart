import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../flexride/presentation/modules/map/simulated_map_view.dart';

class PlacePickerBottomSheet extends StatefulWidget {
  final int locationIndex; // 1, 2, or 3
  final Function(String placeName, String address) onPlaceSelected;

  const PlacePickerBottomSheet({
    super.key,
    required this.locationIndex,
    required this.onPlaceSelected,
  });

  @override
  State<PlacePickerBottomSheet> createState() => _PlacePickerBottomSheetState();
}

class _PlacePickerBottomSheetState extends State<PlacePickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _suggestions = [
    {
      'name': 'Pasar Pagi Batuphat',
      'category': 'Pasar Tradisional & Bahan Pokok',
      'address': 'Jl. Medan - Banda Aceh, Batuphat Timur',
      'distance': '1.2 km',
    },
    {
      'name': 'Apotek Kimia Farma',
      'category': 'Apotek & Obat Rutin',
      'address': 'Jl. Perdagangan No. 8, Lhokseumawe',
      'distance': '2.4 km',
    },
    {
      'name': 'Supermarket Suzuya Mall',
      'category': 'Supermarket & Kebutuhan Rumah',
      'address': 'Jl. Samudera No. 1, Simpang Empat',
      'distance': '3.1 km',
    },
    {
      'name': 'Toko Buah Segar Berkah',
      'category': 'Aneka Buah Lokal & Import',
      'address': 'Jl. Merdeka Barat No. 45',
      'distance': '1.8 km',
    },
    {
      'name': 'Minimarket Indomaret Sudirman',
      'category': 'Minimarket 24 Jam',
      'address': 'Jl. Jend. Sudirman No. 12',
      'distance': '0.9 km',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchController.text.trim().isEmpty
        ? _suggestions
        : _suggestions.where((item) {
            final query = _searchController.text.toLowerCase();
            return item['name']!.toLowerCase().contains(query) ||
                item['address']!.toLowerCase().contains(query);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_location_alt_rounded,
                      size: 20, color: Color(0xFF6B48FC)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Lokasi ${widget.locationIndex == 1 ? "Utama" : "Singgah ke-${widget.locationIndex}"}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      Text(
                        'Pilih dari peta atau cari nama pasar / toko',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: const Color(0xFF6B6680),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF17152B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Google Maps View Mini Interactive Section
          Container(
            height: 170,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2DCFE), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  const SimulatedMapView(showRoute: false),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 36,
                          color: Color(0xFF6B48FC),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17152B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Titik Lokasi Terpilih',
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ketik nama toko, pasar, apotek...',
                hintStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF6B48FC), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9F8FF),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDD5FE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF6B48FC), width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Custom Input Button jika tidak ada di saran
          if (_searchController.text.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  widget.onPlaceSelected(
                    _searchController.text.trim(),
                    'Lokasi ditentukan pengguna',
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_business_rounded,
                          size: 18, color: Color(0xFF6B48FC)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gunakan "${_searchController.text.trim()}" sebagai nama lokasi',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B48FC),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: Color(0xFF6B48FC)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Suggestions List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: filtered.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xFFF3F0FF), height: 1),
              itemBuilder: (context, index) {
                final place = filtered[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Color(0xFF6B48FC), size: 20),
                  ),
                  title: Text(
                    place['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  subtitle: Text(
                    '${place['category']} • ${place['distance']}',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFC6BCFF)),
                  onTap: () {
                    final selectedName = place['name']!;
                    final selectedAddress = place['address']!;
                    Navigator.of(context).pop();
                    widget.onPlaceSelected(selectedName, selectedAddress);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
