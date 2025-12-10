// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
//
// This function creates a Midtrans Snap Token and Redirect URL.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts"

// Cors headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Get request body
    const { donationId, amount, userDetails, communityName } = await req.json()

    // 2. Validate input
    if (!donationId || !amount) {
      throw new Error('Missing required fields: donationId or amount')
    }

    // 3. Midtrans Configuration
    // Get Server Key from Supabase Secrets
    const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY')
    const isProduction = Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true'

    if (!serverKey) {
      throw new Error('MIDTRANS_SERVER_KEY is not set in Supabase Secrets')
    }

    const baseUrl = isProduction
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions'

    // 4. Create Payload
    const payload = {
      transaction_details: {
        order_id: donationId, // Use donation ID as order ID (or a unique variant)
        gross_amount: Math.round(amount), // Amount must be integer
      },
      credit_card: {
        secure: true,
      },
      item_details: [
        {
          id: 'DONATION',
          price: Math.round(amount),
          quantity: 1,
          name: `Donasi - ${communityName || 'EcoTrack'}`,
        }
      ],
      customer_details: {
        first_name: userDetails?.fullName || 'Donor',
        email: userDetails?.email || '',
        phone: userDetails?.phone || '',
      },
      // Callbacks (optional, can be handled by frontend redirect)
      // callbacks: {
      //   finish: 'ecotrack://payment/finish',
      // }
    }

    // 5. Call Midtrans API
    const authString = btoa(serverKey + ':')

    const response = await fetch(baseUrl, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': `Basic ${authString}`,
      },
      body: JSON.stringify(payload),
    })

    const data = await response.json()

    if (!response.ok) {
      throw new Error(`Midtrans API Error: ${JSON.stringify(data)}`)
    }

    // 6. Return Result
    return new Response(
      JSON.stringify({
        token: data.token,
        redirect_url: data.redirect_url,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
