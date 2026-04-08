'use strict';
const Anthropic = require('@anthropic-ai/sdk');
const config    = require('../config');

const client = new Anthropic({ apiKey: config.anthropic.apiKey });

// ── Sistem Promptları ────────────────────────────────────────────────────────

const SYSTEM_PROMPTS = {
  budget_audit: (ctx) => `
Sen bir mali denetim uzmanısın. Kullanıcının harcama verilerine erişimin var.
Konuşma dili: Türkçe. Yanıtlarını MUTLAKA Markdown formatında yaz.

Kullanıcı bağlamı:
- Aylık gelir: ${ctx.monthlyIncome} TL
- Aylık gider: ${ctx.monthlyExpenses} TL
- Net nakit: ${ctx.netCash} TL
- İşlem özeti: ${ctx.transactionsSummary}

Görevin:
- Bütçe aşımlarını tespit et ve acımasızca işaretle
- Her önerin sonunda "Bu kesintinin yıllık etkisi: X TL" hesabını yap
- Somut TL bazında kesinti önerileri sun
- Tablo ve liste formatı kullan
- "Bence" veya "sanırım" gibi belirsiz ifadeler kullanma — direktif ol
`.trim(),

  portfolio_advisor: (ctx) => `
Sen deneyimli bir portföy yöneticisisin. Türkiye yatırım ekosistemini iyi biliyorsun.
Konuşma dili: Türkçe. Yanıtlarını MUTLAKA Markdown formatında yaz.

Kullanıcı profili:
- Risk profili: ${ctx.riskProfile}
- Aylık yatırım kapasitesi: ${ctx.netCash} TL
- Portföy: ${ctx.portfolioSummary}
${ctx.goalTitle ? `- Hedef: ${ctx.goalTitle} (%${ctx.goalProgress?.toFixed(0)} tamamlandı)` : ''}

Kurallar:
- Dağılım önerisinde her zaman yüzde + TL bazında somut rakam ver
- Türkiye'ye özgü araçlara odaklan: TEFAS, BIST, altın, kripto
- ABD'ye özgü araçları (401K, Roth IRA vb.) önerme
- Her öneri için risk/getiri dengesi analizi yap
`.trim(),

  goal_tracker: (ctx) => `
Sen bir finansal koç ve hedef takip uzmanısın. Türkçe yanıt ver. Markdown kullan.

${ctx.goalTitle ? `
Kullanıcının hedefi: ${ctx.goalTitle}
İlerleme: %${ctx.goalProgress?.toFixed(0)}
Deadline: ${ctx.goalDeadline || 'Belirsiz'}
Aylık birikim kapasitesi: ${ctx.netCash} TL
` : 'Kullanıcının aktif hedefi yok. Hedef oluşturmasını öner.'}

Hedefe ulaşma hızını artırmanın somut 3 yolunu öner.
Her önerinin aylık ve yıllık TL etkisini hesapla.
`.trim(),

  free_chat: (ctx) => `
Sen kişisel finans alanında uzman bir Türk AI asistanısın. Türkçe yanıt ver. Markdown kullan.
Türkiye ekonomisi, TL, BIST, TEFAS, altın, kripto konularını iyi biliyorsun.

Kullanıcı profili özeti:
- Risk profili: ${ctx.riskProfile}
- Net aylık birikim kapasitesi: ${ctx.netCash} TL

Dürüst, veri odaklı, pratik ol. Gerekirse kullanıcının fikirlerine itiraz et.
`.trim(),
};

// ── Ana Servis Fonksiyonu ─────────────────────────────────────────────────────

/**
 * Claude API'ye mesaj gönderir
 * @param {string} message - Kullanıcı mesajı
 * @param {string} mode    - budget_audit | portfolio_advisor | goal_tracker | free_chat
 * @param {object} context - Kullanıcı finansal bağlamı
 * @param {Array}  history - Konuşma geçmişi (son 10 mesaj)
 * @returns {Promise<{id, content, inputTokens, outputTokens}>}
 */
async function sendMessage({ message, mode, context, history = [] }) {
  const systemPrompt = SYSTEM_PROMPTS[mode]?.(context) ?? SYSTEM_PROMPTS.free_chat(context);

  // Geçmişi Claude formatına dönüştür
  const messages = [
    ...history.map(h => ({ role: h.role, content: h.content })),
    { role: 'user', content: message },
  ];

  const response = await client.messages.create({
    model:      config.anthropic.model,
    max_tokens: config.anthropic.maxTokens,
    system:     systemPrompt,
    messages,
  });

  const content = response.content[0]?.text ?? '';

  return {
    id:           response.id,
    content,
    timestamp:    new Date().toISOString(),
    inputTokens:  response.usage.input_tokens,
    outputTokens: response.usage.output_tokens,
  };
}

// ── Aylık Otomatik Rapor ──────────────────────────────────────────────────────

/**
 * Her ayın 1'i çalışır — tam bütçe denetimi
 * @param {object} userData - Kullanıcı aylık verisi
 */
async function generateMonthlyReport(userData) {
  const { monthName, context } = userData;

  const response = await client.messages.create({
    model:      config.anthropic.model,
    max_tokens: 2000,
    system:     SYSTEM_PROMPTS.budget_audit(context),
    messages: [{
      role: 'user',
      content: `${monthName} ayı için tam bütçe denetimi yap.
      Geçen aya göre karşılaştırmalı analiz sun.
      Gelecek ay için 3 somut aksiyon öner.
      Yanıtı Markdown formatında yaz.`,
    }],
  });

  return {
    content:   response.content[0]?.text ?? '',
    month:     monthName,
    createdAt: new Date().toISOString(),
  };
}

module.exports = { sendMessage, generateMonthlyReport };
