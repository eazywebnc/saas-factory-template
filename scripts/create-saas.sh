#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# SaaS Factory — Create a new SaaS in < 5 minutes
# Usage: ./scripts/create-saas.sh <saas-id> [options]
#
# Example:
#   ./scripts/create-saas.sh trackncolis \
#     --name "TrackNColis" \
#     --desc "Suivi de colis en Nouvelle-Caledonie" \
#     --color "#10b981" \
#     --price-pro 2900 \
#     --price-enterprise 9900
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${BLUE}[FACTORY]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header()  { echo -e "\n${CYAN}${BOLD}$1${NC}"; }

# ============================================================
# Parse arguments
# ============================================================
usage() {
  cat <<'USAGE'
Usage: create-saas.sh <saas-id> [options]

Required:
  <saas-id>              Unique ID (lowercase, hyphens ok). Used for DB prefix, subdomain, CF Pages name.

Options:
  --name "Name"          Display name (default: derived from saas-id)
  --desc "Description"   Short description
  --color "#hex"         Primary brand color (default: #6366f1)
  --price-pro CENTS      Pro plan price in EUR cents (default: 2900 = 29€)
  --price-enterprise CENTS  Enterprise plan price in EUR cents (default: 9900 = 99€)
  --output-dir DIR       Where to create the project (default: ../<saas-id>)
  --no-deploy            Skip deployment (just scaffold)
  --no-stripe            Skip Stripe product creation
  --no-github            Skip GitHub repo creation
  -h, --help             Show this help

Environment variables required (set in .env.local or export):
  SAAS_SUPABASE_URL              Supabase project URL
  SAAS_SUPABASE_ANON_KEY         Supabase anon key
  SAAS_SUPABASE_SERVICE_ROLE_KEY Supabase service role key
  SUPABASE_ACCESS_TOKEN          Supabase Management API token
  SAAS_SUPABASE_PROJECT_REF      Supabase project reference ID
  STRIPE_SECRET_KEY              Stripe secret key
  STRIPE_PUBLISHABLE_KEY         Stripe publishable key
  CLOUDFLARE_PAGES_TOKEN         Cloudflare Pages API token
  CLOUDFLARE_DNS_TOKEN           Cloudflare DNS API token
  GITHUB_TOKEN                   GitHub Personal Access Token
USAGE
  exit 0
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
fi

SAAS_ID="$1"; shift

# Validate saas-id
if ! echo "$SAAS_ID" | grep -qE '^[a-z][a-z0-9-]{1,30}$'; then
  error "saas-id must be lowercase, start with letter, 2-31 chars, only [a-z0-9-]"
fi

# Defaults
SAAS_NAME=""
SAAS_DESC="Un SaaS propulse par EazyWebNC"
PRIMARY_COLOR="#6366f1"
PRICE_PRO=2900
PRICE_ENTERPRISE=9900
OUTPUT_DIR=""
DO_DEPLOY=true
DO_STRIPE=true
DO_GITHUB=true

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    --name) SAAS_NAME="$2"; shift 2 ;;
    --desc) SAAS_DESC="$2"; shift 2 ;;
    --color) PRIMARY_COLOR="$2"; shift 2 ;;
    --price-pro) PRICE_PRO="$2"; shift 2 ;;
    --price-enterprise) PRICE_ENTERPRISE="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --no-deploy) DO_DEPLOY=false; shift ;;
    --no-stripe) DO_STRIPE=false; shift ;;
    --no-github) DO_GITHUB=false; shift ;;
    *) error "Unknown option: $1" ;;
  esac
done

# Derive name from saas-id if not provided
if [ -z "$SAAS_NAME" ]; then
  SAAS_NAME=$(echo "$SAAS_ID" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
fi

# Output dir
TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$(dirname "$TEMPLATE_DIR")/$SAAS_ID"
fi

TABLE_PREFIX="${SAAS_ID//-/_}_"
PRICE_PRO_EUR=$(echo "scale=0; $PRICE_PRO / 100" | bc)
PRICE_ENT_EUR=$(echo "scale=0; $PRICE_ENTERPRISE / 100" | bc)

# ============================================================
# Load environment
# ============================================================
load_env() {
  for f in "$TEMPLATE_DIR/.env.local" "$TEMPLATE_DIR/.env" "$HOME/.saas-factory.env"; do
    if [ -f "$f" ]; then
      set -a; source "$f"; set +a
      log "Loaded env from $f"
      return
    fi
  done
  warn "No .env file found — using exported environment variables"
}

load_env

# ============================================================
# Preflight checks
# ============================================================
header "=== SaaS Factory — Creating: $SAAS_NAME ($SAAS_ID) ==="
echo ""
log "Table prefix:  ${TABLE_PREFIX}"
log "Domain:        ${SAAS_ID}.eazyweb.nc"
log "Output:        ${OUTPUT_DIR}"
log "Deploy:        ${DO_DEPLOY}"
log "Stripe:        ${DO_STRIPE}"
log "GitHub:        ${DO_GITHUB}"
echo ""

check_var() {
  local var_name="$1"
  local required="$2"
  if [ -z "${!var_name:-}" ]; then
    if [ "$required" = "true" ]; then
      error "Missing required env var: $var_name"
    else
      warn "Optional env var not set: $var_name"
      return 1
    fi
  fi
  return 0
}

# Always required
check_var "SAAS_SUPABASE_URL" "true"
check_var "SAAS_SUPABASE_ANON_KEY" "true"
check_var "SAAS_SUPABASE_SERVICE_ROLE_KEY" "true"

# Required for deploy
if [ "$DO_DEPLOY" = "true" ]; then
  check_var "SUPABASE_ACCESS_TOKEN" "true"
  check_var "SAAS_SUPABASE_PROJECT_REF" "true"
  check_var "CLOUDFLARE_PAGES_TOKEN" "true"
  check_var "CLOUDFLARE_DNS_TOKEN" "true"
fi

if [ "$DO_STRIPE" = "true" ]; then
  check_var "STRIPE_SECRET_KEY" "true"
  check_var "STRIPE_PUBLISHABLE_KEY" "true"
fi

if [ "$DO_GITHUB" = "true" ]; then
  check_var "GITHUB_TOKEN" "true"
fi

# Check output dir doesn't exist
if [ -d "$OUTPUT_DIR" ]; then
  error "Output directory already exists: $OUTPUT_DIR"
fi

# ============================================================
# Step 1: Copy template
# ============================================================
header "Step 1/6: Copying template..."

# Copy template, excluding .git, node_modules, .next, nested dir
mkdir -p "$OUTPUT_DIR"
rsync -a \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='saas-factory-template' \
  --exclude='.env.local' \
  --exclude='.env' \
  "$TEMPLATE_DIR/" "$OUTPUT_DIR/"

success "Template copied to $OUTPUT_DIR"

# ============================================================
# Step 2: Configure saas.config.ts
# ============================================================
header "Step 2/6: Configuring saas.config.ts..."

cat > "$OUTPUT_DIR/saas.config.ts" << TSEOF
/**
 * SaaS Factory Configuration
 * Generated by create-saas.sh for: ${SAAS_NAME}
 */
export const saasConfig = {
  saasId: "${SAAS_ID}",
  name: "${SAAS_NAME}",
  description: "${SAAS_DESC}",
  domain: "${SAAS_ID}.eazyweb.nc",

  branding: {
    primaryColor: "${PRIMARY_COLOR}",
    logo: "/logo.svg",
  },

  landing: {
    headline: "Simplifiez votre quotidien",
    subheadline: "${SAAS_DESC}",
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
        price: ${PRICE_PRO_EUR},
        currency: "EUR",
        interval: "month" as const,
        features: [
          "5 utilisateurs",
          "10 Go de stockage",
          "Support prioritaire",
          "API access",
        ],
        stripePriceId: "", // Set by create-saas.sh or manually
        popular: true,
      },
      {
        id: "enterprise",
        name: "Entreprise",
        description: "Pour les grandes equipes",
        price: ${PRICE_ENT_EUR},
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
        stripePriceId: "", // Set by create-saas.sh or manually
      },
    ],
  },

  get tablePrefix() {
    return this.saasId.replace(/-/g, "_") + "_";
  },
};

export type SaaSConfig = typeof saasConfig;
TSEOF

success "saas.config.ts configured"

# ============================================================
# Step 3: Create .env.local
# ============================================================
header "Step 3/6: Creating .env.local..."

cat > "$OUTPUT_DIR/.env.local" << ENVEOF
# SaaS Factory — ${SAAS_NAME}
# Generated by create-saas.sh

# Supabase (shared SaaS Factory project)
NEXT_PUBLIC_SUPABASE_URL=${SAAS_SUPABASE_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${SAAS_SUPABASE_ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${SAAS_SUPABASE_SERVICE_ROLE_KEY}

# Stripe
STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY:-sk_test_xxx}
STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY:-pk_test_xxx}
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY:-pk_test_xxx}
STRIPE_WEBHOOK_SECRET=

# Cloudflare (for deploy script)
CLOUDFLARE_PAGES_TOKEN=${CLOUDFLARE_PAGES_TOKEN:-}
CLOUDFLARE_DNS_TOKEN=${CLOUDFLARE_DNS_TOKEN:-}
CLOUDFLARE_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID:-}

# Supabase Management API (for deploy script)
SUPABASE_ACCESS_TOKEN=${SUPABASE_ACCESS_TOKEN:-}
SUPABASE_PROJECT_REF=${SAAS_SUPABASE_PROJECT_REF:-}
ENVEOF

success ".env.local created"

# ============================================================
# Step 4: Create Stripe products (optional)
# ============================================================
if [ "$DO_STRIPE" = "true" ] && [ -n "${STRIPE_SECRET_KEY:-}" ]; then
  header "Step 4/6: Creating Stripe products..."

  # Create product
  PRODUCT_ID=$(curl -s -X POST "https://api.stripe.com/v1/products" \
    -u "${STRIPE_SECRET_KEY}:" \
    -d "name=${SAAS_NAME}" \
    -d "description=${SAAS_DESC}" \
    -d "metadata[saas_id]=${SAAS_ID}" | jq -r '.id')

  if [ -z "$PRODUCT_ID" ] || [ "$PRODUCT_ID" = "null" ]; then
    warn "Failed to create Stripe product — skipping"
  else
    success "Stripe product created: $PRODUCT_ID"

    # Create Pro price
    PRO_PRICE_ID=$(curl -s -X POST "https://api.stripe.com/v1/prices" \
      -u "${STRIPE_SECRET_KEY}:" \
      -d "product=${PRODUCT_ID}" \
      -d "unit_amount=${PRICE_PRO}" \
      -d "currency=eur" \
      -d "recurring[interval]=month" \
      -d "metadata[plan]=pro" \
      -d "metadata[saas_id]=${SAAS_ID}" | jq -r '.id')

    if [ -n "$PRO_PRICE_ID" ] && [ "$PRO_PRICE_ID" != "null" ]; then
      success "Pro price created: $PRO_PRICE_ID (${PRICE_PRO_EUR}EUR/month)"
      # Update saas.config.ts with price ID
      sed -i "s|stripePriceId: \"\", // Set by create-saas.sh or manually|stripePriceId: \"${PRO_PRICE_ID}\",|" "$OUTPUT_DIR/saas.config.ts"
    fi

    # Create Enterprise price
    ENT_PRICE_ID=$(curl -s -X POST "https://api.stripe.com/v1/prices" \
      -u "${STRIPE_SECRET_KEY}:" \
      -d "product=${PRODUCT_ID}" \
      -d "unit_amount=${PRICE_ENTERPRISE}" \
      -d "currency=eur" \
      -d "recurring[interval]=month" \
      -d "metadata[plan]=enterprise" \
      -d "metadata[saas_id]=${SAAS_ID}" | jq -r '.id')

    if [ -n "$ENT_PRICE_ID" ] && [ "$ENT_PRICE_ID" != "null" ]; then
      success "Enterprise price created: $ENT_PRICE_ID (${PRICE_ENT_EUR}EUR/month)"
      # Update the second occurrence (enterprise plan)
      sed -i "0,/stripePriceId: \"\", \/\/ Set by create-saas.sh or manually/{s|stripePriceId: \"\", // Set by create-saas.sh or manually|stripePriceId: \"${ENT_PRICE_ID}\",|}" "$OUTPUT_DIR/saas.config.ts"
    fi
  fi
else
  log "Step 4/6: Skipping Stripe product creation"
fi

# ============================================================
# Step 5: Install dependencies & init git
# ============================================================
header "Step 5/6: Installing dependencies..."

cd "$OUTPUT_DIR"
npm install --loglevel=warn 2>&1 | tail -3
success "Dependencies installed"

# Init git
git init -q
git add -A
git commit -q -m "feat: scaffold ${SAAS_NAME} SaaS from factory template

Co-Authored-By: Paperclip <noreply@paperclip.ing>"
success "Git repository initialized"

# Create GitHub repo (optional)
if [ "$DO_GITHUB" = "true" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  log "Creating GitHub repository..."

  CREATE_REPO=$(curl -s -X POST "https://api.github.com/orgs/eazywebnc/repos" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${SAAS_ID}\",
      \"description\": \"${SAAS_DESC} — Built with EazyWebNC SaaS Factory\",
      \"private\": true,
      \"auto_init\": false
    }" 2>/dev/null)

  REPO_URL=$(echo "$CREATE_REPO" | jq -r '.clone_url // empty')

  if [ -n "$REPO_URL" ]; then
    # Use token-authenticated URL
    AUTH_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/eazywebnc/${SAAS_ID}.git"
    git remote add origin "$AUTH_URL"
    git branch -M main
    git push -u origin main -q 2>/dev/null || warn "Could not push to GitHub"
    success "GitHub repo created: https://github.com/eazywebnc/${SAAS_ID}"
  else
    warn "Could not create GitHub repo — $(echo "$CREATE_REPO" | jq -r '.message // "unknown error"')"
  fi
fi

# ============================================================
# Step 6: Deploy (optional)
# ============================================================
if [ "$DO_DEPLOY" = "true" ]; then
  header "Step 6/6: Deploying..."

  # Run the deploy script (it handles Supabase tables, CF Pages, DNS, build)
  if [ -f scripts/deploy.sh ]; then
    bash scripts/deploy.sh
  else
    warn "deploy.sh not found — skipping deployment"
  fi
else
  log "Step 6/6: Skipping deployment (use --no-deploy was set)"
  log "To deploy later: cd $OUTPUT_DIR && bash scripts/deploy.sh"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo -e "${CYAN}${BOLD}=========================================="
echo -e " SaaS Factory — Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "  ${BOLD}Name:${NC}      ${SAAS_NAME}"
echo -e "  ${BOLD}ID:${NC}        ${SAAS_ID}"
echo -e "  ${BOLD}Directory:${NC} ${OUTPUT_DIR}"
echo -e "  ${BOLD}Domain:${NC}    https://${SAAS_ID}.eazyweb.nc"
echo -e "  ${BOLD}Pages:${NC}     https://${SAAS_ID}.pages.dev"
if [ -n "${REPO_URL:-}" ]; then
echo -e "  ${BOLD}GitHub:${NC}    https://github.com/eazywebnc/${SAAS_ID}"
fi
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    cd ${OUTPUT_DIR}"
echo -e "    npm run dev          # Local development"
echo -e "    bash scripts/deploy.sh  # Re-deploy"
echo ""
