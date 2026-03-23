---
name: nextjs-bootstrap
description: Bootstraps new Next.js projects with the standard stack — Neon Postgres, Prisma, NextAuth, Tailwind v4, Vitest, Playwright, CLAUDE.md, and common deps. Reflects actual patterns from 20+ production projects.
---

# Next.js Bootstrap

Orchestrator skill for setting up Next.js projects using the standard stack.

## Standard Stack (Default)

```
Next.js 16 + React 19 + TypeScript (strict)
Tailwind v4 + shadcn/ui
Neon PostgreSQL + Prisma 7 (or Drizzle)
NextAuth v4 (magic link + Google OAuth)
Anthropic Claude SDK
Zod validation
Vitest + Playwright
Sonner (toasts), Lucide (icons), Framer Motion (animation)
Vercel deployment
```

## Port Registry

A global port registry lives at `/Users/johnblythe/code/.port-registry.json`. It tracks dev server ports and Supabase port ranges for all projects.

**On every bootstrap:**
1. Read `.port-registry.json` to see allocated ports
2. Auto-assign the next available dev server port (start from 3000, skip taken)
3. If Supabase is selected, assign a free port range (base + 0-5, starting from 54321, incrementing base by 100 to avoid overlap)
4. Register the new project's ports in the registry before proceeding
5. Confirm the assigned ports with the user before creating the project

**When manually setting a port:** validate it doesn't collide with any registered port. If it does, warn and suggest the next free one.

## Ask First

1. **New or existing project?**
2. **What does it do?** (one sentence — for CLAUDE.md and package.json)
3. **Port?** Check `.port-registry.json` for conflicts. Auto-assign next free port if not specified.
4. **Which features now?**
   - [ ] Auth → `auth-setup` skill
   - [ ] Email → `email-setup` skill
   - [ ] Payments (Stripe) → `stripe-payments` skill
   - [ ] File uploads → `file-uploads` skill
   - [ ] AI (Claude) → `ai-integration` skill
   - [ ] Background jobs → `background-jobs` skill
   - [ ] Analytics → `analytics-setup` skill
5. **Database?**
   - Neon PostgreSQL (default — free, scale-to-zero, 100 projects on free tier)
   - Supabase PostgreSQL (if you need Supabase auth/storage/realtime bundle)
   - Turso/libSQL (if SQLite is acceptable, $5/mo unlimited DBs, use Drizzle)
6. **ORM?**
   - Prisma 7 (default — better DX, mature ecosystem)
   - Drizzle (lighter, SQL-like, required for Turso)

## Step 1: Create Project

```bash
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --import-alias "@/*"
cd my-app
```

**Note:** Next.js 16 uses Tailwind v4 by default. No `tailwind.config.ts` — uses CSS-based config in `app/globals.css`.

## Step 2: Set Port

In `package.json`, update the dev script:

```json
"scripts": {
  "dev": "next dev --turbopack -p PORT_NUMBER"
}
```

## Step 3: Core Dependencies

```bash
# Validation
npm install zod

# UI essentials
npm install sonner lucide-react framer-motion

# Utilities
npm install clsx tailwind-merge date-fns nanoid

# shadcn/ui
npx shadcn@latest init
npx shadcn@latest add button input card form dialog toast
```

Create `lib/utils.ts`:

```typescript
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## Step 4: Database — Neon PostgreSQL + Prisma 7

### Install

```bash
npm install prisma @prisma/client @prisma/adapter-pg pg dotenv
npm install -D @types/pg
npx prisma init
```

### Neon Setup

1. Go to [neon.tech](https://neon.tech), create a project (free tier: 100 projects, 0.5 GB each)
2. Copy connection strings (pooled + direct)

### Environment

```env
# Pooled connection — for app queries
DATABASE_URL="postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/dbname?sslmode=require"

# Direct connection — for migrations
DIRECT_URL="postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/dbname?sslmode=require"
```

### Prisma Schema

**Prisma 7 breaking change:** Connection URLs go in `prisma.config.ts`, NOT in `schema.prisma`.

`prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("users")
}
```

`prisma.config.ts`:

```typescript
import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: { path: "prisma/migrations" },
  datasource: { url: process.env["DATABASE_URL"] },
});
```

### Prisma Client Singleton

**Prisma 7 breaking change:** Requires a driver adapter. Import from generated output path.

`src/lib/prisma.ts`:

```typescript
import { PrismaClient } from "@/generated/prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

function createPrismaClient() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) throw new Error("DATABASE_URL is not set");
  const adapter = new PrismaPg({ connectionString });
  return new PrismaClient({ adapter });
}

export const prisma = globalForPrisma.prisma ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

### Migration Rules

- `prisma migrate deploy` = **DEFAULT** — safe, non-destructive, applies existing migrations
- `prisma migrate dev --name <name>` = ONLY when creating NEW schema changes
- **Never use `prisma db push`**
- Never run migrations directly against prod — Vercel handles it
- Generated client at `src/generated/prisma/` (gitignored)

## Step 4 (Alt): Database — Neon + Drizzle

```bash
npm install drizzle-orm @neondatabase/serverless
npm install -D drizzle-kit
```

`drizzle.config.ts`:

```typescript
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/db/schema/index.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
});
```

## Step 4 (Alt): Database — Supabase + Prisma

Use this if you need Supabase auth, storage, or realtime — otherwise prefer Neon.

```bash
npm install prisma @prisma/client @prisma/adapter-pg
```

```env
# Pooled (port 6543) — for app queries
POSTGRES_PRISMA_URL="postgresql://user:pass@host:6543/db?pgbouncer=true"
# Direct (port 5432) — for migrations
POSTGRES_URL_NON_POOLING="postgresql://user:pass@host:5432/db"
```

## Step 5: Testing

### Vitest

```bash
npm install -D vitest @vitejs/plugin-react happy-dom @testing-library/react @testing-library/jest-dom
```

`vitest.config.ts`:

```typescript
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "happy-dom",
    include: ["src/**/*.test.{ts,tsx}"],
    setupFiles: ["./vitest.setup.ts"],
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
```

`vitest.setup.ts`:

```typescript
import "@testing-library/jest-dom/vitest";
```

Add to `package.json`:

```json
"scripts": {
  "test": "vitest run",
  "test:watch": "vitest"
}
```

### Playwright

```bash
npm install -D @playwright/test
npx playwright install
```

`playwright.config.ts`:

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./tests",
  use: {
    baseURL: "http://localhost:PORT_NUMBER",
  },
  webServer: {
    command: "npm run dev",
    port: PORT_NUMBER,
    reuseExistingServer: true,
  },
});
```

Add to `package.json`:

```json
"scripts": {
  "test:e2e": "playwright test"
}
```

## Step 6: CLAUDE.md

Create `CLAUDE.md` at project root. This is critical — it defines conventions for every future Claude Code session.

```markdown
# [Project Name]

[One-line description]. Next.js 16, TypeScript strict, Prisma, Neon PostgreSQL.

## Commands
- `npm run dev` — dev server on port [PORT]
- `npm run build` — production build (DON'T run unless explicitly asked)
- `npm run lint` — ESLint
- `npm run typecheck` — tsc --noEmit
- `npm run test` — Vitest
- `npm run test:watch` — Vitest watch mode

## Rules
- Don't run `npm run build` or `npm run dev` unless explicitly asked
- Every PR updates CHANGELOG.md BEFORE `gh pr create`
- Always `prisma migrate dev --name <name>` after schema changes
- Never `prisma db push`
- Trunk-based development: all PRs target `main`

## Architecture
- All API routes: validate (Zod) → auth → execute → respond
- Server Components by default, `'use client'` only for interactivity
- Import types from generated Prisma client, never redefine enums
- Infer types from Zod schemas with `z.infer<>`, never duplicate interfaces
- All prices in cents (Int)

## Testing
- Vitest for unit/integration tests
- Tests live alongside source: `src/**/*.test.{ts,tsx}`
- happy-dom environment
- Playwright for e2e in `tests/`

## Database
- Prisma 7 with Neon PostgreSQL
- `prisma migrate deploy` = default (safe)
- `prisma migrate dev --name <name>` = only for new schema changes
- Never `prisma db push`

## Naming
- Path alias: `@/*` → `./src/*`
- Files: kebab-case
- Components: PascalCase
- API routes: kebab-case directories
```

## Step 7: CHANGELOG.md

Create `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial project setup
```

## Step 8: Vercel Deployment Config

`vercel.json`:

```json
{
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-store" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-XSS-Protection", "value": "1; mode=block" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ]
}
```

Add cron jobs and function timeouts as needed:

```json
{
  "crons": [
    { "path": "/api/cron/daily-task", "schedule": "0 14 * * *" }
  ],
  "functions": {
    "app/api/ai/*/route.ts": { "maxDuration": 60 }
  }
}
```

## Step 9: Middleware

`middleware.ts` (if using auth):

```typescript
import { withAuth } from "next-auth/middleware";

export default withAuth({
  pages: { signIn: "/auth/login" },
});

export const config = {
  matcher: ["/dashboard/:path*", "/api/protected/:path*"],
};
```

## Step 10: Environment & Git

`.env.example`:

```env
# Database (Neon)
DATABASE_URL=
DIRECT_URL=

# Auth (NextAuth)
AUTH_SECRET=
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=

# AI
ANTHROPIC_API_KEY=

# Email
RESEND_API_KEY=
EMAIL_FROM=

# Stripe
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=

# App
NEXT_PUBLIC_SITE_URL=http://localhost:PORT
```

Ensure `.gitignore` includes:

```
.env.local
.env
tmp/
dev.db
node_modules/
.next/
src/generated/
```

## Step 11: Package.json Scripts

Ensure these exist:

```json
{
  "scripts": {
    "dev": "next dev --turbopack -p PORT",
    "build": "prisma generate && prisma migrate deploy && next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
```

## Step 12: Project Structure

```
src/
├── app/
│   ├── (auth)/           # Auth pages (login, signup)
│   ├── (dashboard)/      # Protected route group
│   │   └── layout.tsx    # Auth-gated layout
│   ├── api/
│   │   ├── auth/[...nextauth]/route.ts
│   │   └── webhooks/stripe/route.ts
│   ├── layout.tsx
│   └── page.tsx
├── components/
│   └── ui/               # shadcn/ui components
├── hooks/                # Custom React hooks
├── lib/
│   ├── prisma.ts         # DB client singleton
│   ├── auth.ts           # NextAuth config
│   ├── utils.ts          # cn() helper
│   ├── email/            # Email templates
│   └── ai/               # Claude API calls
├── types/                # TypeScript types
├── services/             # Domain services
└── middleware.ts

prisma/
├── schema.prisma
├── migrations/
└── seed.ts               # Test data

tests/                    # Playwright e2e
CLAUDE.md
CHANGELOG.md
vercel.json
```

## Delegation to Feature Skills

After the base is set up, delegate to specialized skills:

- **Auth**: `auth-setup` — NextAuth v4 + magic links + Google OAuth + Prisma adapter
- **Email**: `email-setup` — Resend + React Email templates
- **Payments**: `stripe-payments` — Checkout, subscriptions, webhooks
- **File uploads**: `file-uploads` — Supabase Storage or S3
- **AI**: `ai-integration` — Anthropic Claude SDK + prompt security
- **Background jobs**: `background-jobs` — Inngest or Vercel Cron
- **Analytics**: `analytics-setup` — Vercel Analytics or PostHog

## Bootstrap Checklist

- [ ] Port registry checked and new project registered in `/Users/johnblythe/code/.port-registry.json`
- [ ] Project created with `create-next-app`
- [ ] Port configured (no conflicts per registry)
- [ ] Core deps installed (Zod, Sonner, Lucide, Framer Motion, clsx, tailwind-merge)
- [ ] shadcn/ui initialized
- [ ] Database configured (Neon + Prisma default)
- [ ] Prisma schema + initial migration
- [ ] Prisma client singleton
- [ ] Testing: Vitest + Playwright configured
- [ ] CLAUDE.md created with project conventions
- [ ] CHANGELOG.md created
- [ ] vercel.json with security headers
- [ ] .env.example with all expected vars
- [ ] .gitignore updated (tmp/, dev.db, generated/)
- [ ] middleware.ts (if auth)
- [ ] package.json scripts complete
- [ ] `npm install` clean, no warnings
- [ ] Feature skills delegated as needed

## Quick Reference

```bash
# Create project
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --import-alias "@/*"

# Database (Neon + Prisma)
npm install prisma @prisma/client @prisma/adapter-neon @neondatabase/serverless
npx prisma init && npx prisma migrate dev --name init

# Database (Neon + Drizzle)
npm install drizzle-orm @neondatabase/serverless && npm install -D drizzle-kit

# Auth
npm install next-auth @auth/prisma-adapter

# AI
npm install @anthropic-ai/sdk

# Email
npm install resend @react-email/components

# Payments
npm install stripe @stripe/stripe-js

# Testing
npm install -D vitest @vitejs/plugin-react happy-dom @testing-library/react @testing-library/jest-dom
npm install -D @playwright/test && npx playwright install

# UI
npm install sonner lucide-react framer-motion
npx shadcn@latest init

# Utilities
npm install zod clsx tailwind-merge date-fns nanoid
```
