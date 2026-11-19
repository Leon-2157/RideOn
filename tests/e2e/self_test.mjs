import http from 'node:http';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {
  COORDS,
  DEFAULT_ADMIN_CREDS,
  DEFAULT_SECRETS,
  FINANCE_CONSTANTS,
  PRICING_RULES,
  SAMPLE_STATIC_QRIS,
} from './lib/fixtures.mjs';
import {
  crc16CcittFalse,
  createClient,
  createRunId,
  formatIdr,
  parseEmvcoTlv,
} from './lib/client.mjs';

const MOCK_JWT_SECRET = 'rideon-e2e-mock-jwt-secret-2026';

function signJwt(payload) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const body = Buffer.from(
    JSON.stringify({
      ...payload,
      exp: Math.floor(Date.now() / 1000) + 86400,
    })
  ).toString('base64url');
  const sig = crypto
    .createHmac('sha256', MOCK_JWT_SECRET)
    .update(`${header}.${body}`)
    .digest('base64url');
  return `${header}.${body}.${sig}`;
}

function verifyJwt(token) {
  if (!token || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  let header;
  try {
    header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (!header || header.alg !== 'HS256') return null;
  const expectedSig = crypto
    .createHmac('sha256', MOCK_JWT_SECRET)
    .update(`${parts[0]}.${parts[1]}`)
    .digest('base64url');
  const sigBuf = Buffer.from(parts[2]);
  const expBuf = Buffer.from(expectedSig);
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    return null;
  }
  try {
    const claims = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (claims.exp && claims.exp < Math.floor(Date.now() / 1000)) return null;
    return claims;
  } catch {
    return null;
  }
}

function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function parseMultipartBuffer(buf, contentType) {
  const m = /boundary=(?:"([^"]+)"|([^;\s]+))/i.exec(contentType || '');
  if (!m) return null;
  const boundary = m[1] || m[2];
  const delim = Buffer.from(`--${boundary}`);
  const fields = {};
  const files = [];

  let pos = buf.indexOf(delim);
  while (pos !== -1) {
    const start = pos + delim.length;
    if (buf.subarray(start, start + 2).equals(Buffer.from('--'))) break;
    const headerStart = buf[start] === 0x0d && buf[start + 1] === 0x0a ? start + 2 : start;
    const headerEnd = buf.indexOf(Buffer.from('\r\n\r\n'), headerStart);
    if (headerEnd === -1) break;

    const headerStr = buf.subarray(headerStart, headerEnd).toString('utf8');
    const nextPos = buf.indexOf(delim, headerEnd + 4);
    if (nextPos === -1) break;

    let dataEnd = nextPos;
    if (buf[dataEnd - 2] === 0x0d && buf[dataEnd - 1] === 0x0a) dataEnd -= 2;
    const content = buf.subarray(headerEnd + 4, dataEnd);

    const nameMatch = /name="([^"]+)"/i.exec(headerStr);
    const fileMatch = /filename="([^"]*)"/i.exec(headerStr);
    const ctMatch = /content-type:\s*([^\r\n;]+)/i.exec(headerStr);

    if (fileMatch) {
      files.push({
        field: nameMatch ? nameMatch[1] : 'file',
        filename: fileMatch[1],
        contentType: ctMatch ? ctMatch[1].trim() : 'application/octet-stream',
        data: content,
      });
    } else if (nameMatch) {
      fields[nameMatch[1]] = content.toString('utf8');
    }

    pos = nextPos;
  }
  return { fields, files };
}

function isValidImageOrDocMagic(buf, filename) {
  if (!buf || buf.length === 0) return false;
  if (filename && /\.(sh|exe|bat|cmd|js|php)$/i.test(filename)) return false;
  const isPng = buf.length >= 8 && buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47;
  const isJpeg = buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff;
  const isPdf = buf.length >= 4 && buf.subarray(0, 4).toString('ascii') === '%PDF';
  return isPng || isJpeg || isPdf;
}

function buildDynamicQris(staticPayload, payableAmount, { corruptCrc = false } = {}) {
  const tags = parseEmvcoTlv(staticPayload || SAMPLE_STATIC_QRIS);
  delete tags['63'];
  tags['00'] = tags['00'] || '01';
  tags['01'] = '12';
  tags['53'] = '360';
  tags['54'] = String(payableAmount);
  tags['58'] = 'ID';
  const sortedKeys = Object.keys(tags).sort((a, b) => Number(a) - Number(b));
  let body = '';
  for (const k of sortedKeys) {
    const val = tags[k];
    body += k + String(val.length).padStart(2, '0') + val;
  }
  body += '6304';
  let crc = crc16CcittFalse(body);
  if (corruptCrc) {
    crc = crc === '0000' ? 'FFFF' : '0000';
  }
  return body + crc;
}

function makeQrSvg(text) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 280 280"><rect width="280" height="280" fill="#fff"/><text x="10" y="20" font-size="10">${text.slice(0, 24)}</text></svg>`;
}

function extractIdrAmount(text) {
  if (typeof text !== 'string') return null;
  const norm = text.replace(/\u00a0/g, ' ').trim();
  if (/-\s*(?:Rp\.?|IDR)/i.test(norm) || /(?:Rp\.?|IDR)\s*-/i.test(norm)) {
    return null;
  }
  const m =
    /(?:Rp\.?|IDR)\s*(\d[\d.,]*(?:,-)?)/i.exec(norm) ||
    /(\d[\d.,]*)\s*IDR\b/i.exec(norm);
  if (!m) return null;
  let numStr = m[1].replace(/,-$/, '');
  if (/^\d{1,3}(\.\d{3})+(,\d{1,2})?$/.test(numStr)) {
    numStr = numStr.split(',')[0].replace(/\./g, '');
  } else if (/^\d{1,3}(,\d{3})+(\.\d{1,2})?$/.test(numStr)) {
    numStr = numStr.split('.')[0].replace(/,/g, '');
  } else {
    numStr = numStr.replace(/[.,]/g, '');
  }
  const parsed = Number.parseInt(numStr, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

function normalizePhone(raw) {
  const digits = String(raw || '').replace(/\D/g, '');
  if (digits.startsWith('0')) return `62${digits.slice(1)}`;
  if (digits.startsWith('62')) return digits;
  return digits;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function sendJson(res, status, data) {
  const payload = JSON.stringify(data);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

function sendHtml(res, status, html) {
  res.writeHead(status, {
    'Content-Type': 'text/html; charset=utf-8',
    'Content-Length': Buffer.byteLength(html),
  });
  res.end(html);
}

export function createMockServer() {
  let seqId = 100;
  const nextId = () => {
    seqId += 1;
    return seqId;
  };

  const faults = {
    break_crc16: false,
    break_409_race: false,
    leak_api_key: false,
    break_commission_math: false,
    break_auth_401: false,
  };

  const db = {
    users: new Map(),
    drivers: new Map(),
    stores: new Map(),
    registrations: new Map(),
    menus: new Map(),
    pricingRules: new Map(
      Object.entries(PRICING_RULES).map(([k, v]) => [k, { ...v }])
    ),
    promotions: new Map(),
    favorites: new Map(),
    orders: new Map(),
    orderItems: new Map(),
    ratings: new Map(),
    qrisTxs: new Map(),
    wallets: new Map(),
    walletTxs: [],
    withdrawals: new Map(),
    talanganClaims: new Map(),
    aiProviders: new Map(),
    aiChatMessages: [],
    supportTickets: new Map(),
    emailOtps: new Map(),
    waOtps: new Map(),
    uploads: new Map(),
    staticQris: SAMPLE_STATIC_QRIS,
  };

  // Seed admin, 1 store, 2 menus, 1 promo
  const adminUser = {
    id: 1,
    firebase_uid: 'admin-uid-1',
    name: 'Admin RideOn',
    email: DEFAULT_ADMIN_CREDS.email,
    phone: '081200000001',
    password: DEFAULT_ADMIN_CREDS.password,
    role: 'admin',
    status: 'Aktif',
  };
  db.users.set(1, adminUser);

  const seedStoreUser = {
    id: 2,
    firebase_uid: 'store-uid-2',
    name: 'Bang Luthfi',
    email: 'toko.seed@rideons.app',
    phone: '081200000002',
    password: 'SeedPassword123!',
    role: 'store',
    status: 'Aktif',
  };
  db.users.set(2, seedStoreUser);
  db.stores.set(1, {
    id: 1,
    user_id: 2,
    store_name: 'Warung Kopi Bukit Indah',
    owner_name: 'Bang Luthfi',
    description: 'Kopi Sanger & Mie Aceh Bukit Indah',
    category: 'Makanan & Minuman',
    address: COORDS.KAMPUS_BUKIT_INDAH.address,
    service_area: 'Lhokseumawe',
    latitude: COORDS.KAMPUS_BUKIT_INDAH.lat,
    longitude: COORDS.KAMPUS_BUKIT_INDAH.lng,
    open_hours: '07.00 - 23.00',
    is_open: true,
    withdraw_pin: '123456',
    verification_status: 'Disetujui',
    rating_avg: 4.9,
  });
  db.menus.set(1, {
    id: 1,
    store_id: 1,
    name: 'Mie Aceh Pedas Spesial',
    description: 'Mie Aceh rempah pilihan',
    category: 'Makanan Utama',
    price: 20000,
    is_available: true,
    total_sold: 45,
    rating_avg: 4.9,
    created_at: Date.now() - 10000,
  });

  function ensureWallet(userId, ownerType) {
    const key = `${ownerType}:${userId}`;
    if (!db.wallets.has(key)) {
      db.wallets.set(key, {
        id: nextId(),
        user_id: userId,
        owner_type: ownerType,
        balance: 0,
      });
    }
    return db.wallets.get(key);
  }

  function findUserByIdentifier(identifier) {
    for (const u of db.users.values()) {
      if (
        (u.email && u.email === identifier) ||
        (u.phone && normalizePhone(u.phone) === normalizePhone(identifier))
      ) {
        return u;
      }
    }
    return null;
  }

  function getDriverByUserId(uid) {
    for (const d of db.drivers.values()) {
      if (d.user_id === uid) return d;
    }
    return null;
  }

  function getStoreByUserId(uid) {
    for (const s of db.stores.values()) {
      if (s.user_id === uid) return s;
    }
    return null;
  }

  function authUser(req) {
    const auth = req.headers.authorization || '';
    if (!auth.startsWith('Bearer ')) return null;
    const claims = verifyJwt(auth.slice(7).trim());
    if (!claims) return null;
    return db.users.get(claims.user_id) || null;
  }

  function computeEstimate(body) {
    const svc = body.service_type;
    const rule = db.pricingRules.get(svc);
    if (!rule) return { error: `Unknown service_type: ${svc}` };
    const { pickup_lat, pickup_lng, dest_lat, dest_lng } = body;
    for (const [val, min, max] of [
      [pickup_lat, -90, 90],
      [dest_lat, -90, 90],
      [pickup_lng, -180, 180],
      [dest_lng, -180, 180],
    ]) {
      if (typeof val !== 'number' || Number.isNaN(val) || val < min || val > max) {
        return { error: 'Invalid coordinates' };
      }
    }
    const distanceKm = Math.round(haversineKm(pickup_lat, pickup_lng, dest_lat, dest_lng) * 100) / 100;
    const extraKm = Math.max(0, distanceKm - Number(rule.base_distance_km));
    const stops = Array.isArray(body.stops) ? body.stops : [];
    const extraStopCount = Math.max(0, stops.length - 1);
    const extraStopFee = extraStopCount * Number(rule.extra_stop_fee || 0);
    const deliveryFee = Math.round(Number(rule.base_fare) + extraKm * Number(rule.per_km_rate) + extraStopFee);
    const serviceFee = Number(rule.app_service_fee);

    let discountAmount = 0;
    if (body.promo_code) {
      const promo = db.promotions.get(String(body.promo_code).toUpperCase());
      if (promo && promo.is_active) {
        const rawDisc = Number(promo.discount_amount);
        discountAmount =
          Number(promo.max_discount) > 0 ? Math.min(rawDisc, Number(promo.max_discount)) : rawDisc;
      }
    }

    const totalAmount = Math.max(0, deliveryFee + serviceFee - discountAmount);
    return {
      distance_km: distanceKm,
      delivery_fee: deliveryFee,
      extra_stop_fee: extraStopFee,
      service_fee: serviceFee,
      discount_amount: discountAmount,
      total_amount: totalAmount,
      routing_source: 'haversine',
    };
  }

  function recalcOrderRatings(driverId, storeId) {
    if (driverId) {
      const dr = Array.from(db.ratings.values()).filter((r) => r.driver_id === driverId && r.driver_stars);
      if (dr.length > 0) {
        const avg = dr.reduce((s, r) => s + r.driver_stars, 0) / dr.length;
        const d = db.drivers.get(driverId);
        if (d) d.rating_avg = Math.round(avg * 100) / 100;
      }
    }
    if (storeId) {
      const sr = Array.from(db.ratings.values()).filter((r) => r.store_id === storeId && r.store_stars);
      if (sr.length > 0) {
        const avg = sr.reduce((s, r) => s + r.store_stars, 0) / sr.length;
        const st = db.stores.get(storeId);
        if (st) st.rating_avg = Math.round(avg * 100) / 100;
      }
    }
  }

  function settleOrderPayment(orderId) {
    const order = db.orders.get(orderId);
    if (!order) return;
    order.payment_status = 'PAID';
    if (order.status === 'WAITING_PAYMENT') {
      order.status = order.service_type === 'FlexFood' ? 'WAITING_STORE' : 'SEARCHING_DRIVER';
    }
  }

  const server = http.createServer(async (req, res) => {
    try {
      const rawUrl = req.url || '/';
      const parsed = new URL(rawUrl, 'http://127.0.0.1');
      const pathname = parsed.pathname;
      const method = req.method || 'GET';

      // Nginx /wa/* prefix strip
      if (pathname === '/wa' || pathname.startsWith('/wa/')) {
        const waPath = pathname === '/wa' ? '/' : pathname.slice(3);
        const bodyBuf = await readBody(req);
        let body = {};
        if (bodyBuf.length > 0) {
          try {
            body = JSON.parse(bodyBuf.toString('utf8'));
          } catch {
            return sendJson(res, 400, { status: false, error: 'Invalid JSON' });
          }
        }

        const checkWaSecret = () => {
          const sec = req.headers['x-gateway-secret'] || body.secret || parsed.searchParams.get('secret');
          return sec === DEFAULT_SECRETS.waGateway;
        };

        if (method === 'GET' && waPath === '/health') {
          return sendJson(res, 200, { status: 'ok', service: 'RideOn WhatsApp Gateway', connection: 'sandbox' });
        }
        if (method === 'GET' && waPath === '/status') {
          return sendJson(res, 200, { service: 'RideOn WhatsApp Gateway', status: 'sandbox', paired: false, sandbox: true });
        }
        if (method === 'GET' && waPath === '/qr') {
          return sendHtml(res, 200, '<html><body><h1>RideOn WA Gateway QR</h1></body></html>');
        }
        if (method === 'POST' && waPath === '/api/otp/send') {
          const phone = body.phoneNumber || body.phone || body.target;
          if (!phone) return sendJson(res, 400, { success: false, error: 'Missing phoneNumber' });
          const norm = normalizePhone(phone);
          const code = String(crypto.randomInt(100000, 999999));
          db.waOtps.set(norm, { code, attempts: 0, expiresAt: Date.now() + 300000 });
          return sendJson(res, 200, { success: true, simulated: true, code, expiresIn: 300 });
        }
        if (method === 'POST' && waPath === '/api/otp/verify') {
          const phone = body.phoneNumber || body.phone || body.target;
          const code = body.code || body.otp;
          if (!phone || !code) return sendJson(res, 400, { success: false, error: 'Missing phone or code' });
          const norm = normalizePhone(phone);
          const entry = db.waOtps.get(norm);
          if (!entry) return sendJson(res, 400, { success: false, error: 'OTP not found' });
          if (entry.attempts >= 5) {
            return sendJson(res, 429, { success: false, error: 'Terlalu banyak percobaan salah' });
          }
          if (String(code) !== entry.code) {
            entry.attempts += 1;
            return sendJson(res, 400, { success: false, error: 'Kode OTP salah' });
          }
          db.waOtps.delete(norm);
          return sendJson(res, 200, { success: true, message: 'OTP verified' });
        }
        if (method === 'POST' && waPath === '/api/auth/reset-password') {
          if (!body.newPassword || String(body.newPassword).length < 6) {
            return sendJson(res, 400, { success: false, error: 'Kata sandi minimal 6 karakter' });
          }
          return sendJson(res, 503, { success: false, error: 'Firebase Admin not configured in local fallback' });
        }
        if (method === 'POST' && ['/send', '/logout', '/reset-chat-sessions', '/restart'].includes(waPath)) {
          if (!checkWaSecret()) {
            return sendJson(res, 401, { status: false, error: 'Unauthorized: Invalid gateway secret' });
          }
          if (waPath === '/send') {
            if (!body.target || !body.message) {
              return sendJson(res, 400, { status: false, error: 'Missing target phone number or message content' });
            }
            return sendJson(res, 200, {
              status: true,
              messageId: `mock-${nextId()}`,
              target: `${normalizePhone(body.target)}@s.whatsapp.net`,
            });
          }
          return sendJson(res, 200, { status: true });
        }
        return sendJson(res, 404, { error: 'Not found' });
      }

      // Gateway & Admin HTML routes
      if (method === 'GET' && pathname === '/health') {
        return sendJson(res, 200, { status: 'ok', service: 'rideon-gateway' });
      }
      if (method === 'GET' && (pathname === '/' || pathname === '/login')) {
        return sendHtml(
          res,
          200,
          `<!doctype html><html><head><title>RideOn Admin</title></head><body><h1>RideOn Admin ${pathname === '/login' ? 'Login' : 'Dashboard'}</h1></body></html>`
        );
      }

      // Static uploads
      if (method === 'GET' && pathname.startsWith('/uploads/')) {
        if (pathname.includes('..') || rawUrl.toLowerCase().includes('%2f..')) {
          return sendJson(res, 403, { success: false, error: 'Forbidden path' });
        }
        const key = pathname.slice('/uploads/'.length);
        const file = db.uploads.get(key);
        if (!file) return sendJson(res, 404, { success: false, error: 'File not found' });
        res.writeHead(200, {
          'Content-Type': file.contentType,
          'Content-Length': file.data.length,
        });
        return res.end(file.data);
      }

      // Multipart upload
      if (method === 'POST' && pathname === '/v1/upload') {
        const user = authUser(req);
        if (!user) return sendJson(res, 401, { success: false, error: 'Unauthorized' });
        const raw = await readBody(req);
        const parsedMp = parseMultipartBuffer(raw, req.headers['content-type']);
        if (!parsedMp || parsedMp.files.length === 0) {
          return sendJson(res, 400, { success: false, error: 'File required' });
        }
        const f = parsedMp.files[0];
        if (!isValidImageOrDocMagic(f.data, f.filename)) {
          return sendJson(res, 415, { success: false, error: 'Unsupported or empty file' });
        }
        const cat = parsedMp.fields.category || 'misc';
        const key = `${cat}/${nextId()}_${f.filename || 'file.png'}`;
        db.uploads.set(key, { data: f.data, contentType: f.contentType || 'image/png' });
        return sendJson(res, 200, { success: true, url: `/uploads/${key}` });
      }

      // JSON body for all other API routes
      const rawBuf = await readBody(req);
      let body = {};
      if (rawBuf.length > 0) {
        try {
          body = JSON.parse(rawBuf.toString('utf8'));
        } catch {
          return sendJson(res, 400, { success: false, error: 'Malformed JSON body' });
        }
      }

      // =======================================================================
      // /pay/* (PayG)
      // =======================================================================
      if (pathname === '/pay/health' && method === 'GET') {
        return sendJson(res, 200, { status: 'ok', service: 'payg' });
      }
      if (pathname === '/pay/status' && method === 'GET') {
        const pendingCount = Array.from(db.qrisTxs.values()).filter((t) => t.status === 'PENDING').length;
        const settledCount = Array.from(db.qrisTxs.values()).filter((t) => t.status === 'SETTLEMENT').length;
        return sendJson(res, 200, {
          app: 'RideOn PayG',
          static_qr_configured: Boolean(db.staticQris),
          active_pending: pendingCount,
          total_settled: settledCount,
        });
      }
      if (pathname === '/pay/static-qr' && method === 'POST') {
        const user = authUser(req);
        const sec = req.headers['x-payg-secret'];
        if (sec !== DEFAULT_SECRETS.payg && (!user || user.role !== 'admin')) {
          return sendJson(res, user ? 403 : 401, { success: false, error: 'Admin required' });
        }
        const q = String(body.static_qris || '').trim();
        if (q.length < 20 || q.slice(-8, -4) !== '6304' || crc16CcittFalse(q.slice(0, -4)) !== q.slice(-4)) {
          return sendJson(res, 400, { success: false, error: 'Invalid QRIS checksum (CRC-16 tag 63 mismatch)' });
        }
        db.staticQris = q;
        return sendJson(res, 200, { success: true, crc_valid: true });
      }
      if (pathname === '/pay/checkout/create' && method === 'POST') {
        const user = authUser(req);
        if (!user) return sendJson(res, 401, { success: false, error: 'Unauthorized' });
        const amount = Number(body.amount);
        if (!Number.isFinite(amount) || amount <= 0) {
          return sendJson(res, 400, { success: false, error: 'Amount must be greater than zero' });
        }
        const taken = new Set(
          Array.from(db.qrisTxs.values())
            .filter((t) => t.status === 'PENDING')
            .map((t) => t.payable_amount)
        );
        let uniqueCode = null;
        for (let offset = 1; offset <= 999; offset++) {
          if (!taken.has(amount + offset)) {
            uniqueCode = offset;
            break;
          }
        }
        if (uniqueCode === null) {
          return sendJson(res, 503, { success: false, error: 'CodeAmountPoolExhausted' });
        }
        const payableAmount = amount + uniqueCode;
        const ref = `PAYG-${nextId()}`;
        const qrString = buildDynamicQris(db.staticQris, payableAmount, {
          corruptCrc: faults.break_crc16,
        });
        const tx = {
          id: nextId(),
          transaction_ref: ref,
          invoice_number: body.invoice_number || `INV-${ref}`,
          order_id: body.order_id ? Number(body.order_id) : null,
          wallet_topup_user_id: body.wallet_topup_user_id ? Number(body.wallet_topup_user_id) : null,
          purpose: body.purpose || 'ORDER_PAYMENT',
          base_amount: amount,
          unique_code: uniqueCode,
          payable_amount: payableAmount,
          qr_string: qrString,
          qr_svg: makeQrSvg(qrString),
          merchant_name: 'KEDAI RIDEON',
          status: 'PENDING',
          expires_at: new Date(Date.now() + 900000).toISOString(),
          settled_at: null,
        };
        db.qrisTxs.set(ref, tx);
        return sendJson(res, 200, { success: true, data: tx });
      }
      if (pathname.startsWith('/pay/checkout/') && pathname.endsWith('/status') && method === 'GET') {
        const ref = pathname.split('/')[3];
        const tx = db.qrisTxs.get(ref);
        if (!tx) return sendJson(res, 404, { success: false, error: 'Transaction not found' });
        return sendJson(res, 200, { success: true, data: tx });
      }
      if (pathname === '/pay/transactions' && method === 'GET') {
        const user = authUser(req);
        if (!user || user.role !== 'admin') {
          return sendJson(res, user ? 403 : 401, { success: false, error: 'Admin required' });
        }
        return sendJson(res, 200, { success: true, transactions: Array.from(db.qrisTxs.values()).reverse() });
      }
      if (pathname.startsWith('/pay/transactions/') && pathname.endsWith('/manual-confirm') && method === 'POST') {
        const user = authUser(req);
        if (!user || user.role !== 'admin') {
          return sendJson(res, user ? 403 : 401, { success: false, error: 'Admin required' });
        }
        const ref = pathname.split('/')[3];
        const tx = db.qrisTxs.get(ref);
        if (!tx) return sendJson(res, 404, { success: false, error: 'Transaction not found' });
        if (tx.status !== 'SETTLEMENT') {
          tx.status = 'SETTLEMENT';
          tx.settled_at = new Date().toISOString();
          if (tx.purpose === 'ORDER_PAYMENT' && tx.order_id) {
            settleOrderPayment(tx.order_id);
          } else if (tx.purpose === 'DRIVER_TOPUP' && tx.wallet_topup_user_id) {
            const w = ensureWallet(tx.wallet_topup_user_id, 'DRIVER');
            w.balance += tx.base_amount;
            db.walletTxs.push({
              wallet_id: w.id,
              category: 'Top Up',
              gross_amount: tx.base_amount,
              net_amount: tx.base_amount,
              is_debit: false,
              balance_after: w.balance,
            });
          }
        }
        return sendJson(res, 200, { success: true, transaction: tx });
      }
      if (pathname === '/pay/webhook/macrodroid' && method === 'POST') {
        const sec = req.headers['x-payg-secret'];
        if (!faults.break_auth_401 && sec !== DEFAULT_SECRETS.payg) {
          return sendJson(res, 401, { success: false, error: 'Unauthorized X-PayG-Secret' });
        }
        const amt = extractIdrAmount(body.notification_text || body.text || body.message || '');
        if (!amt) {
          return sendJson(res, 422, { success: false, error: 'Unable to parse positive IDR amount' });
        }
        const pending = Array.from(db.qrisTxs.values()).find(
          (t) => t.status === 'PENDING' && t.payable_amount === amt
        );
        if (!pending) {
          return sendJson(res, 404, { success: false, error: 'No matching pending transaction' });
        }
        pending.status = 'SETTLEMENT';
        pending.settled_at = new Date().toISOString();
        if (pending.purpose === 'ORDER_PAYMENT' && pending.order_id) {
          settleOrderPayment(pending.order_id);
        } else if (pending.purpose === 'DRIVER_TOPUP' && pending.wallet_topup_user_id) {
          const w = ensureWallet(pending.wallet_topup_user_id, 'DRIVER');
          w.balance += pending.base_amount;
          db.walletTxs.push({
            wallet_id: w.id,
            category: 'Top Up',
            gross_amount: pending.base_amount,
            net_amount: pending.base_amount,
            is_debit: false,
            balance_after: w.balance,
          });
        }
        return sendJson(res, 200, {
          success: true,
          transaction_ref: pending.transaction_ref,
          status: 'SETTLEMENT',
          payable_amount: pending.payable_amount,
        });
      }

      // =======================================================================
      // /ai/* (AI Service)
      // =======================================================================
      if (pathname === '/ai/health' && method === 'GET') {
        return sendJson(res, 200, { status: 'ok', service: 'ai-service', active_providers: db.aiProviders.size });
      }
      if (pathname === '/ai/webhook/whatsapp' && method === 'POST') {
        if (req.headers['x-gateway-secret'] !== DEFAULT_SECRETS.waGateway) {
          return sendJson(res, 401, { success: false, error: 'Unauthorized X-Gateway-Secret' });
        }
        const msg = String(body.message || '').trim();
        if (!msg) return sendJson(res, 400, { success: false, error: 'Empty message' });
        const sessionId = `wa_${normalizePhone(body.sender)}`;
        const ticketCode = `TKT-${nextId()}`;
        const matchedUser = findUserByIdentifier(body.sender);
        db.supportTickets.set(ticketCode, {
          id: nextId(),
          ticket_code: ticketCode,
          user_id: matchedUser ? matchedUser.id : null,
          app_source: 'WHATSAPP',
          category: 'whatsapp_cs',
          subject: 'Pertanyaan WhatsApp CS',
          description: msg,
          status: 'OPEN',
          admin_reply: null,
        });
        db.aiChatMessages.push({
          session_id: sessionId,
          sender_phone: body.sender,
          app_source: 'WHATSAPP',
          role: 'user',
          message_text: msg,
        });
        return sendJson(res, 200, {
          success: true,
          session_id: sessionId,
          reply: 'Permintaan Anda dicatat oleh CS AI RideOn. Untuk perubahan saldo/refund akan ditangani Admin melalui tiket.',
          ticket_code: ticketCode,
        });
      }
      if (pathname.startsWith('/ai/')) {
        const user = authUser(req);
        if (!user) return sendJson(res, 401, { success: false, error: 'Unauthorized' });

        if (pathname === '/ai/cs/chat' && method === 'POST') {
          const msg = String(body.message || '').trim();
          if (!msg) return sendJson(res, 400, { success: false, error: 'Message required' });
          const sessionId = body.session_id || `cs_${user.id}_${nextId()}`;
          const actionsTaken = [];
          let ticketCode = null;

          // Safe Action Boundary: ONLY cancel WAITING_PAYMENT or SEARCHING_DRIVER
          if (body.order_id && /batal/i.test(msg)) {
            const ord = db.orders.get(Number(body.order_id));
            if (ord && ord.customer_id === user.id && ['WAITING_PAYMENT', 'SEARCHING_DRIVER'].includes(ord.status)) {
              ord.status = 'CANCELLED';
              actionsTaken.push('cancel_order');
            }
          }
          if (/tiket|bantuan|komplain|masalah/i.test(msg) || actionsTaken.length === 0) {
            ticketCode = `TKT-${nextId()}`;
            db.supportTickets.set(ticketCode, {
              id: nextId(),
              ticket_code: ticketCode,
              user_id: user.id,
              order_id: body.order_id || null,
              app_source: body.app_source || 'CUSTOMER_APP',
              category: body.issue_category || 'general',
              subject: 'Tiket CS AI',
              description: msg,
              status: 'OPEN',
              admin_reply: null,
            });
            actionsTaken.push('create_support_ticket');
          }
          return sendJson(res, 200, {
            success: true,
            session_id: sessionId,
            reply: 'CS AI RideOn siap membantu. Permintaan Anda telah diproses sesuai batas keamanan sistem.',
            provider_used: 'local-fallback',
            actions_taken: actionsTaken,
            ticket_code: ticketCode,
          });
        }
        if (pathname === '/ai/food-assistant' && method === 'POST') {
          const q = String(body.query || '').trim();
          if (!q) return sendJson(res, 400, { success: false, error: 'Query required' });
          const maxP = Number(body.max_price || 1000000);
          const recs = Array.from(db.menus.values()).filter((m) => m.is_available && m.price <= maxP);
          return sendJson(res, 200, {
            success: true,
            reply: `Berikut rekomendasi menu sesuai "${q}" di sekitar Lhokseumawe:`,
            recommended_menus: recs,
            provider_used: 'local-fallback',
          });
        }
        if (pathname === '/ai/quick-replies' && method === 'POST') {
          return sendJson(res, 200, {
            success: true,
            suggestions: ['Baik, saya tunggu di titik jemput.', 'Hati-hati di jalan ya Kak.', 'Sudah di depan gerbang.'],
            provider_used: 'local-fallback',
          });
        }
        if (pathname === '/ai/driver/summarize-shopping' && method === 'POST') {
          return sendJson(res, 200, {
            success: true,
            summary_checklist: ['Cek barang stop 1 & simpan struk asli'],
            busy_area_tip: 'Area Pasar Inpres cukup ramai pada jam makan siang.',
            provider_used: 'local-fallback',
          });
        }
        if (pathname === '/ai/store/menu-copywriter' && method === 'POST') {
          return sendJson(res, 200, {
            success: true,
            description: `${body.name || 'Menu Spesial'} racikan autentik Aceh dengan cita rasa gurih dan harga bersahabat Rp ${formatIdr(body.price || 20000)}.`,
            provider_used: 'local-fallback',
          });
        }
        if (pathname === '/ai/store/sales-insight' && method === 'GET') {
          return sendJson(res, 200, {
            success: true,
            insight: 'Menu terlaris Anda mendominasi pesanan siang di sekitar Kampus Bukit Indah.',
            top_menus: Array.from(db.menus.values()).slice(0, 5),
            provider_used: 'local-fallback',
          });
        }
        if (pathname === '/ai/admin/executive-summary' && method === 'GET') {
          if (user.role !== 'admin') return sendJson(res, 403, { success: false, error: 'Admin only' });
          return sendJson(res, 200, {
            success: true,
            summary: `Ekosistem RideOn Lhokseumawe beroperasi normal dengan ${db.orders.size} pesanan dan ${db.stores.size} toko aktif.`,
            metrics: { orders: db.orders.size, stores: db.stores.size, drivers: db.drivers.size },
            provider_used: 'local-fallback',
          });
        }
        if (pathname === '/ai/admin/test-provider' && method === 'POST') {
          if (user.role !== 'admin') return sendJson(res, 403, { success: false, error: 'Admin only' });
          return sendJson(res, 200, {
            success: false,
            error: 'Upstream provider unreachable (R5 local fallback safe)',
            latency_ms: 12,
          });
        }
      }

      // =======================================================================
      // /v1/* (rideon-api)
      // =======================================================================
      if (pathname === '/v1/auth/register' && method === 'POST') {
        if (body.role === 'admin') {
          return sendJson(res, 403, { success: false, error: 'Cannot self-register as admin' });
        }
        if (!body.name || !body.password || (!body.email && !body.phone)) {
          return sendJson(res, 400, { success: false, error: 'Missing required fields' });
        }
        if (body.email && findUserByIdentifier(body.email)) {
          return sendJson(res, 409, { success: false, error: 'Email already registered' });
        }
        if (body.phone && findUserByIdentifier(body.phone)) {
          return sendJson(res, 409, { success: false, error: 'Phone already registered' });
        }

        const role = ['customer', 'driver', 'store'].includes(body.role) ? body.role : 'customer';
        const uid = nextId();
        const isPartner = role === 'driver' || role === 'store';
        const user = {
          id: uid,
          firebase_uid: `fb-${role}-${uid}`,
          name: body.name,
          email: body.email || null,
          phone: body.phone || null,
          password: body.password,
          role,
          status: isPartner ? 'Menunggu verifikasi' : 'Aktif',
        };
        db.users.set(uid, user);

        let driver = null;
        let store = null;
        if (role === 'driver') {
          const did = nextId();
          driver = {
            id: did,
            user_id: uid,
            vehicle_type: body.vehicle_type || 'MOTOR',
            vehicle_brand: body.vehicle_brand || 'Honda Beat',
            plate_number: body.plate_number || `BL ${did} AA`,
            service_area: body.service_area || 'Lhokseumawe',
            cash_capital_limit: Number(body.cash_capital_limit ?? 200000),
            is_online: false,
            verification_status: 'Menunggu verifikasi',
            rating_avg: 5.0,
          };
          db.drivers.set(did, driver);
          ensureWallet(uid, 'DRIVER');
        } else if (role === 'store') {
          const sid = nextId();
          store = {
            id: sid,
            user_id: uid,
            store_name: body.store_name || `Toko ${uid}`,
            owner_name: body.owner_name || body.name,
            description: body.description || '',
            category: body.store_category || 'Makanan & Minuman',
            address: body.store_address || COORDS.BLANG_PULO.address,
            service_area: body.service_area || 'Lhokseumawe',
            latitude: Number(body.store_lat ?? COORDS.BLANG_PULO.lat),
            longitude: Number(body.store_lng ?? COORDS.BLANG_PULO.lng),
            open_hours: '08.00 - 21.00',
            is_open: false,
            withdraw_pin: null,
            verification_status: 'Menunggu verifikasi',
            rating_avg: 5.0,
          };
          db.stores.set(sid, store);
          ensureWallet(uid, 'STORE');
        }

        const rid = nextId();
        const reg = {
          id: rid,
          reg_code: `REG-${rid}`,
          user_id: uid,
          kind: role === 'driver' ? 'Driver' : role === 'store' ? 'Toko' : 'Customer',
          status: isPartner ? 'Menunggu verifikasi' : 'Disetujui',
          ktp_url: body.ktp_url || null,
          sim_url: body.sim_url || null,
          stnk_url: body.stnk_url || null,
          business_doc_url: body.business_doc_url || null,
        };
        db.registrations.set(rid, reg);

        const token = signJwt({ user_id: uid, firebase_uid: user.firebase_uid, role, email: user.email, phone: user.phone });
        return sendJson(res, 201, { success: true, token, user, driver, store, registration: reg });
      }

      if (pathname === '/v1/auth/login') {
        if (method !== 'POST') return sendJson(res, 405, { success: false, error: 'Method Not Allowed' });
        const user = findUserByIdentifier(body.identifier);
        if (!user || user.password !== body.password) {
          return sendJson(res, 401, { success: false, error: 'Invalid credentials' });
        }
        if (body.role && body.role !== user.role) {
          return sendJson(res, 403, { success: false, error: 'Role mismatch' });
        }
        const token = signJwt({ user_id: user.id, firebase_uid: user.firebase_uid, role: user.role, email: user.email, phone: user.phone });
        return sendJson(res, 200, {
          success: true,
          token,
          user,
          driver: getDriverByUserId(user.id),
          store: getStoreByUserId(user.id),
        });
      }

      if (pathname === '/v1/auth/google' && method === 'POST') {
        if (!body.email) return sendJson(res, 400, { success: false, error: 'Email required' });
        let user = findUserByIdentifier(body.email);
        let isNew = false;
        if (!user) {
          isNew = true;
          const uid = nextId();
          user = {
            id: uid,
            firebase_uid: `fb-ggl-${uid}`,
            name: body.name || 'Google User',
            email: body.email,
            phone: null,
            password: null,
            role: 'customer',
            status: 'Aktif',
          };
          db.users.set(uid, user);
        }
        const token = signJwt({ user_id: user.id, firebase_uid: user.firebase_uid, role: user.role, email: user.email });
        return sendJson(res, 200, { success: true, token, user, is_new: isNew });
      }

      if (pathname === '/v1/auth/otp/send' && method === 'POST') {
        const key = `${body.channel || 'EMAIL'}:${body.identifier}`;
        const code = String(crypto.randomInt(100000, 999999));
        db.emailOtps.set(key, { code, expiresAt: Date.now() + 300000 });
        return sendJson(res, 200, { success: true, message: 'OTP sent (local fallback)', dev_otp: code });
      }

      if (pathname === '/v1/auth/otp/verify' && method === 'POST') {
        const key = `${body.channel || 'EMAIL'}:${body.identifier}`;
        const rec = db.emailOtps.get(key);
        if (!rec || rec.code !== String(body.code)) {
          return sendJson(res, 400, { success: false, error: 'Invalid OTP' });
        }
        return sendJson(res, 200, { success: true, verified: true });
      }

      if (pathname === '/v1/auth/password/reset' && method === 'POST') {
        const key = `${body.channel || 'EMAIL'}:${body.identifier}`;
        const rec = db.emailOtps.get(key);
        if (!rec || rec.code !== String(body.code)) {
          return sendJson(res, 400, { success: false, error: 'Invalid OTP' });
        }
        const user = findUserByIdentifier(body.identifier);
        if (!user) return sendJson(res, 404, { success: false, error: 'User not found' });
        user.password = body.new_password;
        db.emailOtps.delete(key);
        return sendJson(res, 200, { success: true, message: 'Password updated' });
      }

      if (pathname === '/v1/home' && method === 'GET') {
        return sendJson(res, 200, {
          success: true,
          promotions: Array.from(db.promotions.values()),
          best_sellers: Array.from(db.menus.values()).slice(0, 10),
          top20: Array.from(db.menus.values()).slice(0, 20),
          wisata_recommendations: [
            { name: 'Pantai Ujong Blang', lat: 5.1972, lng: 97.1361 },
            { name: 'Islamic Center Lhokseumawe', lat: 5.1785, lng: 97.1436 },
          ],
        });
      }

      if (pathname === '/v1/stores' && method === 'GET') {
        const list = Array.from(db.stores.values())
          .filter((s) => s.verification_status === 'Disetujui')
          .reverse();
        return sendJson(res, 200, { success: true, stores: list });
      }

      if (/^\/v1\/stores\/\d+\/menus$/.test(pathname) && method === 'GET') {
        const storeId = Number(pathname.split('/')[3]);
        const store = db.stores.get(storeId);
        if (!store) return sendJson(res, 404, { success: false, error: 'Store not found' });
        const menus = Array.from(db.menus.values())
          .filter((m) => m.store_id === storeId)
          .sort((a, b) => b.created_at - a.created_at || b.id - a.id);
        return sendJson(res, 200, { success: true, store, menus });
      }

      if (pathname === '/v1/menus' && method === 'GET') {
        const menus = Array.from(db.menus.values()).sort((a, b) => b.created_at - a.created_at || b.id - a.id);
        return sendJson(res, 200, { success: true, menus });
      }

      if (pathname === '/v1/pricing/estimate' && method === 'POST') {
        const est = computeEstimate(body);
        if (est.error) return sendJson(res, 400, { success: false, error: est.error });
        return sendJson(res, 200, { success: true, ...est });
      }

      // Authenticated /v1/* endpoints
      const user = authUser(req);
      if (!user) {
        if (pathname.startsWith('/v1/')) {
          // Return 404 for unknown routes even when unauthenticated (T2-A1-01), else 401
          const knownPrefixes = [
            '/v1/me',
            '/v1/store',
            '/v1/driver',
            '/v1/orders',
            '/v1/favorites',
            '/v1/wallet',
            '/v1/admin',
          ];
          if (knownPrefixes.some((p) => pathname.startsWith(p))) {
            return sendJson(res, 401, { success: false, error: 'Unauthorized' });
          }
          return sendJson(res, 404, { success: false, error: 'Route not found' });
        }
        return sendJson(res, 404, { success: false, error: 'Not found' });
      }

      if (pathname === '/v1/me' && method === 'GET') {
        const drv = getDriverByUserId(user.id);
        const st = getStoreByUserId(user.id);
        const w =
          user.role === 'driver'
            ? ensureWallet(user.id, 'DRIVER')
            : user.role === 'store'
              ? ensureWallet(user.id, 'STORE')
              : null;
        return sendJson(res, 200, { success: true, user, driver: drv, store: st, wallet: w });
      }

      // Store endpoints
      if (pathname === '/v1/store/profile' && (method === 'POST' || method === 'PUT')) {
        if (user.role !== 'store') return sendJson(res, 403, { success: false, error: 'Store only' });
        const st = getStoreByUserId(user.id);
        Object.assign(st, {
          store_name: body.store_name ?? st.store_name,
          description: body.description ?? st.description,
          category: body.category ?? st.category,
          address: body.address ?? st.address,
          latitude: body.latitude ?? st.latitude,
          longitude: body.longitude ?? st.longitude,
          open_hours: body.open_hours ?? st.open_hours,
        });
        if (body.withdraw_pin) st.withdraw_pin = String(body.withdraw_pin);
        return sendJson(res, 200, { success: true, store: st });
      }

      if (pathname === '/v1/store/status' && ['PATCH', 'PUT', 'POST'].includes(method)) {
        if (user.role !== 'store') return sendJson(res, 403, { success: false, error: 'Store only' });
        const st = getStoreByUserId(user.id);
        if (st.verification_status !== 'Disetujui') {
          return sendJson(res, 403, { success: false, error: 'Akun toko masih menunggu verifikasi admin' });
        }
        st.is_open = Boolean(body.is_open);
        return sendJson(res, 200, { success: true, is_open: st.is_open });
      }

      if (pathname === '/v1/store/menus' && method === 'POST') {
        if (user.role !== 'store') return sendJson(res, 403, { success: false, error: 'Store only' });
        const st = getStoreByUserId(user.id);
        if (!body.name || !String(body.name).trim() || Number(body.price) <= 0) {
          return sendJson(res, 400, { success: false, error: 'Invalid menu name or price' });
        }
        const mid = nextId();
        const menu = {
          id: mid,
          store_id: st.id,
          name: String(body.name).trim(),
          description: body.description || '',
          category: body.category || 'Makanan Utama',
          price: Number(body.price),
          image_url: body.image_url || null,
          is_available: body.is_available !== false,
          total_sold: 0,
          rating_avg: 5.0,
          created_at: Date.now() + mid,
        };
        db.menus.set(mid, menu);
        return sendJson(res, 201, { success: true, menu });
      }

      if (/^\/v1\/store\/menus\/\d+$/.test(pathname)) {
        if (user.role !== 'store') return sendJson(res, 403, { success: false, error: 'Store only' });
        const st = getStoreByUserId(user.id);
        const mid = Number(pathname.split('/')[4]);
        const menu = db.menus.get(mid);
        if (!menu) return sendJson(res, 404, { success: false, error: 'Menu not found' });
        if (menu.store_id !== st.id) return sendJson(res, 403, { success: false, error: 'Forbidden' });
        if (method === 'PUT' || method === 'PATCH') {
          if (body.price !== undefined) menu.price = Number(body.price);
          if (body.name !== undefined) menu.name = body.name;
          if (body.is_available !== undefined) menu.is_available = Boolean(body.is_available);
          return sendJson(res, 200, { success: true, menu });
        }
        if (method === 'DELETE') {
          db.menus.delete(mid);
          return sendJson(res, 200, { success: true });
        }
      }

      // Driver endpoints
      if (pathname === '/v1/driver/status' && ['PATCH', 'PUT', 'POST'].includes(method)) {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const drv = getDriverByUserId(user.id);
        if (drv.verification_status !== 'Disetujui') {
          return sendJson(res, 403, { success: false, error: 'Akun driver belum disetujui admin' });
        }
        drv.is_online = Boolean(body.is_online);
        if (body.cash_capital_limit !== undefined) drv.cash_capital_limit = Number(body.cash_capital_limit);
        return sendJson(res, 200, { success: true, driver: drv });
      }

      if (pathname === '/v1/driver/documents' && method === 'PUT') {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const reg = Array.from(db.registrations.values()).find((r) => r.user_id === user.id);
        if (reg) {
          reg.ktp_url = body.ktp_url ?? reg.ktp_url;
          reg.sim_url = body.sim_url ?? reg.sim_url;
          reg.stnk_url = body.stnk_url ?? reg.stnk_url;
        }
        return sendJson(res, 200, { success: true, registration: reg });
      }

      // Orders endpoints
      if (pathname === '/v1/orders' && method === 'POST') {
        if (user.role !== 'customer') return sendJson(res, 403, { success: false, error: 'Customer only' });
        const svcType = body.service_type;
        if (!['FlexRide', 'FlexFood', 'FlexSend'].includes(svcType)) {
          return sendJson(res, 400, { success: false, error: 'Invalid service_type' });
        }
        const vehType = body.vehicle_type || 'MOTOR';
        const items = Array.isArray(body.items) ? body.items : [];
        let subtotal = 0;

        if (svcType === 'FlexFood') {
          const st = db.stores.get(Number(body.store_id));
          if (!st || !st.is_open) return sendJson(res, 400, { success: false, error: 'Store closed or not found' });
          if (items.length === 0) return sendJson(res, 400, { success: false, error: 'Items required' });
          for (const it of items) {
            if (!it.quantity || Number(it.quantity) <= 0) {
              return sendJson(res, 400, { success: false, error: 'Invalid item quantity' });
            }
            const m = db.menus.get(Number(it.menu_id));
            if (!m || !m.is_available || m.store_id !== st.id) {
              return sendJson(res, 400, { success: false, error: 'Menu unavailable' });
            }
            subtotal += Number(m.price) * Number(it.quantity);
          }
        } else if (svcType === 'FlexSend') {
          const distinctStops = new Set(items.map((it) => it.stop_index || 1));
          if (items.length > FINANCE_CONSTANTS.MAX_FLEXSEND_STOPS || distinctStops.size > FINANCE_CONSTANTS.MAX_FLEXSEND_STOPS) {
            return sendJson(res, 400, { success: false, error: 'Maximum 3 shopping stops allowed' });
          }
          for (const it of items) {
            subtotal += Number(it.estimated_price || 0) * Number(it.quantity || 1);
          }
        }

        const pricingSvc =
          svcType === 'FlexRide'
            ? vehType === 'MOBIL'
              ? 'FLEXRIDE_MOBIL'
              : 'FLEXRIDE_MOTOR'
            : svcType.toUpperCase();
        const est = computeEstimate({
          service_type: pricingSvc,
          pickup_lat: body.pickup_lat,
          pickup_lng: body.pickup_lng,
          dest_lat: body.dest_lat,
          dest_lng: body.dest_lng,
          stops: items,
          promo_code: body.promo_code,
        });
        if (est.error) return sendJson(res, 400, { success: false, error: est.error });

        const paymentMethod = body.payment_method === 'QRIS' ? 'QRIS' : 'TUNAI';
        const initialStatus =
          paymentMethod === 'QRIS'
            ? 'WAITING_PAYMENT'
            : svcType === 'FlexFood'
              ? 'WAITING_STORE'
              : 'SEARCHING_DRIVER';

        const oid = nextId();
        const order = {
          id: oid,
          order_code: `ORD-${oid}`,
          customer_id: user.id,
          driver_id: null,
          store_id: body.store_id ? Number(body.store_id) : null,
          service_type: svcType,
          vehicle_type: vehType,
          status: initialStatus,
          distance_km: est.distance_km,
          subtotal_amount: subtotal,
          delivery_fee: est.delivery_fee,
          service_fee: est.service_fee,
          parking_fee: 0,
          actual_receipt_amount: 0,
          receipt_photo_url: null,
          discount_amount: est.discount_amount,
          total_amount: subtotal + est.delivery_fee + est.service_fee - est.discount_amount,
          payment_method: paymentMethod,
          payment_status: 'UNPAID',
          created_at: new Date().toISOString(),
        };
        db.orders.set(oid, order);
        const savedItems = items.map((it) => ({
          id: nextId(),
          order_id: oid,
          ...it,
        }));
        db.orderItems.set(oid, savedItems);
        return sendJson(res, 201, { success: true, order, items: savedItems });
      }

      if (pathname === '/v1/orders' && method === 'GET') {
        const list = Array.from(db.orders.values()).filter((o) => {
          if (user.role === 'customer') return o.customer_id === user.id;
          if (user.role === 'store') return o.store_id === getStoreByUserId(user.id)?.id;
          return true;
        });
        return sendJson(res, 200, { success: true, orders: list });
      }

      if (/^\/v1\/orders\/\d+$/.test(pathname) && method === 'GET') {
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order) return sendJson(res, 404, { success: false, error: 'Order not found' });
        if (user.role === 'customer' && order.customer_id !== user.id) {
          return sendJson(res, 403, { success: false, error: 'Forbidden' });
        }
        return sendJson(res, 200, {
          success: true,
          order,
          items: db.orderItems.get(oid) || [],
        });
      }

      if (/^\/v1\/orders\/\d+\/cancel$/.test(pathname) && method === 'POST') {
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order) return sendJson(res, 404, { success: false, error: 'Order not found' });
        if (user.role === 'customer' && order.customer_id !== user.id) {
          return sendJson(res, 403, { success: false, error: 'Forbidden' });
        }
        if (['COMPLETED', 'CANCELLED'].includes(order.status)) {
          return sendJson(res, 409, { success: false, error: 'Cannot cancel completed/cancelled order' });
        }
        order.status = 'CANCELLED';
        return sendJson(res, 200, { success: true, order });
      }

      if (/^\/v1\/orders\/\d+\/accept-store$/.test(pathname) && method === 'POST') {
        if (user.role !== 'store') return sendJson(res, 403, { success: false, error: 'Store only' });
        const st = getStoreByUserId(user.id);
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order) return sendJson(res, 404, { success: false, error: 'Order not found' });
        if (order.store_id !== st.id) return sendJson(res, 403, { success: false, error: 'Forbidden' });
        if (order.status !== 'WAITING_STORE') {
          return sendJson(res, 409, { success: false, error: 'Order not in WAITING_STORE' });
        }
        order.status = 'SEARCHING_DRIVER';
        return sendJson(res, 200, { success: true, order });
      }

      if (/^\/v1\/orders\/\d+\/reject-store$/.test(pathname) && method === 'POST') {
        if (user.role !== 'store') return sendJson(res, 403, { success: false, error: 'Store only' });
        const st = getStoreByUserId(user.id);
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order) return sendJson(res, 404, { success: false, error: 'Order not found' });
        if (order.store_id !== st.id) return sendJson(res, 403, { success: false, error: 'Forbidden' });
        if (order.status !== 'WAITING_STORE') {
          return sendJson(res, 409, { success: false, error: 'Order already accepted or closed' });
        }
        order.status = 'CANCELLED';
        if (order.payment_status === 'PAID') order.payment_status = 'REFUNDED';
        return sendJson(res, 200, { success: true, order });
      }

      if (/^\/v1\/orders\/\d+\/accept-driver$/.test(pathname) && method === 'POST') {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const drv = getDriverByUserId(user.id);
        if (!drv || drv.verification_status !== 'Disetujui') {
          return sendJson(res, 403, { success: false, error: 'Driver not approved' });
        }
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order) return sendJson(res, 404, { success: false, error: 'Order not found' });
        if (order.service_type === 'FlexRide' && order.vehicle_type !== drv.vehicle_type) {
          return sendJson(res, 403, { success: false, error: 'Vehicle type mismatch' });
        }
        if (order.service_type === 'FlexSend' && drv.cash_capital_limit < order.subtotal_amount) {
          return sendJson(res, 403, { success: false, error: 'Insufficient cash_capital_limit' });
        }
        const wallet = ensureWallet(user.id, 'DRIVER');
        if (order.payment_method === 'TUNAI' && wallet.balance <= FINANCE_CONSTANTS.DRIVER_TUNAI_TOLERANCE_FLOOR) {
          return sendJson(res, 403, { success: false, error: 'Saldo minus mencapai batas -Rp 20.000' });
        }
        if (!faults.break_409_race && (order.driver_id !== null || order.status !== 'SEARCHING_DRIVER')) {
          return sendJson(res, 409, { success: false, error: 'Maaf, pesanan ini baru saja diambil driver lain' });
        }
        order.driver_id = drv.id;
        order.status = 'DRIVER_ACCEPTED';
        order.accepted_at = new Date().toISOString();
        return sendJson(res, 200, { success: true, order });
      }

      if (/^\/v1\/orders\/\d+\/status$/.test(pathname) && method === 'POST') {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const drv = getDriverByUserId(user.id);
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order || order.driver_id !== drv.id) {
          return sendJson(res, 403, { success: false, error: 'Not assigned driver' });
        }
        order.status = body.status;
        return sendJson(res, 200, { success: true, order });
      }

      if (/^\/v1\/orders\/\d+\/flexsend-receipt$/.test(pathname) && method === 'POST') {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const drv = getDriverByUserId(user.id);
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order || order.driver_id !== drv.id) {
          return sendJson(res, 403, { success: false, error: 'Not assigned driver' });
        }
        const recAmt = Number(body.actual_receipt_amount);
        const parkAmt = Number(body.parking_fee || 0);
        if (recAmt < 0 || parkAmt < 0 || !body.receipt_photo_url) {
          return sendJson(res, 400, { success: false, error: 'Invalid receipt payload' });
        }
        order.actual_receipt_amount = recAmt;
        order.parking_fee = parkAmt;
        order.receipt_photo_url = body.receipt_photo_url;
        order.total_amount = recAmt + parkAmt + order.delivery_fee + order.service_fee - order.discount_amount;
        return sendJson(res, 200, { success: true, order });
      }

      if (/^\/v1\/orders\/\d+\/complete$/.test(pathname) && method === 'POST') {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const drv = getDriverByUserId(user.id);
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order || order.driver_id !== drv.id || !['ARRIVED', 'PICKED_UP', 'DELIVERING'].includes(order.status)) {
          return sendJson(res, 409, { success: false, error: 'Order cannot be completed in current state' });
        }
        order.status = 'COMPLETED';
        order.completed_at = new Date().toISOString();

        const drvWallet = ensureWallet(user.id, 'DRIVER');
        let driverNet = 0;
        let storeNet = 0;

        if (!faults.break_commission_math) {
          if (order.payment_method === 'QRIS') {
            driverNet = Math.round(order.delivery_fee * 0.95);
            drvWallet.balance += driverNet;
            if (order.store_id) {
              const st = db.stores.get(order.store_id);
              const stWallet = ensureWallet(st.user_id, 'STORE');
              storeNet = Math.round(order.subtotal_amount * 0.95);
              stWallet.balance += storeNet;
            }
          } else {
            const fee = Math.round(order.delivery_fee * 0.05);
            driverNet = -fee;
            drvWallet.balance -= fee;
          }
        }

        if (order.service_type === 'FlexFood') {
          for (const it of db.orderItems.get(oid) || []) {
            const m = db.menus.get(Number(it.menu_id));
            if (m) m.total_sold += Number(it.quantity || 1);
          }
        }
        return sendJson(res, 200, { success: true, order, driver_net: driverNet, store_net: storeNet });
      }

      if (/^\/v1\/orders\/\d+\/rating$/.test(pathname) && method === 'POST') {
        if (user.role !== 'customer') return sendJson(res, 403, { success: false, error: 'Customer only' });
        const oid = Number(pathname.split('/')[3]);
        const order = db.orders.get(oid);
        if (!order) return sendJson(res, 404, { success: false, error: 'Order not found' });
        if (order.customer_id !== user.id) return sendJson(res, 403, { success: false, error: 'Forbidden' });
        if (order.status !== 'COMPLETED') return sendJson(res, 409, { success: false, error: 'Order not completed' });
        if (db.ratings.has(oid)) return sendJson(res, 409, { success: false, error: 'Duplicate rating' });
        for (const stars of [body.driver_stars, body.store_stars]) {
          if (stars !== undefined && (Number(stars) < 1 || Number(stars) > 5)) {
            return sendJson(res, 400, { success: false, error: 'Stars must be 1..5' });
          }
        }
        const rating = {
          id: nextId(),
          order_id: oid,
          customer_id: user.id,
          driver_id: order.driver_id,
          store_id: order.store_id,
          driver_stars: body.driver_stars ?? null,
          store_stars: body.store_stars ?? null,
          comment: body.comment || '',
        };
        db.ratings.set(oid, rating);
        recalcOrderRatings(order.driver_id, order.store_id);
        return sendJson(res, 201, { success: true, rating });
      }

      // Favorites
      if (pathname === '/v1/favorites' && method === 'GET') {
        const list = Array.from(db.favorites.values()).filter((f) => f.user_id === user.id);
        return sendJson(res, 200, { success: true, favorites: list });
      }
      if (pathname === '/v1/favorites' && method === 'POST') {
        if (!['MENU', 'STORE', 'PLACE'].includes(body.target_type)) {
          return sendJson(res, 400, { success: false, error: 'Invalid target_type' });
        }
        const fid = nextId();
        const fav = { id: fid, user_id: user.id, ...body };
        db.favorites.set(fid, fav);
        return sendJson(res, 201, { success: true, favorite: fav });
      }
      if (/^\/v1\/favorites\/\d+$/.test(pathname) && method === 'DELETE') {
        const fid = Number(pathname.split('/')[3]);
        const fav = db.favorites.get(fid);
        if (!fav) return sendJson(res, 404, { success: false, error: 'Not found' });
        if (fav.user_id !== user.id) return sendJson(res, 403, { success: false, error: 'Forbidden' });
        db.favorites.delete(fid);
        return sendJson(res, 200, { success: true });
      }

      // Wallet & Withdraw & Talangan
      if (pathname === '/v1/wallet' && method === 'GET') {
        const ownerType = user.role === 'store' ? 'STORE' : 'DRIVER';
        const w = ensureWallet(user.id, ownerType);
        const txs = db.walletTxs.filter((t) => t.wallet_id === w.id);
        return sendJson(res, 200, { success: true, wallet: w, transactions: txs });
      }
      if (pathname === '/v1/wallet/withdraw' && method === 'POST') {
        if (!['driver', 'store'].includes(user.role)) {
          return sendJson(res, 403, { success: false, error: 'Partner only' });
        }
        const ownerType = user.role === 'store' ? 'STORE' : 'DRIVER';
        const w = ensureWallet(user.id, ownerType);
        const amt = Number(body.amount);
        if (!Number.isFinite(amt) || amt <= FINANCE_CONSTANTS.WITHDRAW_ADMIN_FEE) {
          return sendJson(res, 400, { success: false, error: 'Amount must exceed Rp 2.000 admin fee' });
        }
        if (ownerType === 'STORE') {
          const st = getStoreByUserId(user.id);
          if (!body.pin || String(body.pin).length !== 6 || String(body.pin) !== String(st.withdraw_pin)) {
            return sendJson(res, 403, { success: false, error: 'Invalid 6-digit withdraw PIN' });
          }
        }
        if (w.balance < amt) {
          return sendJson(res, 400, { success: false, error: 'Insufficient balance' });
        }
        w.balance -= amt;
        const wid = nextId();
        const wd = {
          id: wid,
          wd_code: `WD-${wid}`,
          wallet_id: w.id,
          user_id: user.id,
          owner_type: ownerType,
          amount: amt,
          admin_fee: FINANCE_CONSTANTS.WITHDRAW_ADMIN_FEE,
          net_payout: amt - FINANCE_CONSTANTS.WITHDRAW_ADMIN_FEE,
          bank_name: body.bank_name,
          bank_account_number: body.bank_account_number,
          bank_account_holder: body.bank_account_holder,
          status: 'PENDING',
        };
        db.withdrawals.set(wid, wd);
        return sendJson(res, 201, { success: true, withdrawal: wd, balance: w.balance });
      }
      if (pathname === '/v1/wallet/talangan-claims' && method === 'POST') {
        if (user.role !== 'driver') return sendJson(res, 403, { success: false, error: 'Driver only' });
        const drv = getDriverByUserId(user.id);
        const oid = Number(body.order_id);
        const ord = db.orders.get(oid);
        if (!ord || ord.driver_id !== drv.id) {
          return sendJson(res, 403, { success: false, error: 'Not assigned driver' });
        }
        if (!body.receipt_photo_url || !body.donation_photo_url || !body.donation_recipient) {
          return sendJson(res, 400, { success: false, error: 'Both receipt and donation proof required' });
        }
        if (Array.from(db.talanganClaims.values()).some((c) => c.order_id === oid)) {
          return sendJson(res, 409, { success: false, error: 'Duplicate talangan claim' });
        }
        const cid = nextId();
        const totalClaim = Number(body.receipt_amount) + Number(body.parking_amount || 0);
        const claim = {
          id: cid,
          claim_code: `CLM-${cid}`,
          order_id: oid,
          driver_id: drv.id,
          driver_user_id: user.id,
          receipt_amount: Number(body.receipt_amount),
          parking_amount: Number(body.parking_amount || 0),
          total_claim_amount: totalClaim,
          receipt_photo_url: body.receipt_photo_url,
          donation_recipient: body.donation_recipient,
          donation_photo_url: body.donation_photo_url,
          status: 'PENDING',
        };
        db.talanganClaims.set(cid, claim);
        return sendJson(res, 201, { success: true, claim });
      }

      // Admin endpoints
      if (pathname.startsWith('/v1/admin/')) {
        if (user.role !== 'admin') return sendJson(res, 403, { success: false, error: 'Admin only' });

        if (pathname === '/v1/admin/overview' && method === 'GET') {
          return sendJson(res, 200, {
            success: true,
            orders_count: db.orders.size,
            drivers_count: db.drivers.size,
            stores_count: db.stores.size,
          });
        }
        if (pathname === '/v1/admin/orders' && method === 'GET') {
          return sendJson(res, 200, { success: true, orders: Array.from(db.orders.values()) });
        }
        if (pathname === '/v1/admin/drivers' && method === 'GET') {
          return sendJson(res, 200, { success: true, drivers: Array.from(db.drivers.values()) });
        }
        if (pathname === '/v1/admin/stores' && method === 'GET') {
          return sendJson(res, 200, { success: true, stores: Array.from(db.stores.values()) });
        }
        if (pathname === '/v1/admin/customers' && method === 'GET') {
          return sendJson(res, 200, {
            success: true,
            customers: Array.from(db.users.values()).filter((u) => u.role === 'customer'),
          });
        }
        if (pathname === '/v1/admin/map' && method === 'GET') {
          return sendJson(res, 200, {
            success: true,
            stores: Array.from(db.stores.values()),
            drivers: Array.from(db.drivers.values()),
          });
        }
        if (pathname === '/v1/admin/registrations' && method === 'GET') {
          const stFilter = parsed.searchParams.get('status');
          let list = Array.from(db.registrations.values());
          if (stFilter) list = list.filter((r) => r.status === stFilter);
          return sendJson(res, 200, { success: true, registrations: list });
        }
        if (/^\/v1\/admin\/registrations\/\d+\/decide$/.test(pathname) && (method === 'PATCH' || method === 'POST')) {
          const rid = Number(pathname.split('/')[4]);
          const reg = db.registrations.get(rid);
          if (!reg) return sendJson(res, 404, { success: false, error: 'Registration not found' });
          const nextSt = body.status === 'Disetujui' || body.decision === 'APPROVED' ? 'Disetujui' : 'Ditolak';
          reg.status = nextSt;
          const targetUser = db.users.get(reg.user_id);
          if (targetUser) targetUser.status = nextSt === 'Disetujui' ? 'Aktif' : 'Ditolak';
          const drv = getDriverByUserId(reg.user_id);
          if (drv) drv.verification_status = nextSt;
          const st = getStoreByUserId(reg.user_id);
          if (st) st.verification_status = nextSt;
          return sendJson(res, 200, { success: true, registration: reg });
        }
        if (pathname === '/v1/admin/withdrawals' && method === 'GET') {
          return sendJson(res, 200, { success: true, withdrawals: Array.from(db.withdrawals.values()) });
        }
        if (/^\/v1\/admin\/withdrawals\/\d+\/decide$/.test(pathname) && method === 'POST') {
          const wid = Number(pathname.split('/')[4]);
          const wd = db.withdrawals.get(wid);
          if (!wd) return sendJson(res, 404, { success: false, error: 'Not found' });
          if (wd.status !== 'PENDING') return sendJson(res, 409, { success: false, error: 'Already decided' });
          wd.status = body.status;
          if (body.status === 'REJECTED') {
            const w = ensureWallet(wd.user_id, wd.owner_type);
            w.balance += wd.amount;
          }
          return sendJson(res, 200, { success: true, withdrawal: wd });
        }
        if (pathname === '/v1/admin/talangan-claims' && method === 'GET') {
          return sendJson(res, 200, { success: true, talangan_claims: Array.from(db.talanganClaims.values()) });
        }
        if (/^\/v1\/admin\/talangan-claims\/\d+\/decide$/.test(pathname) && method === 'POST') {
          const cid = Number(pathname.split('/')[4]);
          const claim = db.talanganClaims.get(cid);
          if (!claim) return sendJson(res, 404, { success: false, error: 'Not found' });
          if (claim.status !== 'PENDING') return sendJson(res, 409, { success: false, error: 'Already decided' });
          claim.status = body.status;
          if (body.status === 'APPROVED') {
            const w = ensureWallet(claim.driver_user_id, 'DRIVER');
            w.balance += claim.total_claim_amount;
          }
          return sendJson(res, 200, { success: true, claim });
        }
        if (pathname === '/v1/admin/pricing-rules' && method === 'GET') {
          return sendJson(res, 200, { success: true, rules: Array.from(db.pricingRules.values()) });
        }
        if (pathname === '/v1/admin/pricing-rules' && method === 'PUT') {
          const rules = Array.isArray(body.rules) ? body.rules : [];
          for (const r of rules) {
            if (
              Number(r.base_fare) < 0 ||
              Number(r.per_km_rate) < 0 ||
              Number(r.driver_commission_pct) < 0 ||
              Number(r.driver_commission_pct) > 100
            ) {
              return sendJson(res, 400, { success: false, error: 'Invalid pricing rule boundary' });
            }
            if (db.pricingRules.has(r.service_type)) {
              db.pricingRules.set(r.service_type, { ...db.pricingRules.get(r.service_type), ...r });
            }
          }
          return sendJson(res, 200, { success: true, rules: Array.from(db.pricingRules.values()) });
        }
        if (pathname === '/v1/admin/promotions' && method === 'GET') {
          return sendJson(res, 200, { success: true, promotions: Array.from(db.promotions.values()) });
        }
        if (pathname === '/v1/admin/promotions' && method === 'POST') {
          const promo = { id: nextId(), ...body, code: String(body.code).toUpperCase() };
          db.promotions.set(promo.code, promo);
          return sendJson(res, 201, { success: true, promotion: promo });
        }
        if (pathname === '/v1/admin/ai-providers' && method === 'GET') {
          const providers = Array.from(db.aiProviders.values()).map((p) => ({
            id: p.id,
            display_name: p.display_name,
            protocol_type: p.protocol_type,
            base_url: p.base_url,
            model_name: p.model_name,
            priority: p.priority,
            is_active: p.is_active,
            timeout_seconds: p.timeout_seconds,
            api_key_masked: faults.leak_api_key
              ? p.raw_api_key
              : `****${String(p.raw_api_key || '').slice(-4)}`,
          }));
          return sendJson(res, 200, { success: true, providers });
        }
        if (pathname === '/v1/admin/ai-providers' && method === 'POST') {
          if (!['openai_compatible', 'gemini_native'].includes(body.protocol_type)) {
            return sendJson(res, 400, { success: false, error: 'Unsupported protocol_type' });
          }
          const pid = nextId();
          const prov = {
            id: pid,
            display_name: body.display_name,
            protocol_type: body.protocol_type,
            base_url: body.base_url,
            raw_api_key: body.api_key || '',
            model_name: body.model_name,
            priority: Number(body.priority ?? 1),
            is_active: body.is_active !== false,
            timeout_seconds: Number(body.timeout_seconds ?? 20),
          };
          db.aiProviders.set(pid, prov);
          return sendJson(res, 201, {
            success: true,
            provider: { ...prov, raw_api_key: undefined, api_key_masked: `****${prov.raw_api_key.slice(-4)}` },
          });
        }
        if (/^\/v1\/admin\/ai-providers\/\d+$/.test(pathname)) {
          const pid = Number(pathname.split('/')[4]);
          const prov = db.aiProviders.get(pid);
          if (!prov) return sendJson(res, 404, { success: false, error: 'Not found' });
          if (method === 'PUT' || method === 'PATCH') {
            if (body.priority !== undefined) prov.priority = Number(body.priority);
            if (body.is_active !== undefined) prov.is_active = Boolean(body.is_active);
            return sendJson(res, 200, { success: true, provider: prov });
          }
          if (method === 'DELETE') {
            db.aiProviders.delete(pid);
            return sendJson(res, 200, { success: true });
          }
        }
        if (pathname === '/v1/admin/support-tickets' && method === 'GET') {
          return sendJson(res, 200, { success: true, tickets: Array.from(db.supportTickets.values()).reverse() });
        }
        if (/^\/v1\/admin\/support-tickets\/\d+\/reply$/.test(pathname) && method === 'POST') {
          const tid = Number(pathname.split('/')[4]);
          const ticket = Array.from(db.supportTickets.values()).find((t) => t.id === tid);
          if (!ticket) return sendJson(res, 404, { success: false, error: 'Ticket not found' });
          ticket.status = body.status || 'RESOLVED';
          ticket.admin_reply = body.admin_reply || '';
          return sendJson(res, 200, { success: true, ticket });
        }
      }

      return sendJson(res, 404, { success: false, error: `Unmapped route: ${method} ${pathname}` });
    } catch (err) {
      return sendJson(res, 500, { success: false, error: err?.message || 'Internal error' });
    }
  });

  return {
    setFault(name, val = true) {
      faults[name] = val;
    },
    resetFaults() {
      for (const k of Object.keys(faults)) faults[k] = false;
    },
    async start() {
      await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
      const addr = server.address();
      return `http://127.0.0.1:${addr.port}`;
    },
    async close() {
      await new Promise((resolve) => server.close(resolve));
    },
  };
}

export async function runSelfTest({ tiers, selectedTests, allTests, runSuite }) {
  const mock = createMockServer();
  const baseUrl = await mock.start();
  const runId = createRunId();
  const client = createClient({ baseUrl, runId });

  try {
    // Phase 1: Full selected tier(s) against healthy Nginx-equivalent mock
    const phase1 = await runSuite(selectedTests, client);

    // Phase 2: 5 Contract-Breaker Mutation Checks
    const mutationSpecs = [
      { fault: 'break_crc16', targetTestId: 'T1-A9-02', description: 'Corrupted QRIS CRC-16 checksum detected' },
      { fault: 'break_409_race', targetTestId: 'T2-A5-01', description: 'Missing 409 Conflict atomic lock detected' },
      { fault: 'leak_api_key', targetTestId: 'T1-A10-02', description: 'Plaintext AI provider API key leak detected' },
      { fault: 'break_commission_math', targetTestId: 'T1-A7-02', description: 'Broken 5%:5% commission ledger math detected' },
      { fault: 'break_auth_401', targetTestId: 'T2-A9-03', description: 'Bypassed MacroDroid X-PayG-Secret 401 auth detected' },
    ];

    const mutationResults = [];
    for (const spec of mutationSpecs) {
      const targetTest = allTests.find((t) => t.id === spec.targetTestId);
      assert.ok(targetTest, `Missing Phase 2 target test ${spec.targetTestId}`);
      mock.resetFaults();
      mock.setFault(spec.fault, true);
      let caught = false;
      let detail = '';
      try {
        await targetTest.fn({ client });
        detail = 'Test unexpectedly PASSED despite injected fault';
      } catch (err) {
        caught = true;
        detail = err?.message || 'AssertionError';
      } finally {
        mock.resetFaults();
      }
      mutationResults.push({
        fault: spec.fault,
        targetTestId: spec.targetTestId,
        description: spec.description,
        caught,
        detail,
      });
    }

    const mutationsPassed = mutationResults.filter((m) => m.caught).length;
    const ok = phase1.counts.failed === 0 && mutationsPassed === mutationResults.length;

    return {
      ok,
      mode: 'self-test',
      baseUrl,
      runId,
      tiers,
      counts: phase1.counts,
      durationMs: phase1.durationMs,
      results: phase1.results,
      mutationChecks: {
        total: mutationResults.length,
        caught: mutationsPassed,
        failedToCatch: mutationResults.length - mutationsPassed,
        checks: mutationResults,
      },
    };
  } finally {
    await mock.close();
  }
}
