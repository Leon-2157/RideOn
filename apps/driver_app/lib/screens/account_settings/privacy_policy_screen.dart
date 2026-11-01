import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// [PrivacyPolicyScreen]
/// Implementasi Layar Kebijakan Privasi & Syarat sesuai spesifikasi Figma:
/// - Figma/PengaturanAkun/kebijakan.png
/// - Figma/PengaturanAkun/syarat dan ketentuan.png
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Header Bar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B68FC),
                  Color(0xFFB4A1FF),
                  Color(0xFFEBE6FE),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.dark,
                          size: 22,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Kebijakan Privasi & syarat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFC6BCFF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E2FF),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syarat & Ketentuan RideOn',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ketentuan umum penggunaan layanan transportas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Text
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 20),

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
                          const SizedBox(height: 18),

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
                          const SizedBox(height: 18),

                          _buildSectionTitle('3. Tanggung Jawab & Hak Mitra Pengemudi (Driver)'),
                          _buildBulletPoint(
                            'Mitra Pengemudi bertanggung jawab penuh atas keselamatan penumpang, kelayakan jalan kendaraan, serta kesesuaian identitas dan plat nomor kendaraan dengan yang tertera di aplikasi.',
                          ),
                          _buildBulletPoint(
                            'Mitra Pengemudi berhak menolak pesanan jika Customer dinilai mencurigakan, membawa muatan berlebih/berbahaya, atau tidak memenuhi standar keselamatan berkendara.',
                          ),
                          const SizedBox(height: 18),

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
                  ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
