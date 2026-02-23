# 7Tres7 - Documentacion del Proyecto

## Resumen del Proyecto

Sistema de pedidos online para restaurante 7Tres7 (empanadas y mas) con dos aplicaciones:
1. **App Usuario** - Para que clientes hagan pedidos
2. **Admin Panel** - Para administrar el negocio

**URLs de produccion:**
- App Usuario: https://7tres7-online.vercel.app
- Admin Panel: https://7-tres7-admin.vercel.app

**Repos GitHub:**
- `NicoHernaez/7Tres7-Online` (branch: `main`)
- `NicoHernaez/7Tres7-Admin` (branch: `main`)

**Supabase:** https://yfdustfjfmifvgybwinr.supabase.co

**Proyecto relacionado:** `C:\Users\Nico\6to-sentido\` — 6to Sentido (SaaS de contenido). 7Tres7 es el primer negocio que prueba la plataforma. Futuro: el sistema de pedidos se convertirá en white-label feature dentro de 6to Sentido.

---

## Estado Actual (19 Febrero 2026)

### ✅ Completado

- ✅ **App usuario funcional** — 61 productos, carrito, checkout, registro por teléfono
- ✅ **Admin panel** — Google OAuth, paginación, búsqueda, CRM con 2026 clientes importados
- ✅ **MercadoPago conectado** (19 Feb 2026) — Edge Functions deployadas sin JWT, flujo completo carrito→checkout→pago→webhook
- ✅ **Deploy Vercel arreglado** (19 Feb 2026) — Branch `master` sincronizada a `main`, ambas apps en producción con últimos commits
- ✅ **RLS** — Políticas en todas las tablas, lectura pública para products/categories/business_config
- ✅ **Tipos de cliente / CRM** (6 Feb 2026) — ENUMs, retention_status, churn_risk_score, trigger automático, vistas
- ✅ **2026 clientes importados** desde 6to-sentido (6 Feb 2026)
- ✅ **Menú mejorado** (14 Feb 2026) — Observaciones por producto, punto de cocción, muslo/pechuga separados, dirección flexible, indicaciones de entrega
- ✅ **Sync App <-> Admin** (23 Feb 2026) — Productos dinámicos desde Supabase, cache localStorage, fallback 3 niveles. SQL: `12_SYNC_MISSING_PRODUCTS.sql` pendiente de ejecutar.

### ⏳ Pendiente

#### Para probar ya (todo está conectado)
- [ ] **Ejecutar SQL migration** — `12_SYNC_MISSING_PRODUCTS.sql` en Supabase SQL Editor (agrega productos faltantes, subcategorías, iconos, descripciones)
- [ ] **Test de pago real** — Hacer un pedido con MercadoPago desde la app y verificar que el webhook actualiza `orders.payment_status` y crea registro en `payments`

#### Necesita hardware/presencia física
- [ ] **Impresoras térmicas** — Necesita print server local. Evaluar: Electron app, servicio Windows, o impresión via API cloud. Verificar qué impresora tienen en el local.
- [ ] **Lucy WhatsApp** — Necesita teléfono del negocio para verificar número en Meta Cloud API

#### Media prioridad
- [ ] **Horarios del negocio** — `business_config` tiene `business_hours` JSON. Falta mostrar abierto/cerrado en app usuario + UI en admin para editar
- [ ] **Gestión de stock** — Tabla `products` tiene `stock_enabled` y `stock_quantity`. Falta UI en admin + validación en app usuario
- [ ] **Reportes y estadísticas** — Tabla `daily_stats` existe pero no se llena. Falta trigger/cron + UI

#### Baja prioridad
- [ ] **Zonas de delivery** — `delivery_zones` GeoJSON en business_config, falta validación de dirección + UI mapa
- [ ] **Descuentos por cantidad** — Lógica existe en frontend (10% en 36+ empanadas), revisar que funcione
- [ ] **PWA** — manifest.json + service worker para instalar en celular
- [ ] **Tailwind producción** — Actualmente usa CDN (muestra warning), compilar para producción

---

## MercadoPago — Configuración (19 Feb 2026)

### Edge Functions (Supabase)

| Función | URL | JWT | Descripción |
|---------|-----|-----|-------------|
| `create-mp-preference` | `.../functions/v1/create-mp-preference` | No | Crea preferencia de pago, retorna `initPoint` URL |
| `mp-webhook` | `.../functions/v1/mp-webhook` | No | Recibe notificaciones de MercadoPago, actualiza pedido |

Ambas deployadas con `verify_jwt = false` (config en `supabase/config.toml`).

### Flujo completo
1. Cliente elige "Mercado Pago" en checkout
2. App guarda pedido en `orders` (Supabase INSERT anónimo)
3. App llama a `create-mp-preference` con items, customer, orderId
4. Edge Function crea preferencia en MercadoPago API → retorna `initPoint`
5. App redirige al usuario a MercadoPago checkout
6. Usuario paga
7. MercadoPago notifica a `mp-webhook` → actualiza `orders.payment_status` + crea registro en `payments`
8. Usuario vuelve a la app con `?status=success` → muestra confirmación → abre WhatsApp

### Credenciales
- **Public Key:** `APP_USR-6eb41426-d39e-418b-9e30-2016506f983d` (en `business_config`)
- **Access Token:** Configurado como secret en Edge Functions (nunca en frontend)
- **Cuenta MP:** nicohernaez22@gmail.com (User ID: 30888844)

### Deploy de funciones
```bash
cd C:\Users\Nico\7Tres7-Proyecto
SUPABASE_ACCESS_TOKEN=<token> npx supabase functions deploy create-mp-preference --no-verify-jwt --project-ref yfdustfjfmifvgybwinr
SUPABASE_ACCESS_TOKEN=<token> npx supabase functions deploy mp-webhook --no-verify-jwt --project-ref yfdustfjfmifvgybwinr
```

---

## Arquitectura

### Stack
- **Frontend:** HTML + Tailwind CSS (CDN) + JavaScript vanilla
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **Pagos:** MercadoPago (Edge Functions)
- **Deploy:** Vercel (static hosting)
- **Auth admin:** Google OAuth via Supabase Auth

### Estructura de Archivos

```
7Tres7-Proyecto/
├── app-usuario/
│   └── index.html              # App de clientes (single file, productos dinámicos desde Supabase)
├── admin-panel/
│   └── index.html              # Panel de administración (74 KB, single file)
├── database/
│   ├── 01_DATABASE_SCHEMA.sql  # Schema completo
│   ├── 04_PRODUCTOS_REALES_7TRES7.sql
│   ├── 05_PRODUCTOS_COMPLETOS_7TRES7.sql
│   ├── 06_AUTH_RLS_UPDATE.sql  # RLS (EJECUTADO)
│   ├── 07_INTEGRACIONES_API.sql # Credenciales API (EJECUTADO)
│   ├── 08_CUSTOMER_TYPES.sql   # ENUMs, CRM (EJECUTADO)
│   ├── 09_IMPORT_CUSTOMERS.sql # 2026 clientes (EJECUTADO)
│   └── 12_SYNC_MISSING_PRODUCTS.sql # Sync productos app<->admin (PENDIENTE)
├── supabase/
│   ├── config.toml             # verify_jwt = false para ambas funciones
│   └── functions/
│       ├── create-mp-preference/
│       │   └── index.ts
│       └── mp-webhook/
│           └── index.ts
├── CLAUDE.md
└── README.md
```

### Base de Datos (tablas principales)

| Tabla | Estado | Descripción |
|-------|--------|-------------|
| `products` | ✅ 61 productos | Menú completo con precios |
| `categories` | ✅ | Empanadas, Pizzas, Minutas, Restaurante, etc |
| `orders` | ✅ | Pedidos con payment_status, payment_id, payment_details |
| `customers` | ✅ 2026 | CRM con retention_status, churn_risk, acquisition_source |
| `payments` | ✅ | Registro de pagos MercadoPago |
| `business_config` | ✅ | Config del negocio (horarios, delivery, MP, etc) |
| `printers` | ⏳ | Configuración de impresoras (sin backend) |
| `print_jobs` | ⏳ | Cola de impresión (sin backend) |
| `daily_stats` | ⏳ | Stats diarias (tabla vacía, sin trigger) |

### Configuración

**Supabase:**
- URL: `https://yfdustfjfmifvgybwinr.supabase.co`
- Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHVzdGZqZm1pZnZneWJ3aW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMzU3ODQsImV4cCI6MjA4NTgxMTc4NH0.YcLo7YXePi0_okJxtPuYLaMQI2-P4C8UxNzXnLfQoBY`

**Admin email autorizado:** nicohernaez22@gmail.com

**Google OAuth:** Usa credenciales del proyecto 6to Sentido. Redirect URI: `https://yfdustfjfmifvgybwinr.supabase.co/auth/v1/callback`

---

## Detalle Técnico: App Usuario

### Productos dinámicos desde Supabase (23 Feb)
- **Antes:** ~1030 líneas de HTML hardcodeado con precios estáticos
- **Ahora:** Productos se cargan de Supabase y se renderizan dinámicamente
- Fallback de 3 niveles: Supabase (online) → localStorage cache → defaults hardcodeados
- `renderAllProducts()` genera el HTML para las 4 categorías
- `addToCart` funciones usan `products[id]` global (precios de Supabase)
- `UI_OPTIONS` constante con salsas, guarniciones, punto de cocción
- Cambiar precio en admin → recargar app → precio actualizado
- SQL migration: `12_SYNC_MISSING_PRODUCTS.sql` (ejecutar en SQL Editor)

### Observaciones por producto (14 Feb)
- `initProductObservations()` inyecta input en cada tarjeta
- `getProductObs(productId)` lee y limpia
- Se muestra en: carrito, pago, confirmación, WhatsApp, Supabase

### Punto de cocción (14 Feb)
- Integrado en `renderParrillaCard()` para asado, ojo_bife, bife_chorizo
- Select: Jugoso / A punto / Bien cocido

### Muslo / Pechuga (14 Feb)
- `pollo_parrilla` → `pollo_muslo` + `pollo_pechuga` (mismo precio $15.530)

### Dirección flexible (14 Feb)
- Mínimo 3 chars (antes 10), acepta "18 n 737"

### Indicaciones de entrega (14 Feb)
- Campo `deliveryNotes` en registro, se envía en WhatsApp y Supabase

---

## Detalle Técnico: CRM (6 Feb)

### ENUMs
- `acquisition_source_type`: app, whatsapp, instagram, facebook, google, walk_in, referral, mercadopago_qr, mercadopago_point
- `retention_status`: new, active, at_risk, churned, recovered

### Trigger automático
`trigger_update_customer_retention` actualiza `retention_status` y `churn_risk_score` cuando cambia `last_order_at` o `total_orders`.

### Admin Panel
- 5 stats cards por estado (colores)
- Filtro dropdown por retention_status
- Badge + icono origen + barra de churn risk por fila

---

## Notas Técnicas

- **Botones empanadas + MCP**: Los clicks del MCP no disparan onclick en HTML dinámico. Llamar `addToCart()` directo.
- **Auth admin**: `onAuthStateChange` como único handler para evitar race conditions.
- **RLS app usuario**: Políticas `FOR SELECT USING (true)` en products, categories, business_config. INSERT anónimo en orders.
- **Branch**: Ambos repos usan `main`. La branch `master` fue eliminada (19 Feb 2026).

---

## Idioma y Comunicación
- El usuario se comunica en español. Responder SIEMPRE en español a menos que él cambie a inglés.
- Ser orientado a la acción: cuando el usuario reporta un problema, proponer e implementar el fix inmediatamente.

## Deployment y Verificación
- Después de pushear a GitHub, Vercel auto-deploya. NO usar Vercel CLI a menos que se pida.
- URLs de producción: App Usuario `https://7tres7-online.vercel.app`, Admin `https://7-tres7-admin.vercel.app`
- DNS local no resuelve `api.vercel.com` — usar `--resolve api.vercel.com:443:76.76.21.112` para API calls

## Supabase y Migraciones
- SIEMPRE leer schema actual ANTES de escribir SQL de migración.
- Cuando una migración falla, corregir el error específico — NO reescribir desde cero.

## Bug Fixing
- Corregir bugs inmediatamente, no diagnosticar excesivamente.
- Auth usa Google OAuth, no passwords.
- Identificar causa raíz → UN fix puntual.
