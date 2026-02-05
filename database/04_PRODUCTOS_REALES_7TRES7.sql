-- ============================================
-- 7TRES7 - PRODUCTOS REALES COMPLETOS
-- Ejecutar DESPUÉS de los schemas 01, 02, 03
-- Esto REEMPLAZA los productos de ejemplo
-- ============================================

-- Limpiar productos de ejemplo
TRUNCATE TABLE products CASCADE;

-- ============================================
-- Verificar/Crear subcategorías
-- ============================================

-- Solo insertar si no existen
INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Premium', 'premium', c.id, 1 
FROM categories c WHERE c.slug = 'empanadas'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'premium');

INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Comunes', 'comunes', c.id, 2 
FROM categories c WHERE c.slug = 'empanadas'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'comunes');

-- ============================================
-- EMPANADAS PREMIUM - $1.700
-- ============================================

INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, cooking_methods, is_active, is_featured, sort_order) VALUES
('Carne Cortada a Cuchillo', 'emp-carne-cuchillo', '🥩', 1700, 
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'premium'),
  ARRAY['frito', 'horno']::cooking_method[], true, true, 1),

('Jamón y Queso Premium', 'emp-jyq-premium', '🥓', 1700,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'premium'),
  ARRAY['frito', 'horno']::cooking_method[], true, false, 2),

('Pollo Cortado a Cuchillo', 'emp-pollo-cuchillo', '🍗', 1700,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'premium'),
  ARRAY['frito', 'horno']::cooking_method[], true, true, 3),

('Roque (JyQ)', 'emp-roque', '🧀', 1700,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'premium'),
  ARRAY['frito', 'horno']::cooking_method[], true, false, 4),

('Matambre', 'emp-matambre', '🥓', 1700,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'premium'),
  ARRAY['frito', 'horno']::cooking_method[], true, false, 5);

-- ============================================
-- EMPANADAS COMUNES - $1.500
-- ============================================

INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, cooking_methods, is_active, sort_order) VALUES
('Verdura', 'emp-verdura', '🥬', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 10),

('Árabe', 'emp-arabe', '🌯', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 11),

('Carne', 'emp-carne', '🍖', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 12),

('Capresse', 'emp-capresse', '🍅', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 13),

('Agridulce', 'emp-agridulce', '🍯', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 14),

('Calabresa', 'emp-calabresa', '🌶️', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 15),

('Humita', 'emp-humita', '🌽', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 16),

('Atún', 'emp-atun', '🐟', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 17),

('Cebolla y Muzza', 'emp-cebolla-muzza', '🧅', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 18),

('Nuez y Hierbas', 'emp-nuez-hierbas', '🌿', 1500,
  (SELECT id FROM categories WHERE slug = 'empanadas'),
  (SELECT id FROM subcategories WHERE slug = 'comunes'),
  ARRAY['frito', 'horno']::cooking_method[], true, 19);

-- ============================================
-- BEBIDAS
-- ============================================

INSERT INTO products (name, slug, icon, price, category_id, is_active, sort_order) VALUES
('Coca Cola 1.5L', 'coca-cola-15', '🥤', 3500,
  (SELECT id FROM categories WHERE slug = 'bebidas'), true, 1),

('Sprite 1.5L', 'sprite-15', '🥤', 3500,
  (SELECT id FROM categories WHERE slug = 'bebidas'), true, 2),

('Fanta 1.5L', 'fanta-15', '🥤', 3500,
  (SELECT id FROM categories WHERE slug = 'bebidas'), true, 3),

('Agua 1.5L', 'agua-15', '💧', 2000,
  (SELECT id FROM categories WHERE slug = 'bebidas'), true, 4),

('Cerveza 1L', 'cerveza-1', '🍺', 4500,
  (SELECT id FROM categories WHERE slug = 'bebidas'), true, 5);

-- ============================================
-- POSTRES
-- ============================================

INSERT INTO products (name, slug, icon, price, category_id, is_active, sort_order) VALUES
('Cheese Cake Frutos Rojos', 'cheesecake-frutos-rojos', '🍓', 4200,
  (SELECT id FROM categories WHERE slug = 'postres'), true, 1),

('ChocoTorta', 'chocotorta', '🍫', 3800,
  (SELECT id FROM categories WHERE slug = 'postres'), true, 2);

-- ============================================
-- CONFIGURACIÓN DEL NEGOCIO
-- ============================================

UPDATE business_config SET
  business_name = '7Tres7 Restaurante',
  phone = '+5492302419234',
  whatsapp = '+5492302419234',
  address = 'General Pico, La Pampa',
  delivery_enabled = true,
  delivery_fee = 0,
  delivery_min_order = 0,
  delivery_time_minutes = 45,
  delivery_radius_km = 15,
  min_empanadas_discount = 36,
  discount_percentage = 10
WHERE id IS NOT NULL;

-- Si no existe, crear
INSERT INTO business_config (
  business_name, phone, whatsapp, address,
  delivery_enabled, delivery_fee, delivery_min_order,
  delivery_time_minutes, delivery_radius_km,
  min_empanadas_discount, discount_percentage
)
SELECT 
  '7Tres7 Restaurante', '+5492302419234', '+5492302419234', 'General Pico, La Pampa',
  true, 0, 0, 45, 15, 36, 10
WHERE NOT EXISTS (SELECT 1 FROM business_config);

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

-- Ver todos los productos cargados
SELECT 
  c.icon as "🏷️",
  c.name as categoria,
  s.name as subcategoria,
  p.icon as "📦",
  p.name as producto,
  '$' || p.price as precio,
  CASE WHEN p.is_active THEN '✅' ELSE '❌' END as activo,
  CASE WHEN p.is_featured THEN '⭐' ELSE '' END as destacado
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
LEFT JOIN subcategories s ON s.id = p.subcategory_id
ORDER BY c.sort_order, s.sort_order NULLS LAST, p.sort_order;

-- Resumen por categoría
SELECT 
  c.icon || ' ' || c.name as categoria,
  COUNT(p.id) as productos,
  '$' || MIN(p.price) || ' - $' || MAX(p.price) as rango_precios
FROM categories c
LEFT JOIN products p ON p.category_id = c.id AND p.is_active = true
GROUP BY c.id, c.name, c.icon, c.sort_order
ORDER BY c.sort_order;

-- ============================================
-- FIN - Productos cargados: 17 empanadas + 5 bebidas + 2 postres = 24 productos
-- ============================================
