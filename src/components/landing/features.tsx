"use client";

import { motion } from "framer-motion";
import { Zap, Shield, Users, BarChart3, type LucideIcon } from "lucide-react";
import { saasConfig } from "../../../saas.config";

const iconMap: Record<string, LucideIcon> = {
  Zap,
  Shield,
  Users,
  BarChart3,
};

export function Features() {
  return (
    <section id="features" className="py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="mb-16 text-center">
          <h2 className="mb-4 text-3xl font-bold tracking-tight sm:text-4xl">
            Tout ce dont vous avez besoin
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            Des outils puissants pour vous aider a atteindre vos objectifs plus rapidement.
          </p>
        </div>

        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {saasConfig.landing.features.map((feature, i) => {
            const Icon = iconMap[feature.icon] || Zap;
            return (
              <motion.div
                key={feature.title}
                className="group rounded-xl border bg-card p-6 transition-shadow hover:shadow-lg"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: i * 0.1 }}
                viewport={{ once: true }}
              >
                <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10">
                  <Icon className="h-6 w-6 text-primary" />
                </div>
                <h3 className="mb-2 text-lg font-semibold">{feature.title}</h3>
                <p className="text-sm text-muted-foreground">{feature.description}</p>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
