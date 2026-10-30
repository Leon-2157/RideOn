import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sub_header_widget.dart';

class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildSubHeader(context, 'Kebijakan Privasi & syarat'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2DCFE), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC7BCFE),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syarat & Ketentuan RideOn',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketentuan umum penggunaan layanan transportasi',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              color: const Color(0xFF4C4566),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Terms
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, '
                            'Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF4C4566),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('1. Ketentuan Umum & Definisi'),
                          _buildSectionBody(
                            '• RideOn adalah platform perantara yang mempertemukan pihak yang menyediakan layanan transportasi (Mitra Pengemudi) dengan pihak yang membutuhkan layanan perjalanan (Penumpang/Customer).\n'
                            '• RideOn tidak memiliki, menguasai, atau mengelola armada kendaraan yang digunakan oleh Mitra Pengemudi di dalam platform ini.\n'
                            '• Pengguna wajib berusia minimal 17 tahun dan/atau memiliki identitas resmi (KTP/SIM/Paspor) yang sah menurut hukum Republik Indonesia.',
                          ),
                          const SizedBox(height: 14),
                          _buildSectionTitle('2. Tanggung Jawab & Kewajiban Customer'),
                          _buildSectionBody(
                            '• Customer wajib memberikan informasi titik penjemputan dan titik tujuan yang asli dan valid saat melakukan transaksi pemesanan perjalanan.\n'
                            '• Customer dilarang keras membawa barang terlarang, ilegal, berbahaya, atau hewan yang tidak sesuai dengan kebijakan keselamatan.\n'
                            '• Customer wajib mematuhi peraturan lalu lintas, termasuk menggunakan helm pelindung yang disediakan oleh Mitra Pengemudi.',
                          ),
                          const SizedBox(height: 14),
                          _buildSectionTitle('3. Tanggung Jawab & Hak Mitra Pengemudi (Driver)'),
                          _buildSectionBody(
                            '• Mitra Pengemudi bertanggung jawab penuh atas keselamatan penumpang, kelayakan jalan kendaraan, serta kesesuaian identitas dan plat nomor kendaraan.\n'
                            '• Mitra Pengemudi berhak menolak pesanan jika Customer dinilai mencurigakan atau membawa muatan berlebih.',
                          ),
                          const SizedBox(height: 14),
                          _buildSectionTitle('4. Batasan Tanggung Jawab'),
                          _buildSectionBody(
                            '• RideOn terlepas dari segala tuntutan hukum atas kecelakaan, kehilangan barang bawaan, cedera, atau tindakan kriminal di luar prosedur standar aplikasi.\n'
                            '• Segala sengketa adalah tanggung jawab penuh antara Mitra Pengemudi dan Customer. RideOn bertindak sebagai mediator untuk membantu menyelesaikan perselisihan.',
                          ),
                          const SizedBox(height: 20),
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
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF17152B),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        body,
        style: GoogleFonts.roboto(
          fontSize: 10.5,
          color: const Color(0xFF4C4566),
          height: 1.45,
        ),
      ),
    );
  }
}

