"use client";

import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import Image from "next/image";
import dynamic from "next/dynamic";
import { useRouter } from "next/navigation";

type View =
  | "overview"
  | "map"
  | "registrations"
  | "orders"
  | "drivers"
  | "stores"
  | "customers"
  | "finance"
  | "settings";

type OrderStatus = "Berjalan" | "Menunggu" | "Selesai" | "Dibatalkan";
type RegistrationStatus = "Menunggu verifikasi" | "Disetujui" | "Ditolak";
type DetailField = { label: string; value: string };
type DetailView = { category: string; title: string; subtitle: string; fields: DetailField[] };
type Order = {
  id: string;
  orderCode: string;
  customer: string;
  service: string;
  driver: string;
  date: string;
  amount: number;
  status: OrderStatus;
  rawStatus: string;
  pickup: string;
  destination: string;
  payment: string;
};
type OrderFilter = "Semua" | OrderStatus;
type Registration = {
  id: string;
  name: string;
  kind: "Customer" | "Driver" | "Toko";
  submitted: string;
  contact: string;
  area: string;
  status: RegistrationStatus;
  fields: DetailField[];
};
type MapLocation = {
  id: string;
  name: string;
  kind: "driver" | "store";
  city: string;
  status: string;
  latitude: number;
  longitude: number;
  detail: string;
};
type DirectoryPerson = {
  id: string;
  name: string;
  detail: string;
  status: string;
  date: string;
  fields: DetailField[];
};
type WithdrawalRow = {
  id: string;
  owner_type: string;
  requester_name: string;
  amount: number;
  admin_fee: number;
  net_amount: number;
  bank_name: string;
  bank_account_number: string;
  bank_account_holder: string;
  status: string;
  created_at: string;
};
type TalanganClaimRow = {
  id: string;
  order_id: string;
  order_code: string;
  driver_id: string;
  driver_name: string;
  claimed_amount: number;
  goods_photo_url: string;
  receipt_photo_url: string;
  status: string;
  orphanage_name: string;
  donation_photo_url: string;
  created_at: string;
};
type QRISTxRow = {
  id: string;
  reference_id: string;
  purpose: string;
  user_name: string;
  amount: number;
  status: string;
  expires_at: string;
  paid_at: string | null;
};
type WalletTxRow = {
  id: string;
  owner_type: string;
  tx_type: string;
  amount: number;
  balance_before: number;
  balance_after: number;
  reference_id: string;
  description: string;
  created_at: string;
};
type AIProviderRow = {
  id: string;
  display_name: string;
  adapter_type: string;
  base_url: string;
  has_api_key: boolean;
  api_key_masked: string;
  model_name: string;
  system_prompt: string;
  temperature: number;
  max_tokens: number;
  priority_order: number;
  is_active: boolean;
};
type PricingRuleRow = {
  id: string;
  service_type: string;
  base_fare: number;
  per_km_fare: number;
  min_fare: number;
  driver_commission_pct: number;
  store_commission_pct: number;
  platform_fee_fixed: number;
};
type SupportTicketRow = {
  id: string;
  user_name: string;
  channel: string;
  sender_contact: string;
  subject: string;
  body: string;
  status: string;
  admin_reply: string;
  created_at: string;
};

type IconName =
  | "overview"
  | "map"
  | "plus"
  | "orders"
  | "driver"
  | "store"
  | "customer"
  | "finance"
  | "settings"
  | "route"
  | "search"
  | "arrowRight"
  | "arrowUpRight"
  | "check"
  | "info";

function Icon({ name, className, size = 18 }: { name: IconName; className?: string; size?: number }) {
  const drawings: Record<IconName, ReactNode> = {
    overview: (
      <>
        <rect x="3" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="3" y="14" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </>
    ),
    map: (
      <>
        <path d="m3 6 6-3 6 3 6-3v15l-6 3-6-3-6 3z" />
        <path d="M9 3v15M15 6v15" />
      </>
    ),
    plus: <path d="M12 5v14M5 12h14" />,
    orders: (
      <>
        <path d="M8 6h13M8 12h13M8 18h13" />
        <path d="M3 6h.01M3 12h.01M3 18h.01" />
      </>
    ),
    driver: (
      <>
        <circle cx="12" cy="8" r="4" />
        <path d="M5 21a7 7 0 0 1 14 0" />
      </>
    ),
    store: (
      <>
        <path d="M3 10h18l-1.4-6H4.4z" />
        <path d="M5 10v10h14V10M9 20v-6h6v6" />
        <path d="M3 10a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0" />
      </>
    ),
    customer: (
      <>
        <circle cx="9" cy="8" r="3.5" />
        <path d="M2.5 20a6.5 6.5 0 0 1 13 0M16 5.5a3.5 3.5 0 0 1 0 6.8M17.5 14a5.5 5.5 0 0 1 4 5" />
      </>
    ),
    finance: (
      <>
        <rect x="2" y="5" width="20" height="14" rx="2" />
        <path d="M2 10h20M6 15h4" />
      </>
    ),
    settings: (
      <>
        <circle cx="12" cy="12" r="3" />
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.26.6.85 1 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
      </>
    ),
    route: (
      <>
        <circle cx="6" cy="18" r="2.5" />
        <circle cx="18" cy="6" r="2.5" />
        <path d="M8.5 18h2a3 3 0 0 0 3-3v-3a3 3 0 0 1 3-3h1" />
      </>
    ),
    search: (
      <>
        <circle cx="10.8" cy="10.8" r="6.8" />
        <path d="m16 16 5 5" />
      </>
    ),
    arrowRight: <path d="M5 12h14M13 6l6 6-6 6" />,
    arrowUpRight: <path d="M7 17 17 7M8 7h9v9" />,
    check: <path d="m5 12 4 4L19 6" />,
    info: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M12 11v5M12 8h.01" />
      </>
    ),
  };

  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {drawings[name]}
    </svg>
  );
}

const OpenStreetMap = dynamic(() => import("@/components/open-street-map"), {
  ssr: false,
  loading: () => <div className="map-loading">Memuat peta OpenStreetMap…</div>,
});

const orderFilters: OrderFilter[] = ["Semua", "Menunggu", "Berjalan", "Selesai", "Dibatalkan"];
const registrationFilters: ("Semua" | RegistrationStatus)[] = ["Semua", "Menunggu verifikasi", "Disetujui", "Ditolak"];

const navigation: { id: View; label: string; icon: IconName }[] = [
  { id: "overview", label: "Ringkasan", icon: "overview" },
  { id: "map", label: "Peta Aktif", icon: "map" },
  { id: "registrations", label: "Pendaftaran Baru", icon: "plus" },
  { id: "orders", label: "Pesanan", icon: "orders" },
  { id: "drivers", label: "Driver", icon: "driver" },
  { id: "stores", label: "Toko", icon: "store" },
  { id: "customers", label: "Customer", icon: "customer" },
  { id: "finance", label: "Keuangan & QRIS", icon: "finance" },
  { id: "settings", label: "Pengaturan AI & Tarif", icon: "settings" },
];

const titleFor: Record<View, string> = {
  overview: "Ringkasan",
  map: "Peta Aktif",
  registrations: "Pendaftaran Baru",
  orders: "Pesanan",
  drivers: "Driver",
  stores: "Toko",
  customers: "Customer",
  finance: "Keuangan & QRIS",
  settings: "Pengaturan AI & Tarif",
};

const rupiah = (value: number) =>
  new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(value || 0);

function mapOrderStatus(raw: string): OrderStatus {
  const s = (raw || "").toUpperCase();
  if (s === "COMPLETED") return "Selesai";
  if (s === "CANCELLED") return "Dibatalkan";
  if (s === "CREATED" || s === "WAITING_STORE_CONFIRM" || s === "SEARCHING_DRIVER") return "Menunggu";
  return "Berjalan";
}

function mapRegStatus(raw: string): RegistrationStatus {
  const s = (raw || "").toUpperCase();
  if (s === "APPROVED") return "Disetujui";
  if (s === "REJECTED") return "Ditolak";
  return "Menunggu verifikasi";
}

function formatDateID(iso: string) {
  if (!iso) return "-";
  try {
    return new Intl.DateTimeFormat("id-ID", {
      day: "numeric",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

export default function Dashboard() {
  const router = useRouter();
  const [token, setToken] = useState<string>("");
  const [adminUserId, setAdminUserId] = useState<string>("00000000-0000-4000-8000-000000000001");
  const [adminName, setAdminName] = useState<string>("Admin RideOn");
  const [authChecked, setAuthChecked] = useState(false);

  const [view, setView] = useState<View>("overview");
  const [search, setSearch] = useState("");
  const [orderFilter, setOrderFilter] = useState<OrderFilter>("Semua");
  const [registrationFilter, setRegistrationFilter] = useState<(typeof registrationFilters)[number]>("Semua");
  const [selectedRegistrationId, setSelectedRegistrationId] = useState("");
  const [registrationNotice, setRegistrationNotice] = useState("");
  const [today, setToday] = useState("Tanggal lokal");
  const [detail, setDetail] = useState<DetailView | null>(null);
  const closeDetailRef = useRef<HTMLButtonElement>(null);
  const returnFocusRef = useRef<HTMLElement | null>(null);

  // Live states from MySQL API
  const [overviewMetrics, setOverviewMetrics] = useState<Record<string, number>>({});
  const [mapLocations, setMapLocations] = useState<MapLocation[]>([]);
  const [registrations, setRegistrations] = useState<Registration[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [driversList, setDriversList] = useState<DirectoryPerson[]>([]);
  const [storesList, setStoresList] = useState<DirectoryPerson[]>([]);
  const [customersList, setCustomersList] = useState<DirectoryPerson[]>([]);

  // Finance states
  const [withdrawals, setWithdrawals] = useState<WithdrawalRow[]>([]);
  const [talanganClaims, setTalanganClaims] = useState<TalanganClaimRow[]>([]);
  const [qrisTxs, setQrisTxs] = useState<QRISTxRow[]>([]);
  const [walletTxs, setWalletTxs] = useState<WalletTxRow[]>([]);

  // Settings & AI states
  const [aiProviders, setAiProviders] = useState<AIProviderRow[]>([]);
  const [pricingRules, setPricingRules] = useState<PricingRuleRow[]>([]);
  const [sysSettings, setSysSettings] = useState<Record<string, string>>({});
  const [supportTickets, setSupportTickets] = useState<SupportTicketRow[]>([]);
  const [waStatus, setWaStatus] = useState<{ status?: string; paired?: boolean; sandbox?: boolean }>({});

  useEffect(() => {
    const savedToken = window.localStorage.getItem("rideon_admin_token") || "";
    const savedUser = window.localStorage.getItem("rideon_admin_user");
    if (!savedToken) {
      router.replace("/login");
      return;
    }
    if (savedUser) {
      try {
        const parsed = JSON.parse(savedUser);
        if (parsed?.name) setAdminName(parsed.name);
        if (parsed?.id) setAdminUserId(parsed.id);
      } catch {
        // ignore
      }
    }
    setToken(savedToken);
    setAuthChecked(true);
  }, [router]);

  const fetchAllAdminData = useCallback(async (jwt: string) => {
    if (!jwt) return;
    const headers = { Authorization: `Bearer ${jwt}`, "Content-Type": "application/json" };
    try {
      const [ovRes, mapRes, regRes, ordRes, drvRes, stRes, custRes, finRes, setRes, prRes, aiRes, tktRes, waRes] =
        await Promise.all([
          fetch("/v1/admin/overview", { headers }),
          fetch("/v1/admin/map", { headers }),
          fetch("/v1/admin/registrations", { headers }),
          fetch("/v1/admin/orders", { headers }),
          fetch("/v1/admin/drivers", { headers }),
          fetch("/v1/admin/stores", { headers }),
          fetch("/v1/admin/customers", { headers }),
          fetch("/v1/admin/finance", { headers }),
          fetch("/v1/admin/settings", { headers }),
          fetch("/v1/admin/pricing-rules", { headers }),
          fetch("/ai/providers"),
          fetch("/v1/support-tickets"),
          fetch("/wa/status"),
        ]);

      if (ovRes.status === 401) {
        window.localStorage.removeItem("rideon_admin_token");
        router.replace("/login");
        return;
      }

      if (ovRes.ok) {
        const d = await ovRes.json();
        setOverviewMetrics(d.metrics || {});
      }
      if (mapRes.ok) {
        const d = await mapRes.json();
        setMapLocations(d.points || []);
      }
      if (regRes.ok) {
        const d = await regRes.json();
        const mapped: Registration[] = (d.registrations || []).map((r: Record<string, unknown>) => {
          const role = String(r.applicant_role || "DRIVER");
          const kind: "Customer" | "Driver" | "Toko" =
            role === "STORE" ? "Toko" : role === "CUSTOMER" ? "Customer" : "Driver";
          const payload = (r.payload as Record<string, unknown>) || {};
          const area = String(payload.area || payload.address || "Lhokseumawe & Aceh Utara");
          const fields: DetailField[] = [
            { label: "ID pendaftaran", value: String(r.id) },
            { label: "Jenis akun", value: kind },
            { label: "Nama", value: String(r.name || "-") },
            { label: "Email", value: String(r.email || "-") },
            { label: "Nomor WhatsApp", value: String(r.phone || "-") },
            { label: "Area", value: area },
          ];
          Object.entries(payload).forEach(([k, v]) => {
            fields.push({ label: k.replace(/_/g, " ").toUpperCase(), value: String(v) });
          });
          return {
            id: String(r.id),
            name: String(r.name || "-"),
            kind,
            submitted: formatDateID(String(r.created_at || "")),
            contact: String(r.email || r.phone || "-"),
            area,
            status: mapRegStatus(String(r.status || "PENDING")),
            fields,
          };
        });
        setRegistrations(mapped);
        setSelectedRegistrationId((prev) => prev || mapped[0]?.id || "");
      }
      if (ordRes.ok) {
        const d = await ordRes.json();
        const mapped: Order[] = (d.orders || []).map((o: Record<string, unknown>) => ({
          id: String(o.id),
          orderCode: String(o.order_code || o.id),
          customer: String(o.customer_name || "Pelanggan"),
          service: String(o.service_type || "RIDE_MOTOR"),
          driver: String(o.driver_name || "Menunggu driver"),
          date: formatDateID(String(o.created_at || "")),
          amount: Number(o.total_customer_pay || 0),
          status: mapOrderStatus(String(o.status || "")),
          rawStatus: String(o.status || ""),
          pickup: String(o.pickup_address || "-"),
          destination: String(o.dropoff_address || "-"),
          payment: `${o.payment_method || "CASH"} (${o.payment_status || "UNPAID"})`,
        }));
        setOrders(mapped);
      }
      if (drvRes.ok) {
        const d = await drvRes.json();
        const mapped: DirectoryPerson[] = (d.drivers || []).map((dr: Record<string, unknown>) => ({
          id: String(dr.id),
          name: String(dr.name || "-"),
          detail: `${dr.vehicle_type} · ${dr.vehicle_brand} (${dr.vehicle_plate})`,
          status: dr.user_status !== "ACTIVE" ? String(dr.user_status) : dr.is_online ? "Online" : "Offline",
          date: formatDateID(String(dr.created_at || "")),
          fields: [
            { label: "ID Driver", value: String(dr.id) },
            { label: "Status Akun", value: String(dr.user_status) },
            { label: "Kendaraan", value: `${dr.vehicle_type} · ${dr.vehicle_brand}` },
            { label: "Plat Nomor", value: String(dr.vehicle_plate) },
            { label: "Email / WA", value: `${dr.email || "-"} / ${dr.phone || "-"}` },
            { label: "Nomor KTP / SIM", value: `${dr.ktp_number || "-"} / ${dr.sim_number || "-"}` },
            { label: "Modal Kas FlexSend", value: rupiah(Number(dr.cash_float_amount || 0)) },
            { label: "Saldo Dompet", value: rupiah(Number(dr.wallet_balance || 0)) },
            { label: "Rating & Trip", value: `★${dr.rating_avg} (${dr.total_trips} trip)` },
          ],
        }));
        setDriversList(mapped);
      }
      if (stRes.ok) {
        const d = await stRes.json();
        const mapped: DirectoryPerson[] = (d.stores || []).map((st: Record<string, unknown>) => ({
          id: String(st.id),
          name: String(st.store_name || "-"),
          detail: `${st.category} · ${st.address}`,
          status: st.user_status !== "ACTIVE" ? String(st.user_status) : st.is_open ? "Buka" : "Tutup",
          date: formatDateID(String(st.created_at || "")),
          fields: [
            { label: "ID Toko", value: String(st.id) },
            { label: "Pemilik", value: String(st.owner_name || "-") },
            { label: "Kategori", value: String(st.category) },
            { label: "Alamat", value: String(st.address) },
            { label: "Koordinat GPS", value: `${st.lat}, ${st.lng}` },
            { label: "Jam Operasional", value: `${st.open_time} – ${st.close_time}` },
            { label: "Jumlah Menu", value: `${st.menu_count} menu` },
            { label: "Saldo Dompet Toko", value: rupiah(Number(st.wallet_balance || 0)) },
            { label: "Rating", value: `★${st.rating_avg}` },
          ],
        }));
        setStoresList(mapped);
      }
      if (custRes.ok) {
        const d = await custRes.json();
        const mapped: DirectoryPerson[] = (d.customers || []).map((c: Record<string, unknown>) => ({
          id: String(c.id),
          name: String(c.name || "-"),
          detail: `${c.email || "-"} · ${c.phone || "-"}`,
          status: c.status === "ACTIVE" ? "Aktif" : String(c.status),
          date: formatDateID(String(c.created_at || "")),
          fields: [
            { label: "ID Customer", value: String(c.id) },
            { label: "Status Akun", value: String(c.status) },
            { label: "Email", value: String(c.email || "-") },
            { label: "Nomor WhatsApp", value: String(c.phone || "-") },
            { label: "Total Pesanan", value: `${c.order_count || 0} pesanan` },
            { label: "Saldo Dompet", value: rupiah(Number(c.wallet_balance || 0)) },
          ],
        }));
        setCustomersList(mapped);
      }
      if (finRes.ok) {
        const d = await finRes.json();
        setWithdrawals(d.withdrawals || []);
        setTalanganClaims(d.talangan_claims || []);
        setQrisTxs(d.qris_transactions || []);
        setWalletTxs(d.wallet_transactions || []);
      }
      if (setRes.ok) {
        const d = await setRes.json();
        setSysSettings(d.settings || {});
      }
      if (prRes.ok) {
        const d = await prRes.json();
        setPricingRules(d.pricing_rules || []);
      }
      if (aiRes.ok) {
        const d = await aiRes.json();
        setAiProviders(d.providers || []);
      }
      if (tktRes.ok) {
        const d = await tktRes.json();
        setSupportTickets(d.support_tickets || []);
      }
      if (waRes.ok) {
        const d = await waRes.json();
        setWaStatus(d || {});
      }
    } catch {
      // ignore transient network errors
    }
  }, [router]);

  useEffect(() => {
    if (authChecked && token) {
      fetchAllAdminData(token);
    }
  }, [authChecked, token, fetchAllAdminData]);

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => {
      setToday(
        new Intl.DateTimeFormat("id-ID", {
          weekday: "long",
          day: "numeric",
          month: "long",
          year: "numeric",
          timeZone: "Asia/Jakarta",
        }).format(new Date())
      );
    });
    return () => window.cancelAnimationFrame(frame);
  }, []);

  useEffect(() => {
    if (!detail) return;
    const previousFocus = returnFocusRef.current;
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") setDetail(null);
    }
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    document.addEventListener("keydown", onKeyDown);
    closeDetailRef.current?.focus();
    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = previousOverflow;
      previousFocus?.focus();
    };
  }, [detail]);

  function handleLogout() {
    window.localStorage.removeItem("rideon_admin_token");
    window.localStorage.removeItem("rideon_admin_user");
    router.replace("/login");
  }

  function go(next: View) {
    setView(next);
    setSearch("");
    setOrderFilter("Semua");
    setRegistrationFilter("Semua");
    setRegistrationNotice("");
  }

  function openDetail(next: DetailView) {
    returnFocusRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    setDetail(next);
  }

  function openOrderDetail(order: Order) {
    openDetail({
      category: "DETAIL PESANAN MYSQL",
      title: order.orderCode,
      subtitle: `${order.service} · ${order.date}`,
      fields: [
        { label: "ID Pesanan", value: order.id },
        { label: "Kode Pesanan", value: order.orderCode },
        { label: "Status", value: `${order.status} (${order.rawStatus})` },
        { label: "Layanan", value: order.service },
        { label: "Customer", value: order.customer },
        { label: "Driver", value: order.driver },
        { label: "Lokasi jemput", value: order.pickup },
        { label: "Tujuan", value: order.destination },
        { label: "Pembayaran", value: order.payment },
        { label: "Total", value: rupiah(order.amount) },
      ],
    });
  }

  function openPersonDetail(kind: "drivers" | "stores" | "customers", person: DirectoryPerson) {
    const category = kind === "drivers" ? "MITRA DRIVER" : kind === "stores" ? "MITRA TOKO" : "PELANGGAN RIDEON";
    openDetail({ category, title: person.name, subtitle: person.detail, fields: person.fields });
  }

  const pendingRegistrationCount = registrations.filter((r) => r.status === "Menunggu verifikasi").length;
  const activeOrderCount = orders.filter((o) => o.status === "Berjalan" || o.status === "Menunggu").length;
  const filteredRegistrations = registrations.filter((registration) => {
    const matchesStatus = registrationFilter === "Semua" || registration.status === registrationFilter;
    const query = search.trim().toLowerCase();
    return (
      matchesStatus &&
      (!query ||
        [registration.id, registration.name, registration.kind, registration.contact, registration.area].some((value) =>
          value.toLowerCase().includes(query)
        ))
    );
  });
  const selectedRegistration =
    filteredRegistrations.find((registration) => registration.id === selectedRegistrationId) ??
    filteredRegistrations[0] ??
    null;

  async function decideRegistration(id: string, status: RegistrationStatus) {
    const applicant = registrations.find((registration) => registration.id === id);
    if (!applicant) return;
    const action = status === "Disetujui" ? "approve" : "reject";
    try {
      const res = await fetch(`/v1/admin/registrations/${id}/${action}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({ reason: "Ditinjau oleh Super Admin melalui Web Admin Dashboard" }),
      });
      if (res.ok) {
        setRegistrationNotice(`${applicant.name} berhasil ditandai "${status}" dan tersimpan permanen di MySQL rideon_db.`);
        await fetchAllAdminData(token);
      }
    } catch {
      setRegistrationNotice(`Gagal memperbarui status pendaftaran ${applicant.name}.`);
    }
  }

  if (!authChecked) {
    return <main className="login-shell"><div className="login-card"><p>Memuat sesi Administrator RideOn…</p></div></main>;
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <a
          className="brand"
          href="#ringkasan"
          onClick={(event) => {
            event.preventDefault();
            go("overview");
          }}
          aria-label="RideOn Admin, ringkasan"
        >
          <span className="brand-symbol">
            <Image src="/logo_white.png" alt="" width={50} height={34} priority />
          </span>
          <span className="brand-name">
            ride<span>on</span>
            <small>ADMIN</small>
          </span>
        </a>
        <div className="side-caption">PUSAT OPERASIONAL</div>
        <nav className="side-nav" aria-label="Menu utama">
          {navigation.map((item) => (
            <button
              key={item.id}
              type="button"
              className={`nav-link ${view === item.id ? "is-active" : ""}`}
              aria-pressed={view === item.id}
              onClick={() => go(item.id)}
            >
              <span className="nav-icon-wrap">
                <Icon name={item.icon} className="nav-glyph" />
              </span>
              <span>{item.label}</span>
              {item.id === "orders" && <span className="nav-count">{activeOrderCount}</span>}
              {item.id === "map" && <span className="nav-count">{mapLocations.length}</span>}
              {item.id === "registrations" && <span className="nav-count">{pendingRegistrationCount}</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="workspace-card">
            <span className="workspace-icon">R</span>
            <div>
              <strong>RideOn Lhokseumawe</strong>
              <small>MySQL rideon_db · Live</small>
            </div>
          </div>
          <div className="profile">
            <span className="profile-avatar">A</span>
            <div>
              <strong>{adminName}</strong>
              <small>admin@rideons.app</small>
            </div>
            <button type="button" className="logout-btn" onClick={handleLogout} aria-label="Keluar dari akun Admin">
              Keluar
            </button>
          </div>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div className="breadcrumbs">
            <span>RideOn</span>
            <span className="crumb-separator">/</span>
            <strong>{titleFor[view]}</strong>
          </div>
          <div className="topbar-end">
            <span className="live-chip">
              <i /> TERHUBUNG MYSQL &amp; API
            </span>
            <span className="topbar-divider" />
            <time className="topbar-date">{today}</time>
            <span className="topbar-avatar">
              <Image src="/logo_primary.png" alt="RideOn" width={34} height={26} />
            </span>
          </div>
        </header>

        <div className="content-wrap">
          <section className="page-intro">
            <div>
              <div className="overline">PUSAT KENDALI EKOSISTEM</div>
              <h1>{view === "overview" ? `Halo, ${adminName}` : titleFor[view]}</h1>
              <p>
                {view === "overview"
                  ? "Pantau metrik real-time pesanan, mitra driver, mitra warung, dan komisi platform."
                  : view === "map"
                  ? "Sebaran titik koordinat GPS mitra driver dan toko di Lhokseumawe & Aceh Utara."
                  : view === "registrations"
                  ? "Verifikasi pendaftaran mitra Driver dan Toko baru di database MySQL."
                  : view === "finance"
                  ? "Kelola pencairan saldo (Withdraw), klaim talangan donasi panti asuhan, dan transaksi QRIS payG."
                  : view === "settings"
                  ? "Konfigurasi provider AI universal (AES-256-GCM), rumus tarif ongkir, komisi 5%:5%, dan tiket CS."
                  : `Kelola dan pantau data ${titleFor[view].toLowerCase()} RideOn secara langsung.`}
              </p>
            </div>
            {["registrations", "orders", "drivers", "stores", "customers"].includes(view) && (
              <label className="search-field">
                <Icon name="search" size={17} />
                <input
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder={`Cari ${titleFor[view].toLowerCase()}...`}
                  aria-label={`Cari ${titleFor[view].toLowerCase()}`}
                />
                {search && (
                  <button type="button" onClick={() => setSearch("")} aria-label="Hapus pencarian">
                    ×
                  </button>
                )}
              </label>
            )}
          </section>

          {view === "overview" ? (
            <Overview
              adminUserId={adminUserId}
              metricsData={overviewMetrics}
              orders={orders}
              driversCount={driversList.length}
              onlineDriversCount={driversList.filter((d) => d.status === "Online").length}
              storesCount={storesList.length}
              openStoresCount={storesList.filter((s) => s.status === "Buka").length}
              customersCount={customersList.length}
              onNavigate={go}
              onSelectOrder={openOrderDetail}
            />
          ) : view === "map" ? (
            <ActiveMap
              locations={mapLocations}
              token={token}
              onLocationsUpdate={setMapLocations}
            />
          ) : view === "registrations" ? (
            <RegistrationPage
              rows={filteredRegistrations}
              allRows={registrations}
              filter={registrationFilter}
              filters={registrationFilters}
              selected={selectedRegistration}
              notice={registrationNotice}
              onFilter={setRegistrationFilter}
              onSelect={(id) => {
                setSelectedRegistrationId(id);
                setRegistrationNotice("");
              }}
              onDecision={decideRegistration}
              onNoticeDismiss={() => setRegistrationNotice("")}
            />
          ) : view === "finance" ? (
            <FinancePage
              token={token}
              withdrawals={withdrawals}
              talanganClaims={talanganClaims}
              qrisTxs={qrisTxs}
              walletTxs={walletTxs}
              staticQris={sysSettings.payg_static_qris || ""}
              onRefresh={() => fetchAllAdminData(token)}
            />
          ) : view === "settings" ? (
            <SettingsPage
              token={token}
              providers={aiProviders}
              pricingRules={pricingRules}
              settings={sysSettings}
              tickets={supportTickets}
              waStatus={waStatus}
              onRefresh={() => fetchAllAdminData(token)}
            />
          ) : (
            <Directory
              view={view as "orders" | "drivers" | "stores" | "customers"}
              orders={orders}
              drivers={driversList}
              stores={storesList}
              customers={customersList}
              search={search}
              orderFilter={orderFilter}
              onOrderFilter={setOrderFilter}
              onSelectOrder={openOrderDetail}
              onSelectPerson={openPersonDetail}
            />
          )}

          <footer className="footer">
            <span>RideOn Admin · Lhokseumawe &amp; Aceh Utara</span>
            <span>Terhubung ke MySQL rideon_db, PayG QRIS Engine, Universal AI Service, &amp; WhatsApp Gateway.</span>
          </footer>
        </div>
      </main>
      {detail && <DetailModal detail={detail} closeButtonRef={closeDetailRef} onClose={() => setDetail(null)} />}
    </div>
  );
}

function Overview({
  adminUserId,
  metricsData,
  orders,
  driversCount,
  onlineDriversCount,
  storesCount,
  openStoresCount,
  customersCount,
  onNavigate,
  onSelectOrder,
}: {
  adminUserId: string;
  metricsData: Record<string, number>;
  orders: Order[];
  driversCount: number;
  onlineDriversCount: number;
  storesCount: number;
  openStoresCount: number;
  customersCount: number;
  onNavigate: (view: View) => void;
  onSelectOrder: (order: Order) => void;
}) {
  const [aiLoading, setAiLoading] = useState(false);
  const [aiSummary, setAiSummary] = useState("");
  const [aiProvider, setAiProvider] = useState("");

  async function generateExecutiveSummary() {
    setAiLoading(true);
    try {
      const res = await fetch("/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          session_id: `admin-exec-${new Date().toISOString().slice(0, 10)}`,
          user_id: adminUserId,
          app_role: "ADMIN",
          message:
            "Buatkan ringkasan eksekutif operasional RideOn Lhokseumawe hari ini berdasarkan data aktual (pesanan, GMV, pendaftaran pending, penarikan saldo, klaim talangan, serta rekomendasi prioritas tindakan Admin).",
        }),
      });
      const data = await res.json();
      setAiSummary(
        data.reply ||
          "Ringkasan AI tidak tersedia saat ini. Pastikan provider AI aktif di Pengaturan."
      );
      setAiProvider(String(data.provider_used || "ai-service"));
    } catch {
      setAiSummary(
        "Gagal menghubungi layanan Universal AI Service. Periksa status container ai-service."
      );
      setAiProvider("offline");
    } finally {
      setAiLoading(false);
    }
  }

  const activeOrders = metricsData.active_orders ?? orders.filter((o) => o.status === "Berjalan" || o.status === "Menunggu").length;
  const metrics: { label: string; value: string; sub: string; view: View; style: string; icon: IconName }[] = [
    {
      label: "Pesanan aktif",
      value: String(activeOrders).padStart(2, "0"),
      sub: `dari ${orders.length} total pesanan`,
      view: "orders",
      style: "violet",
      icon: "route",
    },
    {
      label: "Driver online",
      value: String(onlineDriversCount).padStart(2, "0"),
      sub: `dari ${driversCount} mitra driver`,
      view: "drivers",
      style: "mint",
      icon: "driver",
    },
    {
      label: "Toko beroperasi",
      value: String(openStoresCount).padStart(2, "0"),
      sub: `dari ${storesCount} mitra warung`,
      view: "stores",
      style: "amber",
      icon: "store",
    },
    {
      label: "Customer",
      value: String(customersCount).padStart(2, "0"),
      sub: `Pendapatan Komisi: ${rupiah(metricsData.platform_revenue || 0)}`,
      view: "customers",
      style: "blue",
      icon: "customer",
    },
  ];
  return (
    <>
      <section className="metric-grid" aria-label="Ringkasan metrik operasional">
        {metrics.map((metric) => (
          <button
            key={metric.label}
            type="button"
            className={`metric-card metric-${metric.style}`}
            onClick={() => onNavigate(metric.view)}
          >
            <span className="metric-label">
              {metric.label}
              <span className="metric-mark">
                <Icon name={metric.icon} size={19} />
              </span>
            </span>
            <strong>{metric.value}</strong>
            <span className="metric-sub">{metric.sub}</span>
          </button>
        ))}
      </section>

      <section className="panel ai-summary-panel" aria-label="AI Executive Summary">
        <div className="panel-head">
          <div>
            <h2>AI Executive Summary</h2>
            <p>Analisis operasional real-time dari MySQL rideon_db oleh Asisten AI Admin</p>
          </div>
          <div className="ai-summary-actions">
            {aiProvider && <span className="ai-provider-chip">Provider: {aiProvider}</span>}
            <button
              type="button"
              className="btn-secondary ai-summary-btn"
              onClick={generateExecutiveSummary}
              disabled={aiLoading}
            >
              {aiLoading ? "Menyusun ringkasan..." : "Buat Ringkasan AI Hari Ini"}
            </button>
          </div>
        </div>
        {aiSummary && <div className="ai-summary-body">{aiSummary}</div>}
      </section>

      <section className="overview-grid">
        <div className="panel activity-panel">
          <div className="panel-head">
            <div>
              <h2>Aktivitas pesanan &amp; antrean</h2>
              <p>Volume operasional Lhokseumawe &amp; Aceh Utara</p>
            </div>
            <span className="period-label">Live · rideon_db</span>
          </div>
          <div className="chart-legend">
            <span>
              <i />
              Pesanan dibuat ({orders.length})
            </span>
            <span className="legend-muted">
              <i />
              Pendaftaran menunggu ({metricsData.pending_registrations || 0})
            </span>
          </div>
          <div className="chart-area" role="img" aria-label="Grafik aktivitas pesanan selama tujuh hari">
            <div className="chart-y">
              <span>40</span>
              <span>30</span>
              <span>20</span>
              <span>10</span>
              <span>0</span>
            </div>
            <svg viewBox="0 0 700 205" preserveAspectRatio="none" aria-hidden="true">
              <defs>
                <linearGradient id="areaFill" x1="0" x2="0" y1="0" y2="1">
                  <stop offset="0" stopColor="#7048ef" stopOpacity=".16" />
                  <stop offset="1" stopColor="#7048ef" stopOpacity="0" />
                </linearGradient>
              </defs>
              <path className="grid-line" d="M0 12H700M0 56H700M0 100H700M0 144H700M0 188H700" />
              <path
                className="chart-fill"
                d="M0 142 C36 132 58 145 100 126 S160 112 200 125 S260 96 300 104 S360 73 400 91 S460 104 500 66 S560 85 600 52 S660 47 700 24 V188 H0Z"
              />
              <path
                className="chart-line"
                d="M0 142 C36 132 58 145 100 126 S160 112 200 125 S260 96 300 104 S360 73 400 91 S460 104 500 66 S560 85 600 52 S660 47 700 24"
              />
              <path
                className="chart-line chart-line-muted"
                d="M0 165 C40 159 60 161 100 153 S160 148 200 155 S260 135 300 141 S360 125 400 138 S460 145 500 117 S560 135 600 106 S660 117 700 91"
              />
              <circle className="chart-point" cx="700" cy="24" r="4" />
            </svg>
            <div className="chart-x">
              <span>Jum</span>
              <span>Sab</span>
              <span>Min</span>
              <span>Sen</span>
              <span>Sel</span>
              <span>Rab</span>
              <span>Kam</span>
            </div>
          </div>
        </div>

        <div className="panel service-panel">
          <div className="panel-head">
            <div>
              <h2>Komposisi layanan</h2>
              <p>Distribusi layanan ekosistem</p>
            </div>
            <button className="quiet-button" onClick={() => onNavigate("orders")}>
              Lihat pesanan
            </button>
          </div>
          <div className="donut-wrap">
            <div
              className="donut"
              role="img"
              aria-label="Komposisi layanan: FlexRide, FlexFood, dan FlexSend"
            >
              <div>
                <strong>{String(orders.length).padStart(2, "0")}</strong>
                <span>total order</span>
              </div>
            </div>
          </div>
          <div className="service-legend">
            <div>
              <span className="legend-dot ride" />
              <span>FlexRide (Motor &amp; Mobil)</span>
              <strong>50%</strong>
            </div>
            <div>
              <span className="legend-dot food" />
              <span>FlexFood (Kuliner)</span>
              <strong>30%</strong>
            </div>
            <div>
              <span className="legend-dot send" />
              <span>FlexSend (Titip Beli)</span>
              <strong>20%</strong>
            </div>
          </div>
        </div>
      </section>

      <section className="panel table-panel overview-table">
        <div className="panel-head">
          <div>
            <h2>Pesanan terbaru</h2>
            <p>Daftar transaksi terbaru dari database MySQL</p>
          </div>
          <button type="button" className="quiet-button" onClick={() => onNavigate("orders")}>
            Semua pesanan <Icon name="arrowRight" size={15} />
          </button>
        </div>
        <OrderTable rows={orders.slice(0, 5)} onSelect={onSelectOrder} />
      </section>
    </>
  );
}

function ActiveMap({
  locations,
  token,
  onLocationsUpdate,
}: {
  locations: MapLocation[];
  token: string;
  onLocationsUpdate: (updater: (prev: MapLocation[]) => MapLocation[]) => void;
}) {
  const [showDrivers, setShowDrivers] = useState(true);
  const [showStores, setShowStores] = useState(true);
  const [selectedId, setSelectedId] = useState(locations[0]?.id || "");
  const [liveSource, setLiveSource] = useState<"rtdb" | "polling">("polling");

  useEffect(() => {
    let es: EventSource | null = null;
    const rtdbBase = (process.env.NEXT_PUBLIC_FIREBASE_DATABASE_URL || "").replace(/\/+$/, "");

    if (rtdbBase && typeof EventSource !== "undefined") {
      try {
        es = new EventSource(`${rtdbBase}/driver_locations.json`);
        const applyRtdbSnapshot = (raw: string) => {
          const parsed = JSON.parse(raw) as { path?: string; data?: Record<string, Record<string, unknown>> | null };
          const payload = parsed?.data ?? parsed;
          if (!payload || typeof payload !== "object") return;
          setLiveSource("rtdb");
          onLocationsUpdate((prev) => {
            const stores = prev.filter((loc) => loc.kind === "store");
            const existingDrivers = new Map(prev.filter((loc) => loc.kind === "driver").map((d) => [d.id, d]));
            Object.entries(payload as Record<string, Record<string, unknown>>).forEach(([key, val]) => {
              if (!val || typeof val !== "object") return;
              const lat = Number(val.lat);
              const lng = Number(val.lng);
              if (!Number.isFinite(lat) || !Number.isFinite(lng)) return;
              const id = String(val.driver_id || key);
              existingDrivers.set(id, {
                id,
                name: String(val.name || existingDrivers.get(id)?.name || "Driver RideOn"),
                kind: "driver",
                city: "Lhokseumawe",
                status: val.is_online === false ? "Offline" : "Online",
                latitude: lat,
                longitude: lng,
                detail: `${String(val.vehicle_type || "MOTOR")} · ${String(val.vehicle_plate || "Live RTDB")}`,
              });
            });
            return [...Array.from(existingDrivers.values()), ...stores];
          });
        };
        es.addEventListener("put", (evt) => {
          try {
            applyRtdbSnapshot((evt as MessageEvent).data);
          } catch {
            // keep polling fallback
          }
        });
        es.addEventListener("patch", (evt) => {
          try {
            applyRtdbSnapshot((evt as MessageEvent).data);
          } catch {
            // keep polling fallback
          }
        });
        es.onerror = () => {
          setLiveSource("polling");
          es?.close();
        };
      } catch {
        setLiveSource("polling");
      }
    }

    const pollTimer = window.setInterval(async () => {
      if (!token) return;
      try {
        const res = await fetch("/v1/admin/map", {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          const data = await res.json();
          if (Array.isArray(data.points)) {
            onLocationsUpdate(() => data.points as MapLocation[]);
          }
        }
      } catch {
        // ignore transient polling failure
      }
    }, 10000);

    return () => {
      window.clearInterval(pollTimer);
      es?.close();
    };
  }, [token, onLocationsUpdate]);

  const visibleLocations = locations.filter((location) => (location.kind === "driver" ? showDrivers : showStores));
  const selected = visibleLocations.find((location) => location.id === selectedId) ?? visibleLocations[0] ?? null;
  const driverCount = visibleLocations.filter((location) => location.kind === "driver").length;
  const storeCount = visibleLocations.filter((location) => location.kind === "store").length;

  return (
    <section className="map-page">
      <div className="map-toolbar panel">
        <div className="map-summary">
          <span className="map-summary-mark">
            <Icon name="map" size={19} />
          </span>
          <div>
            <strong>Sebaran aktivitas Lhokseumawe &amp; Aceh Utara</strong>
            <small>{locations.length} titik koordinat aktif di sekitar Bukit Indah, Blang Pulo, Reuleut, dan Muara Batu</small>
          </div>
        </div>
        <div className="map-filters" aria-label="Filter lokasi peta">
          <button
            type="button"
            className={`map-filter driver-filter ${showDrivers ? "filter-on" : ""}`}
            aria-pressed={showDrivers}
            onClick={() => setShowDrivers((value) => !value)}
          >
            <i />
            Driver aktif<span>{driverCount}</span>
          </button>
          <button
            type="button"
            className={`map-filter store-filter ${showStores ? "filter-on" : ""}`}
            aria-pressed={showStores}
            onClick={() => setShowStores((value) => !value)}
          >
            <i />
            Toko buka<span>{storeCount}</span>
          </button>
        </div>
      </div>

      <div className="map-layout">
        <div className="map-panel panel">
          <div className="map-panel-heading">
            <div>
              <h2>Peta Operasional OpenStreetMap</h2>
              <p>Area Lhokseumawe dan Aceh Utara · Data MySQL &amp; RTDB</p>
            </div>
            <span className="live-chip">
              <i />
              {liveSource === "rtdb" ? "Firebase RTDB Live" : "Polling MySQL 10d"}
            </span>
          </div>
          <div className="map-stage">
            {visibleLocations.length ? (
              <OpenStreetMap points={visibleLocations} selectedId={selected?.id ?? null} onSelect={setSelectedId} />
            ) : (
              <div className="map-empty">Pilih Driver aktif atau Toko buka untuk menampilkan lokasi.</div>
            )}
          </div>
          <div className="map-legend">
            <span>
              <i className="legend-driver" />
              Driver
            </span>
            <span>
              <i className="legend-store" />
              Toko
            </span>
            <span className="map-location-note">OpenStreetMap Lhokseumawe</span>
          </div>
        </div>

        <aside className="map-side panel">
          <div className="map-side-heading">
            <div>
              <h2>Aktif di peta</h2>
              <p>{visibleLocations.length} titik lokasi</p>
            </div>
            <span className="map-side-total">{String(visibleLocations.length).padStart(2, "0")}</span>
          </div>
          {selected && (
            <div className="selected-location">
              <div className={`selected-icon ${selected.kind === "driver" ? "selected-driver" : "selected-store"}`}>
                {selected.kind === "driver" ? "D" : "T"}
              </div>
              <div>
                <span>
                  {selected.kind === "driver" ? "DRIVER" : "TOKO"} · {selected.city.toUpperCase()}
                </span>
                <strong>{selected.name}</strong>
                <small>{selected.detail}</small>
              </div>
              <Status status={selected.status} />
            </div>
          )}
          <div className="location-list">
            {visibleLocations.map((location) => (
              <button
                key={location.id}
                type="button"
                className={`location-row ${selected?.id === location.id ? "location-selected" : ""}`}
                onClick={() => setSelectedId(location.id)}
              >
                <span className={`location-symbol ${location.kind === "driver" ? "symbol-driver" : "symbol-store"}`}>
                  {location.kind === "driver" ? "D" : "T"}
                </span>
                <span className="location-copy">
                  <strong>{location.name}</strong>
                  <small>{location.city}</small>
                </span>
                <span className="location-status">
                  <i className={location.kind === "driver" ? "" : "store-live"} />
                  {location.status}
                </span>
              </button>
            ))}
          </div>
        </aside>
      </div>
    </section>
  );
}

function RegistrationPage({
  rows,
  allRows,
  filter,
  filters,
  selected,
  notice,
  onFilter,
  onSelect,
  onDecision,
  onNoticeDismiss,
}: {
  rows: Registration[];
  allRows: Registration[];
  filter: "Semua" | RegistrationStatus;
  filters: ("Semua" | RegistrationStatus)[];
  selected: Registration | null;
  notice: string;
  onFilter: (filter: "Semua" | RegistrationStatus) => void;
  onSelect: (id: string) => void;
  onDecision: (id: string, status: RegistrationStatus) => void;
  onNoticeDismiss: () => void;
}) {
  const counts = {
    pending: allRows.filter((row) => row.status === "Menunggu verifikasi").length,
    approved: allRows.filter((row) => row.status === "Disetujui").length,
    rejected: allRows.filter((row) => row.status === "Ditolak").length,
  };

  return (
    <section className="registration-page">
      <div className="registration-metrics" aria-label="Ringkasan pendaftaran mitra">
        <div className="registration-metric pending-metric">
          <span>Menunggu tinjauan</span>
          <strong>{String(counts.pending).padStart(2, "0")}</strong>
          <small>Pendaftaran mitra baru</small>
        </div>
        <div className="registration-metric approved-metric">
          <span>Disetujui</span>
          <strong>{String(counts.approved).padStart(2, "0")}</strong>
          <small>Mitra aktif terverifikasi</small>
        </div>
        <div className="registration-metric rejected-metric">
          <span>Ditolak</span>
          <strong>{String(counts.rejected).padStart(2, "0")}</strong>
          <small>Berkas tidak memenuhi syarat</small>
        </div>
      </div>
      {notice && (
        <div className={`registration-notice ${notice.includes("Ditolak") ? "notice-rejected" : ""}`} role="status">
          <span>
            <Icon name="check" size={14} />
          </span>
          <p>{notice}</p>
          <button type="button" aria-label="Tutup notifikasi" onClick={onNoticeDismiss}>
            ×
          </button>
        </div>
      )}
      <div className="registration-layout">
        <section className="panel table-panel registration-list-panel">
          <div className="panel-head">
            <div>
              <h2>Antrean pendaftaran</h2>
              <p>Pilih pendaftar untuk meninjau berkas</p>
            </div>
            <span className="row-count">{rows.length} pendaftaran</span>
          </div>
          <div className="registration-filters" aria-label="Filter status pendaftaran">
            {filters.map((item) => (
              <button
                type="button"
                key={item}
                className={filter === item ? "registration-filter-active" : ""}
                aria-pressed={filter === item}
                onClick={() => onFilter(item)}
              >
                {item}
              </button>
            ))}
          </div>
          <div className="registration-list">
            {rows.length ? (
              rows.map((row) => (
                <button
                  type="button"
                  key={row.id}
                  className={`registration-row ${selected?.id === row.id ? "registration-row-selected" : ""}`}
                  onClick={() => onSelect(row.id)}
                >
                  <span className={`registration-avatar registration-avatar-${row.kind.toLowerCase()}`}>
                    {row.kind === "Customer" ? "C" : row.kind === "Driver" ? "D" : "T"}
                  </span>
                  <span className="registration-row-copy">
                    <strong>{row.name}</strong>
                    <small>
                      {row.kind} · {row.area}
                    </small>
                    <small>
                      {row.contact} · {row.submitted}
                    </small>
                  </span>
                  <Status status={row.status} />
                </button>
              ))
            ) : (
              <div className="registration-empty">Tidak ada pendaftaran untuk filter ini.</div>
            )}
          </div>
        </section>
        <aside className="panel registration-detail-panel" aria-live="polite">
          {selected ? (
            <>
              <div className="registration-detail-head">
                <span className="detail-category">PENDAFTARAN MITRA · {selected.kind.toUpperCase()}</span>
                <Status status={selected.status} />
                <h2>{selected.name}</h2>
                <p>
                  {selected.contact} · Diajukan {selected.submitted}
                </p>
              </div>
              <div className="registration-detail-body">
                <h3>Rincian berkas pendaftaran</h3>
                <dl className="detail-fields registration-detail-fields">
                  {[{ label: "Status verifikasi", value: selected.status }, ...selected.fields].map((field, index) => (
                    <div key={`${selected.id}-${field.label}-${index}`}>
                      <dt>{field.label}</dt>
                      <dd>{field.value}</dd>
                    </div>
                  ))}
                </dl>
              </div>
              {selected.status === "Menunggu verifikasi" ? (
                <div className="registration-actions">
                  <p>Keputusan ini langsung mengaktifkan atau menolak akun mitra di database MySQL.</p>
                  <div>
                    <button type="button" className="reject-button" onClick={() => onDecision(selected.id, "Ditolak")}>
                      Tolak
                    </button>
                    <button type="button" className="approve-button" onClick={() => onDecision(selected.id, "Disetujui")}>
                      Setujui pendaftaran
                    </button>
                  </div>
                </div>
              ) : (
                <div className="registration-closed-note">
                  <span>
                    Pendaftaran ini berstatus <strong>{selected.status.toLowerCase()}</strong>.
                  </span>
                  {selected.status !== "Disetujui" && (
                    <button type="button" onClick={() => onDecision(selected.id, "Disetujui")}>
                      Setujui sekarang
                    </button>
                  )}
                </div>
              )}
            </>
          ) : (
            <div className="registration-no-selection">Pilih pendaftar dari antrean untuk melihat datanya.</div>
          )}
        </aside>
      </div>
    </section>
  );
}

function FinancePage({
  token,
  withdrawals,
  talanganClaims,
  qrisTxs,
  walletTxs,
  staticQris,
  onRefresh,
}: {
  token: string;
  withdrawals: WithdrawalRow[];
  talanganClaims: TalanganClaimRow[];
  qrisTxs: QRISTxRow[];
  walletTxs: WalletTxRow[];
  staticQris: string;
  onRefresh: () => void;
}) {
  const [subTab, setSubTab] = useState<"withdraw" | "talangan" | "qris" | "ledger">("withdraw");
  const [qrisInput, setQrisInput] = useState(staticQris);
  const [feedback, setFeedback] = useState("");

  useEffect(() => {
    setQrisInput(staticQris);
  }, [staticQris]);

  async function handleWithdrawDecision(id: string, action: "approve" | "reject") {
    const res = await fetch(`/v1/admin/withdrawals/${id}/${action}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ admin_notes: `Diproses Admin (${action})` }),
    });
    if (res.ok) {
      setFeedback(`Status pengajuan withdraw ${id.slice(0, 8)} berhasil diperbarui (${action.toUpperCase()}).`);
      onRefresh();
    }
  }

  async function handleTalanganDecision(id: string, action: "approve-step1" | "reimburse" | "reject") {
    const res = await fetch(`/v1/admin/talangan-claims/${id}/${action}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ admin_notes: `Verifikasi klaim talangan (${action})` }),
    });
    if (res.ok) {
      setFeedback(`Klaim talangan ${id.slice(0, 8)} berhasil diproses (${action}).`);
      onRefresh();
    }
  }

  async function handleManualSettleQRIS(referenceId: string) {
    const res = await fetch("/pay/qris/webhook", {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ reference_id: referenceId, verified_by: "admin-manual-dashboard" }),
    });
    if (res.ok) {
      setFeedback(`Transaksi QRIS ${referenceId} berhasil dikonfirmasi LUNAS.`);
      onRefresh();
    }
  }

  async function handleSaveStaticQRIS() {
    const res = await fetch("/v1/admin/settings", {
      method: "PUT",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ payg_static_qris: qrisInput.trim() }),
    });
    if (res.ok) {
      setFeedback("Template String Static QRIS Merchant berhasil disimpan ke system_settings.");
      onRefresh();
    }
  }

  return (
    <section className="registration-page">
      <div className="subtab-bar" role="tablist" aria-label="Menu keuangan dan QRIS">
        <button
          type="button"
          className={`subtab-btn ${subTab === "withdraw" ? "is-active" : ""}`}
          onClick={() => setSubTab("withdraw")}
        >
          Tarik Saldo / Withdraw ({withdrawals.length})
        </button>
        <button
          type="button"
          className={`subtab-btn ${subTab === "talangan" ? "is-active" : ""}`}
          onClick={() => setSubTab("talangan")}
        >
          Klaim Talangan Donasi ({talanganClaims.length})
        </button>
        <button
          type="button"
          className={`subtab-btn ${subTab === "qris" ? "is-active" : ""}`}
          onClick={() => setSubTab("qris")}
        >
          Transaksi &amp; Konfigurasi QRIS payG ({qrisTxs.length})
        </button>
        <button
          type="button"
          className={`subtab-btn ${subTab === "ledger" ? "is-active" : ""}`}
          onClick={() => setSubTab("ledger")}
        >
          Mutasi Dompet ({walletTxs.length})
        </button>
      </div>

      {feedback && (
        <div className="registration-notice" role="status">
          <span>
            <Icon name="check" size={14} />
          </span>
          <p>{feedback}</p>
          <button type="button" aria-label="Tutup pesan" onClick={() => setFeedback("")}>
            ×
          </button>
        </div>
      )}

      {subTab === "withdraw" && (
        <section className="panel table-panel directory-panel">
          <div className="panel-head">
            <div>
              <h2>Pengajuan Tarik Saldo (Withdraw) Driver &amp; Toko</h2>
              <p>Persetujuan pencairan dana ke rekening Bank Aceh Syariah / BSI mitra</p>
            </div>
            <span className="row-count">{withdrawals.length} pengajuan</span>
          </div>
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>MITRA</th>
                  <th>BANK TUJUAN</th>
                  <th>NOMINAL</th>
                  <th>BIAYA ADMIN</th>
                  <th>DITERIMA BERSIH</th>
                  <th>STATUS</th>
                  <th className="align-right">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {withdrawals.length ? (
                  withdrawals.map((w) => (
                    <tr key={w.id}>
                      <td>
                        <strong>{w.requester_name}</strong> ({w.owner_type})
                      </td>
                      <td>
                        {w.bank_name} · {w.bank_account_number} a.n. {w.bank_account_holder}
                      </td>
                      <td>{rupiah(w.amount)}</td>
                      <td>{rupiah(w.admin_fee)}</td>
                      <td className="amount-cell">{rupiah(w.net_amount)}</td>
                      <td>
                        <Status status={w.status === "APPROVED" ? "Disetujui" : w.status === "REJECTED" ? "Ditolak" : "Menunggu"} />
                      </td>
                      <td className="align-right">
                        {w.status === "PENDING" ? (
                          <div style={{ display: "inline-flex", gap: 6 }}>
                            <button type="button" className="btn-success" onClick={() => handleWithdrawDecision(w.id, "approve")}>
                              Setujui
                            </button>
                            <button type="button" className="btn-danger" onClick={() => handleWithdrawDecision(w.id, "reject")}>
                              Tolak
                            </button>
                          </div>
                        ) : (
                          <span>Selesai</span>
                        )}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td className="no-results" colSpan={7}>
                      Belum ada pengajuan tarik saldo yang menunggu konfirmasi.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {subTab === "talangan" && (
        <section className="panel table-panel directory-panel">
          <div className="panel-head">
            <div>
              <h2>Klaim Jaminan Talangan 2 Langkah (Donasi Panti Asuhan)</h2>
              <p>Step 1: Verifikasi Nota Belanja &amp; Barang · Step 2: Verifikasi Foto Donasi Panti Asuhan &amp; Cairkan Reimbursement</p>
            </div>
            <span className="row-count">{talanganClaims.length} klaim</span>
          </div>
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>PESANAN</th>
                  <th>DRIVER</th>
                  <th>NOMINAL KLAIM</th>
                  <th>BUKTI STEP 1 (NOTA)</th>
                  <th>BUKTI STEP 2 (PANTI ASUHAN)</th>
                  <th>STATUS</th>
                  <th className="align-right">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {talanganClaims.length ? (
                  talanganClaims.map((c) => (
                    <tr key={c.id}>
                      <td className="id-cell">{c.order_code}</td>
                      <td>{c.driver_name}</td>
                      <td className="amount-cell">{rupiah(c.claimed_amount)}</td>
                      <td>
                        <a href={c.receipt_photo_url} target="_blank" rel="noreferrer">
                          Lihat Foto Nota
                        </a>
                      </td>
                      <td>
                        {c.orphanage_name ? `${c.orphanage_name} (` : "Belum disalurkan"}
                        {c.donation_photo_url && (
                          <a href={c.donation_photo_url} target="_blank" rel="noreferrer">
                            Foto Donasi
                          </a>
                        )}
                        {c.orphanage_name ? ")" : ""}
                      </td>
                      <td>
                        <Status
                          status={
                            c.status === "COMPLETED_REIMBURSED"
                              ? "Selesai"
                              : c.status === "REJECTED"
                              ? "Ditolak"
                              : "Menunggu"
                          }
                        />
                      </td>
                      <td className="align-right">
                        {c.status === "SUBMITTED_STEP1" && (
                          <div style={{ display: "inline-flex", gap: 6 }}>
                            <button
                              type="button"
                              className="btn-secondary"
                              onClick={() => handleTalanganDecision(c.id, "approve-step1")}
                            >
                              Setujui Step 1 (Izin Donasi)
                            </button>
                            <button
                              type="button"
                              className="btn-danger"
                              onClick={() => handleTalanganDecision(c.id, "reject")}
                            >
                              Tolak
                            </button>
                          </div>
                        )}
                        {c.status === "APPROVED_FOR_DONATION" && (
                          <button
                            type="button"
                            className="btn-success"
                            onClick={() => handleTalanganDecision(c.id, "reimburse")}
                          >
                            Cairkan Reimbursement
                          </button>
                        )}
                        {(c.status === "COMPLETED_REIMBURSED" || c.status === "REJECTED") && <span>{c.status}</span>}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td className="no-results" colSpan={7}>
                      Belum ada pengajuan klaim talangan FlexSend.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {subTab === "qris" && (
        <div className="registration-page">
          <div className="card-box">
            <div>
              <h3>Konfigurasi Payload Static QRIS Merchant (PayG EMVCo Injector)</h3>
              <p>
                String QRIS statis merchant yang akan dikonversi otomatis menjadi QRIS Dinamis (Tag 01=&quot;12&quot;, Tag 54 Nominal, &amp; Tag 63 CRC16-CCITT). Kosongkan untuk memakai template EMVCo standar development.
              </p>
            </div>
            <div className="form-group">
              <label htmlFor="static-qris-input">Payload String Static QRIS (EMVCo)</label>
              <input
                id="static-qris-input"
                value={qrisInput}
                onChange={(e) => setQrisInput(e.target.value)}
                placeholder="00020101021126..."
              />
            </div>
            <div>
              <button type="button" className="btn-primary" onClick={handleSaveStaticQRIS}>
                Simpan Konfigurasi Static QRIS
              </button>
            </div>
          </div>

          <section className="panel table-panel directory-panel">
            <div className="panel-head">
              <div>
                <h2>Log Transaksi QRIS Dinamis (`services/payg`)</h2>
                <p>Mendukung pelunasan otomatis via MacroDroid Webhook maupun tombol Konfirmasi Lunas Manual</p>
              </div>
              <span className="row-count">{qrisTxs.length} transaksi</span>
            </div>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>REFERENSI QRIS</th>
                    <th>TUJUAN</th>
                    <th>PENGGUNA</th>
                    <th>NOMINAL</th>
                    <th>KEDALUWARSA</th>
                    <th>STATUS</th>
                    <th className="align-right">AKSI MANUAL</th>
                  </tr>
                </thead>
                <tbody>
                  {qrisTxs.length ? (
                    qrisTxs.map((q) => (
                      <tr key={q.id}>
                        <td className="id-cell">{q.reference_id}</td>
                        <td>{q.purpose}</td>
                        <td>{q.user_name}</td>
                        <td className="amount-cell">{rupiah(q.amount)}</td>
                        <td>{formatDateID(q.expires_at)}</td>
                        <td>
                          <Status
                            status={
                              q.status === "PAID" ? "Selesai" : q.status === "PENDING" ? "Menunggu" : "Dibatalkan"
                            }
                          />
                        </td>
                        <td className="align-right">
                          {q.status === "PENDING" ? (
                            <button
                              type="button"
                              className="btn-success"
                              onClick={() => handleManualSettleQRIS(q.reference_id)}
                            >
                              Konfirmasi Lunas Manual
                            </button>
                          ) : (
                            <span>{q.status}</span>
                          )}
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td className="no-results" colSpan={7}>
                        Belum ada transaksi QRIS yang tercatat.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {subTab === "ledger" && (
        <section className="panel table-panel directory-panel">
          <div className="panel-head">
            <div>
              <h2>Buku Besar Mutasi Dompet (`wallet_transactions`)</h2>
              <p>Riwayat top-up QRIS, potongan komisi 5%:5%, pendapatan order, withdraw, dan reimbursement talangan</p>
            </div>
            <span className="row-count">{walletTxs.length} mutasi</span>
          </div>
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>WAKTU</th>
                  <th>TIPE DOMPET</th>
                  <th>JENIS TRANSAKSI</th>
                  <th>KETERANGAN</th>
                  <th className="align-right">MUTASI</th>
                  <th className="align-right">SALDO AKHIR</th>
                </tr>
              </thead>
              <tbody>
                {walletTxs.length ? (
                  walletTxs.map((wt) => (
                    <tr key={wt.id}>
                      <td>{formatDateID(wt.created_at)}</td>
                      <td>{wt.owner_type}</td>
                      <td className="id-cell">{wt.tx_type}</td>
                      <td>{wt.description}</td>
                      <td className="align-right amount-cell">{rupiah(wt.amount)}</td>
                      <td className="align-right">{rupiah(wt.balance_after)}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td className="no-results" colSpan={6}>
                      Belum ada riwayat mutasi dompet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </section>
  );
}

function SettingsPage({
  token,
  providers,
  pricingRules,
  settings,
  tickets,
  waStatus,
  onRefresh,
}: {
  token: string;
  providers: AIProviderRow[];
  pricingRules: PricingRuleRow[];
  settings: Record<string, string>;
  tickets: SupportTicketRow[];
  waStatus: { status?: string; paired?: boolean; sandbox?: boolean };
  onRefresh: () => void;
}) {
  const [subTab, setSubTab] = useState<"ai" | "pricing" | "tickets">("ai");
  const [notice, setNotice] = useState("");
  const [apiKeyInputs, setApiKeyInputs] = useState<Record<string, string>>({});
  const [testPrompt, setTestPrompt] = useState("Rekomendasikan kuliner Mie Aceh dekat Kampus Bukit Indah");
  const [testReply, setTestReply] = useState("");
  const [testingAI, setTestingAI] = useState(false);

  const [offerSec, setOfferSec] = useState(settings.driver_offer_seconds || "16");
  const [negLimit, setNegLimit] = useState(settings.driver_negative_balance_limit || "20000");
  const [wdFee, setWdFee] = useState(settings.withdraw_admin_fee || "2000");
  const [replyText, setReplyText] = useState<Record<string, string>>({});

  useEffect(() => {
    setOfferSec(settings.driver_offer_seconds || "16");
    setNegLimit(settings.driver_negative_balance_limit || "20000");
    setWdFee(settings.withdraw_admin_fee || "2000");
  }, [settings]);

  async function handleUpdateProvider(p: AIProviderRow, patch: Record<string, unknown>) {
    const res = await fetch(`/ai/providers/${p.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(patch),
    });
    if (res.ok) {
      setNotice(`Konfigurasi ${p.display_name} berhasil disimpan (API Key dienkripsi AES-256-GCM).`);
      onRefresh();
    }
  }

  async function handleTestAIChat() {
    if (!testPrompt.trim()) return;
    setTestingAI(true);
    setTestReply("");
    try {
      const res = await fetch("/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          session_id: "admin-test-console",
          user_id: "00000000-0000-4000-8000-000000000001",
          app_role: "ADMIN",
          message: testPrompt.trim(),
        }),
      });
      const data = await res.json();
      setTestReply(`[Provider: ${data.provider_used || "-"}] ${data.reply || data.error || ""}`);
    } catch {
      setTestReply("Gagal menghubungi layanan /ai/chat.");
    } finally {
      setTestingAI(false);
    }
  }

  async function handleUpdatePricingRule(rule: PricingRuleRow, field: string, value: number) {
    const res = await fetch(`/v1/admin/pricing-rules/${rule.id}`, {
      method: "PUT",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ [field]: value }),
    });
    if (res.ok) {
      setNotice(`Tarif ${rule.service_type} berhasil diperbarui.`);
      onRefresh();
    }
  }

  async function handleSaveSystemRules() {
    const res = await fetch("/v1/admin/settings", {
      method: "PUT",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        driver_offer_seconds: offerSec,
        driver_negative_balance_limit: negLimit,
        withdraw_admin_fee: wdFee,
      }),
    });
    if (res.ok) {
      setNotice("Parameter operasional sistem berhasil disimpan ke MySQL system_settings.");
      onRefresh();
    }
  }

  async function handleReplyTicket(ticketId: string) {
    const text = (replyText[ticketId] || "").trim();
    if (!text) return;
    const res = await fetch(`/v1/admin/support-tickets/${ticketId}/reply`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ reply: text, status: "RESOLVED" }),
    });
    if (res.ok) {
      setNotice("Balasan tiket bantuan CS berhasil disimpan dan dikirim.");
      setReplyText((prev) => ({ ...prev, [ticketId]: "" }));
      onRefresh();
    }
  }

  return (
    <section className="registration-page">
      <div className="subtab-bar" role="tablist" aria-label="Menu pengaturan AI, tarif, dan tiket CS">
        <button
          type="button"
          className={`subtab-btn ${subTab === "ai" ? "is-active" : ""}`}
          onClick={() => setSubTab("ai")}
        >
          Provider AI Universal ({providers.length})
        </button>
        <button
          type="button"
          className={`subtab-btn ${subTab === "pricing" ? "is-active" : ""}`}
          onClick={() => setSubTab("pricing")}
        >
          Tarif Ongkir &amp; Komisi 5%:5%
        </button>
        <button
          type="button"
          className={`subtab-btn ${subTab === "tickets" ? "is-active" : ""}`}
          onClick={() => setSubTab("tickets")}
        >
          Tiket CS &amp; WhatsApp Gateway ({tickets.length})
        </button>
      </div>

      {notice && (
        <div className="registration-notice" role="status">
          <span>
            <Icon name="check" size={14} />
          </span>
          <p>{notice}</p>
          <button type="button" aria-label="Tutup pesan" onClick={() => setNotice("")}>
            ×
          </button>
        </div>
      )}

      {subTab === "ai" && (
        <div className="registration-page">
          <div className="grid-2col">
            {providers.map((p) => (
              <div key={p.id} className="card-box">
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div>
                    <h3>
                      Prioritas #{p.priority_order} · {p.display_name}
                    </h3>
                    <p>
                      Protokol: <code>{p.adapter_type}</code> · Key: <code>{p.api_key_masked || "Belum diisi"}</code>
                    </p>
                  </div>
                  <Status status={p.is_active ? "Aktif" : "Menunggu"} />
                </div>

                <div className="form-group">
                  <label htmlFor={`base-url-${p.id}`}>Base URL Endpoint</label>
                  <input
                    id={`base-url-${p.id}`}
                    defaultValue={p.base_url}
                    onBlur={(e) => {
                      if (e.target.value !== p.base_url) handleUpdateProvider(p, { base_url: e.target.value });
                    }}
                  />
                </div>

                <div className="form-group">
                  <label htmlFor={`model-name-${p.id}`}>Nama Model</label>
                  <input
                    id={`model-name-${p.id}`}
                    defaultValue={p.model_name}
                    onBlur={(e) => {
                      if (e.target.value !== p.model_name) handleUpdateProvider(p, { model_name: e.target.value });
                    }}
                  />
                </div>

                <div className="form-group">
                  <label htmlFor={`api-key-${p.id}`}>API Key Baru (Disimpan Terenkripsi AES-256-GCM)</label>
                  <div style={{ display: "flex", gap: 8 }}>
                    <input
                      id={`api-key-${p.id}`}
                      type="password"
                      value={apiKeyInputs[p.id] || ""}
                      onChange={(e) => setApiKeyInputs((prev) => ({ ...prev, [p.id]: e.target.value }))}
                      placeholder={p.has_api_key ? `Tersimpan (${p.api_key_masked})` : "Masukkan API Key..."}
                    />
                    <button
                      type="button"
                      className="btn-secondary"
                      onClick={() => {
                        const val = (apiKeyInputs[p.id] || "").trim();
                        if (val) {
                          handleUpdateProvider(p, { api_key: val });
                          setApiKeyInputs((prev) => ({ ...prev, [p.id]: "" }));
                        }
                      }}
                    >
                      Simpan Key
                    </button>
                  </div>
                </div>

                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <button
                    type="button"
                    className={p.is_active ? "btn-danger" : "btn-success"}
                    onClick={() => handleUpdateProvider(p, { is_active: !p.is_active })}
                  >
                    {p.is_active ? "Nonaktifkan Provider" : "Aktifkan Provider"}
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="card-box">
            <div>
              <h3>Konsol Uji Coba Prompt AI (`POST /ai/chat`)</h3>
              <p>Uji router failover otomatis (`priority_order ASC`) atau pesan fallback aman ketika seluruh provider non-aktif.</p>
            </div>
            <div className="form-group">
              <label htmlFor="ai-test-prompt">Pesan Uji ke CS AI RideOn</label>
              <div style={{ display: "flex", gap: 8 }}>
                <input
                  id="ai-test-prompt"
                  value={testPrompt}
                  onChange={(e) => setTestPrompt(e.target.value)}
                  placeholder="Tulis pertanyaan uji..."
                />
                <button type="button" className="btn-primary" onClick={handleTestAIChat} disabled={testingAI}>
                  {testingAI ? "Mengirim..." : "Test Prompt AI"}
                </button>
              </div>
            </div>
            {testReply && (
              <div className="registration-notice" role="status">
                <p>{testReply}</p>
              </div>
            )}
          </div>
        </div>
      )}

      {subTab === "pricing" && (
        <div className="registration-page">
          <section className="panel table-panel directory-panel">
            <div className="panel-head">
              <div>
                <h2>Rumus Tarif Layanan &amp; Komisi Platform (`pricing_rules`)</h2>
                <p>Ubah angka tarif dasar, tarif per km, tarif minimum, dan persentase komisi 5%:5%</p>
              </div>
              <span className="row-count">{pricingRules.length} layanan</span>
            </div>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>LAYANAN</th>
                    <th>TARIF DASAR (RP)</th>
                    <th>TARIF / KM (RP)</th>
                    <th>TARIF MINIMUM (RP)</th>
                    <th>KOMISI DRIVER (%)</th>
                    <th>KOMISI TOKO (%)</th>
                  </tr>
                </thead>
                <tbody>
                  {pricingRules.map((r) => (
                    <tr key={r.id}>
                      <td className="id-cell">{r.service_type}</td>
                      <td>
                        <input
                          type="number"
                          aria-label={`Tarif dasar ${r.service_type}`}
                          defaultValue={r.base_fare}
                          style={{ width: 95, padding: "4px 6px", border: "1px solid #dfdbe8", borderRadius: 6 }}
                          onBlur={(e) => handleUpdatePricingRule(r, "base_fare", Number(e.target.value))}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          aria-label={`Tarif per km ${r.service_type}`}
                          defaultValue={r.per_km_fare}
                          style={{ width: 95, padding: "4px 6px", border: "1px solid #dfdbe8", borderRadius: 6 }}
                          onBlur={(e) => handleUpdatePricingRule(r, "per_km_fare", Number(e.target.value))}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          aria-label={`Tarif minimum ${r.service_type}`}
                          defaultValue={r.min_fare}
                          style={{ width: 95, padding: "4px 6px", border: "1px solid #dfdbe8", borderRadius: 6 }}
                          onBlur={(e) => handleUpdatePricingRule(r, "min_fare", Number(e.target.value))}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          step="0.5"
                          aria-label={`Komisi driver ${r.service_type}`}
                          defaultValue={r.driver_commission_pct}
                          style={{ width: 75, padding: "4px 6px", border: "1px solid #dfdbe8", borderRadius: 6 }}
                          onBlur={(e) => handleUpdatePricingRule(r, "driver_commission_pct", Number(e.target.value))}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          step="0.5"
                          aria-label={`Komisi toko ${r.service_type}`}
                          defaultValue={r.store_commission_pct}
                          style={{ width: 75, padding: "4px 6px", border: "1px solid #dfdbe8", borderRadius: 6 }}
                          onBlur={(e) => handleUpdatePricingRule(r, "store_commission_pct", Number(e.target.value))}
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <div className="card-box">
            <div>
              <h3>Aturan Operasional Runtime (`system_settings`)</h3>
              <p>Durasi broadcast tawaran order ke driver, batas toleransi saldo minus driver, dan biaya admin withdraw.</p>
            </div>
            <div className="grid-2col">
              <div className="form-group">
                <label htmlFor="setting-offer-sec">Durasi Pop-up Tawaran Order Driver (Detik)</label>
                <input id="setting-offer-sec" type="number" value={offerSec} onChange={(e) => setOfferSec(e.target.value)} />
              </div>
              <div className="form-group">
                <label htmlFor="setting-neg-limit">Batas Toleransi Saldo Minus Driver (Rp)</label>
                <input id="setting-neg-limit" type="number" value={negLimit} onChange={(e) => setNegLimit(e.target.value)} />
              </div>
              <div className="form-group">
                <label htmlFor="setting-wd-fee">Biaya Admin Penarikan Saldo / Withdraw (Rp)</label>
                <input id="setting-wd-fee" type="number" value={wdFee} onChange={(e) => setWdFee(e.target.value)} />
              </div>
            </div>
            <div>
              <button type="button" className="btn-primary" onClick={handleSaveSystemRules}>
                Simpan Parameter Operasional
              </button>
            </div>
          </div>
        </div>
      )}

      {subTab === "tickets" && (
        <div className="registration-page">
          <div className="card-box">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <h3>Status Koneksi WhatsApp Gateway (`services/wa-gateway`)</h3>
                <p>
                  Status Socket Baileys: <strong>{waStatus.status || "qr_ready"}</strong> · Paired:{" "}
                  <strong>{waStatus.paired ? "Terhubung" : "Belum Ditautkan"}</strong>
                </p>
              </div>
              <a href="/wa/qr" target="_blank" rel="noreferrer" className="btn-secondary" style={{ display: "inline-flex", alignItems: "center", textDecoration: "none" }}>
                Buka Halaman Scan QR WhatsApp
              </a>
            </div>
          </div>

          <section className="panel table-panel directory-panel">
            <div className="panel-head">
              <div>
                <h2>Daftar Tiket Bantuan CS &amp; Eskalasi (`support_tickets`)</h2>
                <p>Balasan pada tiket ber-email otomatis dikirim melalui Email CS 2 Arah</p>
              </div>
              <span className="row-count">{tickets.length} tiket</span>
            </div>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>PENGIRIM</th>
                    <th>KANAL</th>
                    <th>SUBJEK &amp; PESAN</th>
                    <th>STATUS</th>
                    <th>BALASAN ADMIN</th>
                  </tr>
                </thead>
                <tbody>
                  {tickets.length ? (
                    tickets.map((t) => (
                      <tr key={t.id}>
                        <td>
                          <strong>{t.user_name}</strong>
                          <br />
                          <small>{t.sender_contact}</small>
                        </td>
                        <td>{t.channel}</td>
                        <td>
                          <strong>{t.subject}</strong>
                          <br />
                          <small>{t.body}</small>
                        </td>
                        <td>
                          <Status status={t.status === "RESOLVED" ? "Selesai" : "Menunggu"} />
                        </td>
                        <td>
                          {t.admin_reply ? (
                            <span>{t.admin_reply}</span>
                          ) : (
                            <div style={{ display: "flex", gap: 6 }}>
                              <input
                                aria-label={`Balas tiket ${t.subject}`}
                                value={replyText[t.id] || ""}
                                onChange={(e) => setReplyText((prev) => ({ ...prev, [t.id]: e.target.value }))}
                                placeholder="Tulis balasan CS..."
                                style={{ padding: "4px 8px", border: "1px solid #dfdbe8", borderRadius: 6 }}
                              />
                              <button type="button" className="btn-success" onClick={() => handleReplyTicket(t.id)}>
                                Balas
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td className="no-results" colSpan={5}>
                        Belum ada tiket keluhan yang masuk.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}
    </section>
  );
}

function Directory({
  view,
  orders,
  drivers,
  stores,
  customers,
  search,
  orderFilter,
  onOrderFilter,
  onSelectOrder,
  onSelectPerson,
}: {
  view: "orders" | "drivers" | "stores" | "customers";
  orders: Order[];
  drivers: DirectoryPerson[];
  stores: DirectoryPerson[];
  customers: DirectoryPerson[];
  search: string;
  orderFilter: OrderFilter;
  onOrderFilter: (filter: OrderFilter) => void;
  onSelectOrder: (order: Order) => void;
  onSelectPerson: (kind: "drivers" | "stores" | "customers", person: DirectoryPerson) => void;
}) {
  const filteredOrders = useMemo(
    () =>
      orders.filter(
        (order) =>
          (orderFilter === "Semua" || order.status === orderFilter) &&
          Object.values(order).some((value) => String(value).toLowerCase().includes(search.toLowerCase()))
      ),
    [orders, orderFilter, search]
  );
  const people = view === "drivers" ? drivers : view === "stores" ? stores : view === "customers" ? customers : [];
  const filteredPeople = people.filter((person) =>
    Object.values(person).some((value) => typeof value === "string" && value.toLowerCase().includes(search.toLowerCase()))
  );
  return (
    <section className="panel table-panel directory-panel">
      <div className="panel-head">
        <div>
          <h2>{titleFor[view]}</h2>
          <p>Data real-time dari tabel MySQL rideon_db</p>
        </div>
        <span className="row-count">
          {view === "orders" ? filteredOrders.length : filteredPeople.length} baris ditampilkan
        </span>
      </div>
      {view === "orders" && (
        <div className="order-filter" aria-label="Filter status pesanan">
          {orderFilters.map((filter) => (
            <button
              key={filter}
              type="button"
              className={orderFilter === filter ? "filter-active" : ""}
              aria-pressed={orderFilter === filter}
              onClick={() => onOrderFilter(filter)}
            >
              {filter}
              <span>{filter === "Semua" ? orders.length : orders.filter((order) => order.status === filter).length}</span>
            </button>
          ))}
        </div>
      )}
      {view === "orders" ? (
        <OrderTable rows={filteredOrders} onSelect={onSelectOrder} />
      ) : (
        <PeopleTable view={view} rows={filteredPeople} onSelect={(person) => onSelectPerson(view, person)} />
      )}
    </section>
  );
}

function OrderTable({ rows, onSelect }: { rows: Order[]; onSelect: (order: Order) => void }) {
  return (
    <div className="table-scroll">
      <table>
        <thead>
          <tr>
            <th>KODE PESANAN</th>
            <th>CUSTOMER</th>
            <th>LAYANAN</th>
            <th>DRIVER</th>
            <th>WAKTU</th>
            <th>STATUS</th>
            <th className="align-right">TOTAL</th>
          </tr>
        </thead>
        <tbody>
          {rows.length ? (
            rows.map((order) => (
              <tr key={order.id}>
                <td>
                  <button type="button" className="row-detail-button" onClick={() => onSelect(order)}>
                    {order.orderCode}
                    <Icon name="arrowUpRight" size={13} />
                  </button>
                </td>
                <td>
                  <span className="table-person">
                    <span className="mini-avatar">{order.customer.slice(0, 2).toUpperCase()}</span>
                    {order.customer}
                  </span>
                </td>
                <td>
                  <span className="service-name">{order.service}</span>
                </td>
                <td>{order.driver}</td>
                <td>{order.date}</td>
                <td>
                  <Status status={order.status} />
                </td>
                <td className="align-right amount-cell">{rupiah(order.amount)}</td>
              </tr>
            ))
          ) : (
            <tr>
              <td className="no-results" colSpan={7}>
                Belum ada pesanan yang tercatat untuk filter ini.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function PeopleTable({
  view,
  rows,
  onSelect,
}: {
  view: "drivers" | "stores" | "customers";
  rows: DirectoryPerson[];
  onSelect: (person: DirectoryPerson) => void;
}) {
  return (
    <div className="table-scroll">
      <table>
        <thead>
          <tr>
            <th>NAMA</th>
            <th>RINCIAN / LOKASI</th>
            <th>STATUS</th>
            <th>TERDAFTAR</th>
          </tr>
        </thead>
        <tbody>
          {rows.length ? (
            rows.map((row) => (
              <tr key={row.id}>
                <td>
                  <button type="button" className="person-detail-button" onClick={() => onSelect(row)}>
                    <span className="mini-avatar">{view === "drivers" ? "D" : view === "stores" ? "T" : "C"}</span>
                    <span>{row.name}</span>
                    <Icon name="arrowUpRight" size={13} />
                  </button>
                </td>
                <td>{row.detail}</td>
                <td>
                  <Status status={row.status} />
                </td>
                <td>{row.date}</td>
              </tr>
            ))
          ) : (
            <tr>
              <td className="no-results" colSpan={4}>
                Tidak ada hasil yang cocok dengan pencarian.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function Status({ status }: { status: string }) {
  const type = ["Selesai", "Online", "Buka", "Aktif", "Disetujui", "ACTIVE"].includes(status)
    ? "success"
    : ["Menunggu", "Menunggu verifikasi", "Berjalan", "Dalam perjalanan", "PENDING_APPROVAL", "Offline", "Tutup"].includes(status)
    ? "waiting"
    : ["Ditolak", "REJECTED", "SUSPENDED", "Dibatalkan"].includes(status)
    ? "rejected"
    : "neutral";
  return (
    <span className={`status status-${type}`}>
      <i />
      {status}
    </span>
  );
}

function DetailModal({
  detail,
  closeButtonRef,
  onClose,
}: {
  detail: DetailView;
  closeButtonRef: React.RefObject<HTMLButtonElement | null>;
  onClose: () => void;
}) {
  function keepFocusInside(event: React.KeyboardEvent<HTMLElement>) {
    if (event.key !== "Tab") return;
    const focusable = Array.from(
      event.currentTarget.querySelectorAll<HTMLElement>(
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
    );
    if (focusable.length === 0) {
      event.preventDefault();
      return;
    }
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  }

  return (
    <div
      className="detail-backdrop"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <section className="detail-dialog" role="dialog" aria-modal="true" aria-labelledby="detail-title" onKeyDown={keepFocusInside}>
        <header className="detail-header">
          <div>
            <span className="detail-category">{detail.category}</span>
            <h2 id="detail-title">{detail.title}</h2>
            <p>{detail.subtitle}</p>
          </div>
          <button ref={closeButtonRef} type="button" className="detail-close" onClick={onClose} aria-label="Tutup detail">
            ×
          </button>
        </header>
        <div className="detail-body">
          <h3>Informasi lengkap</h3>
          <dl className="detail-fields">
            {detail.fields.map((field) => (
              <div key={field.label}>
                <dt>{field.label}</dt>
                <dd>{field.value}</dd>
              </div>
            ))}
          </dl>
        </div>
        <footer className="detail-footer">
          <span>Data langsung dari database MySQL rideon_db.</span>
          <button type="button" onClick={onClose}>
            Tutup
          </button>
        </footer>
      </section>
    </div>
  );
}
