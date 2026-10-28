import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TokoMenuScreen extends StatefulWidget {
  const TokoMenuScreen({super.key});

  @override
  State<TokoMenuScreen> createState() => _TokoMenuScreenState();
}

class _TokoMenuScreenState extends State<TokoMenuScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua (24)',
    'Makanan Utama',
    'Minuman',
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'id': '1',
      'name': 'Nasi Goreng Spesial',
      'category': 'Makanan Utama',
      'desc': 'Nasi goreng bumbu rempah dengan telur mata sapi dan ayam suwir.',
      'price': 25000,
      'isAvailable': true,
    },
    {
      'id': '2',
      'name': 'Ayam Bakar Madu',
      'category': 'Makanan Utama',
      'desc': 'Ayam bakar manis gurih lengkap sambal dan lalapan segar.',
      'price': 30000,
      'isAvailable': true,
    },
    {
      'id': '3',
      'name': 'Es Teh Manis Jumbo',
      'category': 'Minuman',
      'desc': 'Es teh segar dengan gula tebu asli ukuran jumbo.',
      'price': 6000,
      'isAvailable': false,
    },
    {
      'id': '4',
      'name': 'Ayam Geprek Sambal Korek',
      'category': 'Makanan Utama',
      'desc': 'Ayam krispi digeprek dengan cabai rawit pedas nikmat.',
      'price': 22000,
      'isAvailable': true,
    },
    {
      'id': '5',
      'name': 'Jus Alpukat Kocok',
      'category': 'Minuman',
      'desc': 'Alpukat mentega murni dengan saus coklat premium.',
      'price': 15000,
      'isAvailable': true,
    },
  ];

  void _openAddEditMenuModal({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditMenuSheet(
        item: item,
        onSave: (newItem) {
          setState(() {
            if (item != null) {
              final idx = _menuItems.indexWhere((m) => m['id'] == item['id']);
              if (idx != -1) _menuItems[idx] = newItem;
            } else {
              _menuItems.insert(0, newItem);
            }
          });
        },
      ),
    );
  }

  void _toggleAvailability(int index) {
    setState(() {
      _menuItems[index]['isAvailable'] = !(_menuItems[index]['isAvailable'] as bool);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: in-memory menu state; upgrade to persistent local storage / SQLite when offline mode required
    final query = _searchController.text.toLowerCase();
    final filtered = _menuItems.where((m) {
      final matchesSearch = (m['name'] as String).toLowerCase().contains(query);
      if (!matchesSearch) return false;
      if (_selectedCategoryIndex == 1) return m['category'] == 'Makanan Utama';
      if (_selectedCategoryIndex == 2) return m['category'] == 'Minuman';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Menu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddEditMenuModal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama menu...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(_categories[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategoryIndex = index);
                        }
                      },
                      selectedColor: AppColors.dark,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.dark : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      showCheckmark: false,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.restaurant_menu_rounded, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'Menu tidak ditemukan',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isAvailable = item['isAvailable'] as bool;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  item['category'] == 'Minuman'
                                      ? Icons.local_drink_rounded
                                      : Icons.lunch_dining_rounded,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            final masterIdx = _menuItems.indexWhere((m) => m['id'] == item['id']);
                                            if (masterIdx != -1) _toggleAvailability(masterIdx);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isAvailable ? AppColors.primarySoft : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isAvailable ? 'Tersedia' : 'Habis',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isAvailable ? AppColors.primary : AppColors.danger,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['desc'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Rp ${(item['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _openAddEditMenuModal(item: item),
                                          child: const Icon(
                                            Icons.edit_note_rounded,
                                            color: AppColors.primary,
                                            size: 22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditMenuSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _AddEditMenuSheet({this.item, required this.onSave});

  @override
  State<_AddEditMenuSheet> createState() => _AddEditMenuSheetState();
}

class _AddEditMenuSheetState extends State<_AddEditMenuSheet> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  String _selectedCategory = 'Makanan Utama';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?['name'] ?? '');
    _priceController = TextEditingController(
      text: widget.item != null ? widget.item!['price'].toString() : '',
    );
    _descController = TextEditingController(text: widget.item?['desc'] ?? '');
    if (widget.item != null && widget.item?['category'] != null) {
      _selectedCategory = widget.item!['category'] as String;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    final priceVal = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    widget.onSave({
      'id': widget.item?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'desc': _descController.text.trim(),
      'price': priceVal,
      'isAvailable': widget.item?['isAvailable'] ?? true,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  isEditing ? 'Edit Menu' : 'Tambah Menu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foto Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(height: 10),
                        const Text('Unggah Foto Menu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Format JPG, PNG maksimal 5MB', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Nama Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama menu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: const [
                      DropdownMenuItem(value: 'Makanan Utama', child: Text('Makanan Utama')),
                      DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                      DropdownMenuItem(value: 'Cemilan', child: Text('Cemilan')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Harga (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Deskripsi Menu (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis deskripsi menu...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'Simpan Perubahan' : 'Simpan Menu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
