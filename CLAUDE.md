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

## Estado Actual (23 Febrero 2026)

### ✅ Completado

- ✅ **App usuario funcional** — 77 productos, carrito, checkout, registro por teléfono
- ✅ **Admin panel** — Google OAuth, paginación, búsqueda, CRM con 2025 clientes importados
- ✅ **MercadoPago conectado** (19 Feb 2026) — Edge Functions deployadas sin JWT, flujo completo carrito→checkout→pago→webhook
- ✅ **Deploy Vercel arreglado** (19 Feb 2026) — Branch `master` sincronizada a `main`, ambas apps en producción con últimos commits
- ✅ **RLS** — Políticas en todas las tablas, lectura pública para products/categories/business_config/subcategories. INSERT anónimo en orders.
- ✅ **Tipos de cliente / CRM** (6 Feb 2026) — ENUMs, retention_status, churn_risk_score, trigger automático, vistas
- ✅ **2025 clientes importados** desde 6to-sentido (6 Feb 2026)
- ✅ **Menú mejorado** (14 Feb 2026) — Observaciones por producto, punto de cocción, muslo/pechuga separados, dirección flexible, indicaciones de entrega
- ✅ **Sync App <-> Admin** (23 Feb 2026) — Productos dinámicos desde Supabase, cache localStorage, fallback 3 niveles. SQL `12` y `13` ejecutados.
- ✅ **Fix RLS subcategories** (23 Feb 2026) — Policy anónima en subcategories + slugs corregidos. SQL `13_FIX_RLS_SUBCATEGORIES.sql` ejecutado.
- ✅ **Fix carga rápida** (23 Feb 2026) — initApp() no-bloqueante, renderiza defaults inmediato y carga Supabase en background.
- ✅ **Fix flan y confirmación** (23 Feb 2026) — Flan con opción "Solo" por defecto. saveOrderToSupabase resiliente a RLS de customers.
- ✅ **Tabla `discounts`** (21 Feb 2026) — Para descuentos generados por Lucy y n8n. Columnas recovery en `customers`.
- ✅ **Integración Lucy/6to-sentido verificada** (23 Feb 2026) — Service key configurada, código revisado, build passing, bug delivery_fee corregido

### ⏳ Pendiente

#### Para probar ya (todo está conectado)
- [ ] **Test de pago real** — Hacer un pedido con MercadoPago desde la app y verificar que el webhook actualiza `orders.payment_status` y crea registro en `payments`

#### Necesita hardware/presencia física
- [ ] **Impresoras térmicas** — Necesita print server local. Evaluar: Electron app, servicio Windows, o impresión via API cloud. Verificar qué impresora tienen en el local.
- [ ] **Lucy WhatsApp** — Necesita teléfono del negocio para verificar número en Meta Cloud API

#### Media prioridad
- [ ] **RLS customers** — La tabla `customers` NO tiene policy anónima. El app no puede crear/buscar clientes. Agregar policy de INSERT anónimo o usar Edge Function. Mientras tanto, `saveOrderToSupabase` guarda el pedido sin customer_id e incluye tel/nombre en customer_notes.
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
│   ├── 12_SYNC_MISSING_PRODUCTS.sql # Sync productos app<->admin (EJECUTADO)
│   └── 13_FIX_RLS_SUBCATEGORIES.sql # Fix RLS subcategories + slugs (EJECUTADO)
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
| `discounts` | ✅ | Códigos descuento generados por Lucy y n8n workflows |
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
- `initApp()` es no-bloqueante: renderiza defaults inmediato, carga Supabase en background y re-renderiza
- `inferSubcategory(slug)` + `SLUG_SUBCATEGORY_MAP`: fallback JS cuando RLS bloquea el JOIN de subcategories
- SQL migrations: `12_SYNC_MISSING_PRODUCTS.sql` + `13_FIX_RLS_SUBCATEGORIES.sql` (ambas ejecutadas)

### Slugs Supabase vs keys JS (23 Feb)
- Los keys JS usan `_` (underscore), los slugs Supabase usan `-` (guión): `loadProductsFromDB()` hace `slug.replace(/-/g, '_')`
- Slugs reales de Supabase que difieren del patrón simple: `pizza-muzzarella` (no `pizza-muzza`), `ojo-de-bife`, `bife-de-chorizo`, `matambre-a-la-pizza`, `bife-de-bondiola`, `matambrito-de-cerdo`, `cheese-cake-frutos-rojos`
- Los defaults en JS ya usan estos keys correctos

### Dos formatos de items en carrito
- **Empanadas** (sistema legacy): `{ productId, cookingMethod, quantity, price }` — NO tiene `id` ni `label`
- **Todo lo demás** (sistema nuevo): `{ id, label, price, quantity, icon, category? }` — NO tiene `productId`
- `updateCart()`, `confirmOrder()`, `updatePromoBanner()` manejan ambos formatos con `if (item.label)`

### Checkout y pedidos (23 Feb)
- `saveOrderToSupabase()`: customers operations en try/catch propio (RLS puede bloquear). Si falla, el pedido se guarda sin customer_id e incluye tel+nombre en customer_notes.
- Flan tiene opción "Solo" como default (no requiere seleccionar tipo)

### Observaciones por producto (14 Feb)
- `initProductObservations()` inyecta input en cada tarjeta
- `getProductObs(productId)` lee y limpia
- Se muestra en: carrito, pago, confirmación, WhatsApp, Supabase

### Punto de cocción (14 Feb)
- Integrado en `renderParrillaCard()` para asado, ojo_de_bife, bife_de_chorizo
- `conPuntoCoccion` incluye ambos formatos de slug (con y sin `_de_`)
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

## Integración Lucy / 6to Sentido (23 Feb 2026)

### Estado de integración

7Tres7 es el primer negocio conectado a **6to Sentido** (`C:\Users\Nico\6to-sentido\`). Lucy es la asistente virtual que atiende clientes por WhatsApp fuera de horario.

**Qué está listo:**
- ✅ `SUPABASE_7TRES7_SERVICE_KEY` configurada en 6to-sentido `.env.local`
- ✅ Código Lucy en 6to-sentido: brain.ts detecta 7Tres7, genera respuestas con menú en vivo, crea descuentos
- ✅ Tabla `discounts` en esta DB: Lucy genera códigos `LUCY15-XXXX` cuando el negocio está cerrado
- ✅ Columnas recovery en `customers`: `last_recovery_attempt`, `recovery_attempts_count`, `recovery_exhausted`
- ✅ `business_config.business_hours`: Lun/Mar cerrados, Mié-Dom dual time slots (12-15 + 19-00/01)
- ✅ n8n workflows: "Reactivación At Risk" (`PpwgLv7qMCQyX0XF`) y "Recuperación Churned" (`93kHf0hkflows8tx`) — inactivos
- ✅ Build de 6to-sentido passing con la integración

**Qué falta para activar:**
1. Teléfono físico del negocio para verificar en Meta Cloud API (WhatsApp Business)
2. Configurar `WHATSAPP_PHONE_NUMBER_ID` + `WHATSAPP_ACCESS_TOKEN` en n8n
3. Agregar `SUPABASE_7TRES7_SERVICE_KEY` a Vercel env vars de 6to-sentido (solo está en .env.local)
4. Setear `lucy_enabled=true` y `lucy_webhook_url` en `business_config` cuando esté listo

### Datos de integración
- **business_id en 6to-sentido**: `d0825b81-f96b-4e9a-9806-b6ecf10d9806`
- **whatsapp_accounts**: registrado como `local`, phone `+5492302515656`, sin verificar
- **secretary_config**: mode=`active`, tone=`casual`, escalation a Nico
- **Clientes**: 2025 (1584 churned, 247 new, 194 at_risk)

### Flujo Lucy (cuando esté activo)
1. Cliente envía WhatsApp al número del negocio
2. Twilio webhook → 6to-sentido `/api/whatsapp/webhook`
3. Webhook detecta cuenta `local` → Secretary flow
4. Brain detecta 7Tres7 → Lucy flow específico
5. Si negocio cerrado → genera descuento LUCY15-XXXX en tabla `discounts` + mensaje fuera de horario
6. Si negocio abierto → consulta menú en vivo + responde con precios actualizados
7. n8n cron workflows envían descuentos a clientes at_risk/churned

---

## Notas Técnicas

- **Botones empanadas + MCP**: Los clicks del MCP no disparan onclick en HTML dinámico. Llamar `addToCart()` directo.
- **Auth admin**: `onAuthStateChange` como único handler para evitar race conditions.
- **RLS app usuario**: Políticas `FOR SELECT USING (true)` en products, categories, business_config, subcategories. INSERT anónimo en orders. La tabla `customers` NO tiene policy anónima — saveOrderToSupabase maneja esto gracefully.
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
