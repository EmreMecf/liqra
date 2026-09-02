/**
 * fetchTefasFunds — TEFAS fon kataloğunu günlük olarak Firestore'a yazar.
 *
 * Neden ayrı ve GÜNLÜK bir fonksiyon:
 *   • Katalog ≈315 KB. Bunu 2 dakikada bir güncellenen market/live_prices
 *     dökümanına koymak günde ~226 MB gereksiz yazma demek olurdu.
 *   • Fon listesi günde en fazla bir kez değişir; 2 dakikada bir çekmenin
 *     hiçbir faydası yok.
 *
 * Firestore hedefi: tefas_funds/catalog  (tek doküman → istemcide 1 okuma)
 *   {
 *     updatedAt: Timestamp,
 *     count:     2574,
 *     funds:     [{ c: "AAL", n: "ATA PORTFÖY…", t: "Para Piyasası Fonu", r: 1, k: "YAT" }]
 *   }
 *
 * NOT: Birim pay değeri (fiyat) TEFAS'ın ücretsiz ucunda YOK. Kullanıcı fon
 * fiyatını uygulamada elle girer; bu fonksiyon yalnızca arama/seçim için
 * gereken katalogu sağlar.
 */

"use strict";

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const { fetchFundCatalog } = require("../market/sources/tefas");

const CATALOG_DOC = "tefas_funds/catalog";

exports.fetchTefasFunds = onSchedule(
  {
    // Hafta içi + hafta sonu 19:30 — TEFAS fon listesini gün sonunda tazeler
    schedule:       "30 19 * * *",
    timeZone:       "Europe/Istanbul",
    memory:         "512MiB",
    timeoutSeconds: 300,
    region:         "europe-west1",
  },
  async () => {
    const started = Date.now();
    const funds   = await fetchFundCatalog();

    if (funds.length === 0) {
      // Sahte veri yazma, mevcut katalogu da silme — olduğu gibi bırak.
      console.error("[fetchTefasFunds] Katalog boş döndü — Firestore güncellenmedi.");
      return;
    }

    const db = getFirestore();
    await db.doc(CATALOG_DOC).set({
      updatedAt: Timestamp.now(),
      count:     funds.length,
      funds,
    });

    console.log(
      `[fetchTefasFunds] ✓ ${funds.length} fon yazıldı (${Date.now() - started}ms)`,
    );
  },
);
