-- ============================================
-- 7TRES7 - TODOS LOS PRODUCTOS COMPLETOS
-- Ejecutar para agregar los productos faltantes
-- ============================================

-- ============================================
-- PIZZAS
-- ============================================

INSERT INTO products (name, slug, icon, price, category_id, is_active, sort_order, description) VALUES
('Pizza Muzzarella', 'pizza-muzza', '🍕', 7900, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 1, 'Media: $3950'),
('Pizza Jamón', 'pizza-jamon', '🍕', 10000, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 2, 'Media: $5000'),
('Pizza Fugazzeta', 'pizza-fugazzeta', '🍕', 10200, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 3, 'Media: $5100'),
('Pizza Napolitana', 'pizza-napolitana', '🍕', 10800, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 4, 'Media: $5400'),
('Pizza 4 Quesos', 'pizza-4quesos', '🍕', 10400, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 5, 'Media: $5200'),
('Pizza Rúcula', 'pizza-rucula', '🍕', 12000, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 6, 'Media: $6000'),
('Pizza Palmitos', 'pizza-palmitos', '🍕', 16000, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 7, 'Media: $8000'),
('Pizza Vegetariana', 'pizza-vegetariana', '🍕', 15500, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 8, 'Media: $7750'),
('Pizza Champiñones', 'pizza-champinones', '🍕', 15300, (SELECT id FROM categories WHERE slug = 'pizzas'), true, 9, 'Media: $7650');

-- ============================================
-- MINUTAS - Subcategoría Lomitos
-- ============================================

-- Crear subcategorías de minutas si no existen
INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Lomitos', 'lomitos', c.id, 1 
FROM categories c WHERE c.slug = 'minutas'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'lomitos');

INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Hamburguesas', 'hamburguesas', c.id, 2 
FROM categories c WHERE c.slug = 'minutas'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'hamburguesas');

INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Milanesas', 'milanesas', c.id, 3 
FROM categories c WHERE c.slug = 'minutas'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'milanesas');

-- Lomitos
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description) VALUES
('Lomito Tradicional', 'lomito-tradicional', '🥪', 13400, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'lomitos'),
  true, 1, 'Carne o Pollo - con papas fritas'),
('Lomito Especial', 'lomito-especial', '🥪', 14200, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'lomitos'),
  true, 2, 'Carne o Pollo - con papas fritas'),
('Lomito 737', 'lomito-737', '🥪', 14900, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'lomitos'),
  true, 3, 'Carne o Pollo - con papas fritas');

-- Hamburguesas
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order) VALUES
('Hamburguesa Simple', 'hamburguesa-simple', '🍔', 8500, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 10),
('Hamburguesa Tradicional', 'hamburguesa-tradicional', '🍔', 8500, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 11),
('Hamburguesa Cheddar', 'hamburguesa-cheddar', '🍔', 10000, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 12),
('Hamburguesa Emma''s', 'hamburguesa-emmas', '🍔', 11500, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 13),
('Hamburguesa Completa', 'hamburguesa-completa', '🍔', 11500, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 14),
('Hamburguesa Bomber', 'hamburguesa-bomber', '🍔', 12500, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 15),
('Hamburguesa 3 Quesos', 'hamburguesa-3quesos', '🍔', 12500, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'hamburguesas'),
  true, 16);

-- Milanesas
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description) VALUES
('Milanesa', 'milanesa-simple', '🥩', 13800, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'milanesas'),
  true, 20, 'Carne o Pollo'),
('Milanesa Napolitana', 'milanesa-napolitana', '🥩', 17800, 
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'milanesas'),
  true, 21, 'Carne o Pollo');

-- Papas Fritas (también en minutas)
INSERT INTO products (name, slug, icon, price, category_id, is_active, sort_order) VALUES
('Papas Fritas', 'fritas-comun', '🍟', 4700, 
  (SELECT id FROM categories WHERE slug = 'minutas'), true, 30),
('Fritas 737', 'fritas-737', '🍟', 9400, 
  (SELECT id FROM categories WHERE slug = 'minutas'), true, 31),
('Fritas Cheddar', 'fritas-cheddar', '🍟', 9400, 
  (SELECT id FROM categories WHERE slug = 'minutas'), true, 32);

-- ============================================
-- RESTAURANT - Subcategorías
-- ============================================

-- Crear subcategorías de restaurant
INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Parrilla', 'parrilla', c.id, 1 
FROM categories c WHERE c.slug = 'restaurant'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'parrilla');

INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Pastas', 'pastas', c.id, 2 
FROM categories c WHERE c.slug = 'restaurant'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'pastas');

INSERT INTO subcategories (name, slug, category_id, sort_order) 
SELECT 'Elaborados', 'elaborados', c.id, 3 
FROM categories c WHERE c.slug = 'restaurant'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'elaborados');

-- Parrilla
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description) VALUES
('Matambre a la Pizza', 'matambre-pizza', '🔥', 18800, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 1, 'Con guarnición a elección'),
('Asado', 'asado', '🔥', 12350, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 2, 'Con guarnición a elección'),
('Ojo de Bife', 'ojo-bife', '🔥', 12550, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 3, 'Con guarnición a elección'),
('Bife de Chorizo', 'bife-chorizo', '🔥', 14280, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 4, 'Con guarnición a elección'),
('Pollo Parrilla', 'pollo-parrilla', '🔥', 15530, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 5, 'Con guarnición a elección'),
('Bife de Bondiola', 'bondiola', '🔥', 14980, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 6, 'Con guarnición a elección'),
('Matambrito de Cerdo', 'matambrito-cerdo', '🔥', 14980, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'parrilla'),
  true, 7, 'Con guarnición a elección');

-- Pastas
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description) VALUES
('Sorrentinos JyQ', 'sorrentinos-jyq', '🍝', 10800, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'pastas'),
  true, 10, 'Con salsa a elección'),
('Tagliatelle', 'tagliatelle', '🍝', 7800, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'pastas'),
  true, 11, 'Con salsa a elección'),
('Sorrentinos Salmón', 'sorrentinos-salmon', '🍝', 13500, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'pastas'),
  true, 12, 'Con salsa a elección'),
('Lasagna Verdura', 'lasagna-verdura', '🍝', 11180, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'pastas'),
  true, 13, NULL),
('Ñoquis', 'noquis', '🍝', 9480, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'pastas'),
  true, 14, 'Con salsa a elección');

-- Elaborados
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description) VALUES
('Pollo al Roquefort', 'pollo-roquefort', '🍗', 18850, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'elaborados'),
  true, 20, 'Con guarnición'),
('Pollo al Champiñón', 'pollo-champinon', '🍗', 18850, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'elaborados'),
  true, 21, 'Con guarnición'),
('Lomo Crema Almendras', 'lomo-almendras', '🥩', 23350, 
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'elaborados'),
  true, 22, 'Con guarnición');

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

SELECT 
  c.icon || ' ' || c.name as categoria,
  COUNT(p.id) as productos,
  '$' || MIN(p.price) || ' - $' || MAX(p.price) as rango_precios
FROM categories c
LEFT JOIN products p ON p.category_id = c.id AND p.is_active = true
GROUP BY c.id, c.name, c.icon, c.sort_order
ORDER BY c.sort_order;
