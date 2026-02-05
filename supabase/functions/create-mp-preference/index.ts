// Edge Function: create-mp-preference
// Crea una preferencia de pago en MercadoPago
//
// Deploy: supabase functions deploy create-mp-preference
// Set secret: supabase secrets set MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxx

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
  cookingMethod?: string
}

interface OrderData {
  items: CartItem[]
  customer: {
    name: string
    phone: string
    email?: string
  }
  delivery: {
    type: 'delivery' | 'pickup'
    address?: string
  }
  total: number
  orderId?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const MERCADOPAGO_ACCESS_TOKEN = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')

    if (!MERCADOPAGO_ACCESS_TOKEN) {
      throw new Error('MERCADOPAGO_ACCESS_TOKEN no configurado')
    }

    const orderData: OrderData = await req.json()

    // Construir items para MercadoPago
    const mpItems = orderData.items.map(item => ({
      id: item.id,
      title: item.cookingMethod
        ? `${item.name} (${item.cookingMethod === 'frito' ? 'Frita' : 'Al Horno'})`
        : item.name,
      quantity: item.quantity,
      unit_price: item.price,
      currency_id: 'ARS'
    }))

    // Crear preferencia en MercadoPago
    const preference = {
      items: mpItems,
      payer: {
        name: orderData.customer.name,
        phone: {
          number: orderData.customer.phone
        },
        email: orderData.customer.email || undefined
      },
      back_urls: {
        success: 'https://7tres7-online.vercel.app?status=success',
        failure: 'https://7tres7-online.vercel.app?status=failure',
        pending: 'https://7tres7-online.vercel.app?status=pending'
      },
      auto_return: 'approved',
      external_reference: orderData.orderId || `order_${Date.now()}`,
      notification_url: 'https://yfdustfjfmifvgybwinr.supabase.co/functions/v1/mp-webhook',
      statement_descriptor: '7TRES7',
      expires: true,
      expiration_date_from: new Date().toISOString(),
      expiration_date_to: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24 horas
    }

    const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${MERCADOPAGO_ACCESS_TOKEN}`
      },
      body: JSON.stringify(preference)
    })

    if (!mpResponse.ok) {
      const errorData = await mpResponse.text()
      console.error('MercadoPago error:', errorData)
      throw new Error(`MercadoPago API error: ${mpResponse.status}`)
    }

    const mpData = await mpResponse.json()

    return new Response(
      JSON.stringify({
        success: true,
        preferenceId: mpData.id,
        initPoint: mpData.init_point, // URL para redireccionar al usuario
        sandboxInitPoint: mpData.sandbox_init_point // URL para testing
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
