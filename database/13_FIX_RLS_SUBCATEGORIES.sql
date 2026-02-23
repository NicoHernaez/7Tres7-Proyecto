-- ============================================
-- 7TRES7 - FIX RLS SUBCATEGORIES + SLUGS CORRECTOS
-- Ejecutar en Supabase SQL Editor
-- Fecha: 23 Febrero 2026
-- ============================================
-- Problema 1: subcategories no tiene policy de lectura anónima.
--   El JOIN en la app siempre devuelve null → subcategorías vacías.
-- Problema 2: Algunos slugs en Supabase difieren de los usados en
--   la migración 12 (ej: pizza-muzzarella vs pizza-muzza).
--   Las UPDATEs de iconos y descripciones no aplicaron.
-- ============================================

-- 1. AGREGAR POLICY DE LECTURA ANÓNIMA EN SUBCATEGORIES
CREATE POLICY "Anon can read subcategories" ON subcategories
  FOR SELECT USING (true);

-- 2. DESCRIPCIONES DE PIZZAS (slugs reales de Supabase)
UPDATE products SET description = 'Muzzarella' WHERE slug = 'pizza-muzzarella';
UPDATE products SET description = 'Muzzarella, jamón' WHERE slug = 'pizza-jamon';
UPDATE products SET description = 'Muzzarella, cebolla' WHERE slug = 'pizza-fugazzeta';
UPDATE products SET description = 'Muzzarella, tomate, ajo' WHERE slug = 'pizza-napolitana';
UPDATE products SET description = 'Muzza, provolone, roquefort, parmesano' WHERE slug = 'pizza-4quesos';
UPDATE products SET description = 'Muzzarella, rúcula, jamón crudo, parmesano' WHERE slug = 'pizza-rucula';
UPDATE products SET description = 'Muzzarella, palmitos, salsa golf' WHERE slug = 'pizza-palmitos';
UPDATE products SET description = 'Muzzarella, morrones, aceitunas, huevo' WHERE slug = 'pizza-vegetariana';
UPDATE products SET description = 'Muzzarella, champiñones, cebolla' WHERE slug = 'pizza-champinones';

-- 3. DESCRIPCIONES DE HAMBURGUESAS (slugs correctos, re-aplicar)
UPDATE products SET description = 'Queso cheddar - con papas fritas' WHERE slug = 'hamburguesa-simple';
UPDATE products SET description = 'Tomate, lechuga - con papas fritas' WHERE slug = 'hamburguesa-tradicional';
UPDATE products SET description = 'Tomate, lechuga, cheddar - con papas fritas' WHERE slug = 'hamburguesa-cheddar';
UPDATE products SET description = 'Cheddar, panceta, cebolla - con papas fritas' WHERE slug = 'hamburguesa-emmas';
UPDATE products SET description = 'Todo + jamón + huevo - con papas fritas' WHERE slug = 'hamburguesa-completa';
UPDATE products SET description = 'Doble carne - con papas fritas' WHERE slug = 'hamburguesa-bomber';
UPDATE products SET description = 'Cheddar, tybo, muzza - con papas fritas' WHERE slug = 'hamburguesa-3quesos';

-- 4. ICONOS DE PIZZAS (slugs correctos)
UPDATE products SET icon = '🧀' WHERE slug = 'pizza-muzzarella';
UPDATE products SET icon = '🥓' WHERE slug = 'pizza-jamon';
UPDATE products SET icon = '🧅' WHERE slug = 'pizza-fugazzeta';
UPDATE products SET icon = '🍅' WHERE slug = 'pizza-napolitana';
UPDATE products SET icon = '🧀' WHERE slug = 'pizza-4quesos';
UPDATE products SET icon = '🥗' WHERE slug = 'pizza-rucula';
UPDATE products SET icon = '🌴' WHERE slug = 'pizza-palmitos';
UPDATE products SET icon = '🥬' WHERE slug = 'pizza-vegetariana';
UPDATE products SET icon = '🍄' WHERE slug = 'pizza-champinones';

-- 5. ICONOS DE PARRILLA (slugs reales de Supabase)
UPDATE products SET icon = '🥩' WHERE slug IN ('matambre-a-la-pizza', 'asado', 'ojo-de-bife', 'bife-de-chorizo');
UPDATE products SET icon = '🍗' WHERE slug IN ('pollo-muslo', 'pollo-pechuga');
UPDATE products SET icon = '🐷' WHERE slug IN ('bife-de-bondiola', 'matambrito-de-cerdo');

-- 6. ICONOS DE ELABORADOS
UPDATE products SET icon = '🍗' WHERE slug IN ('pollo-roquefort', 'pollo-champinon');
UPDATE products SET icon = '🥩' WHERE slug IN ('lomo-almendras', 'lomo-champinon');

-- 7. ICONOS DE PASTAS
UPDATE products SET icon = '🥟' WHERE slug IN ('sorrentinos-jyq', 'sorrentinos-salmon');
UPDATE products SET icon = '🥬' WHERE slug = 'lasagna-verdura';

-- 8. ICONOS DE MILANESAS
UPDATE products SET icon = '🥩' WHERE slug = 'milanesa-simple';
UPDATE products SET icon = '🥩🍅' WHERE slug = 'milanesa-napolitana';

-- 9. ICON FRITAS CHEDDAR
UPDATE products SET icon = '🍟🧀' WHERE slug = 'fritas-cheddar';

-- ============================================
-- VERIFICAR
-- ============================================

-- Verificar que subcategories es legible
SELECT s.slug, s.name, c.slug as parent_category
FROM subcategories s
JOIN categories c ON s.category_id = c.id
ORDER BY c.sort_order, s.sort_order;

-- Verificar productos con subcategoría
SELECT
  c.name as categoria,
  s.name as subcategoria,
  p.name, p.slug, p.icon, p.price, p.description
FROM products p
JOIN categories c ON p.category_id = c.id
LEFT JOIN subcategories s ON p.subcategory_id = s.id
WHERE p.is_active = true
ORDER BY c.sort_order, COALESCE(s.sort_order, 0), p.sort_order;
