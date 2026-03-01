# 7Tres7 - Documentacion del Proyecto

## Resumen del Proyecto

Sistema de pedidos online para restaurante 7Tres7 (empanadas y mas) con tres aplicaciones:
1. **App Usuario** - Para que clientes hagan pedidos
2. **Admin Panel** - Para administrar el negocio
3. **App Caja** - Panel de caja para gestionar pedidos en el local

**URLs de produccion:**
- App Usuario: https://7tres7-online.vercel.app
- Admin Panel: https://7-tres7-admin.vercel.app
- App Caja: https://7-tres7-caja.vercel.app

**Repos GitHub:**
- `NicoHernaez/7Tres7-Online` (branch: `main`)
- `NicoHernaez/7Tres7-Admin` (branch: `main`)
- `NicoHernaez/7Tres7-Caja` (branch: `main`) — local: `C:\Users\Nico\7tres7-caja`

**Supabase:** https://yfdustfjfmifvgybwinr.supabase.co

**Proyecto relacionado:** `C:\Users\Nico\6to-sentido\` — 6to Sentido (SaaS de contenido). 7Tres7 es el primer negocio que prueba la plataforma. Futuro: el sistema de pedidos se convertirá en white-label feature dentro de 6to Sentido.

---

## Estado Actual (1 Marzo 2026)

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
- ✅ **App Electron impresión térmica** (25 Feb 2026) — `7tres7-print-app/` creada. Supabase Realtime sobre `print_jobs`. ESC/POS raw via WinAPI PowerShell inline. Configs BARRA/COCINA. SQL `14` ejecutado: categorías→impresoras asignadas, RLS anon, Realtime, trigger reescrito.
- ✅ **Fix impresión .exe portable** (27 Feb 2026) — Eliminado `raw-print.ps1` externo (no se empaquetaba). PowerShell 100% inline via `-EncodedCommand`. 2 fallbacks: `copy /b` + `print /d:`. Detección `pc-config.json` mejorada (5 paths). Nombres impresoras case-sensitive. v1.0.1.
- ✅ **App Caja documentada** (25 Feb 2026) — `7tres7-caja/` single-file HTML en Vercel. Master-detail pedidos, cierre de caja, staff, descuentos, WhatsApp, Realtime.
- ✅ **QZ Tray eliminado de Caja** (25 Feb 2026) — Todo código QZ Tray removido. Impresión 100% via Supabase trigger + Electron app.
- ✅ **PWA App Usuario** (25 Feb 2026) — manifest.json, service worker, offline.html, 9 iconos, install banner (Android + iOS). Instalable desde celular.
- ✅ **Horarios del negocio** (26 Feb 2026) — App usuario: indicador abierto/cerrado en welcome + banner en menú cuando cerrado. Admin: sección "Horarios" con toggle por día, turnos mediodía/noche, guardar a Supabase.
- ✅ **Flujo WhatsApp invertido** (27 Feb 2026) — Antes: cliente enviaba WhatsApp al negocio. Ahora: cliente confirma → pedido en Supabase (pending) → pantalla "Pedido Recibido". Caja confirma → elige tiempo estimado (25/35/45/55 min) → WhatsApp al CLIENTE con confirmación + tiempo.
- ✅ **Rediseño UI Caja — Dark Theme** (1 Mar 2026) — Glassmorphism, gradientes, glow buttons. Sub-tabs eliminadas → lista unificada con separadores de grupo por estado. Imágenes reales (Empanada-avatar.png, LOGO737.jpg).
- ✅ **Flujo ENVIAR con cadetes** (1 Mar 2026) — Pedidos delivery en preparación muestran botón ENVIAR → modal selector de cadete → pasa a En Camino + notificación WhatsApp al cliente con nombre del cadete. En Camino muestra botón ENTREGADO → marca delivered.

### ⏳ Pendiente

#### Para probar ya (todo está conectado)
- [ ] **Test de pago real** — Hacer un pedido con MercadoPago desde otra cuenta y verificar que el webhook actualiza `orders.payment_status` y crea registro en `payments`

#### Necesita hardware/presencia física
- [ ] **Impresoras térmicas — Instalar** — SQL ya ejecutado. Falta: instalar app Electron en PC Barra y PC Cocina, verificar nombres de impresoras en Windows, probar con pedido real.
- [ ] **Lucy WhatsApp** — Necesita teléfono del negocio para verificar número en Meta Cloud API

#### Media prioridad
- [ ] **Gestión de stock** — Tabla `products` tiene `stock_enabled` y `stock_quantity`. Falta UI en admin + validación en app usuario
- [ ] **Reportes y estadísticas** — Tabla `daily_stats` existe pero no se llena. Falta trigger/cron + UI

#### Baja prioridad
- [ ] **Zonas de delivery** — `delivery_zones` GeoJSON en business_config, falta validación de dirección + UI mapa
- [ ] **Descuentos por cantidad** — Lógica existe en frontend (10% en 36+ empanadas), revisar que funcione
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
8. Usuario vuelve a la app con `?status=success` → muestra "Pedido Recibido" (sin WhatsApp, la confirmación va desde Caja)

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
│   ├── index.html              # App de clientes (single file, productos dinámicos desde Supabase)
│   ├── manifest.json           # PWA manifest
│   ├── sw.js                   # Service Worker
│   ├── offline.html            # Página sin conexión
│   └── icons/                  # Iconos PWA (72-512px + apple-touch-icon)
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
│   ├── 13_FIX_RLS_SUBCATEGORIES.sql # Fix RLS subcategories + slugs (EJECUTADO)
│   └── 14_PRINT_SYSTEM.sql   # print_jobs + printers + trigger + Realtime (EJECUTADO)
├── 7tres7-print-app/
│   ├── main.js                # Proceso principal Electron
│   ├── preload.js             # Bridge seguro IPC
│   ├── pc-config.json         # {"pc":"BARRA","printers":["Barra"]}
│   ├── src/
│   │   ├── config.js          # Config por PC, mapeo categorias→impresoras, CATEGORY_PRINTER_MAP
│   │   ├── printer.js         # ESC/POS builder + raw print via WinAPI inline (NO .ps1)
│   │   ├── supabase-listener.js # Supabase Realtime en print_jobs
│   │   └── tray.js            # Icono bandeja del sistema
│   └── renderer/
│       ├── index.html         # UI estado
│       └── renderer.js        # Lógica renderer
├── supabase/
│   ├── config.toml             # verify_jwt = false para ambas funciones
│   └── functions/
│       ├── create-mp-preference/
│       │   └── index.ts
│       └── mp-webhook/
│           └── index.ts
├── CLAUDE.md
└── README.md

7tres7-caja/                      # Repo separado: NicoHernaez/7Tres7-Caja
└── index.html                    # App Caja (single file, ~2100 líneas, Tailwind + Supabase)
```

### Base de Datos (tablas — auditado 25 Feb 2026)

| Tabla | Rows | Descripción |
|-------|------|-------------|
| `products` | 77 | Menú completo con precios, stock_enabled, stock_quantity |
| `categories` | 6 | Empanadas, Pizzas, Minutas, Restaurant, Postres, Bebidas. Cada una con `printer_id` y `printer_secondary_id` |
| `subcategories` | 10 | Subcategorías (ej: Horno/Fritas para Empanadas) |
| `orders` | 25 | Pedidos (18 pending, 5 delivered, 1 cancelled, 1 confirmed) |
| `customers` | 2026 | CRM con retention_status, churn_risk, acquisition_source |
| `payments` | 8 | Pagos MP: mp_payment_id, mp_preference_id, amount, method, status, mp_response |
| `business_config` | — | Config negocio (horarios, delivery, MP keys, etc) |
| `printers` | 3 | Barra (BARRA), minuta (MINUTA), parrilla delivery (PARRILLA). Nombres = nombres exactos en Windows |
| `print_jobs` | 3 | Cola impresión con Realtime. printer_id FK, raw_data JSONB, ticket_type, attempts |
| `staff` | 2 | Cadetes para delivery (Cadete 1, Cadete 2). Roles: cadete. Usado por app Caja |
| `discounts` | 0 | Códigos descuento para Lucy/n8n (tabla lista, sin datos aún) |
| `admin_users` | — | Usuarios admin autorizados |
| `activity_logs` | — | Log de actividad del sistema |
| `order_status_history` | — | Historial de cambios de estado de pedidos |
| `printer_templates` | — | Templates de impresión (sin uso activo) |
| `whatsapp_messages` | — | Mensajes WhatsApp (para integración Lucy futura) |
| `daily_stats` | 0 | Stats diarias (tabla vacía, sin trigger/cron) |

### Triggers activos

| Trigger | Tabla | Evento | Descripción |
|---------|-------|--------|-------------|
| `trigger_create_print_jobs` | `orders` | AFTER INSERT/UPDATE | Crea print_jobs cuando `status` cambia a `confirmed` |
| `trigger_update_customer_stats` | `orders` | AFTER INSERT/UPDATE | Actualiza stats del cliente (total_orders, last_order_at, etc) |
| `trigger_update_customer_retention` | `customers` | BEFORE UPDATE | Recalcula retention_status y churn_risk_score |
| `update_*_updated_at` | varias | BEFORE UPDATE | Auto-actualiza `updated_at` en business_config, categories, customers, orders, print_jobs, printers, products |

### RLS Policies (auditado 25 Feb 2026)

| Tabla | Anon | Auth | Notas |
|-------|------|------|-------|
| `products` | SELECT | ALL | Lectura pública |
| `categories` | SELECT | ALL | Lectura pública |
| `subcategories` | SELECT | ALL | Lectura pública |
| `business_config` | SELECT | ALL | Lectura pública |
| `orders` | SELECT, INSERT | ALL | Anon puede crear pedidos y ver los propios |
| `customers` | SELECT, INSERT, UPDATE | ALL | Anon CRUD completo (corregido) |
| `payments` | — | ALL | Solo autenticados |
| `printers` | SELECT | ALL | Lectura para app Electron (anon key) |
| `print_jobs` | SELECT, UPDATE | ALL | Electron lee y actualiza status |
| `staff` | SELECT | INSERT, UPDATE | Lectura pública, escritura autenticada |
| `discounts` | — | ALL | Solo autenticados |
| `daily_stats` | — | ALL | Solo autenticados |
| `admin_users` | — | ALL | Solo autenticados |
| `activity_logs` | — | ALL | Solo autenticados |
| `order_status_history` | — | ALL | Solo autenticados |
| `printer_templates` | — | ALL | Solo autenticados |
| `whatsapp_messages` | — | ALL | Solo autenticados |

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

### Checkout y pedidos (27 Feb)
- `saveOrderToSupabase()`: customers operations en try/catch propio (RLS puede bloquear). Si falla, el pedido se guarda sin customer_id e incluye tel+nombre en customer_notes.
- Flan tiene opción "Solo" como default (no requiere seleccionar tipo)
- **Flujo WhatsApp invertido (27 Feb):** `confirmOrder()` ya NO construye mensaje WhatsApp ni redirige. Solo guarda en Supabase y muestra `showSuccess(orderNumber)`. La notificación WhatsApp la envía la Caja al confirmar (negocio→cliente).

### Observaciones por producto (14 Feb)
- `initProductObservations()` inyecta input en cada tarjeta
- `getProductObs(productId)` lee y limpia
- Se muestra en: carrito, pago, confirmación, Supabase

### Punto de cocción (14 Feb)
- Integrado en `renderParrillaCard()` para asado, ojo_de_bife, bife_de_chorizo
- `conPuntoCoccion` incluye ambos formatos de slug (con y sin `_de_`)
- Select: Jugoso / A punto / Bien cocido

### Muslo / Pechuga (14 Feb)
- `pollo_parrilla` → `pollo_muslo` + `pollo_pechuga` (mismo precio $15.530)

### Dirección flexible (14 Feb)
- Mínimo 3 chars (antes 10), acepta "18 n 737"

### Indicaciones de entrega (14 Feb)
- Campo `deliveryNotes` en registro, se envía en Supabase (y en WhatsApp desde Caja)

---

## Detalle Técnico: PWA App Usuario (25 Feb 2026)

### Archivos creados
- `manifest.json` — Metadata PWA: name, short_name, theme_color `#e94560`, display `standalone`, 8 iconos
- `sw.js` — Service Worker network-first. Cachea HTML y iconos. Ignora requests a Supabase/CDN. Fallback offline.
- `offline.html` — Página sin conexión con botón reintentar y teléfono del local
- `icons/` — 9 PNGs (72, 96, 128, 144, 152, 192, 384, 512) + apple-touch-icon (180)

### Meta tags agregados al head
```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#e94560">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="7Tres7">
<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png">
```

### Install Banner
- **Android/Chrome**: Captura `beforeinstallprompt`, muestra banner a los 5s con botón "Instalar". Si descarta, no vuelve por 7 días.
- **iOS/Safari**: Detecta user-agent iOS + no-standalone, muestra instrucción "Toca compartir y Agregar a inicio" a los 8s.
- No se muestra si la app ya está en modo standalone (ya instalada).

### Service Worker Strategy
- **Network-first**: Intenta fetch, si falla sirve desde cache
- **Excluidos**: Supabase API, CDNs (Tailwind, Supabase JS) — siempre van a red
- **Cache**: `7tres7-v1` con `/`, `/offline.html`, iconos principales
- **Offline**: Si navega sin internet → muestra `offline.html`

---

## Detalle Técnico: App Caja (1 Mar 2026)

### Ubicación y deploy
- **Repo local:** `C:\Users\Nico\7tres7-caja`
- **GitHub:** `NicoHernaez/7Tres7-Caja`
- **URL:** https://7-tres7-caja.vercel.app
- **Arquitectura:** Single-file HTML (`index.html`, ~2100 líneas), Tailwind CSS CDN, vanilla JS, Supabase

### Auth
- Google OAuth + Magic Link via Supabase Auth
- Emails autorizados: `nicohernaez22@gmail.com`, `lumimartin24@gmail.com`, `martinludmila300@gmail.com`
- Constante `AUTHORIZED_EMAILS` valida acceso post-login

### UI — Dark Theme (1 Mar 2026)
- **Glassmorphism:** `backdrop-blur`, `bg-white/5`, bordes `border-white/10`
- **Glow buttons:** `btn-glow-green/blue/purple/orange/urgent` con gradientes + box-shadow
- **`btn-glow-urgent`:** rojo/naranja + `urgentPulse` animation (scale + glow) para CONFIRMAR
- **Status badges:** `status-badge-confirmed/preparing/ready/delivering` con colores por estado
- **Status strips:** Barra vertical izquierda en cada order card con gradiente por estado
- **Scrollbar dark:** thumb blanco transparente
- **Imágenes:** `Empanada-avatar.png` (login + header), `LOGO737.jpg` (disponible)

### Funcionalidades principales
1. **Gestión de pedidos (master-detail):** Lista izquierda (58%) + detalle derecho (42%). Mother tabs: Todos/Mostrador/Delivery/Salon. Búsqueda por # o nombre.
2. **Lista unificada con grupos:** Sub-tabs eliminadas. Pedidos se muestran en una sola lista con separadores de grupo: Pendientes, En Preparacion, En Camino, Entregados, Cancelados. Cada grupo con conteo.
3. **Flujo de estados (delivery):** Pendiente → CONFIRMAR → En Preparación → ENVIAR (modal cadete) → En Camino → ENTREGADO → Entregados.
4. **Flujo de estados (mostrador):** Pendiente → CONFIRMAR → En Preparación → MARCAR ENTREGADO → Entregados.
5. **Flujo ENVIAR con cadetes (1 Mar 2026):** `openEnviarModal()` → modal con lista de cadetes desde `staffCache` → `enviarConCadete(name)` actualiza status a `delivering`, asigna `assigned_to`, notifica cliente via WhatsApp con nombre del cadete.
6. **Impresión:** Trigger SQL `create_print_jobs_for_order()` al confirmar. Botón "Reimprimir" en detalle.
7. **Medios de pago:** Efectivo, Débito, Crédito, MercadoPago, QR, Prepaga, Transferencia.
8. **Descuentos:** % o monto fijo con motivo.
9. **Cierre de caja:** Modal con resumen por día/turno.
10. **Staff/Cadetes:** CRUD de cadetes. Modal de gestión.
11. **Agregar items:** Modal para agregar productos a pedidos existentes.
12. **Notificación WhatsApp (negocio→cliente):** Confirmar (tiempo estimado), Enviar (nombre cadete), Entregado.
13. **Realtime:** Supabase Realtime en `orders`. Auto-refresh al recibir INSERT/UPDATE.

### Quick action buttons en la lista
| Estado | Tipo | Botón | Acción |
|--------|------|-------|--------|
| pending | todos | **CONFIRMAR** (btn-glow-urgent, pulsa) | `confirmOrder()` → modal tiempo |
| confirmed/preparing | delivery | **ENVIAR** (btn-glow-blue) | `openEnviarModal()` → modal cadete |
| confirmed/preparing | mostrador | PREPARANDO (badge) | — |
| delivering | delivery | **ENTREGADO** (btn-glow-green) | `markDelivered()` |
| delivered/ready | todos | — (opacity 50%) | — |
| cancelled | todos | — (opacity 50%, tachado) | — |

### Stats en header
- Revenue del día, cantidad de pedidos, ticket promedio
- Badge de pedidos demorados (>15min sin confirmar)

### Variables de estado principales
- `allOrders[]` — todos los pedidos del día
- `selectedOrderId` — pedido seleccionado en el detalle
- `motherTab` — filtro por tipo (todos/mostrador/delivery/salon)
- `staffCache[]` — cadetes cargados
- `productsCache[]` — productos para modal "Agregar item"
- `enviarOrderId` — orderId para modal de enviar con cadete

### Status priority sort
```javascript
const statusPriority = { pending: 0, preparing: 1, confirmed: 2, delivering: 3, ready: 4, delivered: 4, cancelled: 5 };
```

### Group definitions
```javascript
const groupDefs = [
    { key: 'pending', label: 'Pendientes', filter: o => o.status === 'pending' },
    { key: 'preparing', label: 'En Preparacion', filter: o => o.status === 'preparing' || o.status === 'confirmed' },
    { key: 'delivering', label: 'En Camino', filter: o => o.status === 'delivering' },
    { key: 'delivered', label: 'Entregados', filter: o => o.status === 'delivered' || o.status === 'ready' },
    { key: 'cancelled', label: 'Cancelados', filter: o => o.status === 'cancelled' }
];
```

### Flujo WhatsApp (negocio→cliente)
- `notifyCustomerWhatsApp(orderId, event, estimatedMinutes, cadeteName)` — 4 parámetros
- **confirmed:** "Tu pedido #X fue *confirmado*. Tiempo estimado: *Y minutos*."
- **delivering:** "Tu pedido #X ya *salio en camino*! Lo lleva *CadeteName*."
- **delivered:** "Tu pedido #X fue *entregado*."

### QZ Tray: ELIMINADO (25 Feb 2026)
- Impresión 100% via Supabase trigger + Electron app.
- `reprintOrder()` fuerza re-ejecución del trigger.

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
- ✅ Código Lucy aislado en 6to-sentido: `src/lib/7tres7/` (lucy-handler, lucy-commands, menu, client, lucy-prompt)
- ✅ Tabla `discounts` en esta DB: Lucy genera códigos `LUCY15-XXXX` cuando el negocio está cerrado
- ✅ Columnas recovery en `customers`: `last_recovery_attempt`, `recovery_attempts_count`, `recovery_exhausted`
- ✅ `business_config.business_hours`: Lun/Mar cerrados, Mié-Dom dual time slots (12-15 + 19-00/01)
- ✅ n8n workflows: "Reactivación At Risk" (`PpwgLv7qMCQyX0XF`) y "Recuperación Churned" (`93kHf0hkflows8tx`) — inactivos
- ✅ Build de 6to-sentido passing con la integración

**Qué falta para activar:**
1. Teléfono físico del negocio para verificar en Meta Cloud API (WhatsApp Business)
2. Configurar `WHATSAPP_PHONE_NUMBER_ID` + `WHATSAPP_ACCESS_TOKEN` en n8n
3. Agregar `SUPABASE_7TRES7_SERVICE_KEY` a Vercel env vars de 6to-sentido (solo está en .env.local)
4. `secretary_config.lucy_enabled` ya es `true` (migración 26 Feb 2026). Setear `lucy_webhook_url` en `business_config` cuando esté listo

### Datos de integración
- **business_id en 6to-sentido**: `d0825b81-f96b-4e9a-9806-b6ecf10d9806`
- **whatsapp_accounts**: registrado como `local`, phone `+5492302515656`, sin verificar
- **secretary_config**: mode=`active`, tone=`casual`, escalation a Nico
- **Clientes**: 2025 (1584 churned, 247 new, 194 at_risk)

### Flujo Lucy (cuando esté activo)
1. Cliente envía WhatsApp al número del negocio
2. Twilio webhook → 6to-sentido `/api/whatsapp/webhook`
3. Webhook detecta cuenta `local` → Secretary flow
4. Secretary lee `secretary_config.lucy_enabled=true` → Lucy handler (`src/lib/7tres7/lucy-handler.ts`)
5. Si negocio cerrado → genera descuento LUCY15-XXXX en tabla `discounts` + mensaje fuera de horario
6. Si negocio abierto → consulta menú en vivo + responde con precios actualizados
7. Admin Brain commands (pausar lucy, estado lucy, etc.) → `src/lib/7tres7/lucy-commands.ts` via command registry
8. n8n cron workflows envían descuentos a clientes at_risk/churned (insertan directo via Supabase REST, no via API)

---

## Detalle Técnico: App Impresión Electron (25 Feb 2026)

### Arquitectura
- **Comunicación**: Supabase Realtime (NO WebSocket a Vercel — Vercel no soporta WS persistente)
- **Flujo**: Caja confirma pedido → trigger SQL crea `print_jobs` row → Supabase Realtime notifica → Electron recibe → filtra items por categoría → imprime ESC/POS
- **Impresión**: Raw print via WinAPI (`winspool.drv WritePrinter`) usando PowerShell inline `-EncodedCommand` (NO archivos .ps1 externos). Fallback 1: `copy /b`. Fallback 2: `print /d:`.
- **Codificación**: CP858 para caracteres españoles (ñ, á, é, etc.) via `iconv-lite`

### PCs y Impresoras
| PC | IP | Nombre Windows | Modelo | Categorías |
|----|----|-----------|---------|----|
| BARRA | 192.168.1.6 | Barra | ITPOS 80EU | bebidas, gaseosas, cervezas, vinos + ticket completo |
| COCINA | 192.168.1.9 | minuta | 3nStar RPT008 | empanadas, pizzas, minutas, postres |
| COCINA | 192.168.1.9 | parrilla delivery | Hasar MIS1785 | restaurant, carnes, pastas, parrilla |

### Configuración por PC
- Archivo `pc-config.json` junto al .exe: `{"pc": "BARRA", "printers": ["Barra"]}` o `{"pc": "COCINA", "printers": ["minuta", "parrilla delivery"]}`
- Detección en 5 ubicaciones: PORTABLE_EXECUTABLE_DIR, junto al .exe, resources, relativo a src, CWD
- Fallback: detecta por hostname de Windows
- Default: BARRA
- **Nombres CASE-SENSITIVE**: `Barra` (mayúscula), `minuta` y `parrilla delivery` (minúscula)

### Formato `order_data` en `print_jobs`
```json
{
  "orderNumber": 123,
  "tableOrDelivery": "Delivery - Calle 18 N 737",
  "items": [{"name": "Emp. Carne", "category": "empanadas", "quantity": 6, "price": 1700, "subtotal": 10200, "notes": "Sin picante", "cooking": "horno"}],
  "subtotal": 25000, "discount": 0, "deliveryFee": 1500, "total": 26500,
  "paymentMethod": "cash", "customerNotes": "Tocar timbre"
}
```

### SQL ejecutado (25 Feb)
- Categorías asignadas a impresoras: Empanadas/Pizzas/Minutas/Postres → Minuta, Restaurant → Parrilla Delivery, Bebidas → Barra
- Barra como `printer_secondary_id` en todas las categorías (ticket completo)
- RLS: anon SELECT + UPDATE en `print_jobs`, anon SELECT en `printers`
- Realtime habilitado en `print_jobs`
- Trigger `create_print_jobs_for_order()` reescrito: filtra items por category, 1 job/impresora + 1 full_ticket para Barra

### Pasos para instalar en las PCs del local
1. Ejecutar `14_PRINT_SYSTEM.sql` en Supabase
2. En Supabase Dashboard: Database → Replication → verificar que `print_jobs` está en `supabase_realtime`
3. Compartir impresoras en Windows (nombres EXACTOS case-sensitive: "Barra", "minuta", "parrilla delivery")
4. En PC Barra: copiar .exe + `pc-config.json` de `PC BARRA/` a una carpeta (ej: `C:\7Tres7\`), ejecutar
5. En PC Cocina: copiar .exe + `pc-config.json` de `PC COCINA/` a una carpeta, ejecutar
6. Probar con botón "Imprimir Prueba" en la UI

### Build del .exe portable
```bash
cd 7tres7-print-app
npm run build:win
# Genera dist/7Tres7 Print X.X.X.exe (portable, ~67MB)
```

### Estructura pendrive (D:\737 app\)
```
737 app/
├── 7Tres7 Print 1.0.1.exe      (v1.0.1, PowerShell inline, sin .ps1)
├── INSTRUCCIONES.txt
├── PC BARRA/
│   └── pc-config.json          {"pc":"BARRA","printers":["Barra"]}
└── PC COCINA/
    └── pc-config.json          {"pc":"COCINA","printers":["minuta","parrilla delivery"]}
```

---

## Notas Técnicas

- **Botones empanadas + MCP**: Los clicks del MCP no disparan onclick en HTML dinámico. Llamar `addToCart()` directo.
- **Auth admin**: `onAuthStateChange` como único handler para evitar race conditions.
- **RLS app usuario**: Políticas `FOR SELECT USING (true)` en products, categories, business_config, subcategories. INSERT anónimo en orders. La tabla `customers` tiene policies anón SELECT+INSERT+UPDATE (corregido 25 Feb).
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
