"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { motion } from "framer-motion";
import { ArrowRight } from "lucide-react";
import { saasConfig } from "../../../saas.config";

export function Hero() {
  return (
    <section className="relative flex min-h-[90vh] items-center justify-center overflow-hidden pt-16">
      {/* Background gradient */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute left-1/2 top-0 h-[600px] w-[600px] -translate-x-1/2 rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute bottom-0 right-0 h-[400px] w-[400px] rounded-full bg-primary/10 blur-3xl" />
      </div>

      <div className="mx-auto max-w-4xl px-4 text-center sm:px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <div className="mb-6 inline-flex items-center rounded-full border bg-background px-4 py-1.5 text-sm font-medium text-muted-foreground">
            Nouveau — Decouvrez nos fonctionnalites
            <ArrowRight className="ml-2 h-3.5 w-3.5" />
          </div>
        </motion.div>

        <motion.h1
          className="mb-6 text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl lg:text-7xl"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
        >
          {saasConfig.landing.headline}
        </motion.h1>

        <motion.p
          className="mx-auto mb-10 max-w-2xl text-lg text-muted-foreground sm:text-xl"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          {saasConfig.landing.subheadline}
        </motion.p>

        <motion.div
          className="flex flex-col items-center gap-4 sm:flex-row sm:justify-center"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
        >
          <Link href="/auth/signup">
            <Button size="lg" className="h-12 px-8 text-base">
              Commencer gratuitement
              <ArrowRight className="ml-2 h-4 w-4" />
            </Button>
          </Link>
          <a href="#features">
            <Button variant="outline" size="lg" className="h-12 px-8 text-base">
              En savoir plus
            </Button>
          </a>
        </motion.div>
      </div>
    </section>
  );
}
