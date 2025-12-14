import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Parse request body
    const { donationId, amount, userDetails, communityName } =
      await req.json();

    if (!donationId || !amount) {
      throw new Error("Missing required fields: donationId or amount");
    }

    // 2. Midtrans config (SINGLE SOURCE OF TRUTH)
    const isProduction =
      Deno.env.get("MIDTRANS_IS_PRODUCTION") === "true";

    const serverKey = Deno.env
      .get("MIDTRANS_SERVER_KEY")
      ?.trim();

    if (!serverKey) {
      throw new Error("MIDTRANS_SERVER_KEY missing");
    }

    const baseUrl = isProduction
      ? "https://app.midtrans.com/snap/v1/transactions"
      : "https://app.sandbox.midtrans.com/snap/v1/transactions";

    console.log(
      `Midtrans ENV: ${isProduction ? "PRODUCTION" : "SANDBOX"}`
    );

    // 3. Payload
    const payload = {
      transaction_details: {
        order_id: donationId,
        gross_amount: Math.round(amount),
      },
      credit_card: {
        secure: true,
      },
      item_details: [
        {
          id: "DONATION",
          price: Math.round(amount),
          quantity: 1,
          name: `Donasi - ${communityName || "EcoTrack"}`,
        },
      ],
      customer_details: {
        first_name: userDetails?.fullName || "Donor",
        email: userDetails?.email || "",
        phone: userDetails?.phone || "",
      },
    };

    // 4. Call Midtrans
    const auth = btoa(`${serverKey}:`);

    const response = await fetch(baseUrl, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Midtrans Error:", data);

      let errorMessage = data?.error_messages?.join(", ") || "Midtrans payment creation failed";

      if (response.status === 401) {
        const keyPrefix = serverKey.substring(0, 5);
        const envName = isProduction ? 'PRODUCTION' : 'SANDBOX';

        errorMessage = `Unauthorized (401). 
        Debug Info:
        - Env: ${envName}
        - KeyPrefix: '${keyPrefix}...'
        
        Midtrans rejected this key for the Sandbox environment.`;
      }

      throw new Error(errorMessage);
    }

    // 5. Success response
    return new Response(
      JSON.stringify({
        token: data.token,
        redirect_url: data.redirect_url,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (err: any) {
    console.error("Edge Function Error:", err.message);

    return new Response(
      JSON.stringify({ error: err.message }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
