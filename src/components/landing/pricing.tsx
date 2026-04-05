"use client";

import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Check } from "lucide-react";
import Link from "next/link";
import { saasConfig } from "../../../saas.config";

export function Pricing() {
  return (
    <section id="pricing" className="py-24 bg-muted/30">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="mb-16 text-center">
          <h2 className="mb-4 text-3xl font-bold tracking-tight sm:text-4xl">
            Tarifs simples et transparents
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            Choisissez le plan qui correspond a vos besoins. Changez a tout moment.
          </p>
        </div>

        <div className="grid gap-8 md:grid-cols-3">
          {saasConfig.pricing.plans.map((plan, i) => (
            <motion.div
              key={plan.id}
              className={`relative rounded-2xl border bg-card p-8 ${
                "popular" in plan && plan.popular
                  ? "border-primary shadow-lg ring-1 ring-primary"
                  : ""
              }`}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: i * 0.1 }}
              viewport={{ once: true }}
            >
              {"popular" in plan && plan.popular && (
                <Badge className="absolute -top-3 left-1/2 -translate-x-1/2">
                  Populaire
                </Badge>
              )}
              <div className="mb-6">
                <h3 className="text-xl font-semibold">{plan.name}</h3>
                <p className="mt-1 text-sm text-muted-foreground">{plan.description}</p>
              </div>
              <div className="mb-6">
                <span className="text-4xl font-bold">
                  {plan.price === 0 ? "Gratuit" : `${plan.price}€`}
                </span>
                {plan.price > 0 && (
                  <span className="text-muted-foreground">/{plan.interval === "month" ? "mois" : "an"}</span>
                )}
              </div>
              <ul className="mb-8 space-y-3">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-center gap-3 text-sm">
                    <Check className="h-4 w-4 text-primary shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>
              <Link href="/auth/signup">
                <Button
                  className="w-full"
                  variant={"popular" in plan && plan.popular ? "default" : "outline"}
                >
                  {plan.price === 0 ? "Commencer" : "Essayer gratuitement"}
                </Button>
              </Link>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
