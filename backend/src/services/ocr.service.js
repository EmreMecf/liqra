'use strict';
const Anthropic = require('@anthropic-ai/sdk');
const axios     = require('axios');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// ── OCR + Yapay Zeka Parsing ───────────────────────────────────────────────

/**
 * Base64 görüntüden fiş/fatura okur ve yapılandırılmış harcama verisi döner
 * @param {string} base64Image  — base64 kodlu görüntü (jpeg/png/webp)
 * @param {string} mediaType    — 'image/jpeg' | 'image/png' | 'image/webp'
 * @returns {Promise<ReceiptResult>}
 */
async function parseReceipt(base64Image, mediaType = 'image/jpeg') {
  const systemPrompt = `Sen bir Türk fiş/fatura analiz asistanısın.
Kullanıcıdan bir fiş veya fatura görüntüsü gelecek. Görevin:
1. Görüntüdeki yazıları oku (OCR)
2. Harcama kalemlerini çıkar
3. Aşağıdaki JSON formatında yanıt ver — başka hiçbir şey yazma

JSON formatı:
{
  "merchant": "mağaza/restoran/işyeri adı",
  "date": "YYYY-MM-DD veya null",
  "total": 123.45,
  "currency": "TRY",
  "category": "yeme_icme|market|ulasim|eglence|saglik|giyim|fatura|diger",
  "items": [
    { "name": "ürün adı", "quantity": 1, "unitPrice": 12.50, "total": 12.50 }
  ],
  "tax": 18.75,
  "confidence": 0.95,
  "rawText": "fişten okunan ham metin"
}

Eğer görüntü fiş değilse veya okunamazsa: { "error": "Fiş okunamadı", "confidence": 0 }
Tüm parasal değerler TL cinsinden olmalı. Kategori tahmini zorunlu.`;

  const response = await client.messages.create({
    model:      'claude-sonnet-4-5',
    max_tokens: 1024,
    system:     systemPrompt,
    messages: [{
      role:    'user',
      content: [
        {
          type:   'image',
          source: {
            type:       'base64',
            media_type: mediaType,
            data:       base64Image,
          },
        },
        {
          type: 'text',
          text: 'Bu fişi/faturayı analiz et ve JSON formatında yanıt ver.',
        },
      ],
    }],
  });

  const raw = response.content[0].text.trim();

  // JSON bloğunu çıkar (markdown code fence varsa temizle)
  const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) || [null, raw];
  const jsonStr   = jsonMatch[1].trim();

  try {
    const parsed = JSON.parse(jsonStr);
    if (parsed.error) {
      return { success: false, error: parsed.error, confidence: parsed.confidence ?? 0 };
    }
    return {
      success: true,
      data:    _normalizeReceipt(parsed),
    };
  } catch {
    return { success: false, error: 'JSON parse hatası', rawResponse: raw };
  }
}

/**
 * Google Vision API ile OCR yapıp ham metin döner, sonra Claude ile parse eder
 * TODO: GOOGLE_VISION_API_KEY env değişkeni gerektirir
 */
async function parseReceiptViaVision(base64Image) {
  const apiKey = process.env.GOOGLE_VISION_API_KEY;
  if (!apiKey) {
    // Vision API yoksa direkt Claude ile işle
    return parseReceipt(base64Image);
  }

  try {
    const visionRes = await axios.post(
      `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`,
      {
        requests: [{
          image:    { content: base64Image },
          features: [{ type: 'TEXT_DETECTION', maxResults: 1 }],
        }],
      },
      { timeout: 10000 }
    );

    const text = visionRes.data.responses?.[0]?.fullTextAnnotation?.text ?? '';
    if (!text) return { success: false, error: 'Görüntüde metin bulunamadı' };

    // Çıkarılan metni Claude ile yapılandır
    return _parseReceiptText(text);
  } catch (err) {
    console.warn('[Vision API Error] Fallback to Claude vision:', err.message);
    return parseReceipt(base64Image);
  }
}

/**
 * Ham fiş metnini Claude ile parse eder
 */
async function _parseReceiptText(text) {
  const response = await client.messages.create({
    model:      'claude-haiku-4-5-20251001',
    max_tokens: 1024,
    messages: [{
      role:    'user',
      content: `Aşağıdaki fiş metnini analiz et ve şu JSON formatında yanıt ver — başka hiçbir şey yazma:
{
  "merchant": "...", "date": "YYYY-MM-DD veya null", "total": 0.00,
  "currency": "TRY", "category": "yeme_icme|market|ulasim|eglence|saglik|giyim|fatura|diger",
  "items": [], "tax": 0.00, "confidence": 0.0
}

FİŞ METNİ:
${text}`,
    }],
  });

  const raw = response.content[0].text.trim();
  const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) || [null, raw];
  try {
    const parsed = JSON.parse(jsonMatch[1].trim());
    return { success: true, data: _normalizeReceipt(parsed) };
  } catch {
    return { success: false, error: 'Parse hatası', rawText: text };
  }
}

/**
 * Normalize — eksik alanları varsayılan değerlerle tamamlar
 */
function _normalizeReceipt(raw) {
  return {
    merchant:   raw.merchant   ?? 'Bilinmeyen',
    date:       raw.date       ?? new Date().toISOString().slice(0, 10),
    total:      Number(raw.total)   || 0,
    currency:   raw.currency   ?? 'TRY',
    category:   raw.category   ?? 'diger',
    items:      Array.isArray(raw.items) ? raw.items : [],
    tax:        Number(raw.tax)     || 0,
    confidence: Number(raw.confidence) || 0.5,
    rawText:    raw.rawText    ?? '',
  };
}

// ── Kategori → Flutter harcama kategorisine map ────────────────────────────
const CATEGORY_MAP = {
  yeme_icme: 'Yeme-İçme',
  market:    'Market',
  ulasim:    'Ulaşım',
  eglence:   'Eğlence',
  saglik:    'Sağlık',
  giyim:     'Giyim',
  fatura:    'Fatura',
  diger:     'Diğer',
};

function mapCategory(raw) {
  return CATEGORY_MAP[raw] ?? 'Diğer';
}

module.exports = { parseReceipt, parseReceiptViaVision, mapCategory };
