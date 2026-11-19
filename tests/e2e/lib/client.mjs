import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {
  COORDS,
  DEFAULT_ADMIN_CREDS,
  DEFAULT_SECRETS,
  DEFAULT_TIMEOUT_MS,
  VALID_1X1_PNG_BYTES,
} from './fixtures.mjs';

let globalSeq = 0;

export function createRunId() {
  return `${Date.now().toString(36)}_${crypto.randomBytes(3).toString('hex')}`;
}

export function nextSeq() {
  globalSeq += 1;
  return globalSeq;
}

export function uniqueIdentity(role = 'user', runId = 'e2e') {
  const seq = nextSeq();
  const numTail = String(Date.now()).slice(-6) + String(seq).padStart(3, '0');
  const phone = `0812${numTail.slice(-8)}`;
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const suffix =
    letters[seq % 26] + letters[(seq * 7) % 26] + letters[(seq * 13) % 26];
  return {
    seq,
    name: `E2E ${role} ${runId} #${seq}`,
    email: `e2e_${role}_${runId}_${seq}@rideons.test`,
    phone,
    waPhone: `62${phone.slice(1)}`,
    password: `RideOn!${seq}Pass99`,
    plateNumber: `BL ${1000 + (seq % 8999)} ${suffix}`,
  };
}

export function uniqueInvoice(runId = 'e2e') {
  const seq = nextSeq();
  return `INV-E2E-${String(runId).toUpperCase()}-${seq}`;
}

export function formatIdr(amount) {
  const n = Math.trunc(Number(amount));
  const sign = n < 0 ? '-' : '';
  const digits = String(Math.abs(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${sign}${digits}`;
}

export function decodeJwtPayload(token) {
  assert.equal(typeof token, 'string', 'JWT token must be a string');
  const parts = token.split('.');
  assert.equal(parts.length, 3, 'JWT must have 3 dot-separated segments');
  const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
  const padded = b64.padEnd(Math.ceil(b64.length / 4) * 4, '=');
  return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
}

export function crc16CcittFalse(input) {
  let crc = 0xffff;
  for (let i = 0; i < input.length; i++) {
    crc ^= (input.charCodeAt(i) & 0xff) << 8;
    for (let bit = 0; bit < 8; bit++) {
      if (crc & 0x8000) {
        crc = ((crc << 1) ^ 0x1021) & 0xffff;
      } else {
        crc = (crc << 1) & 0xffff;
      }
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

export function parseEmvcoTlv(payload) {
  assert.equal(typeof payload, 'string', 'QRIS payload must be a string');
  const tags = {};
  let idx = 0;
  while (idx + 4 <= payload.length) {
    const tag = payload.slice(idx, idx + 2);
    const lenStr = payload.slice(idx + 2, idx + 4);
    const len = Number.parseInt(lenStr, 10);
    if (Number.isNaN(len) || len < 0 || idx + 4 + len > payload.length) {
      throw new Error(`Invalid EMVCo TLV at offset ${idx} (tag=${tag}, len=${lenStr})`);
    }
    const val = payload.slice(idx + 4, idx + 4 + len);
    tags[tag] = val;
    idx += 4 + len;
  }
  assert.equal(idx, payload.length, `Trailing unparsed bytes in EMVCo QRIS (${idx} != ${payload.length})`);
  return tags;
}

export function verifyDynamicQris(qrString, expectedPayableAmount) {
  assert.equal(typeof qrString, 'string', 'qr_string must be a string');
  assert.ok(qrString.length >= 20, 'qr_string too short');
  assert.equal(qrString.slice(-8, -4), '6304', 'QRIS must terminate with Tag 63 length 04');

  const computedCrc = crc16CcittFalse(qrString.slice(0, -4));
  const actualCrc = qrString.slice(-4);
  assert.equal(
    actualCrc,
    computedCrc,
    `QRIS CRC-16/CCITT-FALSE mismatch: expected ${computedCrc}, got ${actualCrc}`
  );

  const tags = parseEmvcoTlv(qrString);
  assert.equal(tags['00'], '01', 'EMVCo Tag 00 Payload Format Indicator must be "01"');
  assert.equal(tags['01'], '12', 'EMVCo Tag 01 Point of Initiation must be "12" (Dynamic)');
  assert.equal(tags['53'], '360', 'EMVCo Tag 53 Currency Code must be "360" (IDR)');
  assert.equal(tags['58'], 'ID', 'EMVCo Tag 58 Country Code must be "ID"');
  assert.equal(
    tags['54'],
    String(expectedPayableAmount),
    `EMVCo Tag 54 Transaction Amount mismatch: expected ${expectedPayableAmount}, got ${tags['54']}`
  );
  return tags;
}

export async function runConcurrent(fns) {
  return Promise.all(fns.map((fn) => fn()));
}

export function extractData(body, ...candidateKeys) {
  if (!body || typeof body !== 'object') return body;
  for (const key of candidateKeys) {
    if (body[key] !== undefined && body[key] !== null) return body[key];
  }
  if (body.data && typeof body.data === 'object') {
    for (const key of candidateKeys) {
      if (body.data[key] !== undefined && body.data[key] !== null) return body.data[key];
    }
    return body.data;
  }
  return body;
}

export function extractId(obj) {
  if (obj === null || obj === undefined) return undefined;
  if (typeof obj === 'number' || typeof obj === 'string') return obj;
  return obj.id ?? obj.order_id ?? obj.store_id ?? obj.driver_id ?? obj.user_id;
}

export function createClient({
  baseUrl,
  secrets = DEFAULT_SECRETS,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  runId = createRunId(),
}) {
  const normalizedBase = baseUrl.replace(/\/+$/, '');
  const state = {
    adminToken: null,
    adminUser: null,
  };

  async function request(
    method,
    path,
    { token = null, headers = {}, body = undefined, isMultipart = false, rawBody = undefined } = {}
  ) {
    const url = path.startsWith('http') ? path : `${normalizedBase}${path.startsWith('/') ? '' : '/'}${path}`;
    const reqHeaders = { ...headers };
    if (token) {
      reqHeaders.Authorization = `Bearer ${token}`;
    }

    let payload;
    if (rawBody !== undefined) {
      payload = rawBody;
    } else if (isMultipart) {
      payload = body;
    } else if (body !== undefined) {
      if (!reqHeaders['Content-Type'] && !reqHeaders['content-type']) {
        reqHeaders['Content-Type'] = 'application/json';
      }
      payload = typeof body === 'string' ? body : JSON.stringify(body);
    }

    const res = await fetch(url, {
      method,
      headers: reqHeaders,
      body: payload,
      signal: AbortSignal.timeout(timeoutMs),
    });

    const buf = Buffer.from(await res.arrayBuffer());
    const text = buf.toString('utf8');
    let json = null;
    try {
      json = JSON.parse(text);
    } catch {
      json = null;
    }

    return {
      status: res.status,
      ok: res.ok,
      headers: res.headers,
      buffer: buf,
      text,
      json,
      url,
    };
  }

  const get = (path, opts) => request('GET', path, opts);
  const post = (path, body, opts = {}) => request('POST', path, { ...opts, body });
  const put = (path, body, opts = {}) => request('PUT', path, { ...opts, body });
  const patch = (path, body, opts = {}) => request('PATCH', path, { ...opts, body });
  const del = (path, opts) => request('DELETE', path, opts);

  async function loginAdmin(creds = DEFAULT_ADMIN_CREDS, { force = false } = {}) {
    if (!force && state.adminToken) {
      return { token: state.adminToken, user: state.adminUser };
    }
    const res = await post('/v1/auth/login', {
      identifier: creds.email,
      password: creds.password,
      role: 'admin',
    });
    assert.equal(res.status, 200, `Admin login failed (${res.status}): ${res.text}`);
    const token = res.json?.token || res.json?.data?.token;
    const user = res.json?.user || res.json?.data?.user;
    assert.ok(token, 'Admin login response missing token');
    const claims = decodeJwtPayload(token);
    assert.equal(claims.role, 'admin', 'Admin JWT role claim must be "admin"');
    state.adminToken = token;
    state.adminUser = user;
    return { token, user };
  }

  async function uploadDummyPng(token, category = 'ktp') {
    const form = new FormData();
    const seq = nextSeq();
    form.append('category', category);
    form.append(
      'file',
      new Blob([VALID_1X1_PNG_BYTES], { type: 'image/png' }),
      `${category}_${runId}_${seq}.png`
    );
    const res = await request('POST', '/v1/upload', {
      token,
      body: form,
      isMultipart: true,
    });
    assert.ok(
      res.status === 200 || res.status === 201,
      `Upload PNG failed (${res.status}): ${res.text}`
    );
    const url = res.json?.url || res.json?.data?.url;
    assert.ok(typeof url === 'string' && url.includes('/uploads/'), `Unexpected upload url: ${res.text}`);
    return { url, res };
  }

  async function registerCustomer(overrides = {}) {
    const id = uniqueIdentity('cust', runId);
    const payload = {
      name: id.name,
      email: id.email,
      phone: id.phone,
      password: id.password,
      role: 'customer',
      ...overrides,
    };
    const res = await post('/v1/auth/register', payload);
    assert.ok(
      res.status === 200 || res.status === 201,
      `registerCustomer failed (${res.status}): ${res.text}`
    );
    const token = res.json?.token || res.json?.data?.token;
    const user = res.json?.user || res.json?.data?.user;
    assert.ok(token, 'registerCustomer missing token');
    return { token, user, creds: payload, identity: id, res };
  }

  async function registerDriverPending(overrides = {}) {
    const id = uniqueIdentity('drv', runId);
    const payload = {
      name: id.name,
      email: id.email,
      phone: id.phone,
      password: id.password,
      role: 'driver',
      vehicle_type: overrides.vehicle_type || 'MOTOR',
      vehicle_brand: overrides.vehicle_brand || 'Honda Beat',
      plate_number: overrides.plate_number || id.plateNumber,
      service_area: overrides.service_area || 'Lhokseumawe',
      cash_capital_limit: overrides.cash_capital_limit ?? 200000,
      ...overrides,
    };
    const res = await post('/v1/auth/register', payload);
    assert.ok(
      res.status === 200 || res.status === 201,
      `registerDriverPending failed (${res.status}): ${res.text}`
    );
    const token = res.json?.token || res.json?.data?.token;
    const user = res.json?.user || res.json?.data?.user;
    const driver = res.json?.driver || res.json?.data?.driver;
    const registration = res.json?.registration || res.json?.data?.registration;
    return { token, user, driver, registration, creds: payload, identity: id, res };
  }

  async function registerAndApproveDriver(adminToken, opts = {}) {
    const {
      uploadDocs = false,
      goOnline = true,
      vehicleType = 'MOTOR',
      cashCapitalLimit = 200000,
      ...rest
    } = opts;

    const reg = await registerDriverPending({
      vehicle_type: vehicleType,
      cash_capital_limit: cashCapitalLimit,
      ...rest,
    });

    if (uploadDocs) {
      const ktp = await uploadDummyPng(reg.token, 'ktp');
      const sim = await uploadDummyPng(reg.token, 'sim');
      const stnk = await uploadDummyPng(reg.token, 'stnk');
      const docRes = await put(
        '/v1/driver/documents',
        {
          ktp_url: ktp.url,
          sim_url: sim.url,
          stnk_url: stnk.url,
          vehicle_type: vehicleType,
        },
        { token: reg.token }
      );
      assert.equal(docRes.status, 200, `Driver documents update failed: ${docRes.text}`);
    }

    const regId = extractId(reg.registration);
    assert.ok(regId, 'Driver registration ID missing');
    const decideRes = await patch(
      `/v1/admin/registrations/${regId}/decide`,
      { status: 'Disetujui', review_notes: 'E2E auto-approved' },
      { token: adminToken }
    );
    assert.equal(decideRes.status, 200, `Approve driver failed: ${decideRes.text}`);

    if (goOnline) {
      const onlineRes = await patch(
        '/v1/driver/status',
        { is_online: true, cash_capital_limit: cashCapitalLimit },
        { token: reg.token }
      );
      assert.equal(onlineRes.status, 200, `Driver goOnline failed: ${onlineRes.text}`);
    }

    const meRes = await get('/v1/me', { token: reg.token });
    assert.equal(meRes.status, 200, `Driver /v1/me failed: ${meRes.text}`);
    return {
      ...reg,
      user: meRes.json?.user || reg.user,
      driver: meRes.json?.driver || reg.driver,
      wallet: meRes.json?.wallet,
    };
  }

  async function registerStorePending(overrides = {}) {
    const id = uniqueIdentity('store', runId);
    const coord = overrides.coord || COORDS.BLANG_PULO;
    const payload = {
      name: id.name,
      email: id.email,
      phone: id.phone,
      password: id.password,
      role: 'store',
      store_name: overrides.store_name || `Warung E2E ${id.seq}`,
      owner_name: overrides.owner_name || id.name,
      store_category: overrides.store_category || 'Makanan & Minuman',
      store_address: overrides.store_address || coord.address,
      store_lat: overrides.store_lat ?? coord.lat,
      store_lng: overrides.store_lng ?? coord.lng,
      service_area: overrides.service_area || 'Lhokseumawe',
      ...overrides,
    };
    delete payload.coord;
    const res = await post('/v1/auth/register', payload);
    assert.ok(
      res.status === 200 || res.status === 201,
      `registerStorePending failed (${res.status}): ${res.text}`
    );
    const token = res.json?.token || res.json?.data?.token;
    const user = res.json?.user || res.json?.data?.user;
    const store = res.json?.store || res.json?.data?.store;
    const registration = res.json?.registration || res.json?.data?.registration;
    return { token, user, store, registration, creds: payload, identity: id, res };
  }

  async function registerAndApproveStore(adminToken, opts = {}) {
    const {
      pin = '123456',
      openStore = true,
      createMenu = true,
      menuPrice = 20000,
      menuName = null,
      uploadDoc = false,
      ...rest
    } = opts;

    const reg = await registerStorePending(rest);
    if (uploadDoc) {
      await uploadDummyPng(reg.token, 'business');
    }

    const regId = extractId(reg.registration);
    assert.ok(regId, 'Store registration ID missing');
    const decideRes = await patch(
      `/v1/admin/registrations/${regId}/decide`,
      { status: 'Disetujui', review_notes: 'E2E store approved' },
      { token: adminToken }
    );
    assert.equal(decideRes.status, 200, `Approve store failed: ${decideRes.text}`);

    if (pin) {
      const profRes = await post(
        '/v1/store/profile',
        {
          store_name: reg.creds.store_name,
          description: 'Warung E2E Lhokseumawe',
          category: reg.creds.store_category,
          address: reg.creds.store_address,
          postal_code: '24352',
          latitude: reg.creds.store_lat,
          longitude: reg.creds.store_lng,
          open_hours: '08.00 - 22.00',
          is_open: openStore,
          withdraw_pin: pin,
        },
        { token: reg.token }
      );
      assert.equal(profRes.status, 200, `Update store profile/PIN failed: ${profRes.text}`);
    }

    if (openStore) {
      const stRes = await patch('/v1/store/status', { is_open: true }, { token: reg.token });
      assert.equal(stRes.status, 200, `Open store failed: ${stRes.text}`);
    }

    let menu = null;
    if (createMenu) {
      const mRes = await post(
        '/v1/store/menus',
        {
          name: menuName || `Mie Aceh E2E ${reg.identity.seq}`,
          description: 'Mie Aceh spesial rempah pilihan',
          category: 'Makanan Utama',
          price: menuPrice,
          is_available: true,
        },
        { token: reg.token }
      );
      assert.ok(
        mRes.status === 200 || mRes.status === 201,
        `Create initial menu failed: ${mRes.text}`
      );
      menu = mRes.json?.menu || mRes.json?.data?.menu || mRes.json?.data;
    }

    const meRes = await get('/v1/me', { token: reg.token });
    assert.equal(meRes.status, 200, `Store /v1/me failed: ${meRes.text}`);
    return {
      ...reg,
      user: meRes.json?.user || reg.user,
      store: meRes.json?.store || reg.store,
      wallet: meRes.json?.wallet,
      menu,
      pin,
    };
  }

  return {
    baseUrl: normalizedBase,
    runId,
    secrets,
    state,
    request,
    get,
    post,
    put,
    patch,
    del,
    loginAdmin,
    uploadDummyPng,
    registerCustomer,
    registerDriverPending,
    registerAndApproveDriver,
    registerStorePending,
    registerAndApproveStore,
  };
}
