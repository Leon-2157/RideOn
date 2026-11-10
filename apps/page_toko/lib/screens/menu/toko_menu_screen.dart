import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_image.dart';

class TokoMenuScreen extends StatefulWidget {
  const TokoMenuScreen({super.key});

  @override
  State<TokoMenuScreen> createState() => _TokoMenuScreenState();
}

class _TokoMenuScreenState extends State<TokoMenuScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'id': '1',
      'name': 'Nasi Goreng Spesial',
      'category': 'Makanan Utama',
      'desc': 'Nasi goreng bumbu rempah dengan telur mata sapi dan ayam suwir.',
      'price': 25000,
      'isAvailable': true,
      'image': 'assets/images/food_nasgor.png',
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

  void _deleteMenuItem(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Menu?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "$name" dari daftar menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _menuItems.removeWhere((m) => m['id'] == id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Menu "$name" dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
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
    final categories = [
      'Semua (${_menuItems.length})',
      'Makanan Utama',
      'Minuman',
      'Cemilan',
    ];
    final query = _searchController.text.toLowerCase();
    final filtered = _menuItems.where((m) {
      final matchesSearch = (m['name'] as String).toLowerCase().contains(query);
      if (!matchesSearch) return false;
      if (_selectedCategoryIndex == 1) return m['category'] == 'Makanan Utama';
      if (_selectedCategoryIndex == 2) return m['category'] == 'Minuman';
      if (_selectedCategoryIndex == 3) return m['category'] == 'Cemilan';
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
                  const Expanded(
                    child: Text(
                      'Daftar Menu',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                children: List.generate(categories.length, (index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(categories[index]),
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
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: item['image'] != null
                                    ? AppImage(
                                        assetPath: item['image'] as String,
                                        width: 72,
                                        height: 72,
                                        borderRadius: BorderRadius.circular(14),
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
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
                                        Expanded(
                                          child: Text(
                                            'Rp ${(item['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _deleteMenuItem(item['id'] as String, item['name'] as String),
                                              child: const Padding(
                                                padding: EdgeInsets.only(right: 10),
                                                child: Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: AppColors.danger,
                                                  size: 20,
                                                ),
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
  String? _imagePath;
  String? _imageError;
  String? _nameError;
  String? _priceError;
  final ImagePicker _picker = ImagePicker();

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
    if (widget.item != null && widget.item?['image'] != null) {
      _imagePath = widget.item!['image'] as String?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final fileSize = await picked.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            setState(() {
              _imageError = 'Ukuran foto maksimal 5MB.';
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _imagePath = picked.path;
            _imageError = null;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _imageError = 'Gagal memilih foto: $e';
      });
    }
  }

  void _openPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Foto Menu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPickerOption(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Dari Kamera',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _buildPickerOption(
                icon: Icons.image_rounded,
                title: 'Pilih Dari Galeri',
                subtitle: 'Pilih Foto Dari Perangkat',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                _buildPickerOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Hapus Foto',
                  subtitle: 'Gunakan Ikon Default',
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _imagePath = null;
                      _imageError = null;
                    });
                  },
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optColor = color ?? AppColors.primary;
    return Material(
      color: const Color(0xFFF5F3FF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: optColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color ?? AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final priceVal = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    bool hasError = false;
    if (name.isEmpty) {
      setState(() => _nameError = 'Nama menu wajib diisi');
      hasError = true;
    }
    if (priceVal <= 0) {
      setState(() => _priceError = 'Harga harus lebih dari Rp 0');
      hasError = true;
    }
    if (hasError) return;

    final data = <String, dynamic>{
      'id': widget.item?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'category': _selectedCategory,
      'desc': _descController.text.trim(),
      'price': priceVal,
      'isAvailable': widget.item?['isAvailable'] ?? true,
    };
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      data['image'] = _imagePath;
    }

    widget.onSave(data);
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
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foto Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    key: const Key('btn_upload_menu_photo'),
                    onTap: _openPhotoPickerSheet,
                    child: _imagePath != null
                        ? Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: AppImage(
                                    assetPath: _imagePath!,
                                    borderRadius: BorderRadius.circular(16),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.dark.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Ubah Foto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
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
                  ),
                  if (_imageError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _imageError!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text('Nama Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama menu',
                      errorText: _nameError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
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
                    onChanged: (_) {
                      if (_priceError != null) setState(() => _priceError = null);
                    },
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      errorText: _priceError,
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
