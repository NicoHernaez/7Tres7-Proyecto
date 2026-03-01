// Edge Function: mp-webhook
// Recibe notificaciones de MercadoPago cuando un pago se procesa
//
// Deploy: supabase functions deploy mp-webhook
// Set secret: supabase secrets set MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxx

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const MERCADOPAGO_ACCESS_TOKEN = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!MERCADOPAGO_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error('Variables de entorno no configuradas')
    }

    // Crear cliente Supabase con service role (bypass RLS)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Obtener datos de la notificacion - soportar AMBOS formatos:
    // 1. IPN (query params): ?topic=payment&id=12345
    // 2. Webhooks v2 (POST body): {"type":"payment","data":{"id":"12345"}}
    const url = new URL(req.url)
    let topic = url.searchParams.get('topic') || url.searchParams.get('type')
    let id = url.searchParams.get('id')

    // Si no hay datos en query params, intentar leer del body (formato Webhooks v2)
    if (!topic || !id) {
      try {
        const body = await req.json()
        if (body.type) topic = body.type
        if (body.data?.id) id = body.data.id.toString()
        // Algunos webhooks envían action como "payment.created", "payment.updated"
        if (!topic && body.action?.startsWith('payment')) topic = 'payment'
      } catch (_e) {
        // Body vacío o no es JSON — continuar con query params
      }
    }

    console.log('Webhook recibido:', { topic, id, method: req.method })

    // MercadoPago envia notificaciones de diferentes tipos
    // Solo nos interesan las de payment
    if (topic !== 'payment' && topic !== 'merchant_order') {
      console.log('Notificacion ignorada:', topic)
      return new Response('OK', { status: 200 })
    }

    // Si es un payment, obtener detalles del pago
    if (topic === 'payment' && id) {
      const paymentResponse = await fetch(`https://api.mercadopago.com/v1/payments/${id}`, {
        headers: {
          'Authorization': `Bearer ${MERCADOPAGO_ACCESS_TOKEN}`
        }
      })

      if (!paymentResponse.ok) {
        throw new Error(`Error obteniendo pago: ${paymentResponse.status}`)
      }

      const paymentData = await paymentResponse.json()

      console.log('Pago recibido:', {
        id: paymentData.id,
        status: paymentData.status,
        external_reference: paymentData.external_reference,
        amount: paymentData.transaction_amount
      })

      // Buscar el pedido por external_reference
      const orderRef = paymentData.external_reference

      if (orderRef) {
        // Si el external_reference es un UUID de order
        const { data: order, error: orderError } = await supabase
          .from('orders')
          .select('id')
          .eq('id', orderRef)
          .single()

        if (order) {
          // Actualizar estado del pedido segun el pago
          const paymentStatus = paymentData.status === 'approved' ? 'approved'
            : paymentData.status === 'pending' ? 'pending'
            : paymentData.status === 'rejected' ? 'rejected'
            : 'pending'

          // Actualizar order
          await supabase
            .from('orders')
            .update({
              payment_status: paymentStatus,
              payment_id: paymentData.id.toString(),
              payment_details: paymentData
            })
            .eq('id', order.id)

          // Insertar en payments
          await supabase
            .from('payments')
            .insert({
              order_id: order.id,
              mp_payment_id: paymentData.id.toString(),
              mp_preference_id: paymentData.preference_id,
              amount: paymentData.transaction_amount,
              method: 'mercadopago',
              status: paymentStatus,
              mp_response: paymentData
            })

          console.log('Pedido actualizado:', order.id, paymentStatus)
        }
      }
    }

    return new Response('OK', {
      headers: corsHeaders,
      status: 200
    })

  } catch (error) {
    console.error('Webhook error:', error)
    // MercadoPago reintenta si devolvemos error, asi que devolvemos 200
    return new Response('OK', { status: 200 })
  }
})
