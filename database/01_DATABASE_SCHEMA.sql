-- ============================================
-- 7TRES7 - DATABASE SCHEMA
-- Versión: 1.0
-- Fecha: Febrero 2026
-- Database: PostgreSQL (Supabase)
-- ============================================

-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- TIPOS PERSONALIZADOS
-- ============================================

-- Estados de pedido
CREATE TYPE order_status AS ENUM (
  'pending',      -- Recién creado
  'confirmed',    -- Confirmado
  'preparing',    -- En preparación
  'ready',        -- Listo para entrega
  'delivering',   -- En camino
  'delivered',    -- Entregado
  'cancelled'     -- Cancelado
);

-- Métodos de pago
CREATE TYPE payment_method AS ENUM (
  'cash',
  'mercadopago',
  'transfer'
);

-- Estados de pago
CREATE TYPE payment_status AS ENUM (
  'pending',
  'approved',
  'rejected',
  'refunded'
);

-- Métodos de cocción
CREATE TYPE cooking_method AS ENUM (
  'frito',
  'horno',
  'parrilla',
  'ambos',
  'ninguno'
);

-- Segmento de cliente
CREATE TYPE customer_segment AS ENUM (
  'nuevo',
  'ocasional',
  'frecuente',
  'vip',
  'inactivo'
);

-- ============================================
-- TABLA: business_config
-- Configuración general del negocio
-- ============================================

CREATE TABLE business_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_name TEXT NOT NULL DEFAULT '7Tres7',
  slug TEXT UNIQUE NOT NULL DEFAULT '7tres7',
  
  -- Contacto
  phone TEXT,
  whatsapp TEXT,
  email TEXT,
  
  -- Ubicación
  address TEXT,
  city TEXT DEFAULT 'General Pico',
  province TEXT DEFAULT 'La Pampa',
  country TEXT DEFAULT 'Argentina',
  location GEOGRAPHY(POINT, 4326),
  
  -- Horarios (JSON: {"lunes": {"open": "11:00", "close": "23:00"}, ...})
  business_hours JSONB DEFAULT '{
    "lunes": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "00:00"},
    "martes": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "00:00"},
    "miercoles": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "00:00"},
    "jueves": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "00:00"},
    "viernes": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "01:00"},
    "sabado": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "01:00"},
    "domingo": {"open": "11:00", "close": "15:00", "evening_open": "20:00", "evening_close": "00:00"}
  }'::jsonb,
  
  -- Delivery
  delivery_enabled BOOLEAN DEFAULT true,
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  delivery_min_order DECIMAL(10,2) DEFAULT 0,
  delivery_radius_km DECIMAL(5,2) DEFAULT 10,
  delivery_time_minutes INTEGER DEFAULT 45,
  
  -- Zonas de delivery (GeoJSON)
  delivery_zones JSONB DEFAULT '[]'::jsonb,
  
  -- Configuración de pedidos
  min_empanadas_discount INTEGER DEFAULT 36,
  discount_percentage DECIMAL(5,2) DEFAULT 10,
  
  -- Integraciones
  mercadopago_enabled BOOLEAN DEFAULT false,
  mercadopago_public_key TEXT,
  mercadopago_access_token TEXT,
  
  lucy_enabled BOOLEAN DEFAULT false,
  lucy_webhook_url TEXT,
  
  sexto_sentido_enabled BOOLEAN DEFAULT false,
  sexto_sentido_api_key TEXT,
  
  google_maps_api_key TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLA: categories
-- Categorías de productos
-- ============================================

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  icon TEXT, -- Emoji
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  
  -- Configuración visual
  color_primary TEXT DEFAULT '#f97316',
  color_secondary TEXT DEFAULT '#fed7aa',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_categories_active ON categories(is_active);
CREATE INDEX idx_categories_order ON categories(sort_order);

-- ============================================
-- TABLA: subcategories
-- Subcategorías de productos
-- ============================================

CREATE TABLE subcategories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  icon TEXT,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(category_id, slug)
);

-- Índices
CREATE INDEX idx_subcategories_category ON subcategories(category_id);

-- ============================================
-- TABLA: products
-- Productos del menú
-- ============================================

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  subcategory_id UUID REFERENCES subcategories(id) ON DELETE SET NULL,
  
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  icon TEXT, -- Emoji
  image_url TEXT,
  
  -- Precios
  price DECIMAL(10,2) NOT NULL,
  price_promo DECIMAL(10,2), -- Precio promocional
  promo_active BOOLEAN DEFAULT false,
  promo_label TEXT, -- "PROMO", "2x1", etc.
  
  -- Opciones de cocción (para empanadas)
  cooking_methods cooking_method[] DEFAULT '{}',
  
  -- Disponibilidad
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  available_from TIME, -- Hora desde (ej: menú ejecutivo solo mediodía)
  available_until TIME,
  available_days INTEGER[], -- 0=Domingo, 1=Lunes, etc.
  
  -- Stock
  stock_enabled BOOLEAN DEFAULT false,
  stock_quantity INTEGER,
  
  -- Metadata
  tags TEXT[],
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_subcategory ON products(subcategory_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_featured ON products(is_featured);

-- ============================================
-- TABLA: customers
-- Base de clientes
-- ============================================

CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Datos básicos
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  email TEXT,
  
  -- Dirección principal
  address TEXT,
  address_notes TEXT,
  location GEOGRAPHY(POINT, 4326),
  
  -- Segmentación
  segment customer_segment DEFAULT 'nuevo',
  
  -- Estadísticas
  total_orders INTEGER DEFAULT 0,
  total_spent DECIMAL(12,2) DEFAULT 0,
  average_ticket DECIMAL(10,2) DEFAULT 0,
  last_order_at TIMESTAMPTZ,
  
  -- Preferencias (aprendidas por IA)
  preferences JSONB DEFAULT '{}'::jsonb,
  -- Ejemplo: {"favoritos": ["emp_carne_cuchillo"], "coccion_preferida": "horno", "notas": "sin picante"}
  
  -- Marketing
  accepts_marketing BOOLEAN DEFAULT true,
  marketing_channel TEXT, -- whatsapp, email, sms
  
  -- Fuente de adquisición
  acquisition_source TEXT, -- app, whatsapp, instagram, etc.
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_segment ON customers(segment);
CREATE INDEX idx_customers_location ON customers USING GIST(location);

-- ============================================
-- TABLA: orders
-- Pedidos
-- ============================================

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number SERIAL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  
  -- Estado
  status order_status DEFAULT 'pending',
  
  -- Items (JSONB para flexibilidad)
  items JSONB NOT NULL,
  -- Estructura: [{"product_id": "uuid", "name": "Emp. Carne", "quantity": 12, "price": 1700, "cooking": "horno", "subtotal": 20400}]
  
  -- Totales
  subtotal DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) DEFAULT 0,
  discount_reason TEXT,
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  
  -- Entrega
  delivery_type TEXT DEFAULT 'delivery', -- delivery, pickup
  delivery_address TEXT,
  delivery_notes TEXT,
  delivery_location GEOGRAPHY(POINT, 4326),
  estimated_delivery TIMESTAMPTZ,
  actual_delivery TIMESTAMPTZ,
  
  -- Pago
  payment_method payment_method DEFAULT 'cash',
  payment_status payment_status DEFAULT 'pending',
  payment_id TEXT, -- ID externo (MercadoPago)
  payment_details JSONB DEFAULT '{}'::jsonb,
  
  -- Observaciones
  customer_notes TEXT,
  internal_notes TEXT,
  
  -- Fuente
  source TEXT DEFAULT 'app', -- app, whatsapp, telefono, local
  
  -- Asignación
  assigned_to TEXT, -- Repartidor asignado
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  preparing_at TIMESTAMPTZ,
  ready_at TIMESTAMPTZ,
  delivering_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- Índices
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(created_at);
CREATE INDEX idx_orders_number ON orders(order_number);

-- ============================================
-- TABLA: order_status_history
-- Historial de estados de pedido
-- ============================================

CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  status order_status NOT NULL,
  notes TEXT,
  changed_by TEXT, -- Usuario que cambió el estado
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_order_history_order ON order_status_history(order_id);

-- ============================================
-- TABLA: payments
-- Registro de pagos
-- ============================================

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  
  -- MercadoPago
  mp_payment_id TEXT,
  mp_preference_id TEXT,
  mp_merchant_order_id TEXT,
  
  -- Detalles
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'ARS',
  method payment_method NOT NULL,
  status payment_status DEFAULT 'pending',
  
  -- Metadata de MercadoPago
  mp_response JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_mp ON payments(mp_payment_id);

-- ============================================
-- TABLA: admin_users
-- Usuarios administradores
-- ============================================

CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'staff', -- owner, admin, staff
  
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMPTZ,
  
  permissions JSONB DEFAULT '{}'::jsonb,
  -- {"orders": ["read", "write"], "products": ["read", "write"], "reports": ["read"]}
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLA: activity_logs
-- Registro de actividad
-- ============================================

CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT, -- order, product, customer, etc.
  entity_id UUID,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_activity_user ON activity_logs(user_id);
CREATE INDEX idx_activity_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_date ON activity_logs(created_at);

-- ============================================
-- TABLA: daily_stats
-- Estadísticas diarias (pre-calculadas)
-- ============================================

CREATE TABLE daily_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE UNIQUE NOT NULL,
  
  -- Pedidos
  total_orders INTEGER DEFAULT 0,
  orders_delivery INTEGER DEFAULT 0,
  orders_pickup INTEGER DEFAULT 0,
  orders_cancelled INTEGER DEFAULT 0,
  
  -- Ventas
  total_revenue DECIMAL(12,2) DEFAULT 0,
  total_discount DECIMAL(12,2) DEFAULT 0,
  average_ticket DECIMAL(10,2) DEFAULT 0,
  
  -- Productos
  total_empanadas INTEGER DEFAULT 0,
  top_products JSONB DEFAULT '[]'::jsonb,
  
  -- Clientes
  new_customers INTEGER DEFAULT 0,
  returning_customers INTEGER DEFAULT 0,
  
  -- Pagos
  cash_revenue DECIMAL(12,2) DEFAULT 0,
  mp_revenue DECIMAL(12,2) DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_daily_stats_date ON daily_stats(date);

-- ============================================
-- TABLA: whatsapp_messages
-- Mensajes de WhatsApp (para Lucy)
-- ============================================

CREATE TABLE whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  
  -- Mensaje
  direction TEXT NOT NULL, -- inbound, outbound
  message_type TEXT, -- text, image, audio, location
  content TEXT,
  media_url TEXT,
  
  -- WhatsApp IDs
  wa_message_id TEXT,
  wa_conversation_id TEXT,
  
  -- Procesamiento IA
  intent TEXT, -- order, query, complaint, greeting
  entities JSONB DEFAULT '{}'::jsonb,
  ai_response TEXT,
  
  -- Estado
  status TEXT DEFAULT 'received', -- received, processed, responded, failed
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_wa_messages_customer ON whatsapp_messages(customer_id);
CREATE INDEX idx_wa_messages_date ON whatsapp_messages(created_at);

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_business_config_updated_at
  BEFORE UPDATE ON business_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Función para actualizar estadísticas del cliente
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.status = 'delivered' AND OLD.status != 'delivered') THEN
    UPDATE customers
    SET 
      total_orders = total_orders + 1,
      total_spent = total_spent + NEW.total,
      average_ticket = (total_spent + NEW.total) / (total_orders + 1),
      last_order_at = NEW.delivered_at,
      segment = CASE
        WHEN total_orders + 1 >= 20 THEN 'vip'::customer_segment
        WHEN total_orders + 1 >= 10 THEN 'frecuente'::customer_segment
        WHEN total_orders + 1 >= 3 THEN 'ocasional'::customer_segment
        ELSE 'nuevo'::customer_segment
      END
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_stats
  AFTER INSERT OR UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_customer_stats();

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Configuración del negocio
INSERT INTO business_config (business_name, slug, phone, whatsapp, address, city)
VALUES ('7Tres7 Restaurante', '7tres7', '+5492302419234', '+5492302419234', 'General Pico', 'General Pico');

-- Categorías
INSERT INTO categories (name, slug, icon, sort_order) VALUES
('Empanadas', 'empanadas', '🥟', 1),
('Pizzas', 'pizzas', '🍕', 2),
('Minutas', 'minutas', '🍔', 3),
('Restaurant', 'restaurant', '🍽️', 4),
('Bebidas', 'bebidas', '🥤', 5),
('Postres', 'postres', '🍰', 6);

-- Subcategorías de Empanadas
INSERT INTO subcategories (category_id, name, slug, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'empanadas'), 'Premium', 'premium', 1),
((SELECT id FROM categories WHERE slug = 'empanadas'), 'Comunes', 'comunes', 2);

-- Subcategorías de Minutas
INSERT INTO subcategories (category_id, name, slug, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'minutas'), 'Lomitos', 'lomitos', 1),
((SELECT id FROM categories WHERE slug = 'minutas'), 'Hamburguesas', 'hamburguesas', 2),
((SELECT id FROM categories WHERE slug = 'minutas'), 'Milanesas', 'milanesas', 3),
((SELECT id FROM categories WHERE slug = 'minutas'), 'Papas Fritas', 'papas-fritas', 4);

-- Subcategorías de Restaurant
INSERT INTO subcategories (category_id, name, slug, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'restaurant'), 'Parrilla', 'parrilla', 1),
((SELECT id FROM categories WHERE slug = 'restaurant'), 'Pastas', 'pastas', 2),
((SELECT id FROM categories WHERE slug = 'restaurant'), 'Elaborados', 'elaborados', 3);

-- Productos de ejemplo (Empanadas Premium)
INSERT INTO products (category_id, subcategory_id, name, slug, icon, price, cooking_methods, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'empanadas'), 
 (SELECT id FROM subcategories WHERE slug = 'premium'),
 'Carne Cortada a Cuchillo', 'emp-carne-cuchillo', '🥩', 1700, ARRAY['frito', 'horno']::cooking_method[], 1),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'premium'),
 'Jamón y Queso Premium', 'emp-jyq-premium', '🧀', 1700, ARRAY['frito', 'horno']::cooking_method[], 2),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'premium'),
 'Pollo Cortado a Cuchillo', 'emp-pollo-cuchillo', '🍗', 1700, ARRAY['frito', 'horno']::cooking_method[], 3),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'premium'),
 'Roquefort', 'emp-roquefort', '🧀', 1700, ARRAY['frito', 'horno']::cooking_method[], 4),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'premium'),
 'Matambre', 'emp-matambre', '🥩', 1700, ARRAY['frito', 'horno']::cooking_method[], 5);

-- Productos de ejemplo (Empanadas Comunes)
INSERT INTO products (category_id, subcategory_id, name, slug, icon, price, cooking_methods, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'comunes'),
 'Verdura', 'emp-verdura', '🥬', 1400, ARRAY['frito', 'horno']::cooking_method[], 1),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'comunes'),
 'Árabe', 'emp-arabe', '🌯', 1400, ARRAY['frito', 'horno']::cooking_method[], 2),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'comunes'),
 'Carne', 'emp-carne', '🥩', 1400, ARRAY['frito', 'horno']::cooking_method[], 3),
((SELECT id FROM categories WHERE slug = 'empanadas'),
 (SELECT id FROM subcategories WHERE slug = 'comunes'),
 'Capresse', 'emp-capresse', '🍅', 1400, ARRAY['frito', 'horno']::cooking_method[], 4);

-- Bebidas
INSERT INTO products (category_id, name, slug, icon, price, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'bebidas'), 'Coca Cola 1.5L', 'coca-15', '🥤', 3500, 1),
((SELECT id FROM categories WHERE slug = 'bebidas'), 'Sprite 1.5L', 'sprite-15', '🥤', 3500, 2),
((SELECT id FROM categories WHERE slug = 'bebidas'), 'Agua 1.5L', 'agua-15', '💧', 2000, 3),
((SELECT id FROM categories WHERE slug = 'bebidas'), 'Cerveza 1L', 'cerveza-1', '🍺', 4500, 4);

-- Postres
INSERT INTO products (category_id, name, slug, icon, price, sort_order) VALUES
((SELECT id FROM categories WHERE slug = 'postres'), 'Cheese Cake Frutos Rojos', 'cheesecake', '🍓', 4200, 1),
((SELECT id FROM categories WHERE slug = 'postres'), 'ChocoTorta', 'chocotorta', '🍫', 3800, 2);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista: Pedidos del día con detalles
CREATE OR REPLACE VIEW v_orders_today AS
SELECT 
  o.*,
  c.name as customer_name,
  c.phone as customer_phone,
  c.segment as customer_segment
FROM orders o
LEFT JOIN customers c ON c.id = o.customer_id
WHERE DATE(o.created_at) = CURRENT_DATE
ORDER BY o.created_at DESC;

-- Vista: Productos más vendidos (últimos 30 días)
CREATE OR REPLACE VIEW v_top_products AS
SELECT 
  p.id,
  p.name,
  p.icon,
  p.price,
  COALESCE(SUM((item->>'quantity')::integer), 0) as total_sold,
  COALESCE(SUM((item->>'subtotal')::decimal), 0) as total_revenue
FROM products p
LEFT JOIN orders o ON o.status = 'delivered' AND o.created_at > NOW() - INTERVAL '30 days'
LEFT JOIN LATERAL jsonb_array_elements(o.items) as item ON (item->>'product_id')::uuid = p.id
GROUP BY p.id, p.name, p.icon, p.price
ORDER BY total_sold DESC;

-- Vista: Estadísticas del dashboard
CREATE OR REPLACE VIEW v_dashboard_stats AS
SELECT 
  (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE) as orders_today,
  (SELECT COALESCE(SUM(total), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status != 'cancelled') as revenue_today,
  (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status = 'pending') as pending_orders,
  (SELECT COUNT(*) FROM customers WHERE DATE(created_at) = CURRENT_DATE) as new_customers_today,
  (SELECT COALESCE(AVG(total), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status != 'cancelled') as avg_ticket_today;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Habilitar RLS en TODAS las tablas
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Politicas: solo usuarios autenticados (Google OAuth via Supabase Auth)
-- El anon key permite el flujo de auth pero no puede leer datos sin login

CREATE POLICY "Authenticated full access" ON orders
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON customers
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON products
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON categories
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON subcategories
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON business_config
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON payments
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON order_status_history
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON daily_stats
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON whatsapp_messages
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON activity_logs
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated full access" ON admin_users
  FOR ALL USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- Indices adicionales para performance
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers USING btree (name);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders USING btree (created_at DESC);

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE business_config IS 'Configuración general del negocio 7Tres7';
COMMENT ON TABLE categories IS 'Categorías del menú (Empanadas, Pizzas, etc.)';
COMMENT ON TABLE subcategories IS 'Subcategorías (Premium, Comunes, Lomitos, etc.)';
COMMENT ON TABLE products IS 'Productos del menú con precios y opciones';
COMMENT ON TABLE customers IS 'Base de clientes con historial y preferencias';
COMMENT ON TABLE orders IS 'Pedidos con items, totales y seguimiento';
COMMENT ON TABLE payments IS 'Registro de pagos (MercadoPago, efectivo)';
COMMENT ON TABLE whatsapp_messages IS 'Mensajes de WhatsApp para integración con Lucy';

-- ============================================
-- FIN DEL SCHEMA
-- ============================================
