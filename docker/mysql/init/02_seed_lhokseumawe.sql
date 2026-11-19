SET NAMES utf8mb4;
SET time_zone = '+07:00';

USE `rideon_db`;

-- Demo seed data for Lhokseumawe & Aceh Utara (Bukit Indah, Blang Pulo, Reuleut, Muara Batu).
-- Admin bcrypt hash = RideOnAdmin2026!, demo user hash = RideOnDemo2026!, store PIN hash = 123456.

INSERT INTO `users` (`id`, `email`, `phone`, `password_hash`, `google_uid`, `firebase_uid`, `name`, `role`, `status`, `avatar_url`)
VALUES
  ('00000000-0000-4000-8000-000000000001', 'admin@rideons.app', '628116700001', '$2a$10$qnJjbPYAegfYJ9fCFFsdOOCAu0TH3gPoSpawhQVnd6glJnRJyOS.C', NULL, 'fb-admin-001', 'Super Admin RideOn Lhokseumawe', 'ADMIN', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000101', 'cut.meutia@mhs.unimal.ac.id', '6285260000101', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-cust-101', 'Cut Meutia Sari', 'CUSTOMER', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000102', 'teuku.ryan@mhs.unimal.ac.id', '6285260000102', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-cust-102', 'Teuku Ryan Alfarizi', 'CUSTOMER', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000201', 'zulkifli.motor@rideons.app', '6285260000201', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-drv-201', 'Zulkifli Gampong Blang Pulo', 'DRIVER', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000202', 'hendrik.motor@rideons.app', '6285260000202', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-drv-202', 'Hendrik Saputra Bukit Indah', 'DRIVER', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000203', 'muhammad.mobil@rideons.app', '6285260000203', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-drv-203', 'Muhammad Rizal Reuleut', 'DRIVER', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000204', 'syahrul.mobil@rideons.app', '6285260000204', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-drv-204', 'Syahrul Ramadhan Muara Batu', 'DRIVER', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000205', 'fauzi.pending@rideons.app', '6285260000205', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-drv-205', 'Ahmad Fauzi Krueng Geukueh', 'DRIVER', 'PENDING_APPROVAL', NULL),
  ('00000000-0000-4000-8000-000000000301', 'mieaceh.bukitindah@rideons.app', '6285260000301', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-str-301', 'Bang Joni Mie Aceh', 'STORE', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000302', 'kopi.blangpulo@rideons.app', '6285260000302', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-str-302', 'Tgk. Maimun Kopi Sanger', 'STORE', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000303', 'geprek.unimal@rideons.app', '6285260000303', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-str-303', 'Kak Nisa Geprek Kampus', 'STORE', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000304', 'naspad.reuleut@rideons.app', '6285260000304', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-str-304', 'Uda Hendra Minang Reuleut', 'STORE', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000305', 'martabak.muarabatu@rideons.app', '6285260000305', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-str-305', 'Bang Dedi Martabak Krueng Mane', 'STORE', 'ACTIVE', NULL),
  ('00000000-0000-4000-8000-000000000306', 'dimsum.pending@rideons.app', '6285260000306', '$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2', NULL, 'fb-str-306', 'Rina Dimsum Blang Pulo', 'STORE', 'PENDING_APPROVAL', NULL)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `password_hash` = VALUES(`password_hash`),
  `role` = VALUES(`role`),
  `status` = VALUES(`status`);

INSERT INTO `drivers` (`id`, `user_id`, `vehicle_type`, `vehicle_brand`, `vehicle_plate`, `ktp_number`, `sim_number`, `is_online`, `cash_float_amount`, `last_lat`, `last_lng`, `rating_avg`, `total_trips`, `approved_by`, `approved_at`)
VALUES
  ('10000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000201', 'MOTOR', 'Honda Beat Street Hitam', 'BL 4512 N', '1173011205950001', '950511730001', 1, 150000, 5.2039000, 97.0642000, 4.92, 87, '00000000-0000-4000-8000-000000000001', NOW()),
  ('10000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000202', 'MOTOR', 'Yamaha NMAX Merah', 'BL 3819 NA', '1173011808970002', '970811730002', 1, 200000, 5.2012000, 97.0615000, 4.88, 64, '00000000-0000-4000-8000-000000000001', NOW()),
  ('10000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-000000000203', 'MOBIL', 'Toyota Avanza Veloz Putih', 'BL 1284 K', '1108022103900003', '900311080003', 1, 300000, 5.2215000, 96.9531000, 4.95, 112, '00000000-0000-4000-8000-000000000001', NOW()),
  ('10000000-0000-4000-8000-000000000204', '00000000-0000-4000-8000-000000000204', 'MOBIL', 'Daihatsu Sigra Silver', 'BL 1892 Z', '1108020511920004', '921111080004', 1, 250000, 5.2398000, 96.9310000, 4.85, 53, '00000000-0000-4000-8000-000000000001', NOW()),
  ('10000000-0000-4000-8000-000000000205', '00000000-0000-4000-8000-000000000205', 'MOTOR', 'Honda Vario 160 Hitam', 'BL 5521 NB', '1108031407990005', '990711080005', 0, 100000, 5.2340000, 97.0220000, 5.00, 0, NULL, NULL)
ON DUPLICATE KEY UPDATE
  `vehicle_type` = VALUES(`vehicle_type`),
  `is_online` = VALUES(`is_online`),
  `cash_float_amount` = VALUES(`cash_float_amount`),
  `last_lat` = VALUES(`last_lat`),
  `last_lng` = VALUES(`last_lng`);

INSERT INTO `stores` (`id`, `user_id`, `store_name`, `category`, `description`, `address`, `lat`, `lng`, `is_open`, `open_time`, `close_time`, `pin_hash`, `rating_avg`, `approved_by`, `approved_at`)
VALUES
  ('20000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000301', 'Mie Aceh & Martabak Bukit Indah', 'Mie & Seafood', 'Spesialis Mie Aceh Kepiting, Daging Sapi, dan Martabak Telur depan Gerbang Kampus Unimal Bukit Indah.', 'Jl. Kampus Unimal Bukit Indah, Blang Pulo, Kec. Muara Satu, Kota Lhokseumawe', 5.2041000, 97.0638000, 1, '09:00', '23:30', '$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2', 4.91, '00000000-0000-4000-8000-000000000001', NOW()),
  ('20000000-0000-4000-8000-000000000302', '00000000-0000-4000-8000-000000000302', 'Warkop Sanger & Kopi Khop Blang Pulo', 'Kopi & Minuman', 'Kopi Sanger Arabika Gayo, Kopi Khop, Timphan, dan Cane Susu favorit mahasiswa Blang Pulo.', 'Jl. Medan - Banda Aceh, Gampong Blang Pulo, Kec. Muara Satu, Kota Lhokseumawe', 5.2015000, 97.0619000, 1, '07:00', '23:59', '$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2', 4.95, '00000000-0000-4000-8000-000000000001', NOW()),
  ('20000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-000000000303', 'Ayam Geprek & Lalapan Kampus Unimal', 'Ayam & Bebek', 'Ayam Geprek Sambal Bawang & Sambal Ijo level 1-10 gratis es teh untuk mahasiswa.', 'Lorong Merpati II, Bukit Indah, Blang Pulo, Kota Lhokseumawe', 5.2052000, 97.0651000, 1, '10:00', '22:00', '$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2', 4.87, '00000000-0000-4000-8000-000000000001', NOW()),
  ('20000000-0000-4000-8000-000000000304', '00000000-0000-4000-8000-000000000304', 'RM Minang & Kuah Beulangong Reuleut', 'Nasi & Lauk', 'Nasi Padang Rendang Sapi, Ayam Pop, dan Kuah Beulangong khas Aceh Utara dekat Kampus Unimal Reuleut.', 'Jl. Kampus Unimal Reuleut Timu, Kec. Muara Batu, Kab. Aceh Utara', 5.2218000, 96.9535000, 1, '08:00', '21:30', '$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2', 4.89, '00000000-0000-4000-8000-000000000001', NOW()),
  ('20000000-0000-4000-8000-000000000305', '00000000-0000-4000-8000-000000000305', 'Martabak Durian & Roti Cane Muara Batu', 'Jajanan & Dessert', 'Martabak Durian Asli Aceh Utara, Roti Cane Coklat Keju, dan Sate Matang Krueng Mane.', 'Simpang Pasar Krueng Mane, Kec. Muara Batu, Kab. Aceh Utara', 5.2401000, 96.9308000, 1, '15:00', '23:30', '$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2', 4.93, '00000000-0000-4000-8000-000000000001', NOW()),
  ('20000000-0000-4000-8000-000000000306', '00000000-0000-4000-8000-000000000306', 'Dimsum Mentai & Seblak Blang Pulo', 'Jajanan & Dessert', 'Dimsum Ayam Udang saus mentai bakar dan Seblak Prasmanan.', 'Jl. Darussalam Blang Pulo, Kec. Muara Satu, Kota Lhokseumawe', 5.2028000, 97.0627000, 0, '11:00', '22:00', '$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2', 5.00, NULL, NULL)
ON DUPLICATE KEY UPDATE
  `store_name` = VALUES(`store_name`),
  `pin_hash` = VALUES(`pin_hash`),
  `is_open` = VALUES(`is_open`),
  `lat` = VALUES(`lat`),
  `lng` = VALUES(`lng`);

INSERT INTO `registrations` (`id`, `user_id`, `applicant_role`, `status`, `payload_json`, `reviewed_by`, `reviewed_at`)
VALUES
  ('30000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000201', 'DRIVER', 'APPROVED', JSON_OBJECT('vehicle_type', 'MOTOR', 'vehicle_brand', 'Honda Beat Street Hitam', 'vehicle_plate', 'BL 4512 N', 'area', 'Blang Pulo'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000202', 'DRIVER', 'APPROVED', JSON_OBJECT('vehicle_type', 'MOTOR', 'vehicle_brand', 'Yamaha NMAX Merah', 'vehicle_plate', 'BL 3819 NA', 'area', 'Bukit Indah'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-000000000203', 'DRIVER', 'APPROVED', JSON_OBJECT('vehicle_type', 'MOBIL', 'vehicle_brand', 'Toyota Avanza Veloz Putih', 'vehicle_plate', 'BL 1284 K', 'area', 'Reuleut'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000204', '00000000-0000-4000-8000-000000000204', 'DRIVER', 'APPROVED', JSON_OBJECT('vehicle_type', 'MOBIL', 'vehicle_brand', 'Daihatsu Sigra Silver', 'vehicle_plate', 'BL 1892 Z', 'area', 'Muara Batu'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000205', '00000000-0000-4000-8000-000000000205', 'DRIVER', 'PENDING', JSON_OBJECT('vehicle_type', 'MOTOR', 'vehicle_brand', 'Honda Vario 160 Hitam', 'vehicle_plate', 'BL 5521 NB', 'area', 'Krueng Geukueh'), NULL, NULL),
  ('30000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000301', 'STORE', 'APPROVED', JSON_OBJECT('store_name', 'Mie Aceh & Martabak Bukit Indah', 'area', 'Bukit Indah'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000302', '00000000-0000-4000-8000-000000000302', 'STORE', 'APPROVED', JSON_OBJECT('store_name', 'Warkop Sanger & Kopi Khop Blang Pulo', 'area', 'Blang Pulo'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-000000000303', 'STORE', 'APPROVED', JSON_OBJECT('store_name', 'Ayam Geprek & Lalapan Kampus Unimal', 'area', 'Bukit Indah'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000304', '00000000-0000-4000-8000-000000000304', 'STORE', 'APPROVED', JSON_OBJECT('store_name', 'RM Minang & Kuah Beulangong Reuleut', 'area', 'Reuleut'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000305', '00000000-0000-4000-8000-000000000305', 'STORE', 'APPROVED', JSON_OBJECT('store_name', 'Martabak Durian & Roti Cane Muara Batu', 'area', 'Muara Batu'), '00000000-0000-4000-8000-000000000001', NOW()),
  ('30000000-0000-4000-8000-000000000306', '00000000-0000-4000-8000-000000000306', 'STORE', 'PENDING', JSON_OBJECT('store_name', 'Dimsum Mentai & Seblak Blang Pulo', 'area', 'Blang Pulo'), NULL, NULL)
ON DUPLICATE KEY UPDATE
  `status` = VALUES(`status`);

-- Driver wallets must start at balance = 0 (tolerance down to -20000 for cash commissions).
INSERT INTO `wallets` (`id`, `owner_type`, `owner_id`, `balance`, `bank_name`, `bank_account_number`, `bank_account_holder`)
VALUES
  ('40000000-0000-4000-8000-000000000001', 'PLATFORM', '00000000-0000-4000-8000-000000000001', 0, 'Bank Aceh Syariah', '01001020009991', 'PT RideOn Lhokseumawe Nusantara'),
  ('40000000-0000-4000-8000-000000000101', 'CUSTOMER', '00000000-0000-4000-8000-000000000101', 0, 'BSI (Bank Syariah Indonesia)', '7182930101', 'Cut Meutia Sari'),
  ('40000000-0000-4000-8000-000000000102', 'CUSTOMER', '00000000-0000-4000-8000-000000000102', 0, 'BSI (Bank Syariah Indonesia)', '7182930102', 'Teuku Ryan Alfarizi'),
  ('40000000-0000-4000-8000-000000000201', 'DRIVER', '10000000-0000-4000-8000-000000000201', 0, 'Bank Aceh Syariah', '0300203000201', 'Zulkifli'),
  ('40000000-0000-4000-8000-000000000202', 'DRIVER', '10000000-0000-4000-8000-000000000202', 0, 'BSI (Bank Syariah Indonesia)', '7182930202', 'Hendrik Saputra'),
  ('40000000-0000-4000-8000-000000000203', 'DRIVER', '10000000-0000-4000-8000-000000000203', 0, 'Bank Aceh Syariah', '0300203000203', 'Muhammad Rizal'),
  ('40000000-0000-4000-8000-000000000204', 'DRIVER', '10000000-0000-4000-8000-000000000204', 0, 'BSI (Bank Syariah Indonesia)', '7182930204', 'Syahrul Ramadhan'),
  ('40000000-0000-4000-8000-000000000205', 'DRIVER', '10000000-0000-4000-8000-000000000205', 0, 'Bank Aceh Syariah', '0300203000205', 'Ahmad Fauzi'),
  ('40000000-0000-4000-8000-000000000301', 'STORE', '20000000-0000-4000-8000-000000000301', 0, 'Bank Aceh Syariah', '0300204000301', 'Bang Joni Mie Aceh'),
  ('40000000-0000-4000-8000-000000000302', 'STORE', '20000000-0000-4000-8000-000000000302', 0, 'BSI (Bank Syariah Indonesia)', '7182940302', 'Tgk. Maimun'),
  ('40000000-0000-4000-8000-000000000303', 'STORE', '20000000-0000-4000-8000-000000000303', 0, 'BSI (Bank Syariah Indonesia)', '7182940303', 'Kak Nisa'),
  ('40000000-0000-4000-8000-000000000304', 'STORE', '20000000-0000-4000-8000-000000000304', 0, 'Bank Aceh Syariah', '0300204000304', 'Uda Hendra'),
  ('40000000-0000-4000-8000-000000000305', 'STORE', '20000000-0000-4000-8000-000000000305', 0, 'BSI (Bank Syariah Indonesia)', '7182940305', 'Bang Dedi'),
  ('40000000-0000-4000-8000-000000000306', 'STORE', '20000000-0000-4000-8000-000000000306', 0, 'BSI (Bank Syariah Indonesia)', '7182940306', 'Rina Dimsum')
ON DUPLICATE KEY UPDATE
  `bank_name` = VALUES(`bank_name`),
  `bank_account_number` = VALUES(`bank_account_number`);

INSERT INTO `store_menus` (`id`, `store_id`, `name`, `description`, `category`, `price`, `is_available`, `stock`)
VALUES
  ('50000000-0000-4000-8000-000000000101', '20000000-0000-4000-8000-000000000301', 'Mie Aceh Goreng Daging Sapi Spesial', 'Mie Aceh goreng rempah khas Lhokseumawe dengan potongan daging sapi empuk, emping, dan acar bawang.', 'Makanan Utama', 25000, 1, 80),
  ('50000000-0000-4000-8000-000000000102', '20000000-0000-4000-8000-000000000301', 'Mie Aceh Kuah Kepiting Jumbo', 'Mie Aceh kuah kental pedas gurih dengan 1 ekor kepiting segar tambak Muara Satu.', 'Makanan Utama', 38000, 1, 45),
  ('50000000-0000-4000-8000-000000000103', '20000000-0000-4000-8000-000000000301', 'Martabak Telur Aceh Kuah Kari', 'Martabak Aceh kulit roti cane dibalut telur bebek & daun bawang, disajikan dengan kuah kari kambing.', 'Camilan', 18000, 1, 90),
  ('50000000-0000-4000-8000-000000000104', '20000000-0000-4000-8000-000000000301', 'Es Timun Serut Selasih', 'Es timun segar serut khas Aceh dengan biji selasih dan sirup jeruk nipis.', 'Minuman', 10000, 1, 120),
  ('50000000-0000-4000-8000-000000000201', '20000000-0000-4000-8000-000000000302', 'Kopi Sanger Panas / Dingin', 'Racikan kopi saring Gayo tradisional tarik susu kental manis.', 'Minuman', 12000, 1, 200),
  ('50000000-0000-4000-8000-000000000202', '20000000-0000-4000-8000-000000000302', 'Kopi Khop Gelas Terbalik', 'Kopi robusta Aceh disajikan dengan gelas terbalik di atas piring kaca dan sedotan.', 'Minuman', 13000, 1, 150),
  ('50000000-0000-4000-8000-000000000203', '20000000-0000-4000-8000-000000000302', 'Kue Timphan Srikaya / Kelapa (3 Pcs)', 'Kue tradisional Aceh berbahan ketan pisang isi srikaya daun pandan.', 'Camilan', 12000, 1, 60),
  ('50000000-0000-4000-8000-000000000204', '20000000-0000-4000-8000-000000000302', 'Teh Tarik Hijau Aceh', 'Teh hijau saring tarik susu berbusa lembut.', 'Minuman', 12000, 1, 150),
  ('50000000-0000-4000-8000-000000000301', '20000000-0000-4000-8000-000000000303', 'Paket Ayam Geprek Kampus + Es Teh', 'Nasi hangat + Ayam crispy geprek sambal bawang level 1-10 + lalapan + Es Teh.', 'Makanan Utama', 18000, 1, 150),
  ('50000000-0000-4000-8000-000000000302', '20000000-0000-4000-8000-000000000303', 'Ayam Geprek Mozzarella Lumer', 'Ayam geprek pedas dengan topping keju mozzarella bakar dan nasi putih.', 'Makanan Utama', 24000, 1, 80),
  ('50000000-0000-4000-8000-000000000303', '20000000-0000-4000-8000-000000000303', 'Paket Ayam Penyet Sambal Ijo', 'Nasi putih + Ayam goreng ungkep penyet sambal cabai hijau + tahu tempe.', 'Makanan Utama', 20000, 1, 100),
  ('50000000-0000-4000-8000-000000000304', '20000000-0000-4000-8000-000000000303', 'Kol Goreng & Tahu Tempe Crispy', 'Porsi ekstra kol goreng garing dan tahu tempe bumbu bawang.', 'Camilan', 8000, 1, 100),
  ('50000000-0000-4000-8000-000000000401', '20000000-0000-4000-8000-000000000304', 'Nasi Padang Rendang Daging Sapi', 'Nasi putih porsi kenyang + Rendang daging sapi asli + sayur nangka + daun singkong + sambal ijo.', 'Makanan Utama', 26000, 1, 90),
  ('50000000-0000-4000-8000-000000000402', '20000000-0000-4000-8000-000000000304', 'Paket Nasi Kuah Beulangong Kambing', 'Nasi putih + Kuah Beulangong daging kambing nangka muda rempah Aceh Utara.', 'Makanan Utama', 32000, 1, 50),
  ('50000000-0000-4000-8000-000000000403', '20000000-0000-4000-8000-000000000304', 'Nasi Ayam Pop Bukittinggi', 'Nasi putih + Ayam Pop goreng kelapa lembut dengan sambal tomat.', 'Makanan Utama', 23000, 1, 75),
  ('50000000-0000-4000-8000-000000000404', '20000000-0000-4000-8000-000000000304', 'Nasi Ikan Tongkol Asam Keueng', 'Nasi putih + Ikan tongkol segar kuah Asam Keueng belimbing wuluh khas Aceh.', 'Makanan Utama', 20000, 1, 80),
  ('50000000-0000-4000-8000-000000000501', '20000000-0000-4000-8000-000000000305', 'Martabak Durian Cane Spesial', 'Roti cane renyah dengan isian daging durian asli Aceh Utara dan susu kental manis.', 'Camilan', 25000, 1, 70),
  ('50000000-0000-4000-8000-000000000502', '20000000-0000-4000-8000-000000000305', 'Roti Cane Coklat Keju Susu', 'Roti cane panggang mentega dengan taburan coklat meses dan keju parut.', 'Camilan', 16000, 1, 100),
  ('50000000-0000-4000-8000-000000000503', '20000000-0000-4000-8000-000000000305', 'Sate Matang Daging Sapi + Kuah Soto', '10 tusuk Sate Matang bumbu kacang + semangkuk kuah kaldu soto rempah + nasi.', 'Makanan Utama', 30000, 1, 65),
  ('50000000-0000-4000-8000-000000000504', '20000000-0000-4000-8000-000000000305', 'Bandrek Susu Telur Kampung', 'Minuman jahe rempah hangat ditambah susu dan kuning telur ayam kampung.', 'Minuman', 15000, 1, 80)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `price` = VALUES(`price`),
  `is_available` = VALUES(`is_available`),
  `stock` = VALUES(`stock`);

-- 5% driver commission and 5% store commission for FlexFood; 5% driver commission for Ride & FlexSend.
INSERT INTO `pricing_rules` (`id`, `service_type`, `base_fare`, `per_km_fare`, `min_fare`, `driver_commission_pct`, `store_commission_pct`, `platform_fee_fixed`, `is_active`)
VALUES
  ('60000000-0000-4000-8000-000000000001', 'RIDE_MOTOR', 5000, 2200, 8000, 5.00, 0.00, 0, 1),
  ('60000000-0000-4000-8000-000000000002', 'RIDE_MOBIL', 12000, 4500, 18000, 5.00, 0.00, 0, 1),
  ('60000000-0000-4000-8000-000000000003', 'FLEX_FOOD', 5000, 2200, 8000, 5.00, 5.00, 0, 1),
  ('60000000-0000-4000-8000-000000000004', 'FLEX_SEND', 6000, 2500, 10000, 5.00, 0.00, 0, 1)
ON DUPLICATE KEY UPDATE
  `base_fare` = VALUES(`base_fare`),
  `per_km_fare` = VALUES(`per_km_fare`),
  `min_fare` = VALUES(`min_fare`),
  `driver_commission_pct` = VALUES(`driver_commission_pct`),
  `store_commission_pct` = VALUES(`store_commission_pct`);

INSERT INTO `promotions` (`id`, `code`, `title`, `description`, `discount_type`, `discount_value`, `min_order_amount`, `max_discount_amount`, `quota`, `used_count`, `start_at`, `end_at`, `is_active`)
VALUES
  ('70000000-0000-4000-8000-000000000001', 'UNIMALHEMAT', 'Diskon Mahasiswa Unimal Bukit Indah & Reuleut', 'Potongan Rp 5.000 untuk pesanan FlexFood & Ride di area Kampus Unimal.', 'FIXED', 5000, 20000, 5000, 500, 12, NOW(), DATE_ADD(NOW(), INTERVAL 180 DAY), 1),
  ('70000000-0000-4000-8000-000000000002', 'LHOKSEUMAWE20', 'Diskon 20% Kuliner Lhokseumawe', 'Diskon 20% hingga Rp 10.000 untuk kuliner Mie Aceh, Kopi Sanger, dan Geprek.', 'PERCENTAGE', 20, 30000, 10000, 300, 8, NOW(), DATE_ADD(NOW(), INTERVAL 180 DAY), 1),
  ('70000000-0000-4000-8000-000000000003', 'FLEXSENDAMAN', 'Promo Ongkir Titip Beli FlexSend', 'Potongan ongkir Rp 4.000 untuk layanan titip beli barang & dokumen.', 'FIXED', 4000, 15000, 4000, 200, 5, NOW(), DATE_ADD(NOW(), INTERVAL 180 DAY), 1)
ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `discount_value` = VALUES(`discount_value`),
  `is_active` = VALUES(`is_active`);

INSERT INTO `user_favorites` (`id`, `user_id`, `target_type`, `store_id`, `menu_id`)
VALUES
  ('80000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'STORE', '20000000-0000-4000-8000-000000000301', NULL),
  ('80000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000101', 'MENU', '20000000-0000-4000-8000-000000000301', '50000000-0000-4000-8000-000000000101'),
  ('80000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000102', 'STORE', '20000000-0000-4000-8000-000000000302', NULL)
ON DUPLICATE KEY UPDATE
  `target_type` = VALUES(`target_type`);

-- Neutral provider slots configured via Web Admin; inactive until API keys are entered.
INSERT INTO `ai_providers` (`id`, `display_name`, `adapter_type`, `base_url`, `api_key_encrypted`, `model_name`, `system_prompt`, `temperature`, `max_tokens`, `priority_order`, `is_active`)
VALUES
  ('90000000-0000-4000-8000-000000000001', 'Provider Utama', 'openai_compatible', 'https://api.example.com/v1', '', 'ganti-dengan-nama-model', 'Anda adalah asisten layanan ekosistem RideOn Lhokseumawe & Aceh Utara. Jawab dengan sopan, ringkas, dan jelas dalam Bahasa Indonesia.', 0.70, 1024, 1, 0),
  ('90000000-0000-4000-8000-000000000002', 'Provider Cadangan', 'gemini_native', 'https://generativelanguage.googleapis.com/v1beta', '', 'gemini-flash-lite-latest', 'Anda adalah asisten layanan ekosistem RideOn Lhokseumawe & Aceh Utara. Jawab dengan sopan, ringkas, dan jelas dalam Bahasa Indonesia.', 0.70, 1024, 2, 0)
ON DUPLICATE KEY UPDATE
  `display_name` = VALUES(`display_name`),
  `adapter_type` = VALUES(`adapter_type`),
  `base_url` = VALUES(`base_url`),
  `model_name` = VALUES(`model_name`),
  `priority_order` = VALUES(`priority_order`);

INSERT INTO `system_settings` (`key`, `value`)
VALUES
  ('driver_offer_seconds', '16'),
  ('driver_negative_balance_limit', '20000'),
  ('withdraw_admin_fee', '2000'),
  ('qris_expire_minutes', '15'),
  ('payg_static_qris', '')
ON DUPLICATE KEY UPDATE
  `value` = VALUES(`value`);
