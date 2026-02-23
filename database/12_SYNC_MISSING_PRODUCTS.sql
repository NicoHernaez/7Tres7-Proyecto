-- ============================================
-- 7TRES7 - SINCRONIZAR PRODUCTOS FALTANTES
-- Ejecutar en Supabase SQL Editor
-- Fecha: 23 Febrero 2026
-- ============================================
-- Varios productos del HTML no existían en Supabase o les faltaba
-- subcategoría. Este script los sincroniza para que la app usuario
-- pueda renderizar dinámicamente desde la DB.
-- ============================================

-- 1. Crear subcategoría 'fritas' bajo Minutas
INSERT INTO subcategories (name, slug, category_id, sort_order)
SELECT 'Papas Fritas', 'fritas', c.id, 4
FROM categories c WHERE c.slug = 'minutas'
AND NOT EXISTS (SELECT 1 FROM subcategories WHERE slug = 'fritas');

-- 2. Asignar papas fritas a la subcategoría 'fritas'
UPDATE products SET subcategory_id = (SELECT id FROM subcategories WHERE slug = 'fritas')
WHERE slug IN ('fritas-comun', 'fritas-737', 'fritas-cheddar');

-- 3. Asignar pollo-muslo y pollo-pechuga a subcategoría 'parrilla'
UPDATE products SET subcategory_id = (SELECT id FROM subcategories WHERE slug = 'parrilla')
WHERE slug IN ('pollo-muslo', 'pollo-pechuga');

-- 4. Agregar productos faltantes: suprema, suprema-napolitana
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description)
VALUES
('Suprema', 'suprema', '🍗', 13800,
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'milanesas'),
  true, 22, NULL),
('Suprema Napolitana', 'suprema-napolitana', '🍗🍅', 17800,
  (SELECT id FROM categories WHERE slug = 'minutas'),
  (SELECT id FROM subcategories WHERE slug = 'milanesas'),
  true, 23, NULL)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, price = EXCLUDED.price, is_active = true,
  subcategory_id = EXCLUDED.subcategory_id, sort_order = EXCLUDED.sort_order,
  icon = EXCLUDED.icon;

-- 5. Agregar productos faltantes: lomo-champinon, cerdo-agridulce
INSERT INTO products (name, slug, icon, price, category_id, subcategory_id, is_active, sort_order, description)
VALUES
('Lomo al Champiñón', 'lomo-champinon', '🥩', 23350,
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'elaborados'),
  true, 23, 'Con guarnición'),
('Cerdo Agridulce', 'cerdo-agridulce', '🐷', 19880,
  (SELECT id FROM categories WHERE slug = 'restaurant'),
  (SELECT id FROM subcategories WHERE slug = 'elaborados'),
  true, 24, 'Con guarnición')
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, price = EXCLUDED.price, is_active = true,
  subcategory_id = EXCLUDED.subcategory_id, sort_order = EXCLUDED.sort_order,
  icon = EXCLUDED.icon, description = EXCLUDED.description;

-- 6. Agregar descripciones a hamburguesas
UPDATE products SET description = 'Queso cheddar - con papas fritas' WHERE slug = 'hamburguesa-simple';
UPDATE products SET description = 'Tomate, lechuga - con papas fritas' WHERE slug = 'hamburguesa-tradicional';
UPDATE products SET description = 'Tomate, lechuga, cheddar - con papas fritas' WHERE slug = 'hamburguesa-cheddar';
UPDATE products SET description = 'Cheddar, panceta, cebolla - con papas fritas' WHERE slug = 'hamburguesa-emmas';
UPDATE products SET description = 'Todo + jamón + huevo - con papas fritas' WHERE slug = 'hamburguesa-completa';
UPDATE products SET description = 'Doble carne - con papas fritas' WHERE slug = 'hamburguesa-bomber';
UPDATE products SET description = 'Cheddar, tybo, muzza - con papas fritas' WHERE slug = 'hamburguesa-3quesos';

-- 7. Agregar descripciones a lomitos
UPDATE products SET description = 'Jamón, Queso - con papas fritas' WHERE slug = 'lomito-tradicional';
UPDATE products SET description = 'Jamón, Queso, Tomate, Lechuga, Huevo - con papas fritas' WHERE slug = 'lomito-especial';
UPDATE products SET description = 'Full toppings + Panceta - con papas fritas' WHERE slug = 'lomito-737';

-- 8. Agregar descripción a lasagna (faltaba)
UPDATE products SET description = 'Con salsa a elección' WHERE slug = 'lasagna-verdura' AND description IS NULL;

-- 9. Actualizar iconos de pizzas para variedad visual
UPDATE products SET icon = '🧀' WHERE slug = 'pizza-muzza';
UPDATE products SET icon = '🥓' WHERE slug = 'pizza-jamon';
UPDATE products SET icon = '🧅' WHERE slug = 'pizza-fugazzeta';
UPDATE products SET icon = '🍅' WHERE slug = 'pizza-napolitana';
UPDATE products SET icon = '🧀' WHERE slug = 'pizza-4quesos';
UPDATE products SET icon = '🥗' WHERE slug = 'pizza-rucula';
UPDATE products SET icon = '🌴' WHERE slug = 'pizza-palmitos';
UPDATE products SET icon = '🥬' WHERE slug = 'pizza-vegetariana';
UPDATE products SET icon = '🍄' WHERE slug = 'pizza-champinones';

-- 10. Actualizar iconos de milanesas
UPDATE products SET icon = '🥩' WHERE slug = 'milanesa-simple';
UPDATE products SET icon = '🥩🍅' WHERE slug = 'milanesa-napolitana';

-- 11. Actualizar iconos de parrilla
UPDATE products SET icon = '🥩' WHERE slug IN ('matambre-pizza', 'asado', 'ojo-bife', 'bife-chorizo');
UPDATE products SET icon = '🍗' WHERE slug IN ('pollo-muslo', 'pollo-pechuga');
UPDATE products SET icon = '🐷' WHERE slug IN ('bondiola', 'matambrito-cerdo');

-- 12. Actualizar iconos de elaborados
UPDATE products SET icon = '🍗' WHERE slug IN ('pollo-roquefort', 'pollo-champinon');
UPDATE products SET icon = '🥩' WHERE slug IN ('lomo-almendras', 'lomo-champinon');

-- 13. Actualizar iconos de pastas
UPDATE products SET icon = '🥟' WHERE slug IN ('sorrentinos-jyq', 'sorrentinos-salmon');
UPDATE products SET icon = '🥬' WHERE slug = 'lasagna-verdura';

-- 14. Actualizar icon de fritas cheddar
UPDATE products SET icon = '🍟🧀' WHERE slug = 'fritas-cheddar';

-- 15. Agregar descripciones a pizzas
UPDATE products SET description = 'Muzzarella' WHERE slug = 'pizza-muzza';
UPDATE products SET description = 'Muzzarella, jamón' WHERE slug = 'pizza-jamon';
UPDATE products SET description = 'Muzzarella, cebolla' WHERE slug = 'pizza-fugazzeta';
UPDATE products SET description = 'Muzzarella, tomate, ajo' WHERE slug = 'pizza-napolitana';
UPDATE products SET description = 'Muzza, provolone, roquefort, parmesano' WHERE slug = 'pizza-4quesos';
UPDATE products SET description = 'Muzzarella, rúcula, jamón crudo, parmesano' WHERE slug = 'pizza-rucula';
UPDATE products SET description = 'Muzzarella, palmitos, salsa golf' WHERE slug = 'pizza-palmitos';
UPDATE products SET description = 'Muzzarella, morrones, aceitunas, huevo' WHERE slug = 'pizza-vegetariana';
UPDATE products SET description = 'Muzzarella, champiñones, cebolla' WHERE slug = 'pizza-champinones';

-- ============================================
-- VERIFICAR
-- ============================================
SELECT
  c.name as categoria,
  s.name as subcategoria,
  p.name, p.slug, p.icon, p.price, p.is_active, p.description
FROM products p
JOIN categories c ON p.category_id = c.id
LEFT JOIN subcategories s ON p.subcategory_id = s.id
WHERE p.is_active = true
ORDER BY c.sort_order, COALESCE(s.sort_order, 0), p.sort_order;
