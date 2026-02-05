-- ============================================
-- 7TRES7 - INTEGRACIONES API
-- Ejecutar en Supabase SQL Editor
-- Fecha: Febrero 2026
-- ============================================
-- Este script configura las credenciales de:
-- 1. MercadoPago (pagos online)
-- 2. Cloudinary (imagenes - futuro)
-- 3. Twilio WhatsApp (notificaciones - futuro)
-- ============================================

-- ============================================
-- PASO 1: Agregar campos faltantes a business_config
-- ============================================

-- Cloudinary (para imagenes de productos)
ALTER TABLE business_config
ADD COLUMN IF NOT EXISTS cloudinary_cloud_name TEXT,
ADD COLUMN IF NOT EXISTS cloudinary_api_key TEXT,
ADD COLUMN IF NOT EXISTS cloudinary_api_secret TEXT;

-- Twilio WhatsApp (para notificaciones)
ALTER TABLE business_config
ADD COLUMN IF NOT EXISTS twilio_account_sid TEXT,
ADD COLUMN IF NOT EXISTS twilio_auth_token TEXT,
ADD COLUMN IF NOT EXISTS twilio_whatsapp_number TEXT;

-- ============================================
-- PASO 2: Configurar credenciales
-- ============================================

UPDATE business_config SET
  -- MercadoPago (credenciales de 6to Sentido - compartidas)
  mercadopago_enabled = true,
  mercadopago_public_key = 'APP_USR-6eb41426-d39e-418b-9e30-2016506f983d',
  -- NOTA: El access_token NO se guarda aqui por seguridad
  -- Se configura como variable de entorno en la Edge Function
  mercadopago_access_token = NULL,

  -- Cloudinary
  cloudinary_cloud_name = 'dtyaqrooy',
  -- API key y secret se configuran en Edge Functions
  cloudinary_api_key = NULL,
  cloudinary_api_secret = NULL,

  -- Twilio WhatsApp
  twilio_whatsapp_number = 'whatsapp:+14155238886'
  -- Account SID y Auth Token se configuran en Edge Functions
WHERE id IS NOT NULL;

-- ============================================
-- VERIFICACION
-- ============================================

SELECT
  business_name,
  mercadopago_enabled,
  mercadopago_public_key,
  cloudinary_cloud_name,
  twilio_whatsapp_number
FROM business_config;

-- ============================================
-- FIN
-- ============================================
