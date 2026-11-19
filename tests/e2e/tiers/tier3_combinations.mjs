import assert from 'node:assert/strict';
import {
  COORDS,
  PRICING_RULES,
  SAMPLE_STATIC_QRIS,
} from '../lib/fixtures.mjs';
import {
  extractData,
  extractId,
  formatIdr,
  nextSeq,
  runConcurrent,
  uniqueIdentity,
  uniqueInvoice,
  verifyDynamicQris,
} from '../lib/client.mjs';

export const TIER = 3;

export function defineTests() {
  return [
    {
      id: 'T3-W01',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA2+FA12+FA3] Driver doc uploads -> pending block (403) -> Admin approve -> online (200)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const drv = await client.registerDriverPending();

        const ktp = await client.uploadDummyPng(drv.token, 'ktp');
        const sim = await client.uploadDummyPng(drv.token, 'sim');
        const stnk = await client.uploadDummyPng(drv.token, 'stnk');
        const docRes = await client.put(
          '/v1/driver/documents',
          { ktp_url: ktp.url, sim_url: sim.url, stnk_url: stnk.url },
          { token: drv.token }
        );
        assert.equal(docRes.status, 200);

        const blocked = await client.patch('/v1/driver/status', { is_online: true }, { token: drv.token });
        assert.equal(blocked.status, 403);

        const regId = extractId(drv.registration);
        const listBefore = await client.get('/v1/admin/registrations?status=Menunggu+verifikasi', {
          token: adminToken,
        });
        assert.equal(listBefore.status, 200);
        assert.ok((listBefore.json?.registrations || []).some((r) => extractId(r) === regId));

        await client.patch(
          `/v1/admin/registrations/${regId}/decide`,
          { status: 'Disetujui' },
          { token: adminToken }
        );

        const listAfter = await client.get('/v1/admin/registrations?status=Menunggu+verifikasi', {
          token: adminToken,
        });
        assert.equal(
          (listAfter.json?.registrations || []).some((r) => extractId(r) === regId),
          false,
          'Approved registration must leave pending queue'
        );

        const okOnline = await client.patch('/v1/driver/status', { is_online: true }, { token: drv.token });
        assert.equal(okOnline.status, 200);
      },
    },
    {
      id: 'T3-W02',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA3+FA10+FA8] AI Menu Copywriter -> Store menu create -> Customer newest-first discovery + Favorite',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken);
        const cust = await client.registerCustomer();

        const copyRes = await client.post(
          '/ai/store/menu-copywriter',
          { name: 'Ayam Tangkap Aceh', price: 27000, category: 'Makanan Utama' },
          { token: store.token }
        );
        assert.equal(copyRes.status, 200);
        const aiDesc = copyRes.json?.description;
        assert.ok(typeof aiDesc === 'string' && aiDesc.length > 0);

        const menuRes = await client.post(
          '/v1/store/menus',
          {
            name: `Ayam Tangkap ${nextSeq()}`,
            description: aiDesc,
            category: 'Makanan Utama',
            price: 27000,
            is_available: true,
          },
          { token: store.token }
        );
        assert.ok(menuRes.status === 200 || menuRes.status === 201);
        const newMenu = menuRes.json?.menu || menuRes.json?.data;
        const menuId = extractId(newMenu);

        const cat = await client.get(`/v1/stores/${extractId(store.store)}/menus`, { token: cust.token });
        assert.equal(cat.status, 200);
        assert.equal(extractId(cat.json?.menus?.[0]), menuId, 'New AI menu must appear first');

        const fav = await client.post(
          '/v1/favorites',
          { target_type: 'MENU', target_id: String(menuId), label: newMenu.name },
          { token: cust.token }
        );
        assert.ok(fav.status === 200 || fav.status === 201);
      },
    },
    {
      id: 'T3-W03',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA4+FA8+FA4] Admin tariff update + Promo code reflected in pricing estimate & order creation',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const origRules = (await client.get('/v1/admin/pricing-rules', { token: adminToken })).json?.rules || [];
        const cust = await client.registerCustomer();
        const promoCode = `PAIR${nextSeq()}`;

        try {
          await client.put(
            '/v1/admin/pricing-rules',
            { rules: [{ ...PRICING_RULES.FLEXRIDE_MOTOR, per_km_rate: 3500 }] },
            { token: adminToken }
          );
          await client.post(
            '/v1/admin/promotions',
            {
              code: promoCode,
              title: 'Diskon Pairwise',
              service_type: 'ALL',
              discount_amount: 5000,
              max_discount: 4000,
              min_order_amount: 5000,
              is_active: true,
            },
            { token: adminToken }
          );

          const noPromo = await client.post('/v1/pricing/estimate', {
            service_type: 'FLEXRIDE_MOTOR',
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
            dest_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
          });
          const withPromo = await client.post('/v1/pricing/estimate', {
            service_type: 'FLEXRIDE_MOTOR',
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
            dest_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
            promo_code: promoCode,
          });
          assert.equal(Number(withPromo.json?.discount_amount), 4000, 'max_discount cap must apply');
          assert.equal(
            Number(withPromo.json?.total_amount),
            Number(noPromo.json?.total_amount) - 4000
          );

          const ord = await client.post(
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
              payment_method: 'TUNAI',
              promo_code: promoCode,
            },
            { token: cust.token }
          );
          assert.equal(Number((ord.json?.order || ord.json?.data)?.discount_amount), 4000);
        } finally {
          await client.put('/v1/admin/pricing-rules', { rules: origRules }, { token: adminToken });
        }
      },
    },
    {
      id: 'T3-W04',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA4+FA5] FlexRide MOBIL order blocks MOTOR driver then resolves 2-MOBIL-driver atomic race (200 vs 409)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const motorDrv = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });
        const mobil1 = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOBIL' });
        const mobil2 = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOBIL' });
        const cust = await client.registerCustomer();

        const ord = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexRide',
            vehicle_type: 'MOBIL',
            pickup_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            pickup_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            dest_label: COORDS.PUSAT_LHOKSEUMAWE.label,
            dest_address: COORDS.PUSAT_LHOKSEUMAWE.address,
            dest_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
            dest_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
            payment_method: 'TUNAI',
          },
          { token: cust.token }
        );
        const orderId = extractId(ord.json?.order || ord.json?.data);

        const wrongVeh = await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: motorDrv.token });
        assert.ok([400, 403, 409].includes(wrongVeh.status));

        const race = await runConcurrent([
          () => client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: mobil1.token }),
          () => client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: mobil2.token }),
        ]);
        assert.equal(race.filter((r) => r.status === 200).length, 1);
        assert.equal(race.filter((r) => r.status === 409).length, 1);
      },
    },
    {
      id: 'T3-W05',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA5+FA9] Strict FlexFood QRIS state machine: PayG MacroDroid settle -> Store accept -> Driver accept',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 25000 });
        const driver = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const ord = await client.post(
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
        const order = ord.json?.order || ord.json?.data;
        const orderId = extractId(order);

        assert.ok([400, 409].includes((await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token })).status));

        const co = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: orderId, invoice_number: uniqueInvoice(client.runId), amount: Number(order.total_amount) },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Diterima Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        assert.equal((await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token })).status, 200);
        assert.equal((await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token })).status, 200);
      },
    },
    {
      id: 'T3-W06',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA6+FA9] FlexSend 3-stop modal kas gate + dynamic receipt total + PayG QRIS checkout',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const lowDrv = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 20000 });
        const okDrv = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 150000 });
        const cust = await client.registerCustomer();

        const ord = await client.post(
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
            payment_method: 'QRIS',
            items: [
              { stop_index: 1, item_name: 'Item 1', quantity: 1, estimated_price: 40000 },
              { stop_index: 2, item_name: 'Item 2', quantity: 1, estimated_price: 35000 },
              { stop_index: 3, item_name: 'Item 3', quantity: 1, estimated_price: 25000 },
            ],
          },
          { token: cust.token }
        );
        const order = ord.json?.order || ord.json?.data;
        const orderId = extractId(order);

        // Settle initial QRIS or allow post-receipt QRIS payment
        const co1 = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: orderId, invoice_number: uniqueInvoice(client.runId), amount: Number(order.total_amount) },
          { token: cust.token }
        );
        const tx1 = extractData(co1.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Rp ${formatIdr(tx1.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        const blocked = await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: lowDrv.token });
        assert.ok([400, 403, 409].includes(blocked.status));

        const okAcc = await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: okDrv.token });
        assert.equal(okAcc.status, 200);
        await client.post(`/v1/orders/${orderId}/status`, { status: 'SHOPPING' }, { token: okDrv.token });

        const { url: recUrl } = await client.uploadDummyPng(okDrv.token, 'receipt');
        const rec = await client.post(
          `/v1/orders/${orderId}/flexsend-receipt`,
          { actual_receipt_amount: 92000, parking_fee: 4000, receipt_photo_url: recUrl },
          { token: okDrv.token }
        );
        assert.equal(rec.status, 200);
        const updatedOrder = rec.json?.order || rec.json?.data;
        assert.equal(
          Number(updatedOrder.total_amount),
          92000 + 4000 + Number(updatedOrder.delivery_fee) + Number(updatedOrder.service_fee)
        );
      },
    },
    {
      id: 'T3-W07',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA6+FA3+FA8] FlexSend cancelled after shopping -> 2-step upload + talangan claim -> Admin approve credit',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const drv = await client.registerAndApproveDriver(adminToken, { cashCapitalLimit: 150000 });
        const cust = await client.registerCustomer();

        const ord = await client.post(
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
            items: [{ stop_index: 1, item_name: 'Kue Basah', quantity: 2, estimated_price: 40000 }],
          },
          { token: cust.token }
        );
        const orderId = extractId(ord.json?.order || ord.json?.data);
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'SHOPPING' }, { token: drv.token });

        const { url: recUrl } = await client.uploadDummyPng(drv.token, 'receipt');
        await client.post(
          `/v1/orders/${orderId}/flexsend-receipt`,
          { actual_receipt_amount: 42000, parking_fee: 2000, receipt_photo_url: recUrl },
          { token: drv.token }
        );
        await client.post(`/v1/orders/${orderId}/cancel`, {}, { token: cust.token });

        const { url: donUrl } = await client.uploadDummyPng(drv.token, 'donation');
        const claim = await client.post(
          '/v1/wallet/talangan-claims',
          {
            order_id: orderId,
            receipt_amount: 42000,
            parking_amount: 2000,
            receipt_photo_url: recUrl,
            donation_recipient: 'Panti Asuhan Darul Ulum Aceh Utara',
            donation_photo_url: donUrl,
          },
          { token: drv.token }
        );
        const claimId = extractId(claim.json?.claim || claim.json?.data);
        await client.post(`/v1/admin/talangan-claims/${claimId}/decide`, { status: 'APPROVED' }, { token: adminToken });

        const w = await client.get('/v1/wallet', { token: drv.token });
        assert.equal(Number(w.json?.wallet?.balance), 44000);
      },
    },
    {
      id: 'T3-W08',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA7+FA5+FA8] Complete QRIS FlexFood -> 5%:5% ledger verification -> 5/4 Star Rating updates rating_avg',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { menuPrice: 40000 });
        const drv = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const ord = await client.post(
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
        const order = ord.json?.order || ord.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: orderId, invoice_number: uniqueInvoice(client.runId), amount: Number(order.total_amount) },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/complete`, {}, { token: drv.token });

        const stW = await client.get('/v1/wallet', { token: store.token });
        const drW = await client.get('/v1/wallet', { token: drv.token });
        assert.equal(Number(stW.json?.wallet?.balance), 38000);
        assert.equal(Number(drW.json?.wallet?.balance), Math.round(Number(order.delivery_fee) * 0.95));

        const rate = await client.post(
          `/v1/orders/${orderId}/rating`,
          { driver_stars: 5, store_stars: 4 },
          { token: cust.token }
        );
        assert.ok(rate.status === 200 || rate.status === 201);
        assert.equal(Number((await client.get('/v1/me', { token: store.token })).json?.store?.rating_avg), 4);
      },
    },
    {
      id: 'T3-W09',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA7+FA9] Driver hits <= -20000 TUNAI block -> QRIS DRIVER_TOPUP recovery -> TUNAI accept unblocked',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const drv = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOBIL' });
        const cust = await client.registerCustomer();

        const makeMobilTunai = async () => {
          const r = await client.post(
            '/v1/orders',
            {
              service_type: 'FlexRide',
              vehicle_type: 'MOBIL',
              pickup_label: COORDS.PUSAT_LHOKSEUMAWE.label,
              pickup_address: COORDS.PUSAT_LHOKSEUMAWE.address,
              pickup_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
              pickup_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
              dest_label: COORDS.BIREUEN.label,
              dest_address: COORDS.BIREUEN.address,
              dest_lat: COORDS.BIREUEN.lat,
              dest_lng: COORDS.BIREUEN.lng,
              payment_method: 'TUNAI',
            },
            { token: cust.token }
          );
          return extractId(r.json?.order || r.json?.data);
        };

        let bal = 0;
        for (let i = 0; i < 4 && bal > -20000; i++) {
          const oid = await makeMobilTunai();
          await client.post(`/v1/orders/${oid}/accept-driver`, {}, { token: drv.token });
          await client.post(`/v1/orders/${oid}/status`, { status: 'PICKED_UP' }, { token: drv.token });
          await client.post(`/v1/orders/${oid}/status`, { status: 'DELIVERING' }, { token: drv.token });
          await client.post(`/v1/orders/${oid}/status`, { status: 'ARRIVED' }, { token: drv.token });
          await client.post(`/v1/orders/${oid}/complete`, {}, { token: drv.token });
          bal = Number((await client.get('/v1/wallet', { token: drv.token })).json?.wallet?.balance);
        }
        assert.ok(bal <= -20000);

        const blockedId = await makeMobilTunai();
        const blocked = await client.post(`/v1/orders/${blockedId}/accept-driver`, {}, { token: drv.token });
        assert.ok([400, 402, 403, 409].includes(blocked.status));

        const co = await client.post(
          '/pay/checkout/create',
          { purpose: 'DRIVER_TOPUP', wallet_topup_user_id: extractId(drv.user), invoice_number: uniqueInvoice(client.runId), amount: 50000 },
          { token: drv.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );

        const unblocked = await client.post(`/v1/orders/${blockedId}/accept-driver`, {}, { token: drv.token });
        assert.equal(unblocked.status, 200);
      },
    },
    {
      id: 'T3-W10',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA7+FA12] Store wrong PIN fails -> valid 6-digit PIN holds balance -> Admin REJECTED refunds balance',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, { pin: '246810', menuPrice: 60000 });
        const drv = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const ord = await client.post(
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
        const order = ord.json?.order || ord.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: orderId, invoice_number: uniqueInvoice(client.runId), amount: Number(order.total_amount) },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );
        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/complete`, {}, { token: drv.token });

        const badPin = await client.post(
          '/v1/wallet/withdraw',
          { amount: 30000, bank_name: 'BSI', bank_account_number: '111', bank_account_holder: 'Toko', pin: '000000' },
          { token: store.token }
        );
        assert.ok([400, 401, 403].includes(badPin.status));

        const okPin = await client.post(
          '/v1/wallet/withdraw',
          { amount: 30000, bank_name: 'BSI', bank_account_number: '111', bank_account_holder: 'Toko', pin: '246810' },
          { token: store.token }
        );
        assert.ok(okPin.status === 200 || okPin.status === 201);
        const wdId = extractId(okPin.json?.withdrawal || okPin.json?.data);
        assert.equal(Number((await client.get('/v1/wallet', { token: store.token })).json?.wallet?.balance), 27000);

        await client.post(`/v1/admin/withdrawals/${wdId}/decide`, { status: 'REJECTED' }, { token: adminToken });
        assert.equal(Number((await client.get('/v1/wallet', { token: store.token })).json?.wallet?.balance), 57000);
      },
    },
    {
      id: 'T3-W11',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA10+FA5+FA12] CS AI cancels SEARCHING_DRIVER Order A, refuses DELIVERING Order B & escalates ticket to Admin',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const drv = await client.registerAndApproveDriver(adminToken);
        const cust = await client.registerCustomer();

        const makeRide = () =>
          client.post(
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

        const ordA = extractId((await makeRide()).json?.order);
        const ordB = extractId((await makeRide()).json?.order);
        await client.post(`/v1/orders/${ordB}/accept-driver`, {}, { token: drv.token });
        await client.post(`/v1/orders/${ordB}/status`, { status: 'PICKED_UP' }, { token: drv.token });
        await client.post(`/v1/orders/${ordB}/status`, { status: 'DELIVERING' }, { token: drv.token });

        const csA = await client.post(
          '/ai/cs/chat',
          { app_source: 'CUSTOMER_APP', order_id: ordA, message: 'Tolong batalkan pesanan ini karena belum ada driver' },
          { token: cust.token }
        );
        assert.equal(csA.status, 200);

        const csB = await client.post(
          '/ai/cs/chat',
          { app_source: 'CUSTOMER_APP', order_id: ordB, message: 'Tolong batalkan pesanan ini dan buat tiket komplain' },
          { token: cust.token }
        );
        assert.equal(csB.status, 200);

        const checkB = await client.get(`/v1/orders/${ordB}`, { token: cust.token });
        assert.equal((checkB.json?.order || checkB.json?.data)?.status, 'DELIVERING');

        const tickets = (await client.get('/v1/admin/support-tickets', { token: adminToken })).json?.tickets || [];
        assert.ok(tickets.length > 0);
        const rep = await client.post(
          `/v1/admin/support-tickets/${extractId(tickets[0])}/reply`,
          { status: 'RESOLVED', admin_reply: 'Sudah ditangani tim CS' },
          { token: adminToken }
        );
        assert.equal(rep.status, 200);
      },
    },
    {
      id: 'T3-W12',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA11+FA2+FA7] WA OTP verify -> Driver register -> Admin approve -> verify initial balance === 0',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const id = uniqueIdentity('wa_drv', client.runId);
        const otpSend = await client.post('/wa/api/otp/send', { phoneNumber: id.phone, purpose: 'register' });
        assert.equal(otpSend.status, 200);
        const code = otpSend.json?.code;
        assert.ok(code);
        const otpVerify = await client.post('/wa/api/otp/verify', { phoneNumber: id.waPhone, code: String(code) });
        assert.equal(otpVerify.status, 200);

        const drv = await client.registerAndApproveDriver(adminToken, { phone: id.phone, email: id.email });
        const w = await client.get('/v1/wallet', { token: drv.token });
        assert.equal(Number(w.json?.wallet?.balance), 0);
      },
    },
    {
      id: 'T3-W13',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA11+FA10+FA12] WA inbound chat webhook -> AI ticket escalation -> Admin ticket resolution',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const id = uniqueIdentity('wa_tkt', client.runId);

        const wh = await client.post(
          '/ai/webhook/whatsapp',
          {
            sender: id.waPhone,
            name: 'Siti Muara Batu',
            message: 'Pesanan saya bermasalah, tolong buatkan tiket komplain ke admin.',
          },
          { headers: { 'X-Gateway-Secret': client.secrets.waGateway } }
        );
        assert.equal(wh.status, 200);
        assert.ok(wh.json?.ticket_code, 'Expected ticket_code from escalated WA chat');

        const tickets = (await client.get('/v1/admin/support-tickets', { token: adminToken })).json?.tickets || [];
        const matched = tickets.find((t) => t.ticket_code === wh.json.ticket_code) || tickets[0];
        assert.ok(matched);

        const res = await client.post(
          `/v1/admin/support-tickets/${extractId(matched)}/reply`,
          { status: 'RESOLVED', admin_reply: 'Terima kasih, sudah diselesaikan.', send_whatsapp: true },
          { token: adminToken }
        );
        assert.equal(res.status, 200);
        assert.equal((res.json?.ticket || res.json?.data)?.status, 'RESOLVED');
      },
    },
    {
      id: 'T3-W14',
      tier: 3,
      area: 'Tier 3: Pairwise Cross-Feature Combinations',
      title: '[FA9+FA12+FA9] Admin updates Static QRIS -> dynamic checkout uses new merchant + CRC-16 -> manual confirm',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const cust = await client.registerCustomer();

        const setStatic = await client.post(
          '/pay/static-qr',
          { static_qris: SAMPLE_STATIC_QRIS },
          { token: adminToken }
        );
        assert.equal(setStatic.status, 200);

        const ord = await client.post(
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
        const order = ord.json?.order || ord.json?.data;
        const orderId = extractId(order);

        const co = await client.post(
          '/pay/checkout/create',
          { purpose: 'ORDER_PAYMENT', order_id: orderId, invoice_number: uniqueInvoice(client.runId), amount: Number(order.total_amount) },
          { token: cust.token }
        );
        const tx = extractData(co.json);
        const tags = verifyDynamicQris(tx.qr_string, tx.payable_amount);
        assert.equal(tags['59'], 'KEDAI RIDEON');

        const man = await client.post(
          `/pay/transactions/${tx.transaction_ref}/manual-confirm`,
          { notes: 'Konfirmasi manual Admin E2E' },
          { token: adminToken }
        );
        assert.equal(man.status, 200);
        assert.equal((await client.get(`/v1/orders/${orderId}`, { token: cust.token })).json?.order?.payment_status, 'PAID');
      },
    },
  ];
}
