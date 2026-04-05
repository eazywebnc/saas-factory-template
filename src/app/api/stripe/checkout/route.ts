import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createCheckoutSession } from "@/lib/stripe";

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { priceId } = await request.json();
  if (!priceId) {
    return NextResponse.json({ error: "Missing priceId" }, { status: 400 });
  }

  const origin = request.headers.get("origin") || "http://localhost:3000";

  const session = await createCheckoutSession({
    priceId,
    successUrl: `${origin}/dashboard/billing?success=true`,
    cancelUrl: `${origin}/dashboard/billing?canceled=true`,
  });

  return NextResponse.json({ url: session.url });
}
