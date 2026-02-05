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

---

## Lo que falta hacer

### Alta Prioridad

1. **Guardar pedidos en Supabase**
   - La app usuario confirma pedidos pero NO los guarda en la base de datos
   - Necesita: INSERT en tabla `orders` y `customers`
   - El RLS actual bloquea inserts anonimos - evaluar si usar Edge Function o permitir insert anonimo

2. **Notificaciones de pedidos**
   - Enviar notificacion al admin cuando llega un pedido nuevo
   - Opciones: Realtime de Supabase, webhook, push notifications

3. **Integracion MercadoPago**
   - Boton de MercadoPago en app usuario esta visual pero no funcional
   - Necesita: crear preferencia de pago, redirect a MP, webhook de confirmacion

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
│   └── 06_AUTH_RLS_UPDATE.sql  # Politicas RLS (YA EJECUTADO)
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

---

## Notas Tecnicas

### Por que los botones de empanadas no funcionaban con MCP
Los clicks del MCP sobre los botones "Fritas" / "Al Horno" no disparaban el evento onclick porque el HTML generado dinamicamente usaba IDs de productos de Supabase que no coincidian exactamente. Se probo llamando `addToCart()` directamente via JavaScript y funciono.

### Auth flow del admin
Se uso `onAuthStateChange` como unico handler de auth en lugar de combinarlo con `getSession()` para evitar race conditions donde la app se inicializaba dos veces.

### RLS y app usuario
La app usuario necesita leer productos sin autenticacion. Se agregaron politicas `FOR SELECT USING (true)` en products, categories y business_config. Para guardar pedidos hay que evaluar si usar Edge Functions o permitir INSERT anonimo con validaciones.
