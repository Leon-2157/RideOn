import assert from 'node:assert/strict';
import { COORDS, PRICING_RULES } from '../lib/fixtures.mjs';
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

export const TIER = 4;

export function defineTests() {
  return [
    {
      id: 'T4-S01',
      tier: 4,
      area: 'Tier 4: Real-World Lhokseumawe & Aceh Utara Scenarios',
      title: 'Lhokseumawe FlexFood QRIS Full Lifecycle (Kampus Bukit Indah -> MacroDroid -> Toko -> 2-Driver Race -> 5%:5% -> Rating)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const store = await client.registerAndApproveStore(adminToken, {
          coord: COORDS.BLANG_PULO,
          menuName: 'Mie Aceh Spesial Bukit Indah',
          menuPrice: 25000,
        });
        const driver1 = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });
        const driver2 = await client.registerAndApproveDriver(adminToken, { vehicleType: 'MOTOR' });
        const cust = await client.registerCustomer();
        const storeId = extractId(store.store);
        const menuId = extractId(store.menu);

        // 1. Browse home & store menus
        const home = await client.get(
          `/v1/home?lat=${COORDS.KAMPUS_BUKIT_INDAH.lat}&lng=${COORDS.KAMPUS_BUKIT_INDAH.lng}`,
          { token: cust.token }
        );
        assert.equal(home.status, 200);
        const menuCatalog = await client.get(`/v1/stores/${storeId}/menus`, { token: cust.token });
        assert.equal(menuCatalog.status, 200);
        assert.ok((menuCatalog.json?.menus || []).some((m) => extractId(m) === menuId));

        // 2. Estimate & place FlexFood QRIS order (2x 25000 = 50000)
        const est = await client.post('/v1/pricing/estimate', {
          service_type: 'FLEXFOOD',
          pickup_lat: COORDS.BLANG_PULO.lat,
          pickup_lng: COORDS.BLANG_PULO.lng,
          dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
          dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
        });
        assert.equal(est.status, 200);

        const ordRes = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: storeId,
            pickup_label: store.creds.store_name,
            pickup_address: store.creds.store_address,
            pickup_lat: COORDS.BLANG_PULO.lat,
            pickup_lng: COORDS.BLANG_PULO.lng,
            dest_label: COORDS.KAMPUS_BUKIT_INDAH.label,
            dest_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
            payment_method: 'QRIS',
            items: [{ menu_id: menuId, quantity: 2 }],
          },
          { token: cust.token }
        );
        assert.ok(ordRes.status === 200 || ordRes.status === 201);
        const order = ordRes.json?.order || ordRes.json?.data;
        const orderId = extractId(order);
        assert.equal(order.status, 'WAITING_PAYMENT');

        // 3. Create PayG Dynamic QRIS & verify EMVCo CRC-16
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
        assert.equal(co.status, 200);
        const tx = extractData(co.json);
        verifyDynamicQris(tx.qr_string, tx.payable_amount);

        // 4. MacroDroid settles -> WAITING_STORE
        const wh = await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `QRIS Diterima Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );
        assert.equal(wh.status, 200);
        const afterPay = (await client.get(`/v1/orders/${orderId}`, { token: cust.token })).json?.order;
        assert.equal(afterPay.payment_status, 'PAID');
        assert.equal(afterPay.status, 'WAITING_STORE');

        // 5. Store accepts -> COOKING/SEARCHING_DRIVER
        const stAcc = await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: store.token });
        assert.equal(stAcc.status, 200);

        // 6. Two drivers race accept-driver
        const race = await runConcurrent([
          () => client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver1.token }),
          () => client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver2.token }),
        ]);
        const winIdx = race.findIndex((r) => r.status === 200);
        assert.ok(winIdx >= 0, 'One driver must win race');
        assert.equal(race.filter((r) => r.status === 409).length, 1);
        const winner = winIdx === 0 ? driver1 : driver2;

        // 7. Complete delivery
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: winner.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: winner.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: winner.token });
        const comp = await client.post(`/v1/orders/${orderId}/complete`, {}, { token: winner.token });
        assert.equal(comp.status, 200);

        // 8. Verify 5%:5% commission split
        const storeWallet = await client.get('/v1/wallet', { token: store.token });
        const driverWallet = await client.get('/v1/wallet', { token: winner.token });
        assert.equal(Number(storeWallet.json?.wallet?.balance), 47500);
        assert.equal(Number(driverWallet.json?.wallet?.balance), Math.round(Number(order.delivery_fee) * 0.95));

        // 9. Customer rating 5/5 & admin overview
        const rate = await client.post(
          `/v1/orders/${orderId}/rating`,
          { driver_stars: 5, store_stars: 5, comment: 'Mantap kali!' },
          { token: cust.token }
        );
        assert.ok(rate.status === 200 || rate.status === 201);
        const ov = await client.get('/v1/admin/overview', { token: adminToken });
        assert.equal(ov.status, 200);
      },
    },
    {
      id: 'T4-S02',
      tier: 4,
      area: 'Tier 4: Real-World Lhokseumawe & Aceh Utara Scenarios',
      title: 'Multi-Stop FlexSend (3 Stops: Pasar Inpres -> Blang Pulo -> Reuleut) + Nota/Parkir + 2-Step Talangan Donasi',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const driver = await client.registerAndApproveDriver(adminToken, {
          vehicleType: 'MOTOR',
          cashCapitalLimit: 150000,
        });
        const cust = await client.registerCustomer();

        const stops = [
          {
            stop_index: 1,
            stop_location_name: 'Pasar Inpres',
            stop_address: COORDS.PASAR_INPRES.address,
            stop_lat: COORDS.PASAR_INPRES.lat,
            stop_lng: COORDS.PASAR_INPRES.lng,
            item_name: 'Sayur & Ikan',
            quantity: 1,
            estimated_price: 40000,
          },
          {
            stop_index: 2,
            stop_location_name: 'Blang Pulo',
            stop_address: COORDS.BLANG_PULO.address,
            stop_lat: COORDS.BLANG_PULO.lat,
            stop_lng: COORDS.BLANG_PULO.lng,
            item_name: 'Bumbu Dapur',
            quantity: 1,
            estimated_price: 20000,
          },
          {
            stop_index: 3,
            stop_location_name: 'Reuleut',
            stop_address: COORDS.REULEUT.address,
            stop_lat: COORDS.REULEUT.lat,
            stop_lng: COORDS.REULEUT.lng,
            item_name: 'Air Galon & Gas',
            quantity: 1,
            estimated_price: 20000,
          },
        ];

        const est = await client.post('/v1/pricing/estimate', {
          service_type: 'FLEXSEND',
          pickup_lat: COORDS.PASAR_INPRES.lat,
          pickup_lng: COORDS.PASAR_INPRES.lng,
          dest_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
          dest_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
          stops: stops.map((s) => ({ lat: s.stop_lat, lng: s.stop_lng })),
        });
        assert.equal(est.status, 200);

        const ord = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexSend',
            pickup_label: COORDS.PASAR_INPRES.label,
            pickup_address: COORDS.PASAR_INPRES.address,
            pickup_lat: COORDS.PASAR_INPRES.lat,
            pickup_lng: COORDS.PASAR_INPRES.lng,
            dest_label: COORDS.PUSAT_LHOKSEUMAWE.label,
            dest_address: COORDS.PUSAT_LHOKSEUMAWE.address,
            dest_lat: COORDS.PUSAT_LHOKSEUMAWE.lat,
            dest_lng: COORDS.PUSAT_LHOKSEUMAWE.lng,
            payment_method: 'TUNAI',
            items: stops,
          },
          { token: cust.token }
        );
        const orderId = extractId(ord.json?.order || ord.json?.data);

        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: driver.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'SHOPPING' }, { token: driver.token });

        const { url: receiptUrl } = await client.uploadDummyPng(driver.token, 'receipt');
        const recRes = await client.post(
          `/v1/orders/${orderId}/flexsend-receipt`,
          { actual_receipt_amount: 85000, parking_fee: 4000, receipt_photo_url: receiptUrl },
          { token: driver.token }
        );
        assert.equal(recRes.status, 200);
        const recOrder = recRes.json?.order || recRes.json?.data;
        assert.equal(
          Number(recOrder.total_amount),
          85000 + 4000 + Number(recOrder.delivery_fee) + Number(recOrder.service_fee)
        );

        await client.post(`/v1/orders/${orderId}/cancel`, { reason: 'Customer tidak bisa dihubungi' }, { token: cust.token });
        const { url: donationUrl } = await client.uploadDummyPng(driver.token, 'donation');

        const claimRes = await client.post(
          '/v1/wallet/talangan-claims',
          {
            order_id: orderId,
            receipt_amount: 85000,
            parking_amount: 4000,
            receipt_photo_url: receiptUrl,
            donation_recipient: 'Panti Asuhan Lhokseumawe',
            donation_photo_url: donationUrl,
          },
          { token: driver.token }
        );
        assert.ok(claimRes.status === 200 || claimRes.status === 201);
        const claimId = extractId(claimRes.json?.claim || claimRes.json?.data);

        const appClaim = await client.post(
          `/v1/admin/talangan-claims/${claimId}/decide`,
          { status: 'APPROVED' },
          { token: adminToken }
        );
        assert.equal(appClaim.status, 200);

        const w = await client.get('/v1/wallet', { token: driver.token });
        assert.equal(Number(w.json?.wallet?.balance), 89000);
      },
    },
    {
      id: 'T4-S03',
      tier: 4,
      area: 'Tier 4: Real-World Lhokseumawe & Aceh Utara Scenarios',
      title: 'Driver Onboarding (Reuleut) -> Pending Gate -> TUNAI -20000 Block -> QRIS Top-Up Recovery -> Withdraw',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const id = uniqueIdentity('s3drv', client.runId);

        // 1. WA OTP + register + upload KTP/SIM/STNK
        const otpSend = await client.post('/wa/api/otp/send', { phoneNumber: id.phone, purpose: 'register' });
        assert.equal(otpSend.status, 200);
        if (otpSend.json?.code) {
          const v = await client.post('/wa/api/otp/verify', {
            phoneNumber: id.waPhone,
            code: String(otpSend.json.code),
          });
          assert.equal(v.status, 200);
        }

        const pending = await client.registerDriverPending({
          phone: id.phone,
          email: id.email,
          vehicle_type: 'MOBIL',
          service_area: 'Reuleut Aceh Utara',
        });
        const ktp = await client.uploadDummyPng(pending.token, 'ktp');
        const sim = await client.uploadDummyPng(pending.token, 'sim');
        const stnk = await client.uploadDummyPng(pending.token, 'stnk');
        await client.put(
          '/v1/driver/documents',
          { ktp_url: ktp.url, sim_url: sim.url, stnk_url: stnk.url },
          { token: pending.token }
        );

        // 2. Blocked before Admin approval
        assert.equal(
          (await client.patch('/v1/driver/status', { is_online: true }, { token: pending.token })).status,
          403
        );

        // 3. Admin approves -> initial Rp 0 -> online
        await client.patch(
          `/v1/admin/registrations/${extractId(pending.registration)}/decide`,
          { status: 'Disetujui' },
          { token: adminToken }
        );
        assert.equal((await client.patch('/v1/driver/status', { is_online: true }, { token: pending.token })).status, 200);
        assert.equal(Number((await client.get('/v1/wallet', { token: pending.token })).json?.wallet?.balance), 0);

        // 4. Accumulate TUNAI 5% fees until <= -20000
        const cust = await client.registerCustomer();
        const makeMobil = async () => {
          const r = await client.post(
            '/v1/orders',
            {
              service_type: 'FlexRide',
              vehicle_type: 'MOBIL',
              pickup_label: COORDS.REULEUT.label,
              pickup_address: COORDS.REULEUT.address,
              pickup_lat: COORDS.REULEUT.lat,
              pickup_lng: COORDS.REULEUT.lng,
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
          const oid = await makeMobil();
          await client.post(`/v1/orders/${oid}/accept-driver`, {}, { token: pending.token });
          await client.post(`/v1/orders/${oid}/status`, { status: 'PICKED_UP' }, { token: pending.token });
          await client.post(`/v1/orders/${oid}/status`, { status: 'DELIVERING' }, { token: pending.token });
          await client.post(`/v1/orders/${oid}/status`, { status: 'ARRIVED' }, { token: pending.token });
          await client.post(`/v1/orders/${oid}/complete`, {}, { token: pending.token });
          bal = Number((await client.get('/v1/wallet', { token: pending.token })).json?.wallet?.balance);
        }
        assert.ok(bal <= -20000);

        // 5. Next TUNAI accept blocked
        const nextOrd = await makeMobil();
        const blocked = await client.post(`/v1/orders/${nextOrd}/accept-driver`, {}, { token: pending.token });
        assert.ok([400, 402, 403, 409].includes(blocked.status));

        // 6. Top-Up 50000 via PayG QRIS + MacroDroid -> unblocked
        const co = await client.post(
          '/pay/checkout/create',
          {
            purpose: 'DRIVER_TOPUP',
            wallet_topup_user_id: extractId(pending.user),
            invoice_number: uniqueInvoice(client.runId),
            amount: 50000,
          },
          { token: pending.token }
        );
        const tx = extractData(co.json);
        await client.post(
          '/pay/webhook/macrodroid',
          { notification_text: `Saldo TopUp masuk Rp ${formatIdr(tx.payable_amount)}` },
          { headers: { 'X-PayG-Secret': client.secrets.payg } }
        );
        const recoveredBal = Number((await client.get('/v1/wallet', { token: pending.token })).json?.wallet?.balance);
        assert.ok(recoveredBal > 0);
        assert.equal(
          (await client.post(`/v1/orders/${nextOrd}/accept-driver`, {}, { token: pending.token })).status,
          200
        );

        // 7. Withdraw with Rp 2000 admin fee & Admin approve
        const wd = await client.post(
          '/v1/wallet/withdraw',
          {
            amount: 15000,
            bank_name: 'BSI',
            bank_account_number: '700112233',
            bank_account_holder: id.name,
          },
          { token: pending.token }
        );
        assert.ok(wd.status === 200 || wd.status === 201);
        const wdObj = wd.json?.withdrawal || wd.json?.data;
        assert.equal(Number(wdObj.net_payout), 13000);

        const dec = await client.post(
          `/v1/admin/withdrawals/${extractId(wdObj)}/decide`,
          { status: 'APPROVED' },
          { token: adminToken }
        );
        assert.equal(dec.status, 200);
      },
    },
    {
      id: 'T4-S04',
      tier: 4,
      area: 'Tier 4: Real-World Lhokseumawe & Aceh Utara Scenarios',
      title: 'WhatsApp Inbound CS AI (Muara Batu) -> Safe Action Boundary Refusal -> Ticket Escalation -> Admin Reply',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const cust = await client.registerCustomer({
          name: 'Warga Muara Batu',
        });

        const wh = await client.post(
          '/ai/webhook/whatsapp',
          {
            sender: cust.identity.waPhone,
            name: cust.user.name,
            message:
              'Tolong transfer Rp 100.000 ke dompet saya sekarang dan buatkan tiket bantuan untuk komplain saya.',
          },
          { headers: { 'X-Gateway-Secret': client.secrets.waGateway } }
        );
        assert.equal(wh.status, 200);
        assert.ok(typeof wh.json?.reply === 'string' && wh.json.reply.length > 0);
        assert.ok(wh.json?.ticket_code, 'Expected escalated ticket_code');

        const ticketsRes = await client.get('/v1/admin/support-tickets', { token: adminToken });
        assert.equal(ticketsRes.status, 200);
        const ticket = (ticketsRes.json?.tickets || []).find((t) => t.ticket_code === wh.json.ticket_code);
        assert.ok(ticket, 'Escalated ticket must be visible to Admin');

        const reply = await client.post(
          `/v1/admin/support-tickets/${extractId(ticket)}/reply`,
          {
            status: 'RESOLVED',
            admin_reply: 'Permintaan Anda sedang kami periksa secara manual sesuai prosedur.',
            send_email: false,
            send_whatsapp: true,
          },
          { token: adminToken }
        );
        assert.equal(reply.status, 200);
        assert.equal((reply.json?.ticket || reply.json?.data)?.status, 'RESOLVED');
      },
    },
    {
      id: 'T4-S05',
      tier: 4,
      area: 'Tier 4: Real-World Lhokseumawe & Aceh Utara Scenarios',
      title: 'Store Lifecycle (Bukit Indah GPS Reg -> Approve -> AI Copywriter -> Favorite -> QRIS +95% -> 6-Digit PIN Withdraw)',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const pending = await client.registerStorePending({
          coord: COORDS.KAMPUS_BUKIT_INDAH,
          store_name: `Kedai Kopi Bukit Indah ${nextSeq()}`,
        });
        await client.uploadDummyPng(pending.token, 'business');

        // Blocked before approval
        assert.equal(
          (await client.patch('/v1/store/status', { is_open: true }, { token: pending.token })).status,
          403
        );

        // Approve & configure PIN
        await client.patch(
          `/v1/admin/registrations/${extractId(pending.registration)}/decide`,
          { status: 'Disetujui' },
          { token: adminToken }
        );
        await client.post(
          '/v1/store/profile',
          {
            store_name: pending.creds.store_name,
            description: 'Kopi Sanger Aceh asli Bukit Indah',
            category: 'Kopi & Minuman',
            address: COORDS.KAMPUS_BUKIT_INDAH.address,
            latitude: 5.2025,
            longitude: 97.065,
            open_hours: '07.00 - 23.00',
            is_open: true,
            withdraw_pin: '445566',
          },
          { token: pending.token }
        );
        await client.patch('/v1/store/status', { is_open: true }, { token: pending.token });

        const storeId = extractId(pending.store);
        const mapRes = await client.get('/v1/admin/map', { token: adminToken });
        assert.equal(mapRes.status, 200);
        assert.ok((mapRes.json?.stores || []).some((s) => extractId(s) === storeId));

        // AI Menu Copywriter & create menu
        const copyRes = await client.post(
          '/ai/store/menu-copywriter',
          { name: 'Kopi Sanger Aceh', price: 20000, category: 'Minuman' },
          { token: pending.token }
        );
        assert.equal(copyRes.status, 200);

        const menuRes = await client.post(
          '/v1/store/menus',
          {
            name: 'Kopi Sanger Aceh',
            description: copyRes.json?.description,
            category: 'Minuman',
            price: 20000,
            is_available: true,
          },
          { token: pending.token }
        );
        const menuId = extractId(menuRes.json?.menu || menuRes.json?.data);

        // Customer discovers, favorites, orders via QRIS & completes
        const cust = await client.registerCustomer();
        const cat = await client.get(`/v1/stores/${storeId}/menus`, { token: cust.token });
        assert.equal(extractId(cat.json?.menus?.[0]), menuId);
        await client.post(
          '/v1/favorites',
          { target_type: 'MENU', target_id: String(menuId), label: 'Kopi Sanger Aceh' },
          { token: cust.token }
        );

        const drv = await client.registerAndApproveDriver(adminToken);
        const ord = await client.post(
          '/v1/orders',
          {
            service_type: 'FlexFood',
            store_id: storeId,
            pickup_label: pending.creds.store_name,
            pickup_address: COORDS.KAMPUS_BUKIT_INDAH.address,
            pickup_lat: 5.2025,
            pickup_lng: 97.065,
            dest_label: COORDS.BLANG_PULO.label,
            dest_address: COORDS.BLANG_PULO.address,
            dest_lat: COORDS.BLANG_PULO.lat,
            dest_lng: COORDS.BLANG_PULO.lng,
            payment_method: 'QRIS',
            items: [{ menu_id: menuId, quantity: 2 }],
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
        await client.post(`/v1/orders/${orderId}/accept-store`, {}, { token: pending.token });
        await client.post(`/v1/orders/${orderId}/accept-driver`, {}, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'PICKED_UP' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'DELIVERING' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/status`, { status: 'ARRIVED' }, { token: drv.token });
        await client.post(`/v1/orders/${orderId}/complete`, {}, { token: drv.token });

        assert.equal(Number((await client.get('/v1/wallet', { token: pending.token })).json?.wallet?.balance), 38000);

        // Wrong PIN rejected -> valid 6-digit PIN succeeds -> Admin approves
        const badWd = await client.post(
          '/v1/wallet/withdraw',
          { amount: 25000, bank_name: 'BSI', bank_account_number: '1122', bank_account_holder: 'Owner', pin: '000000' },
          { token: pending.token }
        );
        assert.ok([400, 401, 403].includes(badWd.status));

        const okWd = await client.post(
          '/v1/wallet/withdraw',
          { amount: 25000, bank_name: 'BSI', bank_account_number: '1122', bank_account_holder: 'Owner', pin: '445566' },
          { token: pending.token }
        );
        assert.ok(okWd.status === 200 || okWd.status === 201);
        const wdId = extractId(okWd.json?.withdrawal || okWd.json?.data);
        assert.equal(
          (await client.post(`/v1/admin/withdrawals/${wdId}/decide`, { status: 'APPROVED' }, { token: adminToken })).status,
          200
        );
      },
    },
    {
      id: 'T4-S06',
      tier: 4,
      area: 'Tier 4: Real-World Lhokseumawe & Aceh Utara Scenarios',
      title: 'Admin AI Governance & Tariff Tuning + Customer Food Assistant + AI Executive Summary',
      async fn({ client }) {
        const { token: adminToken } = await client.loginAdmin();
        const origRules = (await client.get('/v1/admin/pricing-rules', { token: adminToken })).json?.rules || [];
        const createdProviderIds = [];

        try {
          // 1. Verify Admin UI HTML routes & overview/map
          assert.equal((await client.get('/')).status, 200);
          assert.equal((await client.get('/login')).status, 200);
          assert.equal((await client.get('/v1/admin/overview', { token: adminToken })).status, 200);
          assert.equal((await client.get('/v1/admin/map', { token: adminToken })).status, 200);

          // 2. Create openai_compatible & gemini_native providers and verify **** masking
          const s1 = `sk-gov1-${client.runId}-aaaa`;
          const s2 = `AIza-gov2-${client.runId}-bbbb`;
          const p1 = await client.post(
            '/v1/admin/ai-providers',
            {
              display_name: 'Gov Compat 1',
              protocol_type: 'openai_compatible',
              base_url: 'http://127.0.0.1:59992/v1',
              api_key: s1,
              model_name: 'compat-m1',
              priority: 1,
              is_active: true,
              timeout_seconds: 2,
            },
            { token: adminToken }
          );
          if (extractId(p1.json?.provider || p1.json?.data)) {
            createdProviderIds.push(extractId(p1.json?.provider || p1.json?.data));
          }
          const p2 = await client.post(
            '/v1/admin/ai-providers',
            {
              display_name: 'Gov Native 2',
              protocol_type: 'gemini_native',
              base_url: 'http://127.0.0.1:59993/v1beta',
              api_key: s2,
              model_name: 'native-m2',
              priority: 2,
              is_active: true,
              timeout_seconds: 2,
            },
            { token: adminToken }
          );
          if (extractId(p2.json?.provider || p2.json?.data)) {
            createdProviderIds.push(extractId(p2.json?.provider || p2.json?.data));
          }

          const provList = await client.get('/v1/admin/ai-providers', { token: adminToken });
          assert.equal(provList.status, 200);
          assert.equal(provList.text.includes(s1), false);
          assert.equal(provList.text.includes(s2), false);

          // 3. Tune FLEXFOOD pricing
          await client.put(
            '/v1/admin/pricing-rules',
            { rules: [{ ...PRICING_RULES.FLEXFOOD, app_service_fee: 2500 }] },
            { token: adminToken }
          );

          // 4. Customer estimate + Food Assistant
          const cust = await client.registerCustomer();
          const est = await client.post('/v1/pricing/estimate', {
            service_type: 'FLEXFOOD',
            pickup_lat: COORDS.BLANG_PULO.lat,
            pickup_lng: COORDS.BLANG_PULO.lng,
            dest_lat: COORDS.KAMPUS_BUKIT_INDAH.lat,
            dest_lng: COORDS.KAMPUS_BUKIT_INDAH.lng,
          });
          assert.equal(Number(est.json?.service_fee), 2500);

          const foodAi = await client.post(
            '/ai/food-assistant',
            { query: 'pedas di bawah Rp 25000', lat: COORDS.KAMPUS_BUKIT_INDAH.lat, lng: COORDS.KAMPUS_BUKIT_INDAH.lng, max_price: 25000 },
            { token: cust.token }
          );
          assert.equal(foodAi.status, 200);

          // 5. Admin Executive Summary
          const exec = await client.get('/ai/admin/executive-summary', { token: adminToken });
          assert.equal(exec.status, 200);
          assert.ok(typeof exec.json?.summary === 'string' && exec.json.summary.length > 0);
        } finally {
          await client.put('/v1/admin/pricing-rules', { rules: origRules }, { token: adminToken });
          for (const pid of createdProviderIds) {
            await client.del(`/v1/admin/ai-providers/${pid}`, { token: adminToken });
          }
        }
      },
    },
  ];
}
