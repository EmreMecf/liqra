'use strict';
const express  = require('express');
const Joi      = require('joi');
const ocrSvc   = require('../services/ocr.service');

const router = express.Router();

// Dosya boyutu limiti: 5 MB base64 ≈ 3.75 MB gerçek görüntü
const MAX_BASE64_SIZE = 5 * 1024 * 1024;

const ocrSchema = Joi.object({
  image:     Joi.string().max(MAX_BASE64_SIZE).required(),
  mediaType: Joi.string()
    .valid('image/jpeg', 'image/png', 'image/webp')
    .default('image/jpeg'),
  useVision: Joi.boolean().default(false),
});

// ── POST /api/ocr/receipt ──────────────────────────────────────────────────
router.post('/receipt', async (req, res) => {
  const { error, value } = ocrSchema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details[0].message });

  try {
    const result = value.useVision
      ? await ocrSvc.parseReceiptViaVision(value.image)
      : await ocrSvc.parseReceipt(value.image, value.mediaType);

    if (!result.success) {
      return res.status(422).json({ error: result.error });
    }

    // Kategoriyi Flutter uyumlu forma çevir
    result.data.categoryLabel = ocrSvc.mapCategory(result.data.category);

    return res.json(result.data);
  } catch (err) {
    console.error('[OCR Error]', err.message);
    return res.status(500).json({ error: 'Fiş okuma başarısız.' });
  }
});

module.exports = router;
