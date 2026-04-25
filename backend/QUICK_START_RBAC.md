# 🚀 RBAC Quick Start Guide

## ⚡ 5 Adımda Kurulum

### 1️⃣ PostgreSQL Migration (Veritabanı)
```bash
cd muhasebe/backend
psql -U your_user -d your_db -f src/migrations/001_add_user_roles.sql
```

### 2️⃣ Backend'i Start Et
```bash
npm run dev
# Server çalışması gerekli: http://localhost:3000
```

### 3️⃣ Test Tokens Oluştur
```bash
curl -X POST http://localhost:3000/api/auth/test/tokens/test-user-123

# Çıktıdan token'ları kopyala:
# {
#   "tokens": {
#     "merchant_admin": "eyJhbGc...",
#     "merchant_cashier": "eyJhbGc...",
#     ...
#   }
# }
```

### 4️⃣ merchant_admin Erişim (Başarılı ✓)
```bash
TOKEN="<merchant_admin_token_buraya>"

curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/merchant/dashboard

# Response: 200 OK + Dashboard data
```

### 5️⃣ merchant_cashier Erişim (Başarısız ✗)
```bash
CASHIER_TOKEN="<merchant_cashier_token_buraya>"

curl -H "Authorization: Bearer $CASHIER_TOKEN" \
  http://localhost:3000/api/merchant/dashboard

# Response: 403 Forbidden
# "Bu işlemi yapma yetkiniz yok. Gerekli rol: merchant_admin."
```

---

## 📊 Test Endpoints

| Endpoint | Açıklama |
|----------|----------|
| `POST /api/auth/test/tokens/:userId` | Test token oluştur |
| `GET /api/auth/test/info` | Kullanılabilir endpoints |
| `GET /api/auth/test/rbac-demo` | İnteraktif RBAC demo |

---

## 🔑 Test Tokens

```bash
# Merchant Admin
curl -X POST http://localhost:3000/api/auth/test/tokens/admin1

# Merchant Cashier  
curl -X POST http://localhost:3000/api/auth/test/tokens/cashier1

# Her user_id için farklı token oluşturulur
# Tokens 15 dakika geçerli
```

---

## 🛠️ Kurulan Endpoints

### Admin Only (`merchant_admin`)
```
GET    /api/merchant/dashboard           → Pano
GET    /api/merchant/reports             → Raporlar
GET    /api/merchant/staff               → Personel
POST   /api/merchant/staff/:id/role      → Rol Güncelle
PUT    /api/merchant/settings            → Ayarlar
```

### Admin + Cashier (`both roles`)
```
POST   /api/merchant/transaction         → İşlem Yarat
GET    /api/merchant/transactions        → İşlemleri Listele
```

---

## 🧪 Hızlı Test

```bash
# 1. Token al
ADMIN_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/test/tokens/demo | jq -r '.tokens.merchant_admin')

# 2. Dashboard'a eriş (200)
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:3000/api/merchant/dashboard | jq .

# 3. Token'sız dene (401)
curl http://localhost:3000/api/merchant/dashboard | jq .

# 4. Cashier token ile admin route (403)
CASHIER_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/test/tokens/demo | jq -r '.tokens.merchant_cashier')
curl -H "Authorization: Bearer $CASHIER_TOKEN" \
  http://localhost:3000/api/merchant/dashboard | jq .
```

---

## 📖 Full Guide

Detaylı dokumentasyon: `RBAC_IMPLEMENTATION_GUIDE.md`

