#!/usr/bin/env node
/**
 * Liqra POS — Yeni Firma (Merchant) Onboarding Scripti
 *
 * Kullanım:
 *   node scripts/create-merchant.js \
 *     --businessName "Ahmet Bey Büfe" \
 *     --adminEmail   "ahmet@bey-bufe.com" \
 *     --adminPassword "Bufe2024!" \
 *     --adminName    "Ahmet Yılmaz"
 *
 * Alternatif (interaktif mod):
 *   node scripts/create-merchant.js
 *
 * Gereksinimler:
 *   - Backend çalışıyor olmalı  (npm run dev)
 *   - .env'de SUPER_ADMIN_SECRET tanımlı olmalı
 */

'use strict';
const readline = require('readline');

// Backend URL — gerekirse değiştir
const BACKEND_URL     = process.env.BACKEND_URL  || 'http://localhost:3000';
const SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_SECRET;

// ── Argüman parse ─────────────────────────────────────────────────────────────
function parseArgs() {
  const args = {};
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const key = argv[i].replace(/^--/, '');
    const val = argv[i + 1];
    if (val && !val.startsWith('--')) {
      args[key] = val;
      i++;
    }
  }
  return args;
}

// ── Renk yardımcıları ─────────────────────────────────────────────────────────
const c = {
  teal:  '\x1b[36m',
  green: '\x1b[32m',
  red:   '\x1b[31m',
  yellow:'\x1b[33m',
  bold:  '\x1b[1m',
  reset: '\x1b[0m',
};

function log(color, msg) { console.log(`${color}${msg}${c.reset}`); }

// ── İnteraktif prompt ─────────────────────────────────────────────────────────
async function prompt(question, defaultVal) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => {
    const q = defaultVal ? `${question} [${defaultVal}]: ` : `${question}: `;
    rl.question(q, answer => {
      rl.close();
      resolve(answer.trim() || defaultVal || '');
    });
  });
}

// ── fetch (Node 18+ yerleşik) ─────────────────────────────────────────────────
async function callOnboardApi({ businessName, adminEmail, adminPassword, adminName }, superAdminKey) {
  const url = `${BACKEND_URL}/api/auth/merchant/onboard`;
  const res  = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type':      'application/json',
      'X-Super-Admin-Key': superAdminKey,
    },
    body: JSON.stringify({ businessName, adminEmail, adminPassword, adminName }),
  });

  const body = await res.json();
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${body.error ?? JSON.stringify(body)}`);
  }
  return body;
}

// ── Ana akış ─────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n' + c.bold + c.teal);
  console.log('  ██╗     ██╗ ██████╗ ██████╗  █████╗ ');
  console.log('  ██║     ██║██╔═══██╗██╔══██╗██╔══██╗');
  console.log('  ██║     ██║██║   ██║██████╔╝███████║');
  console.log('  ██║     ██║██║▄▄ ██║██╔══██╗██╔══██║');
  console.log('  ███████╗██║╚██████╔╝██║  ██║██║  ██║');
  console.log('  ╚══════╝╚═╝ ╚══▀▀═╝ ╚═╝  ╚═╝╚═╝  ╚═╝');
  console.log(c.reset);
  log(c.bold, '  POS Terminal — Yeni Firma Onboarding Aracı\n');

  let args = parseArgs();
  let superAdminKey = SUPER_ADMIN_KEY;

  // Super admin key kontrolü
  if (!superAdminKey) {
    log(c.yellow, '⚠  SUPER_ADMIN_SECRET ortam değişkeni bulunamadı.');
    superAdminKey = await prompt('Super Admin Key');
    if (!superAdminKey) {
      log(c.red, '✗  Super admin key zorunludur. Çıkılıyor.');
      process.exit(1);
    }
  }

  // Argüman yoksa interaktif mod
  if (!args.businessName) {
    log(c.teal, '─── Firma Bilgileri ─────────────────────────────────\n');
    args.businessName  = await prompt('Firma adı (örn: Ahmet Bey Büfe)');
    args.adminName     = await prompt('Admin adı soyadı');
    args.adminEmail    = await prompt('Admin e-posta');
    args.adminPassword = await prompt('Admin şifre (min 8 karakter)');
  }

  // Validasyon
  const { businessName, adminEmail, adminPassword, adminName } = args;
  const errors = [];
  if (!businessName)             errors.push('Firma adı (--businessName) zorunlu.');
  if (!adminEmail)               errors.push('Admin e-posta (--adminEmail) zorunlu.');
  if (!adminPassword)            errors.push('Admin şifre (--adminPassword) zorunlu.');
  if ((adminPassword||'').length < 8) errors.push('Şifre en az 8 karakter olmalı.');
  if (!adminName)                errors.push('Admin adı (--adminName) zorunlu.');

  if (errors.length) {
    errors.forEach(e => log(c.red, `  ✗ ${e}`));
    process.exit(1);
  }

  log(c.teal, '\n─── Oluşturuluyor ───────────────────────────────────\n');
  log('', `  Firma    : ${c.bold}${businessName}${c.reset}`);
  log('', `  Admin    : ${adminName} <${adminEmail}>`);
  log('', `  Şifre    : ${'*'.repeat(adminPassword.length)}\n`);

  try {
    log(c.teal, '⏳  Backend\'e istek gönderiliyor...');
    const result = await callOnboardApi({ businessName, adminEmail, adminPassword, adminName }, superAdminKey);

    log(c.green, '\n✅  Firma başarıyla oluşturuldu!\n');
    console.log('─'.repeat(52));
    log(c.bold, '  MÜŞTERİYE VERİLECEK GİRİŞ BİLGİLERİ');
    console.log('─'.repeat(52));
    log('', `  Firma ID  : ${c.teal}${result.data.merchantId}${c.reset}`);
    log('', `  E-posta   : ${c.bold}${adminEmail}${c.reset}`);
    log('', `  Şifre     : ${c.bold}${adminPassword}${c.reset}`);
    log('', `  Rol       : merchant_admin`);
    log('', `  UID       : ${result.data.admin.uid}`);
    console.log('─'.repeat(52));
    log(c.yellow, '\n⚠  Bu bilgileri müşteriye güvenli kanaldan iletin.');
    log(c.yellow, '   Şifreyi ilk girişte değiştirmesini isteyin.\n');

    // Sonraki adımlar
    log(c.teal, '─── Sonraki Adımlar ─────────────────────────────────\n');
    log('', '  1. Müşteri bu bilgilerle liqra-web\'e veya liqra-terminal\'e giriş yapar.');
    log('', '  2. Personel menüsünden kasiyer hesaplarını kendisi oluşturabilir.');
    log('', '  3. Kasiyerler oluştuktan sonra liqra-terminal\'e giriş yapabilir.\n');

  } catch (err) {
    log(c.red, `\n✗  Hata: ${err.message}\n`);
    if (err.message.includes('ECONNREFUSED')) {
      log(c.yellow, '  Backend çalışıyor mu? → npm run dev');
    }
    process.exit(1);
  }
}

main();
