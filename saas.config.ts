/**
 * SaaS Factory Configuration
 * Edit this file to customize your SaaS project.
 */
export const saasConfig = {
  // Unique identifier for this SaaS (used for DB table prefixes, subdomain, etc.)
  saasId: "mysaas",

  // Display name
  name: "My SaaS",
  description: "A powerful SaaS built with EazyWebNC SaaS Factory",

  // Domain configuration
  domain: "mysaas.eazyweb.nc",

  // Branding
  branding: {
    primaryColor: "#6366f1", // indigo-500
    logo: "/logo.svg",
  },

  // Landing page content
  landing: {
    headline: "Simplifiez votre quotidien",
    subheadline: "Un outil puissant et intuitif pour booster votre productivite.",
    features: [
      {
        title: "Rapide",
        description: "Performances optimisees pour une experience fluide.",
        icon: "Zap",
      },
      {
        title: "Securise",
        description: "Vos donnees sont protegees avec un chiffrement de pointe.",
        icon: "Shield",
      },
      {
        title: "Collaboratif",
        description: "Travaillez en equipe en temps reel, sans friction.",
        icon: "Users",
      },
      {
        title: "Analytique",
        description: "Tableaux de bord clairs pour piloter votre activite.",
        icon: "BarChart3",
      },
    ],
  },

  // Stripe pricing plans
  pricing: {
    plans: [
      {
        id: "free",
        name: "Gratuit",
        description: "Pour decouvrir",
        price: 0,
        currency: "EUR",
        interval: "month" as const,
        features: [
          "1 utilisateur",
          "100 Mo de stockage",
          "Support communautaire",
        ],
        stripePriceId: null,
      },
      {
        id: "pro",
        name: "Pro",
        description: "Pour les professionnels",
        price: 29,
        currency: "EUR",
        interval: "month" as const,
        features: [
          "5 utilisateurs",
          "10 Go de stockage",
          "Support prioritaire",
          "API access",
        ],
        stripePriceId: "", // Set after creating Stripe price
        popular: true,
      },
      {
        id: "enterprise",
        name: "Entreprise",
        description: "Pour les grandes equipes",
        price: 99,
        currency: "EUR",
        interval: "month" as const,
        features: [
          "Utilisateurs illimites",
          "Stockage illimite",
          "Support dedie",
          "API access",
          "SSO",
          "SLA garanti",
        ],
        stripePriceId: "", // Set after creating Stripe price
      },
    ],
  },

  // Supabase table prefix (derived from saasId)
  get tablePrefix() {
    return this.saasId.replace(/-/g, "_") + "_";
  },
};

export type SaaSConfig = typeof saasConfig;
