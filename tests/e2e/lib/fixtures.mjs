// Lhokseumawe & Aceh Utara coordinates, seed defaults, pricing constants,
// valid 68-byte 1x1 PNG binary, and valid EMVCo Static QRIS fixture.

export const DEFAULT_BASE_URL =
  (process.env.RIDEON_BASE_URL || 'http://localhost:8088').replace(/\/+$/, '');

export const DEFAULT_TIMEOUT_MS = Number(process.env.E2E_TIMEOUT_MS || 15000);

export const DEFAULT_ADMIN_CREDS = {
  email: process.env.ADMIN_EMAIL || process.env.ADMIN_LOGIN_EMAIL || 'admin@rideons.app',
  password: process.env.ADMIN_PASSWORD || process.env.ADMIN_LOGIN_PASSWORD || 'RideOnAdmin2026!',
};

export const DEFAULT_SECRETS = {
  payg: process.env.PAYG_WEBHOOK_SECRET || 'rideon-payg-secret-2026',
  waGateway: process.env.WA_GATEWAY_SECRET || 'rideon-wa-secret-2026',
  internal: process.env.INTERNAL_SERVICE_SECRET || 'rideon-internal-secret-2026',
};

// Lhokseumawe & Aceh Utara geo fixtures (verified against admin dashboard & nominatim service)
export const COORDS = {
  KAMPUS_BUKIT_INDAH: {
    label: 'Kampus Bukit Indah (Unimal)',
    address: 'Jl. Kampus Unimal Bukit Indah, Muara Satu, Lhokseumawe',
    lat: 5.20181,
    lng: 97.06416,
  },
  BLANG_PULO: {
    label: 'Blang Pulo',
    address: 'Jl. Banda Aceh - Medan, Blang Pulo, Muara Satu, Lhokseumawe',
    lat: 5.21141,
    lng: 97.06808,
  },
  REULEUT: {
    label: 'Kampus Reuleut Aceh Utara',
    address: 'Reuleut Timu, Muara Batu, Aceh Utara',
    lat: 5.234121,
    lng: 96.988018,
  },
  PUSAT_LHOKSEUMAWE: {
    label: 'Pusat Kota Lhokseumawe',
    address: 'Jl. Merdeka, Simpang Empat, Banda Sakti, Lhokseumawe',
    lat: 5.18806,
    lng: 97.14028,
  },
  PASAR_INPRES: {
    label: 'Pasar Inpres Lhokseumawe',
    address: 'Pasar Inpres, Banda Sakti, Lhokseumawe',
    lat: 5.1812,
    lng: 97.1456,
  },
  MUARA_BATU: {
    label: 'Krueng Mane / Muara Batu',
    address: 'Jl. Medan - Banda Aceh, Muara Batu, Aceh Utara',
    lat: 5.246,
    lng: 96.958,
  },
  DEWANTARA: {
    label: 'Krueng Geukueh / Dewantara',
    address: 'Dewantara, Aceh Utara',
    lat: 5.2472,
    lng: 97.0261,
  },
  PANTON_LABU: {
    label: 'Panton Labu Aceh Utara',
    address: 'Tanah Jambo Aye, Aceh Utara',
    lat: 5.048,
    lng: 97.46,
  },
  BIREUEN: {
    label: 'Kota Juang Bireuen',
    address: 'Jl. Banda Aceh - Medan, Bireuen',
    lat: 5.203,
    lng: 96.7,
  },
};

export const PRICING_RULES = {
  FLEXRIDE_MOTOR: {
    service_type: 'FLEXRIDE_MOTOR',
    base_fare: 8000,
    base_distance_km: 2,
    per_km_rate: 2500,
    extra_stop_fee: 0,
    app_service_fee: 2000,
    driver_commission_pct: 5,
    store_commission_pct: 0,
  },
  FLEXRIDE_MOBIL: {
    service_type: 'FLEXRIDE_MOBIL',
    base_fare: 15000,
    base_distance_km: 2,
    per_km_rate: 4000,
    extra_stop_fee: 0,
    app_service_fee: 3000,
    driver_commission_pct: 5,
    store_commission_pct: 0,
  },
  FLEXFOOD: {
    service_type: 'FLEXFOOD',
    base_fare: 6000,
    base_distance_km: 2,
    per_km_rate: 2000,
    extra_stop_fee: 0,
    app_service_fee: 2000,
    driver_commission_pct: 5,
    store_commission_pct: 5,
  },
  FLEXSEND: {
    service_type: 'FLEXSEND',
    base_fare: 8000,
    base_distance_km: 2,
    per_km_rate: 2500,
    extra_stop_fee: 3000,
    app_service_fee: 2000,
    driver_commission_pct: 5,
    store_commission_pct: 0,
  },
};

export const FINANCE_CONSTANTS = {
  DRIVER_COMMISSION_PCT: 5,
  STORE_COMMISSION_PCT: 5,
  WITHDRAW_ADMIN_FEE: 2000,
  DRIVER_TUNAI_TOLERANCE_FLOOR: -20000,
  INITIAL_DRIVER_BALANCE: 0,
  MAX_FLEXSEND_STOPS: 3,
  UNIQUE_CODE_MIN: 1,
  UNIQUE_CODE_MAX: 999,
};

// Valid 68-byte 1x1 PNG (IHDR 8-bit grayscale+alpha + IDAT + IEND with valid CRC32)
export const VALID_1X1_PNG_BYTES = Uint8Array.from(
  Buffer.from(
    '89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c020000000b49444154789c63f8ff1f00030001fffc25dc510000000049454e44ae426082',
    'hex'
  )
);

// Valid EMVCo Static QRIS (POI 11, Tag 53=360, Tag 58=ID, Tag 59=KEDAI RIDEON, Tag 60=LHOKSEUMAWE, Tag 63=3B86)
export const SAMPLE_STATIC_QRIS =
  '00020101021126570011ID.DANA.WWW011893600915000012345602091234567890303UMI51440014ID.CO.QRIS.WWW0215ID10200300400500303UMI5204549953033605802ID5912KEDAI RIDEON6011LHOKSEUMAWE61052435163043B86';

export const INVALID_CRC_QRIS = `${SAMPLE_STATIC_QRIS.slice(0, -4)}FFFF`;

export const FEATURE_AREAS = [
  '1. Infra, Nginx Proxy & Seed Baseline',
  '2. Unified Auth, OTP & Approval Gates',
  '3. File Uploads, Store Catalog & Home Feeds',
  '4. Geo/OSRM Pricing & FlexRide Orders',
  '5. FlexFood Store-First Flow & 16s Atomic Lock',
  '6. FlexSend Modal Kas, 3-Stop, Receipt & Talangan',
  '7. Wallet, 5%:5% Commission, -20k Tolerance & Withdraw',
  '8. Favorites, Ratings & Admin API',
  '9. PayG Dynamic QRIS, MacroDroid & Manual Confirm',
  '10. Universal AI Adapter, Safe Boundary & App AI',
  '11. WA Gateway Sessions, OTP & AI Forwarding',
  '12. Web Admin UI Routes & App Contract Parity',
];
