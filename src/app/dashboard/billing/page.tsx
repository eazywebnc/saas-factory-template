"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Check } from "lucide-react";
import { saasConfig } from "../../../../saas.config";

export default function BillingPage() {
  const handleCheckout = async (priceId: string) => {
    const res = await fetch("/api/stripe/checkout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ priceId }),
    });
    const { url } = await res.json();
    if (url) window.location.href = url;
  };

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">Facturation</h1>
        <p className="text-muted-foreground">Gerez votre abonnement et vos paiements.</p>
      </div>

      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Plan actuel</CardTitle>
          <CardDescription>Vous etes actuellement sur le plan Gratuit.</CardDescription>
        </CardHeader>
        <CardContent>
          <Badge variant="secondary">Gratuit</Badge>
        </CardContent>
      </Card>

      <h2 className="mb-4 text-xl font-semibold">Changer de plan</h2>
      <div className="grid gap-6 md:grid-cols-3">
        {saasConfig.pricing.plans.map((plan) => (
          <Card
            key={plan.id}
            className={"popular" in plan && plan.popular ? "border-primary" : ""}
          >
            <CardHeader>
              <CardTitle>{plan.name}</CardTitle>
              <CardDescription>{plan.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="mb-4">
                <span className="text-3xl font-bold">
                  {plan.price === 0 ? "Gratuit" : `${plan.price}€`}
                </span>
                {plan.price > 0 && <span className="text-muted-foreground">/mois</span>}
              </div>
              <ul className="mb-6 space-y-2">
                {plan.features.map((f) => (
                  <li key={f} className="flex items-center gap-2 text-sm">
                    <Check className="h-4 w-4 text-primary" />
                    {f}
                  </li>
                ))}
              </ul>
              {plan.stripePriceId ? (
                <Button
                  className="w-full"
                  onClick={() => handleCheckout(plan.stripePriceId!)}
                >
                  Passer au plan {plan.name}
                </Button>
              ) : plan.price === 0 ? (
                <Button className="w-full" variant="outline" disabled>
                  Plan actuel
                </Button>
              ) : (
                <Button className="w-full" variant="outline" disabled>
                  Bientot disponible
                </Button>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
