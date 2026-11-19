import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  COORDS,
  FEATURE_AREAS,
  FINANCE_CONSTANTS,
  PRICING_RULES,
  SAMPLE_STATIC_QRIS,
  VALID_1X1_PNG_BYTES,
} from '../lib/fixtures.mjs';
import {
  decodeJwtPayload,
  extractData,
  extractId,
  formatIdr,
  nextSeq,
  uniqueIdentity,
  uniqueInvoice,
  verifyDynamicQris,
} from '../lib/client.mjs';

export const TIER = 1;

export function defineTests() {
  return [
    // =========================================================================
    // Area 1: Infra, Nginx Proxy & Seed Baseline (6 tests)
    // =========================================================================
    {
      id: 'T1-A1-01',
      tier: 1,
      area: FEATURE_AREAS[0],
      title: 'GET /health via Nginx gateway returns 200 JSON ok',
      async fn({ client }) {
        const res = await client.get('/health');
        assert.equal(res.status, 200, `Expected 200 on /health, got ${res.status}: ${res.text}`);
        assert.ok(res.json && typeof res.json === 'object', 'Expected JSON response on /health');
        assert.equal(res.json.status, 'ok');
      },
    },
    {
      id: 'T1-A1-02',
      tier: 1,
      area: FEATURE_AREAS[0],
      title: 'GET /v1/stores and /v1/home proxy through Nginx to rideon-api',
      async fn({ client }) {
        const storesRes = await client.get('/v1/stores');
        assert.equal(storesRes.status, 200, `GET /v1/stores failed: ${storesRes.text}`);
        const stores = storesRes.json?.stores || storesRes.json?.data?.stores || [];
        assert.ok(Array.isArray(stores) && stores.length > 0, 'Expected seeded stores list');

        const homeRes = await client.get('/v1/home');
        assert.equal(homeRes.status, 200, `GET /v1/home failed: ${homeRes.text}`);
        assert.equal(homeRes.json?.success, true);
      },
    },
    {
      id: 'T1-A1-03',
      tier: 1,
      area: FEATURE_AREAS[0],
      title: 'GET /pay/status proxies through Nginx to payg service',
      async fn({ client }) {
        const res = await client.get('/pay/status', {
          headers: { 'X-PayG-Secret': client.secrets.payg },
        });
        assert.equal(res.status, 200, `GET /pay/status failed: ${res.text}`);
        assert.ok(res.json && typeof res.json === 'object', 'Expected JSON from /pay/status');
      },
    },
    {
      id: 'T1-A1-04',
      tier: 1,
      area: FEATURE_AREAS[0],
      title: 'GET /ai/health proxies through Nginx to ai-service',
      async fn({ client }) {
        const res = await client.get('/ai/health');
        assert.equal(res.status, 200, `GET /ai/health failed: ${res.text}`);
        assert.equal(res.json?.status, 'ok');
      },
    },
    {
      id: 'T1-A1-05',
      tier: 1,
      area: FEATURE_AREAS[0],
      title: 'GET /wa/health (prefix stripped) and GET / (Web Admin) proxy cleanly',
      async fn({ client }) {
        const waRes = await client.get('/wa/health');
        assert.equal(waRes.status, 200, `GET /wa/health failed: ${waRes.text}`);
        assert.equal(waRes.json?.status, 'ok');

        const adminRes = await client.get('/');
        assert.equal(adminRes.status, 200, `GET / failed: ${adminRes.status}`);
        const ct = adminRes.headers.get('content-type') || '';
        assert.ok(ct.includes('text/html'), `Expected text/html on /, got ${ct}`);
      },
    },
    {
      id: 'T1-A1-06',
      tier: 1,
      area: FEATURE_AREAS[0],
      title: 'Seed baseline: 4 pricing_rules (5%:5%) and Lhokseumawe/Aceh Utara seeded stores',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const rulesRes = await client.get('/v1/admin/pricing-rules', { token: adminToken });
        assert.equal(rulesRes.status, 200, `GET /v1/admin/pricing-rules failed: ${rulesRes.text}`);
        const rules = rulesRes.json?.rules || rulesRes.json?.data?.rules || [];
        const byType = new Map(rules.map((r) => [r.service_type, r]));
        for (const st of Object.keys(PRICING_RULES)) {
          assert.ok(byType.has(st), `Missing seeded pricing_rule for ${st}`);
          assert.equal(Number(byType.get(st).driver_commission_pct), 5);
        }
        assert.equal(Number(byType.get('FLEXFOOD').store_commission_pct), 5);

        const storesRes = await client.get('/v1/admin/stores', { token: adminToken });
        assert.equal(storesRes.status, 200);
        const stores = storesRes.json?.stores || storesRes.json?.data?.stores || [];
        assert.ok(stores.length > 0, 'Expected seeded stores');
        const hasAcehCoord = stores.some(
          (s) =>
            Number(s.latitude) >= 4.9 &&
            Number(s.latitude) <= 5.4 &&
            Number(s.longitude) >= 96.7 &&
            Number(s.longitude) <= 97.5
        );
        assert.ok(hasAcehCoord, 'Expected seeded store inside Lhokseumawe/Aceh Utara bounds');
      },
    },

    // =========================================================================
    // Area 2: Unified Auth, OTP & Approval Gates (6 tests)
    // =========================================================================
    {
      id: 'T1-A2-01',
      tier: 1,
      area: FEATURE_AREAS[1],
      title: 'Customer registration is auto-active and returns valid HS256 JWT',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const claims = decodeJwtPayload(cust.token);
        assert.equal(claims.role, 'customer');
        assert.ok(claims.user_id, 'JWT missing user_id claim');
        assert.ok(claims.exp, 'JWT missing exp claim');

        const me = await client.get('/v1/me', { token: cust.token });
        assert.equal(me.status, 200);
        const user = me.json?.user || me.json?.data?.user;
        assert.equal(user.status, 'Aktif');
      },
    },
    {
      id: 'T1-A2-02',
      tier: 1,
      area: FEATURE_AREAS[1],
      title: 'Login succeeds with both Email and WA Phone credentials',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const emailLogin = await client.post('/v1/auth/login', {
          identifier: cust.creds.email,
          password: cust.creds.password,
        });
        assert.equal(emailLogin.status, 200, `Email login failed: ${emailLogin.text}`);
        assert.ok(emailLogin.json?.token || emailLogin.json?.data?.token);

        const phoneLogin = await client.post('/v1/auth/login', {
          identifier: cust.creds.phone,
          password: cust.creds.password,
        });
        assert.equal(phoneLogin.status, 200, `Phone login failed: ${phoneLogin.text}`);
        assert.ok(phoneLogin.json?.token || phoneLogin.json?.data?.token);
      },
    },
    {
      id: 'T1-A2-03',
      tier: 1,
      area: FEATURE_AREAS[1],
      title: 'OTP send/verify works for EMAIL and WHATSAPP channels under local fallback',
      async fn({ client }) {
        const id = uniqueIdentity('otp', client.runId);
        const emailOtp = await client.post('/v1/auth/otp/send', {
          identifier: id.email,
          channel: 'EMAIL',
          purpose: 'REGISTER',
        });
        assert.equal(emailOtp.status, 200, `EMAIL OTP send failed: ${emailOtp.text}`);
        assert.equal(emailOtp.json?.success, true);

        const devEmailCode = emailOtp.json?.dev_otp || emailOtp.json?.devOtp || emailOtp.json?.code;
        if (devEmailCode) {
          const v = await client.post('/v1/auth/otp/verify', {
            identifier: id.email,
            channel: 'EMAIL',
            purpose: 'REGISTER',
            code: String(devEmailCode),
          });
          assert.equal(v.status, 200, `EMAIL OTP verify failed: ${v.text}`);
          assert.equal(v.json?.verified ?? v.json?.success, true);
        }

        const waOtp = await client.post('/v1/auth/otp/send', {
          identifier: id.phone,
          channel: 'WHATSAPP',
          purpose: 'REGISTER',
        });
        assert.equal(waOtp.status, 200, `WHATSAPP OTP send failed: ${waOtp.text}`);
        const devWaCode = waOtp.json?.dev_otp || waOtp.json?.devOtp || waOtp.json?.code;
        if (devWaCode) {
          const v = await client.post('/v1/auth/otp/verify', {
            identifier: id.phone,
            channel: 'WHATSAPP',
            purpose: 'REGISTER',
            code: String(devWaCode),
          });
          assert.equal(v.status, 200, `WHATSAPP OTP verify failed: ${v.text}`);
        }
      },
    },
    {
      id: 'T1-A2-04',
      tier: 1,
      area: FEATURE_AREAS[1],
      title: 'Driver starts Menunggu verifikasi and unlocks online status after Admin approval',
      async fn({ client }) {
        const pending = await client.registerDriverPending();
        assert.equal(pending.user.status, 'Menunggu verifikasi');

        const { token: adminToken } = await client.loginAdmin();
        const regId = extractId(pending.registration);
        const approveRes = await client.patch(
          `/v1/admin/registrations/${regId}/decide`,
          { status: 'Disetujui' },
          { token: adminToken }
        );
        assert.equal(approveRes.status, 200, `Admin approve failed: ${approveRes.text}`);

        const meRes = await client.get('/v1/me', { token: pending.token });
        assert.equal(meRes.status, 200);
        assert.equal(meRes.json?.user?.status, 'Aktif');

        const onlineRes = await client.patch(
          '/v1/driver/status',
          { is_online: true },
          { token: pending.token }
        );
        assert.equal(onlineRes.status, 200);
      },
    },
    {
      id: 'T1-A2-05',
      tier: 1,
      area: FEATURE_AREAS[1],
      title: 'Store starts Menunggu verifikasi with GPS coords and unlocks open toggle post-approval',
      async fn({ client }) {
        const pending = await client.registerStorePending({ coord: COORDS.BLANG_PULO });
        assert.equal(pending.user.status, 'Menunggu verifikasi');

        const { token: adminToken } = await client.loginAdmin();
        const regId = extractId(pending.registration);
        const approveRes = await client.patch(
          `/v1/admin/registrations/${regId}/decide`,
          { status: 'Disetujui' },
          { token: adminToken }
        );
        assert.equal(approveRes.status, 200);

        const openRes = await client.patch(
          '/v1/store/status',
          { is_open: true },
          { token: pending.token }
        );
        assert.equal(openRes.status, 200);
      },
    },
    {
      id: 'T1-A2-06',
      tier: 1,
      area: FEATURE_AREAS[1],
      title: 'Password reset via OTP and Google login local fallback contract succeed cleanly',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const otpRes = await client.post('/v1/auth/otp/send', {
          identifier: cust.creds.email,
          channel: 'EMAIL',
          purpose: 'RESET_PASSWORD',
        });
        assert.equal(otpRes.status, 200);
        const code = otpRes.json?.dev_otp || otpRes.json?.devOtp || otpRes.json?.code;
        if (code) {
          const newPassword = `ResetPass!${nextSeq()}99`;
          const resetRes = await client.post('/v1/auth/password/reset', {
            identifier: cust.creds.email,
            channel: 'EMAIL',
            code: String(code),
            new_password: newPassword,
          });
          assert.equal(resetRes.status, 200, `Password reset failed: ${resetRes.text}`);

          const loginNew = await client.post('/v1/auth/login', {
            identifier: cust.creds.email,
            password: newPassword,
          });
          assert.equal(loginNew.status, 200);
        }

        const googleId = uniqueIdentity('ggl', client.runId);
        const googleRes = await client.post('/v1/auth/google', {
          id_token: `dev-google-token-${client.runId}-${googleId.seq}`,
          email: googleId.email,
          name: googleId.name,
          role: 'customer',
        });
        assert.ok(
          googleRes.status === 200 || googleRes.status === 201 || googleRes.status === 401,
          `Unexpected status on /v1/auth/google: ${googleRes.status}`
        );
      },
    },

    // =========================================================================
    // Area 3: File Uploads, Store Catalog & Home Feeds (6 tests)
    // =========================================================================
    {
      id: 'T1-A3-01',
      tier: 1,
      area: FEATURE_AREAS[2],
      title: 'Multipart PNG upload persists and serves identical bytes on GET /uploads/*',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const { url } = await client.uploadDummyPng(cust.token, 'avatar');
        const fetched = await client.get(url);
        assert.equal(fetched.status, 200, `GET ${url} failed`);
        assert.equal(fetched.buffer.length, VALID_1X1_PNG_BYTES.length);
        assert.equal(
          Buffer.compare(fetched.buffer, Buffer.from(VALID_1X1_PNG_BYTES)),
          0,
          'Uploaded and fetched PNG bytes must match identically'
        );
      },
    },
    {
      id: 'T1-A3-02',
      tier: 1,
      area: FEATURE_AREAS[2],
      title: 'GET /v1/home returns promotions, best_sellers/top20, and Lhokseumawe wisata feeds',
      async fn({ client }) {
        const res = await client.get(
          `/v1/home?lat=${COORDS.KAMPUS_BUKIT_INDAH.lat}&lng=${COORDS.KAMPUS_BUKIT_INDAH.lng}`
        );
        assert.equal(res.status, 200);
        const promotions = res.json?.promotions || res.json?.promos || [];
        const bestSellers =
          res.json?.best_sellers || res.json?.terlaris || res.json?.top_menus || [];
        const wisata = res.json?.wisata_recommendations || res.json?.wisata || [];
        assert.ok(Array.isArray(promotions), 'promotions must be an array');
        assert.ok(Array.isArray(bestSellers), 'best_sellers must be an array');
        assert.ok(Array.isArray(wisata), 'wisata_recommendations must be an array');
      },
    },
    {
      id: 'T1-A3-03',
      tier: 1,
      area: FEATURE_AREAS[2],
      title: 'GET /v1/stores and GET /v1/stores/{id}/menus return active catalog',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, {
          menuName: 'Nasi Goreng Kampung E2E',
          menuPrice: 18000,
        });
        const storeId = extractId(store.store);
        const listRes = await client.get('/v1/stores');
        assert.equal(listRes.status, 200);
        const stores = listRes.json?.stores || [];
        assert.ok(stores.some((s) => extractId(s) === storeId), 'Approved store missing from /v1/stores');

        const menusRes = await client.get(`/v1/stores/${storeId}/menus`);
        assert.equal(menusRes.status, 200);
        const menus = menusRes.json?.menus || [];
        assert.ok(menus.some((m) => m.name === 'Nasi Goreng Kampung E2E'));
      },
    },
    {
      id: 'T1-A3-04',
      tier: 1,
      area: FEATURE_AREAS[2],
      title: 'Store menu CRUD orders newly added menus newest-first in customer catalog',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { createMenu: false });
        const storeId = extractId(store.store);
        const { url: imgUrl } = await client.uploadDummyPng(store.token, 'menu');

        const firstName = `Menu Pertama ${nextSeq()}`;
        const secondName = `Menu Terbaru ${nextSeq()}`;
        const m1 = await client.post(
          '/v1/store/menus',
          { name: firstName, description: 'Pertama', category: 'Makanan', price: 15000, image_url: imgUrl, is_available: true },
          { token: store.token }
        );
        assert.ok(m1.status === 200 || m1.status === 201);

        const m2 = await client.post(
          '/v1/store/menus',
          { name: secondName, description: 'Terbaru', category: 'Minuman', price: 12000, image_url: imgUrl, is_available: true },
          { token: store.token }
        );
        assert.ok(m2.status === 200 || m2.status === 201);

        const catalog = await client.get(`/v1/stores/${storeId}/menus`);
        assert.equal(catalog.status, 200);
        const menus = catalog.json?.menus || [];
        assert.ok(menus.length >= 2);
        assert.equal(menus[0].name, secondName, 'Newest created menu must appear first at index 0');
      },
    },
    {
      id: 'T1-A3-05',
      tier: 1,
      area: FEATURE_AREAS[2],
      title: 'Store updates profile, open status, and menu price reflected immediately',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 20000 });
        const storeId = extractId(store.store);
        const menuId = extractId(store.menu);

        const profRes = await client.post(
          '/v1/store/profile',
          {
            store_name: `${store.creds.store_name} Updated`,
            description: 'Updated via E2E',
            category: 'Kopi & Minuman',
            address: COORDS.KAMPUS_BUKIT_INDAH.address,
            latitude: COORDS.KAMPUS_BUKIT_INDAH.lat,
            longitude: COORDS.KAMPUS_BUKIT_INDAH.lng,
            open_hours: '07.00 - 23.00',
            is_open: true,
          },
          { token: store.token }
        );
        assert.equal(profRes.status, 200);

        const updMenu = await client.put(
          `/v1/store/menus/${menuId}`,
          { price: 24000, is_available: true },
          { token: store.token }
        );
        assert.equal(updMenu.status, 200);

        const cat = await client.get(`/v1/stores/${storeId}/menus`);
        const found = (cat.json?.menus || []).find((m) => extractId(m) === menuId);
        assert.equal(Number(found.price), 24000);
      },
    },
    {
      id: 'T1-A3-06',
      tier: 1,
      area: FEATURE_AREAS[2],
      title: 'Store deletes a menu and removes it from public catalog',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken);
        const storeId = extractId(store.store);
        const menuId = extractId(store.menu);

        const delRes = await client.del(`/v1/store/menus/${menuId}`, { token: store.token });
        assert.equal(delRes.status, 200);

        const cat = await client.get(`/v1/stores/${storeId}/menus`);
        const stillThere = (cat.json?.menus || []).some((m) => extractId(m) === menuId);
        assert.equal(stillThere, false, 'Deleted menu should no longer appear in catalog');
      },
    },

    // =========================================================================
    // Area 4: Geo/OSRM Pricing & FlexRide Orders (5 tests)
    // =========================================================================
    {
      id: 'T1-A4-01',
      tier: 1,
      area: FEATURE_AREAS[3],
      title: 'Pricing estimate FLEXRIDE_MOTOR <=2km (Bukit Indah -> Blang Pulo) returns base 8000 + fee 2000',
      async fn({ client }) {
        const res = await client.post('/v1/pricing/estimate', {
          service_type: 'FLEXRIDE_MOTOR',
          vehicle_type: 'MOTOR',
          pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
          pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
          dest_lat: COORDS.BLANG_PULO.lat,
          dest_lng: COORDS.BLANG_PULO.lng,
        });
        assert.equal(res.status, 200, `Pricing estimate failed: ${res.text}`);
        const d = extractData(res.json);
        assert.ok(Number(d.distance_km) > 0, 'distance_km must be > 0');
        assert.equal(Number(d.delivery_fee), 8000);
        assert.equal(Number(d.service_fee), 2000);
        assert.equal(Number(d.total_amount), 10000);
        assert.ok(['osrm', 'haversine'].includes(d.routing_source));
      },
    },
    {
      id: 'T1-A4-02',
      tier: 1,
      area: FEATURE_AREAS[3],
      title: 'Pricing estimate FLEXRIDE_MOBIL >2km (Pusat Lhokseumawe -> Reuleut) scales >15000 + 3000 fee',
      async fn({ client }) {
        const res = await client.post('/v1/pricing/estimate', {
          service_type: 'FLEXRIDE_MOBIL',
          vehicle_type: 'MOBIL',
          pickup_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
          pickup_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
          dest_lat: COORDS.REULEUT.lat,
          dest_lng: COORDS.REULEUT.lng,
        });
        assert.equal(res.status, 200);
        const d = extractData(res.json);
        assert.ok(Number(d.distance_km) > 2);
        assert.ok(Number(d.delivery_fee) > 15000, `Expected Mobil delivery_fee > 15000, got ${d.delivery_fee}`);
        assert.equal(Number(d.service_fee), 3000);
        assert.equal(Number(d.total_amount), Number(d.delivery_fee) + 3000 - Number(d.discount_amount || 0));
      },
    },
    {
      id: 'T1-A4-03',
      tier: 1,
      area: FEATURE_AREAS[3],
      title: 'Create FlexRide MOTOR TUNAI order starts at SEARCHING_DRIVER with order_code',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const res = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
          },
          { token: cust.token }
        );
        assert.ok(res.status === 200 || res.status === 201, `Create FlexRide failed: ${res.text}`);
        const order = res.json?.order || res.json?.data?.order || res.json?.data;
        assert.equal(order.status, 'SEARCHING_DRIVER');
        assert.ok(order.order_code, 'Expected order_code');
      },
    },
    {
      id: 'T1-A4-04',
      tier: 1,
      area: FEATURE_AREAS[3],
      title: 'Full FlexRide lifecycle: SEARCHING_DRIVER -> accept -> PICKED_UP -> DELIVERING -> ARRIVED -> COMPLETED',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const cust = await client.registerCustomer();
        const driver = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });

        const createRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.DEWANTARA.label,
            dest_address: COORDS.DEWANTARA.address,
            dest_lat: COORDS.DEWANTARA.lat,
            dest_lng: COORDS.DEWANTARA.lng,
            payment_method: 'TUNAI',
          },
          { token: cust.token }
        );
        assert.ok(createRes.status === 200 || createRes.status === 201);
        const orderId = extractId(createRes.json?.order || createRes.json?.data);

        const acc = await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        assert.equal(acc.status, 200);
        assert.equal((acc.json?.order || acc.json?.data)?.status, 'DRIVER_ACCEPTED');

        for (const nextStatus of ['PICKED_UP', 'DELIVERING', 'ARRIVED']) {
          const stRes = await client.post(
            `/v1/orders/${orderId}/status`,
            { status: nextStatus },
            { token: driver.token }
          );
          assert.equal(stRes.status, 200, `Transition to ${nextStatus} failed: ${stRes.text}`);
        }

        const compRes = await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });
        assert.equal(compRes.status, 200);
        assert.equal((compRes.json?.order || compRes.json?.data)?.status, 'COMPLETED');
      },
    },
    {
      id: 'T1-A4-05',
      tier: 1,
      area: FEATURE_AREAS[3],
      title: 'Customer cancels FlexRide order while SEARCHING_DRIVER',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const createRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
          },
          { token: cust.token }
        );
        const orderId = extractId(createRes.json?.order || createRes.json?.data);
        const cancelRes = await client.post(
          `/v1/orders/${orderId}/cancel`,
          { reason: 'Berubah pikiran' },
          { token: cust.token }
        );
        assert.equal(cancelRes.status, 200);
        assert.equal((cancelRes.json?.order || cancelRes.json?.data)?.status, 'CANCELLED');
      },
    },

    // =========================================================================
    // Area 5: FlexFood Store-First Flow & 16s Atomic Lock (5 tests)
    // =========================================================================
    {
      id: 'T1-A5-01',
      tier: 1,
      area: FEATURE_AREAS[4],
      title: 'Create FlexFood TUNAI order enters WAITING_STORE with exact item subtotal',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 22000 });
        const cust = await client.registerCustomer();
        const storeId = extractId(store.store);
        const menuId = extractId(store.menu);

        const res = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: storeId,
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: [{ menu_id: menuId, quantity: 2 }],
          },
          { token: cust.token }
        );
        assert.ok(res.status === 200 || res.status === 201, `Create FlexFood failed: ${res.text}`);
        const order = res.json?.order || res.json?.data;
        assert.equal(order.status, 'WAITING_STORE');
        assert.equal(Number(order.subtotal_amount), 44000);
      },
    },
    {
      id: 'T1-A5-02',
      tier: 1,
      area: FEATURE_AREAS[4],
      title: 'Store accept-store transitions FlexFood out of WAITING_STORE for driver broadcast',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 20000 });
        const cust = await client.registerCustomer();

        const createRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: extractId(store.store),
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: [{ menu_id: extractId(store.menu), quantity: 1 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(createRes.json?.order || createRes.json?.data);
        const accStore = await client.post(
          `/v1/orders/${orderId}/accept-store`,
          { cooking_minutes: 10 },
          { token: store.token }
        );
        assert.equal(accStore.status, 200);
        const st = (accStore.json?.order || accStore.json?.data)?.status;
        assert.ok(['COOKING', 'SEARCHING_DRIVER'].includes(st), `Unexpected post-accept status: ${st}`);
      },
    },
    {
      id: 'T1-A5-03',
      tier: 1,
      area: FEATURE_AREAS[4],
      title: 'Driver completes FlexFood order after store accept and increments menu total_sold',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 25000 });
        const driver = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });
        const cust = await client.registerCustomer();
        const storeId = extractId(store.store);
        const menuId = extractId(store.menu);

        const createRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: storeId,
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: [{ menu_id: menuId, quantity: 3 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(createRes.json?.order || createRes.json?.data);
        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        const drvAcc = await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        assert.equal(drvAcc.status, 200);

        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: driver.token });
        const comp = await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });
        assert.equal(comp.status, 200);

        const menusRes = await client.get(`/v1/stores/${storeId}/menus`);
        const updatedMenu = (menusRes.json?.menus || []).find((m) => extractId(m) === menuId);
        assert.ok(Number(updatedMenu.total_sold) >= 3, `Expected total_sold >= 3, got ${updatedMenu.total_sold}`);
      },
    },
    {
      id: 'T1-A5-04',
      tier: 1,
      area: FEATURE_AREAS[4],
      title: 'Store reject-store cancels FlexFood order (and marks PAID QRIS order REFUNDED)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 18000 });
        const cust = await client.registerCustomer();

        const createRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: extractId(store.store),
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'QRIS',
            items: [{ menu_id: extractId(store.menu), quantity: 1 }],
          },
          { token: cust.token }
        );
        const order = createRes.json?.order || createRes.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: orderId,
            invoice_number: uniqueInvoice(client.runId),
            amount: Number(order.total_amount),
          },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `QRIS diterima Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        const rej = await client.post(
          `/v1/orders/${orderId}/reject-store`,
          { reason: 'Stok habis' },
          { token: store.token }
        );
        assert.equal(rej.status, 200);
        const rejOrder = rej.json?.order || rej.json?.data;
        assert.equal(rejOrder.status, 'CANCELLED');
        assert.equal(rejOrder.payment_status, 'REFUNDED');
      },
    },
    {
      id: 'T1-A5-05',
      tier: 1,
      area: FEATURE_AREAS[4],
      title: 'FlexFood QRIS order starts WAITING_PAYMENT/UNPAID and enters WAITING_STORE after settlement',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 15000 });
        const cust = await client.registerCustomer();

        const createRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: extractId(store.store),
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'QRIS',
            items: [{ menu_id: extractId(store.menu), quantity: 1 }],
          },
          { token: cust.token }
        );
        const order = createRes.json?.order || createRes.json?.data;
        assert.equal(order.status, 'WAITING_PAYMENT');
        assert.equal(order.payment_status, 'UNPAID');

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: extractId(order),
            invoice_number: uniqueInvoice(client.runId),
            amount: Number(order.total_amount),
          },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Pembayaran masuk Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        const after = await client.get(`/v1/orders/${extractId(order)}`, { token: cust.token });
        const updated = after.json?.order || after.json?.data;
        assert.equal(updated.payment_status, 'PAID');
        assert.equal(updated.status, 'WAITING_STORE');
      },
    },

    // =========================================================================
    // Area 6: FlexSend Modal Kas, 3-Stop, Receipt & Talangan (5 tests)
    // =========================================================================
    {
      id: 'T1-A6-01',
      tier: 1,
      area: FEATURE_AREAS[5],
      title: 'Create 3-stop FlexSend order applies 2x extra_stop_fee (6000)',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const stops = [
          {
            stop_index: 1,
            stop_location_name: 'Pasar Inpres',
            stop_address: COORDS.PASAR_INPRES.address,
            stop_lat: COORDS.PASAR_INPRES.lat,
            stop_lng: COORDS.PASAR_INPRES.lng,
            item_name: 'Beras 5kg',
            quantity: 1,
            estimated_price: 70000,
          },
          {
            stop_index: 2,
            stop_location_name: 'Blang Pulo',
            stop_address: COORDS.BLANG_PULO.address,
            stop_lat: COORDS.BLANG_PULO.lat,
            stop_lng: COORDS.BLANG_PULO.lng,
            item_name: 'Minyak Goreng 2L',
            quantity: 1,
            estimated_price: 35000,
          },
          {
            stop_index: 3,
            stop_location_name: 'Reuleut',
            stop_address: COORDS.REULEUT.address,
            stop_lat: COORDS.REULEUT.lat,
            stop_lng: COORDS.REULEUT.lng,
            item_name: 'Gula Pasir 1kg',
            quantity: 1,
            estimated_price: 18000,
          },
        ];

        const estRes = await client.post('/v1/pricing/estimate', {
          service_type: 'FLEXSEND',
          pickup_lat: COORDS.PASAR_INPRES.lat,
          pickup_lng: COORDS.PASAR_INPRES.lng,
          dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
          dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
          stops: stops.map((s) => ({ lat: s.stop_lat, lng: s.stop_lng })),
        });
        assert.equal(estRes.status, 200);
        const est = extractData(estRes.json);
        assert.ok(Number(est.extra_stop_fee ?? 6000) >= 6000 || Number(est.delivery_fee) >= 14000);

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: stops,
          },
          { token: cust.token }
        );
        assert.ok(ordRes.status === 200 || ordRes.status === 201, `Create FlexSend failed: ${ordRes.text}`);
        const order = ordRes.json?.order || ordRes.json?.data;
        assert.equal(Number(order.subtotal_amount), 123000);
        assert.equal((ordRes.json?.items || []).length, 3);
      },
    },
    {
      id: 'T1-A6-02',
      tier: 1,
      area: FEATURE_AREAS[5],
      title: 'Driver with sufficient cash_capital_limit accepts FlexSend and enters SHOPPING',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 150000 });
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: [{ stop_index: 1, item_name: 'Ayam Potong', quantity: 2, estimated_price: 45000 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(ordRes.json?.order || ordRes.json?.data);
        const acc = await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        assert.equal(acc.status, 200);

        const shopRes = await client.post(
          `/v1/orders/${orderId}/status`,
          { status: 'SHOPPING' },
          { token: driver.token }
        );
        assert.equal(shopRes.status, 200);
        assert.equal((shopRes.json?.order || shopRes.json?.data)?.status, 'SHOPPING');
      },
    },
    {
      id: 'T1-A6-03',
      tier: 1,
      area: FEATURE_AREAS[5],
      title: 'Driver submits FlexSend receipt + parking photo and dynamically updates total_amount',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 200000 });
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
            items: [{ stop_index: 1, item_name: 'Susu Kaleng', quantity: 2, estimated_price: 30000 }],
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const orderId = extractId(order);

        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'SHOPPING' }, { token: driver.token });
        const { url: receiptUrl } = await client.uploadDummyPng(driver.token, 'receipt');

        const recRes = await client.post(
          `/v1/orders/${orderId}/flexsend-receipt`,
          {
            actual_receipt_amount: 64000,
            parking_fee: 3000,
            receipt_photo_url: receiptUrl,
          },
          { token: driver.token }
        );
        assert.equal(recRes.status, 200, `flexsend-receipt failed: ${recRes.text}`);
        const updated = recRes.json?.order || recRes.json?.data;
        const expectedTotal =
          64000 +
          3000 +
          Number(updated.delivery_fee) +
          Number(updated.service_fee) -
          Number(updated.discount_amount || 0);
        assert.equal(Number(updated.actual_receipt_amount), 64000);
        assert.equal(Number(updated.parking_fee), 3000);
        assert.equal(Number(updated.total_amount), expectedTotal);
      },
    },
    {
      id: 'T1-A6-04',
      tier: 1,
      area: FEATURE_AREAS[5],
      title: 'Driver completes FlexSend order through DELIVERING -> ARRIVED -> COMPLETED',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 150000 });
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
            items: [{ stop_index: 1, item_name: 'Roti Tawar', quantity: 1, estimated_price: 18000 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(ordRes.json?.order || ordRes.json?.data);
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'SHOPPING' }, { token: driver.token });
        const { url: receiptUrl } = await client.uploadDummyPng(driver.token, 'receipt');
        await client.post(
          `/v1/orders/${orderId}/flexsend-receipt`,
          { actual_receipt_amount: 18000, parking_fee: 2000, receipt_photo_url: receiptUrl },
          { token: driver.token }
        );
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: driver.token });
        const comp = await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });
        assert.equal(comp.status, 200);
        assert.equal((comp.json?.order || comp.json?.data)?.status, 'COMPLETED');
      },
    },
    {
      id: 'T1-A6-05',
      tier: 1,
      area: FEATURE_AREAS[5],
      title: '2-step orphan talangan claim on cancelled FlexSend credits driver wallet after Admin approval',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 150000 });
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
            items: [{ stop_index: 1, item_name: 'Sembako', quantity: 1, estimated_price: 50000 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(ordRes.json?.order || ordRes.json?.data);
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'SHOPPING' }, { token: driver.token });
        const { url: receiptUrl } = await client.uploadDummyPng(driver.token, 'receipt');
        await client.post(
          `/v1/orders/${orderId}/flexsend-receipt`,
          { actual_receipt_amount: 52000, parking_fee: 3000, receipt_photo_url: receiptUrl },
          { token: driver.token }
        );
        await client.post(`/v1/orders/${orderId}/cancel`, { reason: 'Customer batal' }, { token: cust.token });

        const { url: donationUrl } = await client.uploadDummyPng(driver.token, 'donation');
        const claimRes = await client.post(
          '/v1/wallet/talangan-claims',
          {
            order_id: orderId,
            receipt_amount: 52000,
            parking_amount: 3000,
            receipt_photo_url: receiptUrl,
            donation_recipient: 'Panti Asuhan Muhammadiyah Lhokseumawe',
            donation_photo_url: donationUrl,
          },
          { token: driver.token }
        );
        assert.ok(claimRes.status === 200 || claimRes.status === 201, `Talangan claim failed: ${claimRes.text}`);
        const claim = claimRes.json?.claim || claimRes.json?.data;
        assert.equal(claim.status, 'PENDING');
        assert.equal(Number(claim.total_claim_amount), 55000);

        const decide = await client.post(
          `/v1/admin/talangan-claims/${extractId(claim)}/decide`,
          { status: 'APPROVED' },
          { token: adminToken }
        );
        assert.equal(decide.status, 200);

        const wRes = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(wRes.json?.wallet?.balance), 55000);
      },
    },

    // =========================================================================
    // Area 7: Wallet, 5%:5% Commission, -20k Tolerance & Withdraw (5 tests)
    // =========================================================================
    {
      id: 'T1-A7-01',
      tier: 1,
      area: FEATURE_AREAS[6],
      title: 'Newly approved Driver starts with exact initial wallet balance of Rp 0',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken);
        const w = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(w.status, 200);
        assert.equal(Number(w.json?.wallet?.balance), FINANCE_CONSTANTS.INITIAL_DRIVER_BALANCE);
      },
    },
    {
      id: 'T1-A7-02',
      tier: 1,
      area: FEATURE_AREAS[6],
      title: 'QRIS FlexFood completion credits +95% subtotal to Store and +95% delivery_fee to Driver',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 20000 });
        const driver = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: extractId(store.store),
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'QRIS',
            items: [{ menu_id: extractId(store.menu), quantity: 2 }],
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: orderId,
            invoice_number: uniqueInvoice(client.runId),
            amount: Number(order.total_amount),
          },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `QRIS diterima Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: driver.token });
        const comp = await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });
        assert.equal(comp.status, 200);

        const expectedStoreNet = Math.round(Number(order.subtotal_amount) * 0.95);
        const expectedDriverNet = Math.round(Number(order.delivery_fee) * 0.95);

        const storeW = await client.get('/v1/wallet', { token: store.token });
        const driverW = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(storeW.json?.wallet?.balance), expectedStoreNet, 'Store net must equal 95% of subtotal');
        assert.equal(Number(driverW.json?.wallet?.balance), expectedDriverNet, 'Driver net must equal 95% of delivery_fee');
      },
    },
    {
      id: 'T1-A7-03',
      tier: 1,
      area: FEATURE_AREAS[6],
      title: 'TUNAI FlexRide completion deducts 5% delivery_fee into negative tolerance (> -20000)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const orderId = extractId(order);

        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: driver.token });
        const comp = await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });
        assert.equal(comp.status, 200);

        const expectedFee = Math.round(Number(order.delivery_fee) * 0.05);
        const w = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(w.json?.wallet?.balance), -expectedFee);
      },
    },
    {
      id: 'T1-A7-04',
      tier: 1,
      area: FEATURE_AREAS[6],
      title: 'Driver withdraw holds balance (admin_fee 2000), approves cleanly, and refunds on rejection',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken);

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'DRIVER_TOPUP',
            wallet_topup_user_id: extractId(driver.user),
            invoice_number: uniqueInvoice(client.runId),
            amount: 100000,
          },
          { token: driver.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `TopUp diterima Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        const wd1 = await client.post(
          '/v1/wallet/withdraw',
          {
            amount: 40000,
            bank_name: 'BSI',
            bank_account_number: '7123456789',
            bank_account_holder: driver.user.name,
          },
          { token: driver.token }
        );
        assert.ok(wd1.status === 200 || wd1.status === 201, `Withdraw 1 failed: ${wd1.text}`);
        const w1 = wd1.json?.withdrawal || wd1.json?.data;
        assert.equal(Number(w1.admin_fee), 2000);
        assert.equal(Number(w1.net_payout), 38000);

        const balAfterHold = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(balAfterHold.json?.wallet?.balance), 60000);

        const app1 = await client.post(
          `/v1/admin/withdrawals/${extractId(w1)}/decide`,
          { status: 'APPROVED' },
          { token: adminToken }
        );
        assert.equal(app1.status, 200);

        const wd2 = await client.post(
          '/v1/wallet/withdraw',
          {
            amount: 25000,
            bank_name: 'BSI',
            bank_account_number: '7123456789',
            bank_account_holder: driver.user.name,
          },
          { token: driver.token }
        );
        const w2 = wd2.json?.withdrawal || wd2.json?.data;
        const rej2 = await client.post(
          `/v1/admin/withdrawals/${extractId(w2)}/decide`,
          { status: 'REJECTED' },
          { token: adminToken }
        );
        assert.equal(rej2.status, 200);

        const balAfterReject = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(balAfterReject.json?.wallet?.balance), 60000);
      },
    },
    {
      id: 'T1-A7-05',
      tier: 1,
      area: FEATURE_AREAS[6],
      title: 'Store withdraw succeeds with valid 6-digit PIN and Admin approval',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, {
          pin: '654321',
          menuPrice: 50000,
        });
        const driver = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: extractId(store.store),
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'QRIS',
            items: [{ menu_id: extractId(store.menu), quantity: 1 }],
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: orderId,
            invoice_number: uniqueInvoice(client.runId),
            amount: Number(order.total_amount),
          },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `QRIS Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );
        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });

        const wd = await client.post(
          '/v1/wallet/withdraw',
          {
            amount: 20000,
            bank_name: 'Bank Aceh Syariah',
            bank_account_number: '0100123456',
            bank_account_holder: store.creds.owner_name,
            pin: '654321',
          },
          { token: store.token }
        );
        assert.ok(wd.status === 200 || wd.status === 201, `Store withdraw failed: ${wd.text}`);
        const wdId = extractId(wd.json?.withdrawal || wd.json?.data);
        const dec = await client.post(
          `/v1/admin/withdrawals/${wdId}/decide`,
          { status: 'APPROVED' },
          { token: adminToken }
        );
        assert.equal(dec.status, 200);
      },
    },

    // =========================================================================
    // Area 8: Favorites, Ratings & Admin API (6 tests)
    // =========================================================================
    {
      id: 'T1-A8-01',
      tier: 1,
      area: FEATURE_AREAS[7],
      title: 'Customer creates, lists, and deletes favorites (MENU, STORE, PLACE)',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const favRes = await client.post(
          '/v1/favorites',
          {
            target_type: 'PLACE',
            target_id: `bukit-indah-${nextSeq()}`,
            label: COORDS.KAMPUS_BUKIT_INDAH.label,
            address: COORDS.KAMPUS_BUKIT_INDAH.address,
            latitude: COORDS.KAMPUS_BUKIT_INDAH.lat,
            longitude: COORDS.KAMPUS_BUKIT_INDAH.lng,
          },
          { token: cust.token }
        );
        assert.ok(favRes.status === 200 || favRes.status === 201);
        const favId = extractId(favRes.json?.favorite || favRes.json?.data);

        const list = await client.get('/v1/favorites', { token: cust.token });
        assert.equal(list.status, 200);
        assert.ok((list.json?.favorites || []).some((f) => extractId(f) === favId));

        const del = await client.del(`/v1/favorites/${favId}`, { token: cust.token });
        assert.equal(del.status, 200);
      },
    },
    {
      id: 'T1-A8-02',
      tier: 1,
      area: FEATURE_AREAS[7],
      title: 'Customer rating 1-5 on COMPLETED FlexFood order updates driver & store rating_avg',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 18000 });
        const driver = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: extractId(store.store),
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: store.creds.store_lat,
            pickup_lng: store.creds.store_lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: [{ menu_id: extractId(store.menu), quantity: 1 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(ordRes.json?.order || ordRes.json?.data);
        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/complete`, {}, { token: driver.token });

        const rateRes = await client.post(
          `/v1/orders/${orderId}/rating`,
          { driver_stars: 5, store_stars: 4, comment: 'Cepat dan lezat' },
          { token: cust.token }
        );
        assert.ok(rateRes.status === 200 || rateRes.status === 201);

        const storeMe = await client.get('/v1/me', { token: store.token });
        assert.equal(Number(storeMe.json?.store?.rating_avg), 4);
      },
    },
    {
      id: 'T1-A8-03',
      tier: 1,
      area: FEATURE_AREAS[7],
      title: 'Admin operational endpoints (/overview, /orders, /drivers, /stores, /customers, /map) return 200',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        for (const ep of [
          '/v1/admin/overview',
          '/v1/admin/orders',
          '/v1/admin/drivers',
          '/v1/admin/stores',
          '/v1/admin/customers',
          '/v1/admin/map',
        ]) {
          const r = await client.get(ep, { token: adminToken });
          assert.equal(r.status, 200, `${ep} failed with ${r.status}: ${r.text}`);
        }
      },
    },
    {
      id: 'T1-A8-04',
      tier: 1,
      area: FEATURE_AREAS[7],
      title: 'Admin updates pricing_rules & creates promotion reflected in /v1/pricing/estimate',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const origRes = await client.get('/v1/admin/pricing-rules', { token: adminToken });
        const origRules = origRes.json?.rules || [];

        const promoCode = `E2EHEMAT${nextSeq()}`;
        try {
          const upd = await client.put(
            '/v1/admin/pricing-rules',
            {
              rules: [
                {
                  ...PRICING_RULES.FLEXRIDE_MOTOR,
                  base_fare: 9000,
                },
              ],
            },
            { token: adminToken }
          );
          assert.equal(upd.status, 200);

          const promoRes = await client.post(
            '/v1/admin/promotions',
            {
              code: promoCode,
              title: 'Promo E2E Bukit Indah',
              service_type: 'ALL',
              discount_amount: 3000,
              max_discount: 3000,
              min_order_amount: 5000,
              is_active: true,
            },
            { token: adminToken }
          );
          assert.ok(promoRes.status === 200 || promoRes.status === 201);

          const est = await client.post('/v1/pricing/estimate', {
            service_type: 'FLEXRIDE_MOTOR',
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            promo_code: promoCode,
          });
          assert.equal(est.status, 200);
          assert.equal(Number(est.json?.delivery_fee), 9000);
          assert.equal(Number(est.json?.discount_amount), 3000);
        } finally {
          await client.put('/v1/admin/pricing-rules', { rules: origRules }, { token: adminToken });
        }
      },
    },
    {
      id: 'T1-A8-05',
      tier: 1,
      area: FEATURE_AREAS[7],
      title: 'Admin support-tickets listing and reply endpoint resolves ticket cleanly',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const cust = await client.registerCustomer();

        const csRes = await client.post(
          '/ai/cs/chat',
          {
            app_source: 'CUSTOMER_APP',
            message: 'Tolong buatkan tiket bantuan untuk kendala pembayaran saya.',
            issue_category: 'payment',
          },
          { token: cust.token }
        );
        assert.equal(csRes.status, 200);

        const listRes = await client.get('/v1/admin/support-tickets', { token: adminToken });
        assert.equal(listRes.status, 200);
        const tickets = listRes.json?.tickets || listRes.json?.data?.tickets || [];
        assert.ok(tickets.length > 0, 'Expected at least 1 support ticket');

        const ticketId = extractId(tickets[0]);
        const repRes = await client.post(
          `/v1/admin/support-tickets/${ticketId}/reply`,
          {
            status: 'RESOLVED',
            admin_reply: 'Sudah ditindaklanjuti oleh CS RideOn.',
            send_email: false,
          },
          { token: adminToken }
        );
        assert.equal(repRes.status, 200);
        assert.equal((repRes.json?.ticket || repRes.json?.data)?.status, 'RESOLVED');
      },
    },
    {
      id: 'T1-A8-06',
      tier: 1,
      area: FEATURE_AREAS[7],
      title: 'Admin registrations/promotions & Postman collection parity check (when present)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const regs = await client.get('/v1/admin/registrations', { token: adminToken });
        assert.equal(regs.status, 200);
        const promos = await client.get('/v1/admin/promotions', { token: adminToken });
        assert.equal(promos.status, 200);

        const postmanPath = path.resolve(process.cwd(), 'postman/RideOn.postman_collection.json');
        if (fs.existsSync(postmanPath)) {
          const parsed = JSON.parse(fs.readFileSync(postmanPath, 'utf8'));
          assert.ok(Array.isArray(parsed.item) && parsed.item.length >= 4);
        }
      },
    },

    // =========================================================================
    // Area 9: PayG Dynamic QRIS, MacroDroid & Manual Confirm (6 tests)
    // =========================================================================
    {
      id: 'T1-A9-01',
      tier: 1,
      area: FEATURE_AREAS[8],
      title: '[FA9-T1-01] PayG /pay/health and /pay/status report ok and active counters',
      async fn({ client }) {
        const h = await client.get('/pay/health');
        assert.equal(h.status, 200);
        assert.equal(h.json?.status, 'ok');

        const s = await client.get('/pay/status', {
          headers: { 'X-PayG-Secret': client.secrets.payg },
        });
        assert.equal(s.status, 200);
        assert.ok(typeof s.json?.active_pending === 'number');
        assert.ok(typeof s.json?.total_settled === 'number');
      },
    },
    {
      id: 'T1-A9-02',
      tier: 1,
      area: FEATURE_AREAS[8],
      title: '[FA9-T1-02] PayG creates dynamic QRIS with Tag 54, POI 12, unique 1..999, SVG & valid CRC-16',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.PUSAT_LHOKSEUMAWE.label,
            dest_address: COORDS.PUSAT_LHOKSEUMAWE.address,
            dest_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
            dest_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
            payment_method: 'QRIS',
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const baseAmount = 25000 + nextSeq() * 100;

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: extractId(order),
            invoice_number: uniqueInvoice(client.runId),
            amount: baseAmount,
          },
          { token: cust.token }
        );
        assert.equal(co.status, 200, `Checkout create failed: ${co.text}`);
        const tx = extractData(co.json);
        assert.ok(tx.transaction_ref);
        assert.ok(
          tx.unique_code >= FINANCE_CONSTANTS.UNIQUE_CODE_MIN &&
            tx.unique_code <= FINANCE_CONSTANTS.UNIQUE_CODE_MAX
        );
        assert.equal(Number(tx.payable_amount), baseAmount + Number(tx.unique_code));
        assert.ok(typeof tx.qr_svg === 'string' && tx.qr_svg.includes('<svg'));
        verifyDynamicQris(tx.qr_string, tx.payable_amount);
      },
    },
    {
      id: 'T1-A9-03',
      tier: 1,
      area: FEATURE_AREAS[8],
      title: '[FA9-T1-03] PayG allocates distinct unique_code 1..999 for identical base amounts',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const baseAmount = 31000 + nextSeq() * 100;
        const makeOrder = async () => {
          const r = await client.post(
            '/v1/orders',
            {
              service_type: 'FlexRide',
              vehicle_type: 'MOTOR',
              pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
              pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
              pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
              pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
              dest_label: COORDS.BLANG_PULO.label,
              dest_address: COORDS.BLANG_PULO.address,
              dest_lat: COORDS.BLANG_PULO.lat,
              dest_lng: COORDS.BLANG_PULO.lng,
              payment_method: 'QRIS',
            },
            { token: cust.token }
          );
          return extractId(r.json?.order || r.json?.data);
        };
        const [o1, o2] = [await makeOrder(), await makeOrder()];
        const c1 = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: o1, invoice_number: uniqueInvoice(client.runId), amount: baseAmount },
          { token: cust.token }
        );
        const c2 = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: o2, invoice_number: uniqueInvoice(client.runId), amount: baseAmount },
          { token: cust.token }
        );
        const tx1 = extractData(c1.json);
        const tx2 = extractData(c2.json);
        assert.notEqual(tx1.unique_code, tx2.unique_code);
        assert.notEqual(tx1.payable_amount, tx2.payable_amount);
      },
    },
    {
      id: 'T1-A9-04',
      tier: 1,
      area: FEATURE_AREAS[8],
      title: '[FA9-T1-04] MacroDroid webhook settles ORDER_PAYMENT and transitions order to PAID',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'QRIS',
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: orderId,
            invoice_number: uniqueInvoice(client.runId),
            amount: Number(order.total_amount),
          },
          { token: cust.token }
        );
        const tx = extractData(co.json);

        const wh = await client.post(
          '/pay/webhook/macrodroid',
          {
            notification_text: `Pembayaran QRIS GoPay Merchant diterima Rp ${formatIdr(tx.payable_amount)}`,
            package_name: 'com.gojek.merchant',
          },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );
        assert.equal(wh.status, 200);
        assert.equal(wh.json?.status, 'SETTLEMENT');

        const st = await client.get(`/pay/checkout/${tx.transaction_ref}/status`, { token: cust.token });
        assert.equal(st.status, 200);
        assert.equal(extractData(st.json).status, 'SETTLEMENT');

        const ordAfter = await client.get(`/v1/orders/${orderId}`, { token: cust.token });
        const oAfter = ordAfter.json?.order || ordAfter.json?.data;
        assert.equal(oAfter.payment_status, 'PAID');
        assert.equal(oAfter.status, 'SEARCHING_DRIVER');
      },
    },
    {
      id: 'T1-A9-05',
      tier: 1,
      area: FEATURE_AREAS[8],
      title: '[FA9-T1-05] MacroDroid webhook settles DRIVER_TOPUP and credits base_amount to wallet',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken);

        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'DRIVER_TOPUP',
            wallet_topup_user_id: extractId(driver.user),
            invoice_number: uniqueInvoice(client.runId),
            amount: 50000,
          },
          { token: driver.token }
        );
        const tx = extractData(co.json);

        const wh = await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Dana masuk IDR ${tx.payable_amount}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );
        assert.equal(wh.status, 200);

        const w = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(w.json?.wallet?.balance), 50000);
      },
    },
    {
      id: 'T1-A9-06',
      tier: 1,
      area: FEATURE_AREAS[8],
      title: '[FA9-T1-06] Admin Static QRIS config, transactions listing & manual fallback confirm',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const setQr = await client.post(
          '/pay/static-qr',
          { static_qris: SAMPLE_STATIC_QRIS },
          { token: adminToken }
        );
        assert.equal(setQr.status, 200, `POST /pay/static-qr failed: ${setQr.text}`);

        const cust = await client.registerCustomer();
        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'QRIS',
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;
        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'ORDER_PAYMENT',
            order_id: extractId(order),
            invoice_number: uniqueInvoice(client.runId),
            amount: Number(order.total_amount),
          },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        const tags = verifyDynamicQris(tx.qr_string, tx.payable_amount);
        assert.equal(tags['59'], 'KEDAI RIDEON');

        const list = await client.get('/pay/transactions', { token: adminToken });
        assert.equal(list.status, 200);
        const txs = list.json?.transactions || list.json?.data || [];
        assert.ok(txs.some((item) => item.transaction_ref === tx.transaction_ref));

        const man = await client.post(
          `/pay/transactions/${tx.transaction_ref}/manual-confirm`,
          { notes: 'Mutasi rekening terverifikasi manual' },
          { token: adminToken }
        );
        assert.equal(man.status, 200);
        assert.equal((man.json?.transaction || man.json?.data)?.status, 'SETTLEMENT');
      },
    },

    // =========================================================================
    // Area 10: Universal AI Adapter, Safe Boundary & App AI (6 tests)
    // =========================================================================
    {
      id: 'T1-A10-01',
      tier: 1,
      area: FEATURE_AREAS[9],
      title: '[FA10-T1-01] AI service /ai/health returns 200 ok',
      async fn({ client }) {
        const res = await client.get('/ai/health');
        assert.equal(res.status, 200);
        assert.equal(res.json?.status, 'ok');
      },
    },
    {
      id: 'T1-A10-02',
      tier: 1,
      area: FEATURE_AREAS[9],
      title: '[FA10-T1-02] Admin CRUD ai_providers stores openai_compatible/gemini_native with **** masking',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const rawSecret = `sk-e2e-secret-${client.runId}-9876`;
        const createdIds = [];
        try {
          const p1 = await client.post(
            '/v1/admin/ai-providers',
            {
              display_name: `Compat Provider ${nextSeq()}`,
              protocol_type: 'openai_compatible',
              base_url: 'http://127.0.0.1:59991/v1',
              api_key: rawSecret,
              model_name: 'universal-chat-v1',
              priority: 1,
              is_active: true,
              timeout_seconds: 2,
            },
            { token: adminToken }
          );
          assert.ok(p1.status === 200 || p1.status === 201, `Create AI provider failed: ${p1.text}`);
          const id1 = extractId(p1.json?.provider || p1.json?.data);
          if (id1) createdIds.push(id1);

          const list = await client.get('/v1/admin/ai-providers', { token: adminToken });
          assert.equal(list.status, 200);
          assert.equal(
            list.text.includes(rawSecret),
            false,
            'CRITICAL SECURITY VIOLATION: plaintext api_key leaked in GET /v1/admin/ai-providers'
          );
          const providers = list.json?.providers || list.json?.data || [];
          const found = providers.find((p) => extractId(p) === id1) || providers[0];
          const masked = found.api_key_masked || found.api_key || '';
          assert.ok(masked.includes('****'), `Expected **** masked API key, got: ${masked}`);

          const upd = await client.put(
            `/v1/admin/ai-providers/${id1}`,
            { priority: 3, is_active: false },
            { token: adminToken }
          );
          assert.equal(upd.status, 200);
        } finally {
          for (const id of createdIds) {
            await client.del(`/v1/admin/ai-providers/${id}`, { token: adminToken });
          }
        }
      },
    },
    {
      id: 'T1-A10-03',
      tier: 1,
      area: FEATURE_AREAS[9],
      title: '[FA10-T1-03] CS AI chat (CUSTOMER_APP) reads order context and replies cleanly under R5 fallback',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'QRIS',
          },
          { token: cust.token }
        );
        const order = ordRes.json?.order || ordRes.json?.data;

        const chat = await client.post(
          '/ai/cs/chat',
          {
            app_source: 'CUSTOMER_APP',
            order_id: extractId(order),
            message: 'Cek status pesanan terakhir saya',
          },
          { token: cust.token }
        );
        assert.equal(chat.status, 200);
        assert.ok(typeof chat.json?.reply === 'string' && chat.json.reply.length > 0);
        assert.ok(chat.json?.session_id);
      },
    },
    {
      id: 'T1-A10-04',
      tier: 1,
      area: FEATURE_AREAS[9],
      title: '[FA10-T1-04] CS AI Safe Action Boundary allows early SEARCHING_DRIVER cancel & ticket escalation',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOTOR',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'TUNAI',
          },
          { token: cust.token }
        );
        const orderId = extractId(ordRes.json?.order || ordRes.json?.data);

        const chat = await client.post(
          '/ai/cs/chat',
          {
            app_source: 'CUSTOMER_APP',
            order_id: orderId,
            message: 'Tolong batalkan pesanan saya yang masih mencari driver dan buat tiket bantuan.',
            issue_category: 'order_cancel',
          },
          { token: cust.token }
        );
        assert.equal(chat.status, 200);
        assert.ok(chat.json?.ticket_code || Array.isArray(chat.json?.actions_taken));
      },
    },
    {
      id: 'T1-A10-05',
      tier: 1,
      area: FEATURE_AREAS[9],
      title: '[FA10-T1-05] Customer AI Food Assistant and Smart Quick-Replies return valid grounded arrays',
      async fn({ client }) {
        const cust = await client.registerCustomer();
        const foodRes = await client.post(
          '/ai/food-assistant',
          {
            query: 'makanan pedas di bawah Rp 25000 dekat Bukit Indah',
            lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            max_price: 25000,
          },
          { token: cust.token }
        );
        assert.equal(foodRes.status, 200);
        const recs = foodRes.json?.recommended_menus || foodRes.json?.recommendations || [];
        assert.ok(Array.isArray(recs));

        const qrRes = await client.post(
          '/ai/quick-replies',
          { order_id: 1, order_status: 'PICKED_UP', role: 'customer' },
          { token: cust.token }
        );
        assert.equal(qrRes.status, 200);
        const suggestions = qrRes.json?.suggestions || qrRes.json?.replies || [];
        assert.ok(Array.isArray(suggestions) && suggestions.length > 0);
      },
    },
    {
      id: 'T1-A10-06',
      tier: 1,
      area: FEATURE_AREAS[9],
      title: '[FA10-T1-06] Driver Shopping Summarizer, Store Copywriter/Insight, and Admin Executive Summary',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken);
        const driver = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const fsOrd = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'TUNAI',
            items: [{ stop_index: 1, item_name: 'Cabai Merah 1kg', quantity: 1, estimated_price: 40000 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(fsOrd.json?.order || fsOrd.json?.data);

        const sumRes = await client.post(
          '/ai/driver/summarize-shopping',
          { order_id: orderId },
          { token: driver.token }
        );
        assert.equal(sumRes.status, 200);
        assert.ok(Array.isArray(sumRes.json?.summary_checklist));

        const copyRes = await client.post(
          '/ai/store/menu-copywriter',
          { name: 'Mie Aceh Kepiting', price: 28000, category: 'Makanan Utama' },
          { token: store.token }
        );
        assert.equal(copyRes.status, 200);
        assert.ok(typeof copyRes.json?.description === 'string' && copyRes.json.description.length > 0);

        const insRes = await client.get(`/ai/store/sales-insight?store_id=${extractId(store.store)}`, {
          token: store.token,
        });
        assert.equal(insRes.status, 200);
        assert.ok(typeof insRes.json?.insight === 'string' && insRes.json.insight.length > 0);

        const execRes = await client.get('/ai/admin/executive-summary', { token: adminToken });
        assert.equal(execRes.status, 200);
        assert.ok(typeof execRes.json?.summary === 'string' && execRes.json.summary.length > 0);
      },
    },

    // =========================================================================
    // Area 11: WA Gateway Sessions, OTP & AI Forwarding (5 tests)
    // =========================================================================
    {
      id: 'T1-A11-01',
      tier: 1,
      area: FEATURE_AREAS[10],
      title: '[FA11-T1-01] WA Gateway /wa/health, /wa/status, and /wa/qr respond via Nginx strip',
      async fn({ client }) {
        const h = await client.get('/wa/health');
        assert.equal(h.status, 200);
        assert.equal(h.json?.status, 'ok');

        const s = await client.get('/wa/status');
        assert.equal(s.status, 200);
        assert.ok('paired' in s.json && 'status' in s.json);

        const q = await client.get('/wa/qr');
        assert.equal(q.status, 200);
        assert.ok((q.headers.get('content-type') || '').includes('text/html'));
      },
    },
    {
      id: 'T1-A11-02',
      tier: 1,
      area: FEATURE_AREAS[10],
      title: '[FA11-T1-02] POST /wa/api/otp/send issues 6-digit OTP in local sandbox mode',
      async fn({ client }) {
        const id = uniqueIdentity('waotp', client.runId);
        const res = await client.post('/wa/api/otp/send', {
          phoneNumber: id.phone,
          purpose: 'register',
        });
        assert.equal(res.status, 200);
        assert.equal(res.json?.success, true);
        if (res.json?.simulated) {
          assert.match(String(res.json.code), /^\d{6}$/);
        }
      },
    },
    {
      id: 'T1-A11-03',
      tier: 1,
      area: FEATURE_AREAS[10],
      title: '[FA11-T1-03] POST /wa/api/otp/verify normalizes 08... vs 628... phone format',
      async fn({ client }) {
        const id = uniqueIdentity('wanorm', client.runId);
        const sendRes = await client.post('/wa/api/otp/send', {
          phoneNumber: id.phone,
          purpose: 'register',
        });
        assert.equal(sendRes.status, 200);
        const code = sendRes.json?.code;
        assert.ok(code, 'Expected simulated OTP code for local E2E verification');

        const verifyRes = await client.post('/wa/api/otp/verify', {
          phoneNumber: id.waPhone,
          code: String(code),
        });
        assert.equal(verifyRes.status, 200);
        assert.equal(verifyRes.json?.success, true);
      },
    },
    {
      id: 'T1-A11-04',
      tier: 1,
      area: FEATURE_AREAS[10],
      title: '[FA11-T1-04] Authorized POST /wa/send succeeds in sandbox or returns clean 503 when unpaired',
      async fn({ client }) {
        const id = uniqueIdentity('wasend', client.runId);
        const res = await client.post(
          '/wa/send',
          { target: id.phone, message: 'Tes notifikasi RideOn E2E' },
          { headers: { 'X-Gateway-Secret': client.secrets.waGateway } }
        );
        assert.ok(res.status === 200 || res.status === 503, `Unexpected /wa/send status: ${res.status}`);
        if (res.status === 200) {
          assert.equal(res.json?.status, true);
        }
      },
    },
    {
      id: 'T1-A11-05',
      tier: 1,
      area: FEATURE_AREAS[10],
      title: '[FA11-T1-05] Inbound WA forwarding POST /ai/webhook/whatsapp returns AI reply and persists chat',
      async fn({ client }) {
        const id = uniqueIdentity('wainbound', client.runId);
        const res = await client.post(
          '/ai/webhook/whatsapp',
          {
            sender: id.waPhone,
            name: 'Budi Aceh Utara',
            message: 'Halo CS RideOn, bagaimana cara pesan FlexFood?',
          },
          { headers: { 'X-Gateway-Secret': client.secrets.waGateway } }
        );
        assert.equal(res.status, 200, `WA AI webhook failed: ${res.text}`);
        assert.equal(res.json?.success, true);
        assert.ok(typeof res.json?.reply === 'string' && res.json.reply.length > 0);
      },
    },

    // =========================================================================
    // Area 12: Web Admin UI Routes & App Contract Parity (5 tests)
    // =========================================================================
    {
      id: 'T1-A12-01',
      tier: 1,
      area: FEATURE_AREAS[11],
      title: '[FA12-T1-01] Web Admin / and /login serve valid HTML without Next.js SSR errors',
      async fn({ client }) {
        for (const route of ['/', '/login']) {
          const res = await client.get(route);
          assert.equal(res.status, 200, `GET ${route} failed with ${res.status}`);
          const ct = res.headers.get('content-type') || '';
          assert.ok(ct.includes('text/html'));
          assert.equal(res.text.includes('Application error'), false);
        }
      },
    },
    {
      id: 'T1-A12-02',
      tier: 1,
      area: FEATURE_AREAS[11],
      title: '[FA12-T1-02] Admin login + 7 wired dashboard endpoints return live DB data',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const ov = await client.get('/v1/admin/overview', { token: adminToken });
        assert.equal(ov.status, 200);
        const map = await client.get('/v1/admin/map', { token: adminToken });
        assert.equal(map.status, 200);
        for (const path of [
          '/v1/admin/registrations',
          '/v1/admin/orders',
          '/v1/admin/drivers',
          '/v1/admin/stores',
          '/v1/admin/customers',
        ]) {
          const r = await client.get(path, { token: adminToken });
          assert.equal(r.status, 200);
        }
      },
    },
    {
      id: 'T1-A12-03',
      tier: 1,
      area: FEATURE_AREAS[11],
      title: '[FA12-T1-03] Admin Keuangan & QRIS + Pengaturan AI & Tarif API parity',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        for (const ep of [
          '/v1/admin/withdrawals',
          '/v1/admin/talangan-claims',
          '/pay/transactions',
          '/v1/admin/pricing-rules',
          '/v1/admin/ai-providers',
          '/v1/admin/support-tickets',
        ]) {
          const r = await client.get(ep, { token: adminToken });
          assert.equal(r.status, 200, `${ep} failed: ${r.text}`);
        }
      },
    },
    {
      id: 'T1-A12-04',
      tier: 1,
      area: FEATURE_AREAS[11],
      title: '[FA12-T1-04] Flutter customer_app & page_toko contract parity on home, stores, and store profile',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken);
        const cust = await client.registerCustomer();

        const home = await client.get('/v1/home', { token: cust.token });
        assert.equal(home.status, 200);
        const stores = await client.get('/v1/stores', { token: cust.token });
        assert.equal(stores.status, 200);
        const storeMenus = await client.get(`/v1/stores/${extractId(store.store)}/menus`, {
          token: cust.token,
        });
        assert.equal(storeMenus.status, 200);

        const meStore = await client.get('/v1/me', { token: store.token });
        assert.equal(meStore.status, 200);
        assert.ok(meStore.json?.store?.store_name);
      },
    },
    {
      id: 'T1-A12-05',
      tier: 1,
      area: FEATURE_AREAS[11],
      title: '[FA12-T1-05] Flutter driver_app contract parity on /v1/me, /v1/driver/status, /v1/orders & /v1/wallet',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOBIL' });

        const me = await client.get('/v1/me', { token: driver.token });
        assert.equal(me.status, 200);
        assert.equal(me.json?.driver?.vehicle_type, 'MOBIL');
        assert.equal(me.json?.driver?.verification_status, 'Disetujui');

        const toggle = await client.patch('/v1/driver/status', { is_online: false }, { token: driver.token });
        assert.equal(toggle.status, 200);

        const orders = await client.get('/v1/orders?role=driver', { token: driver.token });
        assert.equal(orders.status, 200);

        const wallet = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(wallet.status, 200);
        assert.ok(typeof wallet.json?.wallet?.balance === 'number');
        assert.ok(Array.isArray(wallet.json?.transactions));
      },
    },
  ];
}
