# 7Tres7 - Sistema de Pedidos Online

Sistema completo para restaurante con app de usuario y panel de administracion.

## URLs de Produccion

- **App Usuario:** https://7tres7-online.vercel.app
- **Admin Panel:** https://7-tres7-admin.vercel.app

## Estructura del Proyecto

```
7Tres7-Proyecto/
├── app-usuario/          # App para clientes (menu y pedidos)
│   └── index.html
├── admin-panel/          # Panel de administracion
│   └── index.html
├── database/             # Scripts SQL para Supabase
│   ├── 01_DATABASE_SCHEMA.sql        # Schema completo
│   ├── 04_PRODUCTOS_REALES_7TRES7.sql # Productos empanadas
│   ├── 05_PRODUCTOS_COMPLETOS_7TRES7.sql # Menu completo
│   └── 06_AUTH_RLS_UPDATE.sql        # Politicas de seguridad
└── README.md
```

## Repositorios GitHub

- **App Usuario:** https://github.com/NicoHernaez/7Tres7-Online
- **Admin Panel:** https://github.com/NicoHernaez/7Tres7-Admin

## Tecnologias

- **Frontend:** HTML, Tailwind CSS, JavaScript
- **Backend:** Supabase (PostgreSQL)
- **Auth:** Google OAuth + Magic Link via Supabase Auth
- **Hosting:** Vercel

## Configuracion Supabase

- **URL:** https://yfdustfjfmifvgybwinr.supabase.co
- **Anon Key:** Hardcodeada en los HTML

## Seguridad (RLS)

- Productos, categorias y config del negocio: Lectura publica
- Clientes, pedidos, pagos: Solo usuarios autenticados
- Admin autorizado: nicohernaez22@gmail.com

## Funcionalidades

### App Usuario
- Registro con telefono, nombre y direccion
- Menu con categorias (Empanadas, Pizzas, Minutas, Restaurant)
- Seleccion de coccion (Fritas/Al Horno) para empanadas
- Carrito con cantidades editables
- Upsell de bebidas y postres
- Pago con Mercado Pago o efectivo
- Confirmacion de pedido

### Admin Panel
- Login con Google o Magic Link
- Dashboard con estadisticas del dia
- Gestion de productos (CRUD, activar/desactivar)
- Gestion de categorias con impresoras asignadas
- Pedidos con filtros y cambio de estado
- Clientes con paginacion (20 por pagina) y busqueda
- Configuracion de impresoras
- Integraciones (MercadoPago, Lucy, 6to Sentido)
