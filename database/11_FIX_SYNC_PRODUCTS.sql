-- ============================================
-- 7TRES7 - SINCRONIZAR PRODUCTOS APP <-> ADMIN
-- Ejecutar en Supabase SQL Editor
-- Fecha: 23 Febrero 2026
-- ============================================
-- Problema: "Pollo Parrilla" existe como 1 producto en Supabase
-- pero la app usuario lo muestra como Muslo y Pechuga separados.
-- También falta Flan en Supabase.
-- ============================================

-- 1. Desactivar "Pollo Parrilla" (viejo)
UPDATE products SET is_active = false WHERE slug = 'pollo-parrilla';

-- 2. Crear Muslo y Pechuga como productos separados
INSERT INTO products (name, slug, category_id, icon, price, is_active, sort_order)
VALUES
  ('Muslo de Pollo', 'pollo-muslo',
   (SELECT id FROM categories WHERE slug = 'restaurant'),
   '🍗', 15530, true, 50),
  ('Pechuga de Pollo', 'pollo-pechuga',
   (SELECT id FROM categories WHERE slug = 'restaurant'),
   '🍗', 15530, true, 51)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, price = EXCLUDED.price, is_active = true;

-- 3. Agregar Flan si no existe
INSERT INTO products (name, slug, category_id, icon, price, is_active, sort_order)
VALUES
  ('Flan', 'flan',
   (SELECT id FROM categories WHERE slug = 'postres'),
   '🍮', 3500, true, 90)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, price = EXCLUDED.price, is_active = true;

-- ============================================
-- VERIFICAR
-- ============================================
SELECT name, slug, price, is_active
FROM products
WHERE slug IN ('pollo-parrilla', 'pollo-muslo', 'pollo-pechuga', 'flan')
ORDER BY slug;
