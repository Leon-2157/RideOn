import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// [TermsAndConditionsSheet]
/// Bottom sheet modal Syarat & Ketentuan RideOn sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/syarat dan ketentuan.png
class TermsAndConditionsSheet extends StatelessWidget {
  final VoidCallback? onAccept;

  const TermsAndConditionsSheet({
    super.key,
    this.onAccept,
  });

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TermsAndConditionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFEAFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Syarat & Ketentuan RideOn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ketentuan umum penggunaan layanan transportas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.dark.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('btn_close_terms'),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.dark.withValues(alpha: 0.60),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.dark,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: AppColors.dark.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('1. Ketentuan Umum & Definisi'),
                  _buildBulletPoint(
                    'RideOn adalah platform perantara yang mempertemukan pihak yang menyediakan layanan transportasi (Mitra Pengemudi) dengan pihak yang membutuhkan layanan perjalanan (Penumpang/Customer).',
                  ),
                  _buildBulletPoint(
                    'RideOn tidak memiliki, menguasai, atau mengelola armada kendaraan yang digunakan oleh Mitra Pengemudi di dalam platform ini.',
                  ),
                  _buildBulletPoint(
                    'Pengguna wajib berusia minimal 17 tahun dan/atau memiliki identitas resmi (KTP/SIM/Paspor) yang sah menurut hukum Republik Indonesia. Pengguna di bawah umur wajib didampingi oleh orang dewasa saat menggunakan layanan.',
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('2. Tanggung Jawab & Kewajiban Customer'),
                  _buildBulletPoint(
                    'Customer wajib memberikan informasi titik penjemputan dan titik tujuan yang asli dan valid saat melakukan transaksi pemesanan perjalanan.',
                  ),
                  _buildBulletPoint(
                    'Customer dilarang keras membawa barang terlarang, ilegal, berbahaya, atau hewan yang tidak sesuai dengan kebijakan keselamatan selama perjalanan berlangsung.',
                  ),
                  _buildBulletPoint(
                    'Customer wajib mematuhi peraturan lalu lintas, termasuk menggunakan helm pelindung (untuk layanan ojek motor) yang disediakan oleh Mitra Pengemudi.',
                  ),
                  _buildBulletPoint(
                    'Kerusakan pada kendaraan Mitra Pengemudi di luar batas wajar pemakaian yang diakibatkan oleh kelalaian atau kesengajaan Customer akan menjadi tanggung jawab Customer sesuai nilai kerugian atau kesepakatan dengan Mitra Pengemudi.',
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('3. Tanggung Jawab & Hak Mitra Pengemudi (Driver)'),
                  _buildBulletPoint(
                    'Mitra Pengemudi bertanggung jawab penuh atas keselamatan penumpang, kelayakan jalan kendaraan, serta kesesuaian identitas dan plat nomor kendaraan dengan yang tertera di aplikasi.',
                  ),
                  _buildBulletPoint(
                    'Mitra Pengemudi berhak menolak pesanan jika Customer dinilai mencurigakan, membawa muatan berlebih/berbahaya, atau tidak memenuhi standar keselamatan berkendara.',
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('4. Batasan Tanggung Jawab'),
                  _buildBulletPoint(
                    'RideOn terlepas dari segala tuntutan hukum atas kecelakaan, kehilangan barang bawaan, cedera, atau tindakan kriminal yang dilakukan oleh pengguna atau pengemudi di luar prosedur standar operasi aplikasi.',
                  ),
                  _buildBulletPoint(
                    'Segala sengketa atau wanprestasi adalah tanggung jawab penuh antara Mitra Pengemudi dan Customer. RideOn hanya akan bertindak sebagai mediator untuk membantu menyelesaikan perselisihan jika diperlukan.',
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button: SAYA MENGERTI & SETUJU
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_setuju_syarat_ketentuan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (onAccept != null) {
                    onAccept!();
                  } else {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text(
                  'SAYA MENGERTI & SETUJU',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppColors.dark.withValues(alpha: 0.80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
