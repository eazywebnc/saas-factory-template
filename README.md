# SaaS Factory Template

Template de scaffolding automatique pour creer un nouveau SaaS en moins de 5 minutes.

**Stack:** Next.js 16 + TypeScript + Tailwind CSS 4 + Supabase + Stripe + Cloudflare Pages

## Quick Start — 1 commande

```bash
./scripts/create-saas.sh trackncolis \
  --name "TrackNColis" \
  --desc "Suivi de colis en Nouvelle-Caledonie" \
  --color "#10b981" \
  --price-pro 2900 \
  --price-enterprise 9900
```

Ce script fait tout automatiquement:
1. Copie le template dans un nouveau dossier
2. Configure `saas.config.ts` avec les valeurs fournies
3. Cree les produits/prix Stripe
4. Installe les dependances
5. Init git + cree le repo GitHub
6. Cree les tables Supabase avec RLS
7. Cree le projet Cloudflare Pages
8. Configure le CNAME `saas-id.eazyweb.nc`
9. Build et deploie

## Ce qui est inclus

| Feature | Details |
|---------|---------|
| Auth | Login, signup, forgot password, OAuth callback |
| Dashboard | Layout responsive, stats, sidebar navigation |
| Billing | Plans Stripe, checkout, gestion abonnement |
| Settings | Profil utilisateur, theme clair/sombre |
| Landing | Hero anime, features, pricing, navbar, footer |
| Stripe | Checkout, webhooks, subscription lifecycle |
| Supabase | Auth, profiles, subscriptions, RLS policies |
| Deploy | 1-click Cloudflare Pages + DNS |

## Configuration

Tout se configure dans `saas.config.ts`:

```typescript
export const saasConfig = {
  saasId: "monsaas",        // Prefixe DB, sous-domaine, nom CF Pages
  name: "Mon SaaS",         // Nom affiche
  description: "...",
  domain: "monsaas.eazyweb.nc",
  branding: { primaryColor: "#6366f1", logo: "/logo.svg" },
  landing: { headline, subheadline, features },
  pricing: { plans: [free, pro, enterprise] },
};
```

## Variables d'environnement

Copier `.env.example` vers `.env.local`:

```bash
cp .env.example .env.local
```

| Variable | Usage |
|----------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role (server-side) |
| `STRIPE_SECRET_KEY` | Stripe server key |
| `STRIPE_PUBLISHABLE_KEY` | Stripe client key |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook verification |
| `CLOUDFLARE_PAGES_TOKEN` | CF Pages API token |
| `CLOUDFLARE_DNS_TOKEN` | CF DNS token |
| `SUPABASE_ACCESS_TOKEN` | Supabase Management API |
| `SUPABASE_PROJECT_REF` | Supabase project ref |
| `GITHUB_TOKEN` | GitHub PAT |

## Developpement local

```bash
npm install
npm run dev
```

## Deploiement manuel

```bash
bash scripts/deploy.sh
```

## Architecture

```
src/
  app/
    api/
      stripe/checkout/    # Stripe checkout session
      webhooks/stripe/    # Stripe webhook handler
    auth/
      login/              # Email/password login
      signup/             # Registration + email verification
      forgot-password/    # Password reset
      callback/           # OAuth/magic link callback
    dashboard/
      billing/            # Subscription management
      settings/           # User profile + theme
      layout.tsx          # Dashboard shell + sidebar
      page.tsx            # Dashboard home
    layout.tsx            # Root layout
    page.tsx              # Landing page
  components/
    dashboard/sidebar.tsx # Nav sidebar
    landing/              # Hero, features, pricing, navbar, footer
    ui/                   # shadcn/ui components
  lib/
    stripe.ts             # Stripe client init
    supabase/             # Client, server, middleware helpers
    utils.ts              # cn() utility
  middleware.ts           # Auth route protection
saas.config.ts            # Central SaaS configuration
scripts/
  create-saas.sh          # 1-command SaaS creation
  deploy.sh               # Supabase + CF Pages + DNS deploy
```

## SaaS Factory — Architecture

Tous les SaaS partagent le **meme projet Supabase**. La separation se fait par prefixe de table (`saas_id_`).

Chaque SaaS = 1 repo GitHub + 1 projet Cloudflare Pages + 1 sous-domaine `saas-id.eazyweb.nc`.

---

Built by [EazyWebNC](https://eazyweb.nc) — Agence web Noumea, Nouvelle-Caledonie
