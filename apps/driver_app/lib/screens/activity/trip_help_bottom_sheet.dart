import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/theme_service.dart';

/// Model item pilihan kendala perjalanan
class TripIssueItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const TripIssueItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// [TripHelpBottomSheet]
/// Bottom sheet modal Bantuan Perjalanan RideOn:
/// - Menyajikan daftar pilihan kendala perjalanan (tarif, rute, penumpang, barang tertinggal, error aplikasi)
/// - Menyediakan tombol / kartu Hubungi Customer Service (CS) 24/7
/// - Mendukung Mode Terang & Gelap secara reaktif
class TripHelpBottomSheet extends StatelessWidget {
  final String orderId;
  final String tripType;
  final ValueChanged<TripIssueItem>? onIssueSelected;
  final VoidCallback? onContactCs;

  const TripHelpBottomSheet({
    super.key,
    this.orderId = 'ID : 12E4S79',
    this.tripType = 'Antar Penumpang',
    this.onIssueSelected,
    this.onContactCs,
  });

  static Future<void> show(
    BuildContext context, {
    String orderId = 'ID : 12E4S79',
    String tripType = 'Antar Penumpang',
    ValueChanged<TripIssueItem>? onIssueSelected,
    VoidCallback? onContactCs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripHelpBottomSheet(
        orderId: orderId,
        tripType: tripType,
        onIssueSelected: onIssueSelected,
        onContactCs: onContactCs,
      ),
    );
  }

  static const List<TripIssueItem> issues = [
    TripIssueItem(
      id: 'fare_issue',
      title: 'Tarif atau pembayaran tidak sesuai',
      subtitle: 'Nominal tunai berbeda atau ongkir bermasalah',
      icon: Icons.payments_outlined,
    ),
    TripIssueItem(
      id: 'route_issue',
      title: 'Rute atau titik lokasi tidak akurat',
      subtitle: 'Titik penjemputan atau lokasi tujuan tidak sesuai peta',
      icon: Icons.location_off_outlined,
    ),
    TripIssueItem(
      id: 'passenger_issue',
      title: 'Kendala dengan penumpang',
      subtitle: 'Penumpang sulit dihubungi, membatalkan, atau tidak hadir',
      icon: Icons.person_outline_rounded,
    ),
    TripIssueItem(
      id: 'lost_item',
      title: 'Barang penumpang tertinggal',
      subtitle: 'Terdapat barang milik penumpang yang tertinggal di kendaraan',
      icon: Icons.work_outline_rounded,
    ),
    TripIssueItem(
      id: 'app_error',
      title: 'Aplikasi bermasalah atau sinyal/GPS terputus',
      subtitle: 'Aplikasi tertutup tiba-tiba atau rute GPS macet',
      icon: Icons.phonelink_erase_rounded,
    ),
  ];

  void _handleIssueTap(BuildContext context, TripIssueItem issue) {
    if (onIssueSelected != null) {
      onIssueSelected!(issue);
      return;
    }

    Navigator.of(context).pop();

    // Tampilkan notifikasi konfirmasi laporan kendala
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Laporan diterima: ${issue.title}. Tim RideOn akan menindaklanjuti.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF17152B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleContactCs(BuildContext context) {
    if (onContactCs != null) {
      onContactCs!();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B48FC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF6B48FC),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Customer Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Layanan bantuan 24 jam siap membantu menyelesaikan kendala perjalanan Anda.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5A576E)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E5F2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.phone_in_talk_rounded, color: Color(0xFF00A838), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Center RideOn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF75718E),
                          ),
                        ),
                        Text(
                          '0800-1-RIDEON (Bebas Pulsa)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E5F2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Bantuan Driver',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF75718E),
                          ),
                        ),
                        Text(
                          '+62 812-3456-7890',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B48FC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode(context);

    final bgColor = isDark ? const Color(0xFF17152B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF28234B) : const Color(0xFFF8F7FC);
    final borderColor = isDark ? const Color(0xFF3B3566) : const Color(0xFFE8E5F2);
    final titleTextColor = isDark ? Colors.white : AppColors.dark;
    final subtitleTextColor = isDark ? const Color(0xFFAAA6C5) : const Color(0xFF75718E);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A4478) : const Color(0xFFD6D1E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B48FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bantuan Perjalanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$tripType • $orderId',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subtitleTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('btn_close_help_sheet'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: subtitleTextColor,
                      size: 22,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Konten Pilihan Kendala & Hubungi CS
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label Pilihan Kendala
                    Text(
                      'PILIHAN KENDALA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: subtitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih kendala yang sesuai untuk penanganan cepat:',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Daftar Kartu Kendala
                    ...issues.map((issue) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            key: Key('issue_${issue.id}'),
                            onTap: () => _handleIssueTap(context, issue),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF383162)
                                          : const Color(0xFFEBE6FE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      issue.icon,
                                      color: const Color(0xFF6B48FC),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          issue.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: titleTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          issue.subtitle,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subtitleTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: subtitleTextColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Kartu / Tombol Hubungi Customer Service
                    Material(
                      color: isDark ? const Color(0xFF231F42) : const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const Key('btn_contact_cs'),
                        onTap: () => _handleContactCs(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF6B48FC).withValues(alpha: 0.5)
                                  : const Color(0xFF6B48FC),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B48FC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Hubungi Customer Service',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Bantuan langsung 24/7 (WhatsApp & Call Center)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFFC6BCFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
