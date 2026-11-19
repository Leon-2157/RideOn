# RideOn Ecosystem — Opaque-Box 4-Tier E2E Test Suite

Zero-dependency Node.js v22 (`node:http`, `node:crypto`, `node:assert/strict`, `fetch`, `FormData`, `Blob`) requirement-driven E2E suite for the RideOn ecosystem (`rideon-api`, `payg`, `ai-service`, `wa-gateway`, `admin-RideOn`, and `nginx`).

## Directory Structure

```text
tests/e2e/
├── run.mjs                     # Unified CLI runner (--tier, --base-url, --dry-run, --self-test, --json, --help)
├── self_test.mjs               # Stateful in-process Nginx-equivalent mock HTTP server + 5 contract-breaker mutations
├── README.md                   # This documentation
├── lib/
│   ├── client.mjs              # Opaque-box HTTP/multipart client, JWT decoder, EMVCo CRC-16 verifier, actor factories
│   └── fixtures.mjs            # Lhokseumawe & Aceh Utara coordinates, seed defaults, pricing rules, 68B PNG, static QRIS
└── tiers/
    ├── tier1_features.mjs      # Tier 1: 66 isolated happy-path tests across all 12 Feature Areas
    ├── tier2_boundaries.mjs    # Tier 2: 68 boundary, negative, concurrency (409), and security tests across 12 Areas
    ├── tier3_combinations.mjs  # Tier 3: 14 pairwise cross-feature combination workflows (T3-W01..T3-W14)
    └── tier4_scenarios.mjs     # Tier 4: 6 multi-actor Lhokseumawe & Aceh Utara E2E journeys (T4-S01..T4-S06)
```

## Coverage Summary (154 Total E2E Tests)

| Tier | File | Count | Scope |
|---|---|---:|---|
| Tier 1 | `tiers/tier1_features.mjs` | 66 | >=5 happy-path tests for each of the 12 Feature Areas |
| Tier 2 | `tiers/tier2_boundaries.mjs` | 68 | >=5 boundary/negative/race/security tests per Feature Area (`Promise.all` 409 lock, `-20000` TUNAI floor, invalid CRC-16, >3 FlexSend stops, wrong 6-digit PIN, Safe Action Boundary prompt injection, `****` API key masking, `X-PayG-Secret` & `X-Gateway-Secret`, cross-tenant IDOR) |
| Tier 3 | `tiers/tier3_combinations.mjs` | 14 | Pairwise cross-feature combination workflows (`T3-W01`..`T3-W14`) |
| Tier 4 | `tiers/tier4_scenarios.mjs` | 6 | Full multi-actor Lhokseumawe & Aceh Utara scenarios (`T4-S01`..`T4-S06`) |
| **Total** | | **154** | **All 12 Feature Areas & Stages 1–6 backend/gateway contracts** |

## CLI Flags

- `--tier=<1|2|3|4|all>` (also accepts comma-separated lists like `--tier=1,3` or `--tier 2`; invalid values exit `1`)
- `--base-url=<url>` (default: `process.env.RIDEON_BASE_URL || 'http://localhost:8088'`)
- `--dry-run` (enumerate selected tests without making any HTTP requests)
- `--self-test` (Phase 1: run selected tier(s) against in-process Nginx-equivalent mock on `127.0.0.1:0`; Phase 2: inject 5 contract-breaker mutations `break_crc16`, `break_409_race`, `leak_api_key`, `break_commission_math`, `break_auth_401` and verify tests catch every regression)
- `--json` (emit a single clean JSON report to stdout)
- `--help`, `-h` (print usage and exit `0`)

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `RIDEON_BASE_URL` | `http://localhost:8088` | Nginx reverse proxy URL |
| `ADMIN_EMAIL` | `admin@rideons.app` | Seeded admin login email (falls back to `ADMIN_LOGIN_EMAIL`) |
| `ADMIN_PASSWORD` | `RideOnAdmin2026!` | Seeded admin password (falls back to `ADMIN_LOGIN_PASSWORD`) |
| `PAYG_WEBHOOK_SECRET` | `rideon-payg-secret-2026` | `X-PayG-Secret` header for MacroDroid webhook |
| `WA_GATEWAY_SECRET` | `rideon-wa-secret-2026` | `X-Gateway-Secret` header for `/wa/*` & `/ai/webhook/whatsapp` |
| `INTERNAL_SERVICE_SECRET` | `rideon-internal-secret-2026` | `X-Internal-Secret` header |
| `E2E_TIMEOUT_MS` | `15000` | Per-request timeout in ms |

## Usage Examples

```bash
# 1. Show CLI usage
node tests/e2e/run.mjs --help

# 2. Enumerate all 154 tests without sending HTTP traffic
node tests/e2e/run.mjs --dry-run --tier=all

# 3. Verify suite & assertions in-process via mock server + 5 contract-breaker mutations
node tests/e2e/run.mjs --self-test --tier=all
node tests/e2e/run.mjs --self-test --tier=all --json

# 4. Run against live 7-container Compose stack (after M1–M4 are up)
node tests/e2e/run.mjs --base-url=http://localhost:8088 --tier=all
```
