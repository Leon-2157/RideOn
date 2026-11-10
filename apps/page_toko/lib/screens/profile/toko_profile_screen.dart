import 'package:flutter/material.dart';
import '../../data/toko_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_image.dart';
import 'edit_profile_screen.dart';

class TokoProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const TokoProfileScreen({super.key, this.onLogout});

  @override
  State<TokoProfileScreen> createState() => _TokoProfileScreenState();
}

class _TokoProfileScreenState extends State<TokoProfileScreen> {
  void _openEditProfileSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: TokoState.ownerName.value,
          initialStoreName: TokoState.storeName.value,
          initialAvatar: TokoState.ownerAvatar.value,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      if (result['name'] != null) {
        TokoState.ownerName.value = result['name'] as String;
      }
      if (result['storeName'] != null) {
        TokoState.storeName.value = result['storeName'] as String;
      }
      if (result['photoPath'] != null) {
        TokoState.ownerAvatar.value = result['photoPath'] as String;
      }
    }
  }

  void _openOperationalHoursSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperationalHoursSheet(
        days: TokoState.operationalDays.value,
        openHour: TokoState.openHour.value,
        closeHour: TokoState.closeHour.value,
        onSave: (d, o, c) {
          TokoState.operationalDays.value = d;
          TokoState.openHour.value = o;
          TokoState.closeHour.value = c;
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
        address: TokoState.storeAddress.value,
        postal: TokoState.storePostal.value,
        country: TokoState.storeCountry.value,
        onSave: (newAddr, newPostal, newCountry) {
          TokoState.storeAddress.value = newAddr;
          TokoState.storePostal.value = newPostal;
          TokoState.storeCountry.value = newCountry;
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
        child: ListenableBuilder(
          listenable: Listenable.merge([
            TokoState.isStoreOpen,
            TokoState.storeName,
            TokoState.ownerName,
            TokoState.storeCategory,
            TokoState.operationalDays,
            TokoState.openHour,
            TokoState.closeHour,
            TokoState.storeAddress,
            TokoState.storePostal,
            TokoState.storeCountry,
            TokoState.ownerAvatar,
          ]),
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Profil Toko',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
            );
          },
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
          GestureDetector(
            onTap: _openEditProfileSheet,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 2),
              ),
              child: AppImage(
                assetPath: TokoState.ownerAvatar.value,
                width: 80,
                height: 80,
                borderRadius: const BorderRadius.all(Radius.circular(40)),
                fit: BoxFit.cover,
                placeholder: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: Builder(
                      builder: (_) {
                        final parts = TokoState.storeName.value
                            .trim()
                            .split(RegExp(r'\s+'))
                            .where((p) => p.isNotEmpty)
                            .toList();
                        final ini = parts.length > 1
                            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                            : (parts.isNotEmpty ? parts[0][0].toUpperCase() : 'T');
                        return Text(
                          ini,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            TokoState.storeName.value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${TokoState.storeCategory.value} • ${TokoState.ownerName.value}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: TokoState.isStoreOpen.value ? AppColors.primarySoft : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              TokoState.isStoreOpen.value ? 'BUKA' : 'TUTUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: TokoState.isStoreOpen.value ? AppColors.primary : AppColors.danger,
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
              children: [
                const Text(
                  'Toko Buka / Tutup',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TokoState.isStoreOpen.value
                      ? 'Toko aktif menerima pesanan masuk'
                      : 'Toko tutup sementara, pesanan dijeda',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: TokoState.isStoreOpen.value,
            onChanged: (val) => TokoState.isStoreOpen.value = val,
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
            subtitle: '${TokoState.operationalDays.value} ${TokoState.openHour.value} - ${TokoState.closeHour.value}',
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
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Apakah Anda Yakin',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 90,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.onLogout?.call();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Iya', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 90,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Tidak', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Jam Operasional',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
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
                    key: const Key('input_op_days'),
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
                    key: const Key('input_op_open'),
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
                    key: const Key('input_op_close'),
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
                  final days = _daysController.text.trim();
                  final open = _openController.text.trim();
                  final close = _closeController.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  if (days.isEmpty || open.isEmpty || close.isEmpty) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Hari dan jam operasional wajib diisi'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }
                  final timePattern = RegExp(r'^([01]\d|2[0-3])[:.]([0-5]\d)$');
                  final openMatch = timePattern.firstMatch(open);
                  final closeMatch = timePattern.firstMatch(close);
                  if (openMatch == null || closeMatch == null) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Format jam harus HH.MM atau HH:MM (contoh: 08.00)'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }
                  final openMinutes = int.parse(openMatch.group(1)!) * 60 + int.parse(openMatch.group(2)!);
                  final closeMinutes = int.parse(closeMatch.group(1)!) * 60 + int.parse(closeMatch.group(2)!);
                  if (openMinutes >= closeMinutes) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Jam tutup harus lebih besar dari jam buka'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }
                  widget.onSave(days, open, close);
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
    );
  }
}

class _LocationSheet extends StatefulWidget {
  final String address;
  final String postal;
  final String country;
  final void Function(String address, String postal, String country) onSave;

  const _LocationSheet({
    required this.address,
    required this.postal,
    required this.country,
    required this.onSave,
  });

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late TextEditingController _addressController;
  late TextEditingController _postalController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
    _postalController = TextEditingController(text: widget.postal);
    _countryController = TextEditingController(text: widget.country);
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
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Lokasi Toko',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pastikan alamat lengkap sesuai lokasi pengiriman')),
                    );
                  },
                  child: const Text('Bantuan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const AppImage(
                          assetPath: 'assets/images/map_satellite.png',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7), width: 2),
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.3),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 24),
                        ),
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
                    keyboardType: TextInputType.number,
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
                        final addr = _addressController.text.trim();
                        final postal = _postalController.text.trim();
                        final country = _countryController.text.trim();
                        if (addr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alamat toko wajib diisi'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        if (postal.isNotEmpty && !RegExp(r'^\d{5,}$').hasMatch(postal)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kode pos harus minimal 5 digit angka'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        if (country.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Negara wajib diisi'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        widget.onSave(addr, postal, country);
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
