-- ============================================
-- 7TRES7 - AUTH & RLS UPDATE
-- Ejecutar en Supabase SQL Editor
-- Fecha: Febrero 2026
-- ============================================
-- Este script:
-- 1. Habilita RLS en TODAS las tablas
-- 2. Elimina politicas permisivas (USING true)
-- 3. Crea nuevas politicas que requieren autenticacion
-- 4. Agrega indices para performance con 4000+ clientes
-- ============================================

-- ============================================
-- PASO 1: Habilitar RLS en tablas que faltan
-- ============================================

ALTER TABLE business_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE printers ENABLE ROW LEVEL SECURITY;
ALTER TABLE print_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE printer_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- RLS ya habilitado en: orders, customers, products

-- ============================================
-- PASO 2: Eliminar politicas existentes (permisivas)
-- ============================================

DROP POLICY IF EXISTS "Allow all for authenticated" ON orders;
DROP POLICY IF EXISTS "Allow all for authenticated" ON customers;
DROP POLICY IF EXISTS "Allow all for authenticated" ON products;

-- ============================================
-- PASO 3: Crear nuevas politicas (solo authenticated)
-- ============================================

-- orders
CREATE POLICY "Authenticated full access" ON orders
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- customers
CREATE POLICY "Authenticated full access" ON customers
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- products
CREATE POLICY "Authenticated full access" ON products
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- categories
CREATE POLICY "Authenticated full access" ON categories
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- subcategories
CREATE POLICY "Authenticated full access" ON subcategories
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- business_config
CREATE POLICY "Authenticated full access" ON business_config
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- printers
CREATE POLICY "Authenticated full access" ON printers
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- print_jobs
CREATE POLICY "Authenticated full access" ON print_jobs
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- printer_templates
CREATE POLICY "Authenticated full access" ON printer_templates
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- payments
CREATE POLICY "Authenticated full access" ON payments
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- order_status_history
CREATE POLICY "Authenticated full access" ON order_status_history
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- daily_stats
CREATE POLICY "Authenticated full access" ON daily_stats
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- whatsapp_messages
CREATE POLICY "Authenticated full access" ON whatsapp_messages
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- activity_logs
CREATE POLICY "Authenticated full access" ON activity_logs
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- admin_users
CREATE POLICY "Authenticated full access" ON admin_users
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- PASO 4: Indices para performance
-- ============================================

-- Indice para busqueda de clientes por nombre
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers USING btree (name);

-- Indice para filtros de pedidos por fecha
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders USING btree (created_at DESC);

-- ============================================
-- FIN
-- ============================================
