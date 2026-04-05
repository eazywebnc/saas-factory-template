#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# SaaS Factory — 1-Command Deploy Script
# Usage: ./scripts/deploy.sh
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[DEPLOY]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Load env
if [ -f .env.local ]; then
  set -a; source .env.local; set +a
elif [ -f .env ]; then
  set -a; source .env; set +a
else
  error "No .env.local or .env file found. Copy .env.example and fill in values."
fi

# Extract saasId from config
SAAS_ID=$(node -e "
  const fs = require('fs');
  const content = fs.readFileSync('saas.config.ts', 'utf8');
  const match = content.match(/saasId:\\s*['\"]([^'\"]+)['\"]/);
  if (match) console.log(match[1]);
  else process.exit(1);
")
TABLE_PREFIX="${SAAS_ID//-/_}_"

log "Deploying SaaS: ${SAAS_ID}"
log "Table prefix: ${TABLE_PREFIX}"

# ============================================================
# Step 1: Create Supabase tables
# ============================================================
log "Step 1/4: Creating Supabase tables..."

SQL="
-- Users profile table
CREATE TABLE IF NOT EXISTS ${TABLE_PREFIX}profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscriptions table
CREATE TABLE IF NOT EXISTS ${TABLE_PREFIX}subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  stripe_price_id TEXT,
  status TEXT DEFAULT 'inactive',
  current_period_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE ${TABLE_PREFIX}profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ${TABLE_PREFIX}subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies: profiles
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '${TABLE_PREFIX}profiles_select') THEN
    CREATE POLICY \"${TABLE_PREFIX}profiles_select\" ON ${TABLE_PREFIX}profiles FOR SELECT USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '${TABLE_PREFIX}profiles_update') THEN
    CREATE POLICY \"${TABLE_PREFIX}profiles_update\" ON ${TABLE_PREFIX}profiles FOR UPDATE USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '${TABLE_PREFIX}profiles_insert') THEN
    CREATE POLICY \"${TABLE_PREFIX}profiles_insert\" ON ${TABLE_PREFIX}profiles FOR INSERT WITH CHECK (auth.uid() = id);
  END IF;
END \$\$;

-- RLS Policies: subscriptions
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = '${TABLE_PREFIX}subscriptions_select') THEN
    CREATE POLICY \"${TABLE_PREFIX}subscriptions_select\" ON ${TABLE_PREFIX}subscriptions FOR SELECT USING (auth.uid() = user_id);
  END IF;
END \$\$;

-- Trigger: auto-create profile on signup
CREATE OR REPLACE FUNCTION ${TABLE_PREFIX}handle_new_user()
RETURNS TRIGGER AS \$\$
BEGIN
  INSERT INTO ${TABLE_PREFIX}profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS ${TABLE_PREFIX}on_auth_user_created ON auth.users;
CREATE TRIGGER ${TABLE_PREFIX}on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ${TABLE_PREFIX}handle_new_user();
"

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg q "$SQL" '{query: $q}')")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  success "Supabase tables created"
else
  BODY=$(echo "$RESPONSE" | sed '$d')
  error "Failed to create tables (HTTP $HTTP_CODE): $BODY"
fi

# ============================================================
# Step 2: Create Cloudflare Pages project
# ============================================================
log "Step 2/4: Creating Cloudflare Pages project..."

# Get account ID
if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
  CLOUDFLARE_ACCOUNT_ID=$(curl -s \
    -H "Authorization: Bearer ${CLOUDFLARE_PAGES_TOKEN}" \
    "https://api.cloudflare.com/client/v4/accounts" | jq -r '.result[0].id')
fi

# Create Pages project (ignore if exists)
CREATE_RESULT=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects" \
  -H "Authorization: Bearer ${CLOUDFLARE_PAGES_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${SAAS_ID}\",
    \"production_branch\": \"main\"
  }")

if echo "$CREATE_RESULT" | jq -e '.success' > /dev/null 2>&1; then
  success "Cloudflare Pages project '${SAAS_ID}' created"
else
  MSG=$(echo "$CREATE_RESULT" | jq -r '.errors[0].message // "unknown error"')
  if echo "$MSG" | grep -qi "already"; then
    warn "Pages project '${SAAS_ID}' already exists — continuing"
  else
    error "Failed to create Pages project: $MSG"
  fi
fi

# ============================================================
# Step 3: Add CNAME record
# ============================================================
log "Step 3/4: Adding DNS CNAME record..."

# Get zone ID for eazyweb.nc
ZONE_ID=$(curl -s \
  -H "Authorization: Bearer ${CLOUDFLARE_DNS_TOKEN}" \
  "https://api.cloudflare.com/client/v4/zones?name=eazyweb.nc" | jq -r '.result[0].id')

if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "null" ]; then
  warn "Could not find zone for eazyweb.nc — skipping DNS"
else
  # Check if record exists
  EXISTING=$(curl -s \
    -H "Authorization: Bearer ${CLOUDFLARE_DNS_TOKEN}" \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=CNAME&name=${SAAS_ID}.eazyweb.nc" | jq -r '.result | length')

  if [ "$EXISTING" -gt 0 ]; then
    warn "CNAME ${SAAS_ID}.eazyweb.nc already exists"
  else
    DNS_RESULT=$(curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CLOUDFLARE_DNS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"CNAME\",
        \"name\": \"${SAAS_ID}\",
        \"content\": \"${SAAS_ID}.pages.dev\",
        \"proxied\": true
      }")

    if echo "$DNS_RESULT" | jq -e '.success' > /dev/null 2>&1; then
      success "CNAME ${SAAS_ID}.eazyweb.nc -> ${SAAS_ID}.pages.dev created"
    else
      warn "DNS creation returned: $(echo "$DNS_RESULT" | jq -r '.errors[0].message // "unknown"')"
    fi
  fi
fi

# ============================================================
# Step 4: Build & Deploy
# ============================================================
log "Step 4/4: Building and deploying..."

npm run build

if command -v npx &> /dev/null; then
  npx wrangler pages deploy .next --project-name="${SAAS_ID}" --branch=main 2>/dev/null || {
    warn "wrangler pages deploy failed — try manual deploy or install @cloudflare/next-on-pages"
    log "Alternative: npx @cloudflare/next-on-pages && npx wrangler pages deploy .vercel/output/static --project-name=${SAAS_ID}"
  }
fi

echo ""
success "=========================================="
success " Deployment complete!"
success " URL: https://${SAAS_ID}.eazyweb.nc"
success " Pages: https://${SAAS_ID}.pages.dev"
success "=========================================="
