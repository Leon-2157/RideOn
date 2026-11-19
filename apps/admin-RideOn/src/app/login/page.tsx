"use client";

import { useState, type FormEvent } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";

export default function AdminLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await fetch("/v1/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), password }),
      });
      const data = await res.json();
      if (!res.ok || !data.token) {
        setError(data.error || "Gagal masuk ke portal Admin RideOn.");
        setLoading(false);
        return;
      }
      if (data.user?.role !== "ADMIN") {
        setError("Akun ini bukan role ADMIN. Gunakan akun Administrator resmi RideOn.");
        setLoading(false);
        return;
      }
      window.localStorage.setItem("rideon_admin_token", data.token);
      window.localStorage.setItem("rideon_admin_user", JSON.stringify(data.user));
      router.push("/");
    } catch {
      setError("Tidak dapat menghubungi server API RideOn (/v1/auth/login).");
      setLoading(false);
    }
  }

  return (
    <main className="login-shell">
      <section className="login-card" aria-labelledby="login-heading">
        <div className="login-brand">
          <span className="login-logo-box">
            <Image src="/logo_primary.png" alt="Logo RideOn" width={46} height={32} priority />
          </span>
          <div>
            <span className="overline">PORTAL OPERASIONAL</span>
            <h1 id="login-heading">RideOn Admin</h1>
            <p>Pusat kendali ekosistem Lhokseumawe &amp; Aceh Utara</p>
          </div>
        </div>

        {error && (
          <div className="login-alert" role="alert">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="login-form">
          <div className="form-group">
            <label htmlFor="admin-email">Email atau Nomor WhatsApp Admin</label>
            <input
              id="admin-email"
              type="text"
              required
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@rideons.app"
            />
          </div>

          <div className="form-group">
            <label htmlFor="admin-password">Kata Sandi</label>
            <input
              id="admin-password"
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Masukkan kata sandi Admin"
            />
          </div>

          <button type="submit" className="login-submit" disabled={loading}>
            {loading ? "Memverifikasi kredensial…" : "Masuk ke Dashboard Admin"}
          </button>
        </form>

        <footer className="login-footer">
          <span>Terhubung ke MySQL <code>rideon_db</code> &amp; Microservices RideOn</span>
        </footer>
      </section>
    </main>
  );
}

