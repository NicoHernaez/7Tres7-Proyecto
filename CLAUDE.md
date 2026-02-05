# 7Tres7 - Documentacion del Proyecto

## Resumen del Proyecto

Sistema de pedidos online para restaurante 7Tres7 (empanadas y mas) con dos aplicaciones:
1. **App Usuario** - Para que clientes hagan pedidos
2. **Admin Panel** - Para administrar el negocio

---

## Lo que se hizo

### 1. Autenticacion con Google OAuth (Admin Panel)

**Archivos modificados:** `admin-panel/index.html`

- Eliminada la pantalla de Setup manual (URL + Key)
- URL y anon key de Supabase hardcodeadas (son publicas)
- Implementado login con Google OAuth via `db.auth.signInWithOAuth({ provider: 'google' })`
- Implementado Magic Link como alternativa via `db.auth.signInWithOtp()`
- Validacion de email autorizado (`nicohernaez22@gmail.com`)
- Si email no autorizado: logout automatico + mensaje de error
- Sidebar muestra nombre/email del usuario logueado
- Boton "Cerrar sesion" en el sidebar
- Fix de race condition en auth flow (variable `appInitialized` para evitar duplicados)

**Configuracion requerida en Supabase Dashboard:**
- Authentication > Providers > Google: habilitado con Client ID y Secret
- Authentication > URL Configuration > Site URL: `https://7-tres7-admin.vercel.app`
- Authentication > URL Configuration > Redirect URLs: `https://7-tres7-admin.vercel.app`

**Configuracion requerida en Google Cloud Console:**
- OAuth Client ID con redirect URI: `https://yfdustfjfmifvgybwinr.supabase.co/auth/v1/callback`

### 2. Row Level Security (RLS) Restrictivo

**Archivos modificados:**
- `database/01_DATABASE_SCHEMA.sql` - Seccion RLS actualizada
- `database/06_AUTH_RLS_UPDATE.sql` - Script de migracion (EJECUTADO)

**Cambios:**
- RLS habilitado en TODAS las tablas (antes solo orders, customers, products)
- Politicas cambiadas de `USING (true)` a `USING (auth.role() = 'authenticated')`
- Agregadas politicas de lectura publica para: products, categories, business_config (para app usuario)

**Tablas con RLS:**
- orders, customers, products, categories, subcategories
- business_config, payments, printers, print_jobs, printer_templates
- order_status_history, daily_stats, whatsapp_messages, activity_logs, admin_users

### 3. Performance para 4.000+ Clientes

**Archivos modificados:** `admin-panel/index.html`

**Paginacion implementada:**
- Clientes: 20 por pagina con navegacion Anterior/Siguiente
- Productos: 20 por pagina
- Pedidos: 20 por pagina

**Busqueda de clientes:**
- Campo de busqueda por nombre o telefono
- Debounce de 300ms para evitar queries excesivas
- Usa `ilike` para busqueda parcial

**Indices agregados en DB:**
- `idx_customers_name` - Para busqueda por nombre
- `idx_orders_created_at` - Para filtros por fecha

### 4. Configuracion App Usuario

**Archivos modificados:** `app-usuario/index.html`

- Configurada URL y anon key de Supabase (antes tenia placeholders)
- Ahora carga 61 productos desde Supabase en vivo

### 5. Deploy en Vercel

**Repositorios GitHub creados:**
- `NicoHernaez/7Tres7-Online` - App usuario
- `NicoHernaez/7Tres7-Admin` - Admin panel

**URLs de produccion:**
- App Usuario: https://7tres7-online.vercel.app
- Admin Panel: https://7-tres7-admin.vercel.app

### 6. Integraciones API (Preparadas)

**Archivos creados:**
- `database/07_INTEGRACIONES_API.sql` - Configura credenciales en business_config
- `supabase/functions/create-mp-preference/index.ts` - Edge Function para crear pagos
- `supabase/functions/mp-webhook/index.ts` - Edge Function para recibir notificaciones de pago

**APIs configuradas (credenciales de 6to Sentido):**
- **MercadoPago:** Public Key configurada, Access Token va en Edge Function
- **Cloudinary:** Cloud name configurado (dtyaqrooy)
- **Twilio WhatsApp:** Numero configurado (whatsapp:+14155238886)

**Para activar MercadoPago:**
1. Ejecutar `07_INTEGRACIONES_API.sql` en Supabase
2. Deploy Edge Functions: `supabase functions deploy create-mp-preference`
3. Configurar secret: `supabase secrets set MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxx`
4. Actualizar app-usuario para llamar a la Edge Function

---

## Configuracion Actual

### Supabase
- **URL:** https://yfdustfjfmifvgybwinr.supabase.co
- **Anon Key:** eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHVzdGZqZm1pZnZneWJ3aW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMzU3ODQsImV4cCI6MjA4NTgxMTc4NH0.YcLo7YXePi0_okJxtPuYLaMQI2-P4C8UxNzXnLfQoBY

### Emails Autorizados (Admin)
- nicohernaez22@gmail.com

### Google OAuth
- Usa las credenciales del proyecto 6to Sentido
- Redirect URI agregada: `https://yfdustfjfmifvgybwinr.supabase.co/auth/v1/callback`

### MercadoPago (compartido con 6to Sentido)
- **Public Key:** APP_USR-6eb41426-d39e-418b-9e30-2016506f983d
- **Access Token:** APP_USR-5924995119910825-010419-e0d111986daf9f58ade8aa6032ba6ef4-30888844
  - ⚠️ NUNCA poner en frontend, solo en Edge Functions

### Cloudinary (compartido con 6to Sentido)
- **Cloud Name:** dtyaqrooy

### Twilio WhatsApp (compartido con 6to Sentido)
- **Numero:** whatsapp:+14155238886

---

## Lo que falta hacer

### Alta Prioridad - PROXIMA SESION

1. **Pruebas de pedidos y pagos**
   - Probar flujo completo: carrito → checkout → MercadoPago → confirmacion
   - Verificar que pedidos se guardan en Supabase
   - Verificar webhook de MercadoPago actualiza estado del pedido

2. **Integracion Lucy (WhatsApp Bot)**
   - Conectar con la API de Lucy/6to Sentido
   - Enviar notificaciones al admin cuando llega pedido
   - Campos en DB: lucy_enabled, lucy_webhook_url en business_config
   - Credenciales Twilio disponibles: whatsapp:+14155238886

3. **Integracion 6to Sentido**
   - Definir que funcionalidad conectar
   - API key disponible en env.local del proyecto 6to Sentido

### Completado

- ✅ **MercadoPago** - Edge Functions deployadas, app actualizada
- ✅ **Guardar pedidos** - Ya funciona con INSERT anonimo
- ✅ **Auth Google** - Admin panel con OAuth
- ✅ **RLS** - Politicas configuradas

### Media Prioridad

4. **Impresoras**
   - Sistema de impresoras esta en el admin pero necesita backend real
   - Las impresoras termicas requieren un servidor local (print server)
   - Evaluar: electron app, servicio Windows, o impresion via API cloud

5. **Gestion de stock**
   - Tabla products tiene campos stock_enabled y stock_quantity
   - Falta UI en admin para activar/gestionar stock
   - Falta validacion en app usuario para productos sin stock

6. **Horarios del negocio**
   - business_config tiene business_hours en JSON
   - Falta mostrar en app usuario si esta abierto/cerrado
   - Falta UI en admin para editar horarios

7. **Zonas de delivery**
   - business_config tiene delivery_zones (GeoJSON)
   - Falta validar que la direccion del cliente este en zona de cobertura
   - Falta UI en admin para dibujar zonas en mapa

### Baja Prioridad

8. **Descuentos por cantidad**
   - business_config tiene min_empanadas_discount y discount_percentage
   - La logica existe en el frontend pero revisar que funcione correctamente

9. **Integracion Lucy (WhatsApp bot)**
   - Campos lucy_enabled y lucy_webhook_url en business_config
   - Falta implementar el bot y conectar con la API

10. **Integracion 6to Sentido**
    - Campos sexto_sentido_enabled y sexto_sentido_api_key en business_config
    - Pendiente definir que hace esta integracion

11. **Reportes y estadisticas**
    - Tabla daily_stats existe pero no se llena automaticamente
    - Falta crear trigger o cron job para calcular stats diarias
    - Falta UI de reportes en admin

12. **PWA / App instalable**
    - Agregar manifest.json y service worker
    - Para que usuarios puedan "instalar" la app en el celular

13. **Tailwind en produccion**
    - Actualmente usa CDN de Tailwind (muestra warning)
    - Para produccion real: compilar Tailwind y servir CSS minificado

---

## Estructura de Archivos

```
7Tres7-Proyecto/
├── app-usuario/
│   └── index.html              # App de clientes (213 KB)
├── admin-panel/
│   └── index.html              # Panel de administracion (74 KB)
├── database/
│   ├── 01_DATABASE_SCHEMA.sql  # Schema completo de la DB
│   ├── 04_PRODUCTOS_REALES_7TRES7.sql    # Datos de empanadas
│   ├── 05_PRODUCTOS_COMPLETOS_7TRES7.sql # Menu completo
│   ├── 06_AUTH_RLS_UPDATE.sql  # Politicas RLS (YA EJECUTADO)
│   └── 07_INTEGRACIONES_API.sql # Credenciales API (PENDIENTE)
├── supabase/
│   └── functions/
│       ├── create-mp-preference/
│       │   └── index.ts        # Crear preferencia MercadoPago
│       └── mp-webhook/
│           └── index.ts        # Webhook de pagos
├── CLAUDE.md                   # Esta documentacion
└── README.md                   # Resumen del proyecto
```

---

## Comandos Utiles

### Sincronizar cambios con GitHub

```bash
# App usuario
cd C:\Users\Nico\7Tres7-Proyecto\app-usuario
git add .
git commit -m "descripcion del cambio"
git push

# Admin panel
cd C:\Users\Nico\7Tres7-Proyecto\admin-panel
git add .
git commit -m "descripcion del cambio"
git push
```

### Ver logs en Vercel
- https://vercel.com/nicohernaez/7tres7-online
- https://vercel.com/nicohernaez/7tres7-admin

### Deploy Edge Functions (Supabase)

```bash
# Instalar Supabase CLI (si no esta instalado)
npm install -g supabase

# Login a Supabase
supabase login

# Vincular proyecto
cd C:\Users\Nico\7Tres7-Proyecto
supabase link --project-ref yfdustfjfmifvgybwinr

# Configurar secrets (solo una vez)
supabase secrets set MERCADOPAGO_ACCESS_TOKEN="APP_USR-5924995119910825-010419-e0d111986daf9f58ade8aa6032ba6ef4-30888844"

# Deploy funciones
supabase functions deploy create-mp-preference
supabase functions deploy mp-webhook
```

### Probar Edge Function localmente

```bash
supabase functions serve create-mp-preference --env-file .env.local
```

---

## Notas Tecnicas

### Por que los botones de empanadas no funcionaban con MCP
Los clicks del MCP sobre los botones "Fritas" / "Al Horno" no disparaban el evento onclick porque el HTML generado dinamicamente usaba IDs de productos de Supabase que no coincidian exactamente. Se probo llamando `addToCart()` directamente via JavaScript y funciono.

### Auth flow del admin
Se uso `onAuthStateChange` como unico handler de auth en lugar de combinarlo con `getSession()` para evitar race conditions donde la app se inicializaba dos veces.

### RLS y app usuario
La app usuario necesita leer productos sin autenticacion. Se agregaron politicas `FOR SELECT USING (true)` en products, categories y business_config. Para guardar pedidos hay que evaluar si usar Edge Functions o permitir INSERT anonimo con validaciones.
