# RBAC (Role-Based Access Control) Implementation Guide

## 📋 Genel Bakış

LIQRA SaaS platformu için 3 rol tabanlı erişim kontrolü (RBAC) sistemi kurulmuştur:

| Rol | Erişim | Örnekler |
|-----|--------|----------|
| **personal** | Bireysel kullanıcı özellikleri | Kişisel pano, profil, varlık yönetimi |
| **merchant_admin** | Tam işletme yönetimi | Pano, raporlar, personel, ayarlar |
| **merchant_cashier** | Sınırlı işletme operasyonları | İşlem oluşturma, günlük raporlar |

---

## 🗄️ Database Setup

### PostgreSQL Migration

```bash
# 1. Migration dosyasını çalıştır
psql -U your_user -d your_db -f src/migrations/001_add_user_roles.sql

# 2. Sonuc kontrol et
psql -c "SELECT id, email, role FROM users LIMIT 10;"
```

**Migration yapacaklar:**
- ✓ `user_role` enum type oluştur
- ✓ `users` tablosuna `role` kolonu ekle (default: 'personal')
- ✓ `role_permissions` referans tablosu (opsiyonal)
- ✓ Index oluştur (hızlı sorgular)

### Mevcut Kullanıcıları Güncelle

```sql
-- Tüm mevcut kullanıcıları 'personal' olarak ayarla
UPDATE users SET role = 'personal' WHERE role IS NULL;

-- Belirli kullanıcıları merchant_admin yap
UPDATE users SET role = 'merchant_admin' WHERE email = 'merchant@example.com';
```

### Firebase Firestore Alternatifi

Eğer PostgreSQL kullanmıyorsan, Firestore'da manuel olarak ekle:

```javascript
// Firestore: users/{uid}
{
  email: "user@example.com",
  role: "merchant_admin",  // Yeni alan
  created_at: Timestamp,
  updated_at: Timestamp
}
```

---

## 🔐 Middleware Kurulumu

### checkRole.middleware.js

**İşlevi:**
1. Authorization header'dan JWT token'ı extract et
2. JWT signature'ı doğrula
3. Veritabanından kullanıcı rolünü al
4. İzin verilen roller listesine karşı kontrol et
5. Başarısızsa 403 döndür

**Supported Databases:**
- ✓ PostgreSQL (pg client)
- ✓ Firebase Firestore (firebase-admin)

**Otomatik fallback:** PostgreSQL başarısız olursa → Firebase'i dene

---

## 🛣️ Routes Kurulumu

### Merchant Routes (`/api/merchant/*`)

Şu endpoints'ler eklenmiştir:

#### **Admin Only** (merchant_admin)
```
GET    /api/merchant/dashboard           → İşletme panosunu görüntüle
GET    /api/merchant/reports             → Detaylı raporlar
GET    /api/merchant/staff               → Personel listesi
POST   /api/merchant/staff/:id/role      → Personel rolü güncelle
PUT    /api/merchant/settings            → İşletme ayarlarını güncelle
```

#### **Admin + Cashier** (both roles)
```
POST   /api/merchant/transaction         → Yeni işlem oluştur
GET    /api/merchant/transactions        → İşlemleri listele
```

---

## 🔑 JWT Token Oluşturma

### Development'ta Test Tokens

```bash
# Test tokens'ı oluştur
curl -X POST http://localhost:3000/api/auth/test/tokens/test-user-123

# Response:
{
  "user_id": "test-user-123",
  "tokens": {
    "personal": "eyJhbGc...",
    "merchant_admin": "eyJhbGc...",
    "merchant_cashier": "eyJhbGc...",
    "invalid": "invalid_token"
  }
}
```

### Production'da Token Oluşturma

Firebase Auth ile sign-in yap, sonra backend'den token al:

```javascript
// Backend (app.js veya auth.routes.js)
const { generateToken } = require('./utils/jwt.utils');

// Firebase Auth'den user UID aldıktan sonra
const jwtToken = generateToken(firebaseUid, 'merchant_admin');
```

---

## 🧪 Testing

### Test Endpoints

```bash
# 1. RBAC demo'yu görüntüle
curl http://localhost:3000/api/auth/test/rbac-demo

# 2. Test tokens oluştur (user_id: your-test-id)
curl -X POST http://localhost:3000/api/auth/test/tokens/your-test-id

# Çıktıdan merchant_admin token'ını kopyala
TOKEN="eyJhbGc..."
```

### Test Case 1: merchant_admin Erişimi (Başarılı)

```bash
TOKEN="eyJhbGc..."  # merchant_admin token

# Dashboard'a erişim (200 OK)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/merchant/dashboard

# Raporlara erişim (200 OK)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/merchant/reports
```

**Beklenen Response:**
```json
{
  "success": true,
  "data": {
    "merchant_id": "your-test-id",
    "merchant_name": "Örnek Esnaf İşletmesi",
    "role": "merchant_admin",
    "stats": {...}
  }
}
```

### Test Case 2: merchant_cashier vs Admin Routes (403)

```bash
CASHIER_TOKEN="eyJhbGc..."  # merchant_cashier token

# Dashboard'a erişim (403 Forbidden)
curl -H "Authorization: Bearer $CASHIER_TOKEN" \
  http://localhost:3000/api/merchant/dashboard
```

**Beklenen Response:**
```json
{
  "error": "Bu işlemi yapma yetkiniz yok. Gerekli rol: merchant_admin.",
  "code": "INSUFFICIENT_ROLE",
  "userRole": "merchant_cashier",
  "requiredRoles": ["merchant_admin"]
}
```

### Test Case 3: Cashier İşlem Oluşturabilir (201)

```bash
CASHIER_TOKEN="eyJhbGc..."

curl -X POST \
  -H "Authorization: Bearer $CASHIER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 250.00,
    "payment_method": "cash",
    "items": [
      {
        "name": "Kahve",
        "quantity": 1,
        "price": 50.00
      }
    ]
  }' \
  http://localhost:3000/api/merchant/transaction
```

**Beklenen Response:**
```json
{
  "success": true,
  "message": "İşlem başarıyla oluşturuldu.",
  "data": {
    "transaction_id": "txn_1714089600000",
    "amount": 250.00,
    "cashier": "your-test-id",
    "cashier_role": "merchant_cashier",
    "status": "completed"
  }
}
```

### Test Case 4: Geçersiz Token (401)

```bash
INVALID_TOKEN="invalid_token_string"

curl -H "Authorization: Bearer $INVALID_TOKEN" \
  http://localhost:3000/api/merchant/dashboard

# Response: 401 Unauthorized
```

---

## 🔄 Request Flow Örneği

```
1. Client (muhasebe app)
   ↓
   User taps "Dashboard" button
   ↓
2. GET /api/merchant/dashboard
   Header: Authorization: Bearer {jwt_token}
   ↓
3. Express middleware (checkRole)
   ├─ Extract token from header
   ├─ Verify JWT signature
   ├─ Extract user ID (uid)
   ├─ Fetch user role from database
   ├─ Check if role in ['merchant_admin']?
   │  ├─ YES → call next()
   │  └─ NO → return 403 Forbidden
   ↓
4. Route handler
   ├─ req.user = { id, role, token }
   ├─ Fetch dashboard data
   ├─ return 200 OK
   ↓
5. Client receives response
   ↓
   UI displays dashboard
```

---

## 📝 Implementation Checklist

### Kurulum
- [ ] PostgreSQL migration çalıştır
- [ ] `checkRole.middleware.js` ve `merchant.routes.js` eklendi
- [ ] `auth.test.routes.js` eklendi (dev only)
- [ ] Routes `app.js`'ye register edildi
- [ ] JWT utility kuruldu

### Database
- [ ] `users` tablosuna `role` kolonu eklendi
- [ ] `role_permissions` table oluşturuldu (opsiyonal)
- [ ] Mevcut users'lar güncellendi (role = 'personal')
- [ ] Test users oluşturuldu (different roles)

### Testing
- [ ] `POST /api/auth/test/tokens/:userId` çalışıyor
- [ ] merchant_admin dashboard'a erişebiliyor
- [ ] merchant_cashier dashboard'a erişemiyor (403)
- [ ] merchant_cashier transaction oluşturabiliyor
- [ ] Invalid token 401 döndürüyor
- [ ] No token 401 döndürüyor

### Uygulama Uyumluluğu
- [ ] Frontend (muhasebe) role'e göre UI gösteriyor
- [ ] API errors (403, 401) düzgün handle ediliyor
- [ ] Token refresh logic çalışıyor
- [ ] Logout'tan sonra token cleanup'ı var

---

## ⚠️ Production Checklist

Yayına çıkmadan önce:

```javascript
// 1. Test routes'lar devre dışı
// app.js:
if (process.env.NODE_ENV === 'production') {
  app.disable('/api/auth/test/*');  // Disable test endpoints
}

// 2. JWT secret güçlü olmalı
// .env:
JWT_SECRET=ağir-rastgele-128-karakter-anahtar-buraya-uzun-ve-guvenli

// 3. HTTPS zorunlu
// middleware:
app.use((req, res, next) => {
  if (req.headers['x-forwarded-proto'] !== 'https' && process.env.NODE_ENV === 'production') {
    return res.status(403).json({ error: 'HTTPS required' });
  }
  next();
});

// 4. CORS whitelist yapılandırma
// config/index.js:
cors: {
  origin: ['https://muhasebe.app', 'https://app.muhasebe.app'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true
}

// 5. Rate limiting production'da daha sıkı
// .env:
GLOBAL_RATE_LIMIT_PER_MIN=30  // dev: 60
AI_RATE_LIMIT_PER_HOUR=10     // dev: 20
```

---

## 🐛 Troubleshooting

### "Token bulunamadı" (401)

```bash
# ✗ YANLIŞ
curl http://localhost:3000/api/merchant/dashboard

# ✓ DOĞRU
TOKEN="eyJhbGc..."
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/merchant/dashboard
```

### "Bu işlemi yapma yetkiniz yok" (403)

**Sebep:** Kullanıcı rolü izin verilen roller listesinde yok.

```bash
# Çözüm: Doğru role'ün token'ını kullan
# Veya kullanıcının veritabanında rolünü güncelle
UPDATE users SET role = 'merchant_admin' WHERE id = 'user-id';
```

### Database connection hatası

```javascript
// checkRole.middleware.js log'larını kontrol et
[RBAC] Database error: connect ECONNREFUSED

// Çözüm:
// - PostgreSQL çalışıyor mu? (psql -U user -d db)
// - DATABASE_URL doğru mu? (.env dosyasında)
// - Firebase Admin SDK başlatılmış mı? (fallback için)
```

---

## 📚 Dosya Özeti

| Dosya | Amaç |
|-------|------|
| `migrations/001_add_user_roles.sql` | PostgreSQL schema |
| `middleware/checkRole.middleware.js` | RBAC middleware (JWT + role check) |
| `routes/merchant.routes.js` | Merchant endpoints (dashboard, reports, etc.) |
| `routes/auth.test.routes.js` | Test endpoints (development only) |
| `utils/jwt.utils.js` | Token generation utilities |
| `app.js` | Routes registration |

---

## 🚀 Sonraki Adımlar

1. **Flutter/muhasebe app** tarafında:
   - Login'dan sonra token'ı secure storage'da sakla
   - API requests'inde `Authorization: Bearer {token}` header'ını ekle
   - 403 hatasında → kullanıcıya "Yetkiniz yok" mesajı göster

2. **Role-based UI:**
   - merchant_admin → Dashboard, Reports, Staff Management
   - merchant_cashier → Transaction Form, Daily Reports
   - personal → Personal Dashboard, Assets

3. **Permissions granularity:**
   - `role_permissions` table'ı kullanarak daha detaylı kontrol
   - Örnek: `['transactions:read', 'transactions:create', 'dashboard:read']`

4. **Audit logging:**
   - Her role-based action'ı log'la (who, what, when)
   - Compliance ve security audit için önemli

---

**Son Güncelleme:** 25 Nisan 2024  
**Sürüm:** 1.0.0
