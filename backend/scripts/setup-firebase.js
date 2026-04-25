#!/usr/bin/env node
/**
 * Firebase Service Account → .env ayarlama aracı
 *
 * Kullanım:
 *   node scripts/setup-firebase.js --json ./serviceAccount.json
 *
 * Bu script:
 *   1. serviceAccount.json dosyasını okur
 *   2. base64'e çevirir
 *   3. .env dosyasına FIREBASE_SERVICE_ACCOUNT_BASE64 olarak yazar
 */
'use strict';
const fs   = require('fs');
const path = require('path');

const args    = process.argv.slice(2);
const jsonArg = args[args.indexOf('--json') + 1];

if (!jsonArg) {
  console.error(`
Kullanım: node scripts/setup-firebase.js --json ./serviceAccount.json

Firebase Console > Proje Ayarları > Hizmet Hesapları >
"Yeni Özel Anahtar Oluştur" butonuna tıkla ve JSON'ı kaydet.
`);
  process.exit(1);
}

const jsonPath = path.resolve(jsonArg);
if (!fs.existsSync(jsonPath)) {
  console.error(`Dosya bulunamadı: ${jsonPath}`);
  process.exit(1);
}

const raw    = fs.readFileSync(jsonPath, 'utf8');
const base64 = Buffer.from(raw).toString('base64');
const envPath = path.resolve(__dirname, '../.env');

let envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';

if (envContent.includes('FIREBASE_SERVICE_ACCOUNT_BASE64=')) {
  // Mevcut değeri güncelle
  envContent = envContent.replace(
    /FIREBASE_SERVICE_ACCOUNT_BASE64=.*/,
    `FIREBASE_SERVICE_ACCOUNT_BASE64=${base64}`
  );
} else {
  envContent += `\nFIREBASE_SERVICE_ACCOUNT_BASE64=${base64}\n`;
}

fs.writeFileSync(envPath, envContent);

const sa = JSON.parse(raw);
console.log(`
✅ Firebase Service Account ayarlandı!
   Proje  : ${sa.project_id}
   E-posta: ${sa.client_email}
   .env    : FIREBASE_SERVICE_ACCOUNT_BASE64 güncellendi

Şimdi backend'i yeniden başlat:
   npm run dev
`);
