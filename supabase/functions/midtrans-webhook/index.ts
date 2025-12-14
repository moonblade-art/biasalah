// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment

import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req: Request) => {
  try {
    // 1. Validate Method
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // 2. Parse Midtrans Notification
    const notification = await req.json()
    console.log('Midtrans Webhook:', JSON.stringify(notification))

    const orderId = notification.order_id
    const transactionStatus = notification.transaction_status
    const fraudStatus = notification.fraud_status
    const transactionId = notification.transaction_id

    // 3. Determine Success
    let isSuccess = false
    if (transactionStatus === 'capture') {
      if (fraudStatus === 'challenge') {
        // TODO: Handle challenge?
      } else if (fraudStatus === 'accept') {
        isSuccess = true
      }
    } else if (transactionStatus === 'settlement') {
      isSuccess = true
    } else if (
      transactionStatus === 'cancel' ||
      transactionStatus === 'deny' ||
      transactionStatus === 'expire'
    ) {
      // TODO: Handle failure (optional, maybe reset donation status)
    }

    if (isSuccess) {
      // 4. Initialize Supabase Admin Client (Bypass RLS)
      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

      const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

      // 5. Call RPC to update Database safely
      // Extract numeric ID if we used a prefix like 'DONATION-'
      // Based on our create-midtrans-token, we passed donationId directly as orderId.
      // But wait... donationId in create-midtrans-token was `donation.midtransOrderId` which is `DONATION-<timestamp>`.
      // We need the original UUID of the donation row to update it efficiently?
      // Actually, standard practice is to store `midtrans_order_id` in the `donations` table.
      // Let's assume we can query by `midtrans_order_id` in the RPC if needed, OR 
      // Re-reading donation_service.dart: 
      // 'midtrans_order_id': orderId  (which is DONATION-timestamp)
      // It updates by: .eq('id', donation.id)
      //
      // Issue: Midtrans sends back `order_id` ('DONATION-timestamp'). We need to find the UUID.

      // Let's first search for the UUID using the midtrans_order_id
      const { data: donationRouter, error: findError } = await supabase
        .from('donations')
        .select('id')
        .eq('midtrans_order_id', orderId)
        .single();

      if (findError || !donationRouter) {
        console.error('Donation not found for order_id:', orderId);
        return new Response('Donation not found', { status: 404 });
      }

      const donationUUID = donationRouter.id;

      // Now call RPC with the UUID
      const { error: rpcError } = await supabase.rpc('process_successful_donation', {
        p_donation_id: donationUUID,
        p_transaction_id: transactionId,
      })

      if (rpcError) {
        console.error('RPC Error:', rpcError)
        return new Response('Internal Server Error', { status: 500 })
      }

      console.log(`Success: Processed donation ${donationUUID}`)
    }

    return new Response(JSON.stringify({ status: 'OK' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (err: any) {
    console.error('Webhook Error:', err.message)
    return new Response(err.message, { status: 400 })
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/midtrans-webhook' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
