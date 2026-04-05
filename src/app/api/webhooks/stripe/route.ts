import { NextResponse } from "next/server";
import { getStripe } from "@/lib/stripe";
import { createClient } from "@supabase/supabase-js";
import { saasConfig } from "../../../../../saas.config";
import Stripe from "stripe";

function getSupabaseAdmin() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
}

const relevantEvents = new Set([
  "checkout.session.completed",
  "customer.subscription.updated",
  "customer.subscription.deleted",
]);

export async function POST(request: Request) {
  const body = await request.text();
  const sig = request.headers.get("stripe-signature")!;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

  let event: Stripe.Event;
  try {
    event = getStripe().webhooks.constructEvent(body, sig, webhookSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  if (!relevantEvents.has(event.type)) {
    return NextResponse.json({ received: true });
  }

  const table = `${saasConfig.tablePrefix}subscriptions`;

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      if (session.mode === "subscription" && session.subscription) {
        const subscription = await getStripe().subscriptions.retrieve(
          session.subscription as string
        );
        const item = subscription.items.data[0];
        await getSupabaseAdmin().from(table).upsert({
          user_id: session.metadata?.user_id ?? session.client_reference_id,
          stripe_customer_id: session.customer as string,
          stripe_subscription_id: subscription.id,
          stripe_price_id: item.price.id,
          status: subscription.status,
          current_period_end: new Date(
            item.current_period_end * 1000
          ).toISOString(),
        });
      }
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      const item = subscription.items.data[0];
      await getSupabaseAdmin()
        .from(table)
        .update({
          status: subscription.status,
          stripe_price_id: item.price.id,
          current_period_end: new Date(
            item.current_period_end * 1000
          ).toISOString(),
        })
        .eq("stripe_subscription_id", subscription.id);
      break;
    }
  }

  return NextResponse.json({ received: true });
}
