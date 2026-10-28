import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TokoProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const TokoProfileScreen({super.key, this.onLogout});

  @override
  State<TokoProfileScreen> createState() => _TokoProfileScreenState();
}

class _TokoProfileScreenState extends State<TokoProfileScreen> {
  bool _isStoreOpen = true;
  String _storeName = 'Warung Taufiq Gateng';
  String _storeCategory = 'Katering & Masakan Nusantara';
  String _operationalDays = 'Senin - Jumat';
  String _openHour = '07.00';
  String _closeHour = '20.00';
  String _address = 'Meunasah Pinto, Kec. Muara Batu, Kabupaten Aceh Utara, Aceh';

  void _openEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        name: _storeName,
        category: _storeCategory,
        onSave: (newName, newCat) {
          setState(() {
            _storeName = newName;
            _storeCategory = newCat;
          });
        },
      ),
    );
  }

  void _openOperationalHoursSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperationalHoursSheet(
        days: _operationalDays,
        openHour: _openHour,
        closeHour: _closeHour,
        onSave: (d, o, c) {
          setState(() {
            _operationalDays = d;
            _openHour = o;
            _closeHour = c;
          });
        },
      ),
    );
  }

  void _openLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(
        address: _address,
        onSave: (newAddr) {
          setState(() => _address = newAddr);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: profile settings combined in one screen; upgrade to nested sub-routes when account settings expand
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profil Toko',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pusat Bantuan Mitra Toko')),
                      );
                    },
                    child: const Text(
                      'Bantuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStoreHeroCard(),
              const SizedBox(height: 16),
              _buildAutoAcceptCard(),
              const SizedBox(height: 16),
              _buildSettingsListCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE27C3E), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'WT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _storeName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _storeCategory,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _isStoreOpen ? AppColors.primarySoft : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isStoreOpen ? 'BUKA' : 'TUTUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _isStoreOpen ? AppColors.primary : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoAcceptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Toko Buka / Tutup',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Terima pesanan secara otomatis',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isStoreOpen,
            onChanged: (val) => setState(() => _isStoreOpen = val),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsListCard() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _settingItem(
            icon: Icons.edit_outlined,
            title: 'Edit Profil Toko',
            onTap: _openEditProfileSheet,
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _settingItem(
            icon: Icons.access_time_rounded,
            title: 'Jam Operasional',
            subtitle: '$_operationalDays $_openHour - $_closeHour',
            onTap: _openOperationalHoursSheet,
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _settingItem(
            icon: Icons.location_on_outlined,
            title: 'Pengaturan Lokasi',
            onTap: _openLocationSheet,
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _settingItem(
            icon: Icons.cancel_outlined,
            title: 'Keluar Akun',
            titleColor: AppColors.danger,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Keluar Akun?'),
                  content: const Text('Anda akan keluar dari sesi toko ini.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLogout?.call();
                      },
                      child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: titleColor ?? AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String name;
  final String category;
  final Function(String, String) onSave;

  const _EditProfileSheet({
    required this.name,
    required this.category,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _categoryController = TextEditingController(text: widget.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Profil Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Nama Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Kategori Masakan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_nameController.text.trim(), _categoryController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalHoursSheet extends StatefulWidget {
  final String days;
  final String openHour;
  final String closeHour;
  final Function(String, String, String) onSave;

  const _OperationalHoursSheet({
    required this.days,
    required this.openHour,
    required this.closeHour,
    required this.onSave,
  });

  @override
  State<_OperationalHoursSheet> createState() => _OperationalHoursSheetState();
}

class _OperationalHoursSheetState extends State<_OperationalHoursSheet> {
  late TextEditingController _daysController;
  late TextEditingController _openController;
  late TextEditingController _closeController;

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: widget.days);
    _openController = TextEditingController(text: widget.openHour);
    _closeController = TextEditingController(text: widget.closeHour);
  }

  @override
  void dispose() {
    _daysController.dispose();
    _openController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jam Operasional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hari Buka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _daysController,
                  decoration: InputDecoration(
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textPrimary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Jam Buka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _openController,
                  decoration: InputDecoration(
                    suffixIcon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textPrimary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Jam Tutup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _closeController,
                  decoration: InputDecoration(
                    suffixIcon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textPrimary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onSave(_daysController.text.trim(), _openController.text.trim(), _closeController.text.trim());
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSheet extends StatefulWidget {
  final String address;
  final ValueChanged<String> onSave;

  const _LocationSheet({required this.address, required this.onSave});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late TextEditingController _addressController;
  final TextEditingController _postalController = TextEditingController(text: '24374');
  final TextEditingController _countryController = TextEditingController(text: 'Indonesia');

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    const Text('Lokasi Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Text('Bantuan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E382E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 2),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                        ),
                        const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Alamat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.primarySoft.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Kode Pos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _postalController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.primarySoft.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Negara', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _countryController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.primarySoft.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onSave(_addressController.text.trim());
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
