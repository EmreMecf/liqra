-- Migration: Add user roles table and role column to users
-- Purpose: Implement role-based access control (RBAC)
-- Date: 2024-04-25

-- Step 1: Create roles enum type
CREATE TYPE user_role AS ENUM (
  'personal',         -- Bireysel kullanıcı
  'merchant_admin',   -- Esnaf işletme yöneticisi
  'merchant_cashier'  -- Esnaf kasiyer (sınırlı erişim)
);

-- Step 2: Add role column to users table
ALTER TABLE users ADD COLUMN role user_role DEFAULT 'personal';

-- Step 3: Add created_at and updated_at timestamps if not exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Step 4: Create index on role for faster queries
CREATE INDEX idx_users_role ON users(role);

-- Step 5: Create permissions reference table (optional but recommended)
CREATE TABLE IF NOT EXISTS role_permissions (
  id SERIAL PRIMARY KEY,
  role user_role NOT NULL,
  permission VARCHAR(100) NOT NULL,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(role, permission)
);

-- Step 6: Insert default permissions
INSERT INTO role_permissions (role, permission, description) VALUES
-- Personal user permissions
('personal', 'profile:read', 'Kendi profilini görüntüle'),
('personal', 'profile:update', 'Kendi profilini güncelle'),
('personal', 'transactions:read', 'Kendi işlemlerini görüntüle'),
('personal', 'transactions:create', 'Yeni işlem ekle'),
('personal', 'assets:read', 'Portföyü görüntüle'),
('personal', 'assets:create', 'Varlık ekle'),
('personal', 'dashboard:read', 'Kişisel panosunu görüntüle'),

-- Merchant admin permissions (all merchant operations)
('merchant_admin', 'merchant:dashboard:read', 'İşletme panosunu görüntüle'),
('merchant_admin', 'merchant:dashboard:update', 'İşletme panosunu güncelle'),
('merchant_admin', 'merchant:reports:read', 'İşletme raporlarını görüntüle'),
('merchant_admin', 'merchant:staff:manage', 'Personel yönetimi'),
('merchant_admin', 'merchant:cashier:manage', 'Kasiyer ayarları'),
('merchant_admin', 'merchant:settings:update', 'İşletme ayarlarını güncelle'),
('merchant_admin', 'merchant:analytics:read', 'İşletme analitikleri'),

-- Merchant cashier permissions (limited operations)
('merchant_cashier', 'merchant:dashboard:read', 'İşletme panosunu görüntüle (sınırlı)'),
('merchant_cashier', 'merchant:transactions:create', 'Satış işlemi oluştur'),
('merchant_cashier', 'merchant:transactions:read', 'Satış işlemlerini görüntüle'),
('merchant_cashier', 'merchant:reports:read', 'Günlük raporları görüntüle')
ON CONFLICT (role, permission) DO NOTHING;

-- Step 7: Sample data - convert existing users
-- NOTE: Run this AFTER migration, update based on your actual user data
-- UPDATE users SET role = 'personal' WHERE role IS NULL;

-- Step 8: Add check constraint
ALTER TABLE users ADD CONSTRAINT check_valid_role CHECK (role IN ('personal', 'merchant_admin', 'merchant_cashier'));
