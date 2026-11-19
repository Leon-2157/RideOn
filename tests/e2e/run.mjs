#!/usr/bin/env node
import { DEFAULT_BASE_URL } from './lib/fixtures.mjs';
import { createClient, createRunId } from './lib/client.mjs';
import { defineTests as defineTier1 } from './tiers/tier1_features.mjs';
import { defineTests as defineTier2 } from './tiers/tier2_boundaries.mjs';
import { defineTests as defineTier3 } from './tiers/tier3_combinations.mjs';
import { defineTests as defineTier4 } from './tiers/tier4_scenarios.mjs';
import { runSelfTest } from './self_test.mjs';

const HELP_TEXT = `RideOn Ecosystem — Opaque-Box 4-Tier E2E Test Runner (Node.js v22, zero deps)

USAGE:
  node tests/e2e/run.mjs [options]

OPTIONS:
  --tier=<val>       Select test tier(s): 1 | 2 | 3 | 4 | all | comma-list (e.g. 1,3)
                     Also supports "--tier 2". Default: all
  --base-url=<url>   Target gateway URL (default: RIDEON_BASE_URL or http://localhost:8088)
  --dry-run          Enumerate selected tests and counts without making HTTP requests
  --self-test        Boot in-process Nginx-equivalent mock HTTP server on 127.0.0.1:0,
                     run selected tier(s) + 5 contract-breaker mutation checks
  --json             Emit a single structured JSON report to stdout
  --help, -h         Show this help message and exit 0

ENVIRONMENT VARIABLES:
  RIDEON_BASE_URL          Gateway base URL (default: http://localhost:8088)
  ADMIN_EMAIL              Seeded admin email (default: ADMIN_LOGIN_EMAIL or admin@rideons.app)
  ADMIN_PASSWORD           Seeded admin password (default: ADMIN_LOGIN_PASSWORD or RideOnAdmin2026!)
  PAYG_WEBHOOK_SECRET      X-PayG-Secret header value (default: rideon-payg-secret-2026)
  WA_GATEWAY_SECRET        X-Gateway-Secret header value (default: rideon-wa-secret-2026)
  INTERNAL_SERVICE_SECRET  X-Internal-Secret header value (default: rideon-internal-secret-2026)
  E2E_TIMEOUT_MS           Per-request timeout in ms (default: 15000)

EXAMPLES:
  node tests/e2e/run.mjs --dry-run --tier=all
  node tests/e2e/run.mjs --self-test --tier=all
  node tests/e2e/run.mjs --self-test --tier=2 --json
  node tests/e2e/run.mjs --base-url=http://localhost:8088 --tier=1,3
`;

function parseTiers(raw) {
  if (!raw || raw === 'all') return [1, 2, 3, 4];
  const parts = String(raw)
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (parts.length === 0) throw new Error('Empty --tier value');
  const set = new Set();
  for (const p of parts) {
    if (p === 'all') {
      [1, 2, 3, 4].forEach((t) => set.add(t));
      continue;
    }
    if (!/^[1-4]$/.test(p)) {
      throw new Error(`Invalid tier value "${p}". Expected 1, 2, 3, 4, or all.`);
    }
    set.add(Number(p));
  }
  return Array.from(set).sort((a, b) => a - b);
}

function parseArgs(argv) {
  const opts = {
    tiersRaw: 'all',
    baseUrl: DEFAULT_BASE_URL,
    dryRun: false,
    selfTest: false,
    json: false,
    help: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') {
      opts.help = true;
    } else if (arg === '--dry-run') {
      opts.dryRun = true;
    } else if (arg === '--self-test') {
      opts.selfTest = true;
    } else if (arg === '--json') {
      opts.json = true;
    } else if (arg.startsWith('--tier=')) {
      opts.tiersRaw = arg.slice('--tier='.length);
    } else if (arg === '--tier') {
      if (i + 1 >= argv.length) throw new Error('Missing value for --tier');
      opts.tiersRaw = argv[++i];
    } else if (arg.startsWith('--base-url=')) {
      opts.baseUrl = arg.slice('--base-url='.length).replace(/\/+$/, '');
    } else if (arg === '--base-url') {
      if (i + 1 >= argv.length) throw new Error('Missing value for --base-url');
      opts.baseUrl = argv[++i].replace(/\/+$/, '');
    } else {
      throw new Error(`Unknown CLI argument: ${arg}`);
    }
  }

  opts.tiers = parseTiers(opts.tiersRaw);
  return opts;
}

export async function runSuite(tests, client) {
  const startedAt = Date.now();
  const results = [];
  let passed = 0;
  let failed = 0;

  for (const t of tests) {
    const t0 = Date.now();
    try {
      await t.fn({ client });
      passed += 1;
      results.push({
        id: t.id,
        tier: t.tier,
        area: t.area,
        title: t.title,
        status: 'pass',
        durationMs: Date.now() - t0,
      });
    } catch (err) {
      failed += 1;
      results.push({
        id: t.id,
        tier: t.tier,
        area: t.area,
        title: t.title,
        status: 'fail',
        durationMs: Date.now() - t0,
        error: err?.message || String(err),
      });
    }
  }

  return {
    counts: {
      total: tests.length,
      passed,
      failed,
      skipped: 0,
    },
    durationMs: Date.now() - startedAt,
    results,
  };
}

function printHumanReport(report) {
  console.log(`RideOn E2E Runner — mode=${report.mode} baseUrl=${report.baseUrl} tiers=[${report.tiers.join(',')}]`);
  console.log(`Run ID: ${report.runId}`);
  console.log('-'.repeat(88));

  if (report.mode === 'dry-run') {
    for (const r of report.results) {
      console.log(`[T${r.tier}] ${r.id.padEnd(10)} | ${r.area} | ${r.title}`);
    }
    console.log('-'.repeat(88));
    console.log(`DRY-RUN ENUMERATED: ${report.counts.total} tests across tiers [${report.tiers.join(', ')}]`);
    return;
  }

  for (const r of report.results) {
    const badge = r.status === 'pass' ? 'PASS' : 'FAIL';
    console.log(`[${badge}] ${r.id.padEnd(10)} (${r.durationMs}ms) ${r.title}`);
    if (r.error) {
      console.log(`       -> ${r.error}`);
    }
  }

  if (report.mutationChecks) {
    console.log('-'.repeat(88));
    console.log('Phase 2 — Contract-Breaker Mutation Checks:');
    for (const m of report.mutationChecks.checks) {
      const badge = m.caught ? 'CAUGHT' : 'MISSED';
      console.log(`[${badge}] ${m.fault.padEnd(22)} -> ${m.targetTestId}: ${m.description}`);
    }
  }

  console.log('-'.repeat(88));
  console.log(
    `SUMMARY: total=${report.counts.total} passed=${report.counts.passed} failed=${report.counts.failed} duration=${report.durationMs}ms`
  );
  if (report.mutationChecks) {
    console.log(
      `MUTATIONS: ${report.mutationChecks.caught}/${report.mutationChecks.total} contract-breakers caught`
    );
  }
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (err) {
    console.error(`Error: ${err.message}`);
    console.error('Run with --help for usage.');
    process.exit(1);
  }

  if (opts.help) {
    console.log(HELP_TEXT);
    process.exit(0);
  }

  const allByTier = {
    1: defineTier1(),
    2: defineTier2(),
    3: defineTier3(),
    4: defineTier4(),
  };
  const allTests = [...allByTier[1], ...allByTier[2], ...allByTier[3], ...allByTier[4]];
  const selectedTests = opts.tiers.flatMap((t) => allByTier[t]);

  if (opts.dryRun) {
    const report = {
      ok: true,
      mode: 'dry-run',
      baseUrl: opts.baseUrl,
      runId: 'dry-run',
      tiers: opts.tiers,
      counts: {
        total: selectedTests.length,
        passed: 0,
        failed: 0,
        skipped: selectedTests.length,
      },
      durationMs: 0,
      mutationChecks: null,
      results: selectedTests.map((t) => ({
        id: t.id,
        tier: t.tier,
        area: t.area,
        title: t.title,
        status: 'skipped',
        durationMs: 0,
      })),
    };
    if (opts.json) {
      console.log(JSON.stringify(report, null, 2));
    } else {
      printHumanReport(report);
    }
    process.exit(0);
  }

  if (opts.selfTest) {
    const report = await runSelfTest({
      tiers: opts.tiers,
      selectedTests,
      allTests,
      runSuite,
    });
    if (opts.json) {
      console.log(JSON.stringify(report, null, 2));
    } else {
      printHumanReport(report);
    }
    process.exit(report.ok ? 0 : 1);
  }

  // Live mode
  const runId = createRunId();
  const client = createClient({ baseUrl: opts.baseUrl, runId });
  const live = await runSuite(selectedTests, client);
  const report = {
    ok: live.counts.failed === 0,
    mode: 'live',
    baseUrl: opts.baseUrl,
    runId,
    tiers: opts.tiers,
    counts: live.counts,
    durationMs: live.durationMs,
    mutationChecks: null,
    results: live.results,
  };

  if (opts.json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    printHumanReport(report);
  }
  process.exit(report.ok ? 0 : 1);
}

main().catch((err) => {
  console.error(err?.stack || err);
  process.exit(1);
});
