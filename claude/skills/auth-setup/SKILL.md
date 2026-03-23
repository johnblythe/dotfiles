---
name: auth-setup
description: Sets up authentication in Next.js projects. Covers NextAuth.js (magic links, OAuth), Clerk (hosted auth), with Prisma adapter.
---

# Auth Setup

## Ask First

1. **Provider preference?**
   - NextAuth.js v4 (stable) - self-hosted, production-proven (recommended with Prisma)
   - NextAuth.js v5 (Auth.js beta) - newer API, but has Edge runtime issues
   - Clerk - hosted, fastest setup, more features OOTB

2. **Auth methods needed?**
   - Magic links (email)
   - OAuth (Google, GitHub, etc.)
   - Email/password (less common now)

3. **Database?**
   - Prisma (recommended) - for session/user storage
   - Drizzle
   - None (JWT only)

---

## ⚠️ Version Warning

**NextAuth v5 (Auth.js) is still beta** - has known production issues:
- **Prisma adapter fails in Edge Runtime** (middleware can't use Prisma)
- Cookie/token handling quirks
- Breaking changes between beta versions

**For production with Prisma + middleware protection:** Use v4 stable

**Reference implementation:** ~/code/jb/travel uses v4 and works reliably

---

## Option A: NextAuth.js v4 (Stable - RECOMMENDED)

### Install

```bash
npm install next-auth@4 @next-auth/prisma-adapter nodemailer@7
```

### Environment

```env
# Generate with: openssl rand -base64 32
NEXTAUTH_SECRET=xxxxx
NEXTAUTH_URL=http://localhost:3000

# OAuth providers (as needed)
GOOGLE_CLIENT_ID=xxxxx
GOOGLE_CLIENT_SECRET=xxxxx
GITHUB_ID=xxxxx
GITHUB_SECRET=xxxxx

# Email provider (for magic links via SES or SMTP)
EMAIL_SERVER_HOST=email-smtp.us-east-1.amazonaws.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=xxxxx
EMAIL_SERVER_PASSWORD=xxxxx
EMAIL_FROM=noreply@example.com
```

### Prisma Schema

Add to `prisma/schema.prisma`:

```prisma
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String    @unique
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

model Account {
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  session_state     String?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@id([provider, providerAccountId])
}

model Session {
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model VerificationToken {
  identifier String
  token      String
  expires    DateTime

  @@id([identifier, token])
}
```

Run migration:
```bash
npx prisma migrate dev --name add-auth
```

### Auth Config

Create `src/lib/auth.ts`:

```typescript
import { NextAuthOptions, getServerSession } from "next-auth";
import { PrismaAdapter } from "@next-auth/prisma-adapter";
import EmailProvider from "next-auth/providers/email";
import GoogleProvider from "next-auth/providers/google";
import GitHubProvider from "next-auth/providers/github";
import { prisma } from "@/lib/prisma";
import nodemailer from "nodemailer";

// Helper to get session (backwards compat with v5 pattern)
export async function auth() {
  return getServerSession(authOptions);
}

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    // Magic link via SMTP/SES
    EmailProvider({
      server: {
        host: process.env.EMAIL_SERVER_HOST,
        port: Number(process.env.EMAIL_SERVER_PORT) || 587,
        auth: {
          user: process.env.EMAIL_SERVER_USER,
          pass: process.env.EMAIL_SERVER_PASSWORD,
        },
      },
      from: process.env.EMAIL_FROM,
    }),
    // OAuth providers (optional)
    ...(process.env.GOOGLE_CLIENT_ID ? [GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    })] : []),
    ...(process.env.GITHUB_ID ? [GitHubProvider({
      clientId: process.env.GITHUB_ID,
      clientSecret: process.env.GITHUB_SECRET!,
    })] : []),
  ],
  callbacks: {
    session: async ({ session, token }) => {
      if (session?.user && token?.sub) {
        session.user.id = token.sub;
      }
      return session;
    },
    jwt: async ({ user, token }) => {
      if (user) {
        token.sub = user.id;
      }
      return token;
    },
  },
  session: { strategy: "jwt" },
  pages: {
    signIn: "/auth/signin",
    verifyRequest: "/auth/verify-request",
    error: "/auth/error",
  },
};
```

Create `src/auth.ts` (re-export for convenience):

```typescript
export { auth, authOptions } from "./lib/auth";
```

### TypeScript Types

Create `src/types/next-auth.d.ts`:

```typescript
import { DefaultSession, DefaultUser } from "next-auth";
import { DefaultJWT } from "next-auth/jwt";

declare module "next-auth" {
  interface Session {
    user: { id: string } & DefaultSession["user"];
  }
  interface User extends DefaultUser {
    id: string;
  }
}

declare module "next-auth/jwt" {
  interface JWT extends DefaultJWT {
    id?: string;
  }
}
```

### API Route

Create `app/api/auth/[...nextauth]/route.ts`:

```typescript
import NextAuth from "next-auth";
import { authOptions } from "@/lib/auth";

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

### Middleware

Create `middleware.ts`:

**IMPORTANT:** Use `getToken` from `next-auth/jwt` - NOT the auth() wrapper.
Prisma cannot run in Edge Runtime, so middleware must only verify JWT signature.

```typescript
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getToken } from "next-auth/jwt";

export async function middleware(request: NextRequest) {
  // Skip auth routes
  if (
    request.nextUrl.pathname.startsWith("/api/auth") ||
    request.nextUrl.pathname.startsWith("/auth")
  ) {
    return NextResponse.next();
  }

  // Check JWT token (no database access needed)
  const token = await getToken({ req: request });

  if (!token) {
    const signInUrl = new URL("/auth/signin", request.url);
    signInUrl.searchParams.set("callbackUrl", request.url);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*", "/settings/:path*"],
};
```

### Login Page

Create `app/auth/signin/page.tsx`:

```tsx
"use client";

import { signIn } from "next-auth/react";
import { useState } from "react";

export default function SignInPage() {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    await signIn("email", { email, callbackUrl: "/dashboard" });
  };

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md space-y-8 p-8">
        <h1 className="text-2xl font-bold text-center">Sign In</h1>

        {/* Magic Link Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="email@example.com"
            required
            className="w-full px-4 py-2 border rounded-lg"
          />
          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-2 bg-black text-white rounded-lg disabled:opacity-50"
          >
            {isLoading ? "Sending..." : "Sign in with Email"}
          </button>
        </form>

        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t" />
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-white text-gray-500">Or continue with</span>
          </div>
        </div>

        {/* OAuth Buttons */}
        <div className="space-y-2">
          <button
            onClick={() => signIn("google", { callbackUrl: "/dashboard" })}
            className="w-full py-2 border rounded-lg"
          >
            Google
          </button>
          <button
            onClick={() => signIn("github", { callbackUrl: "/dashboard" })}
            className="w-full py-2 border rounded-lg"
          >
            GitHub
          </button>
        </div>
      </div>
    </div>
  );
}
```

### Verify Page (Magic Link Sent)

Create `app/auth/verify-request/page.tsx`:

```tsx
export default function VerifyRequestPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center space-y-4">
        <h1 className="text-2xl font-bold">Check your email</h1>
        <p className="text-gray-600">
          A sign in link has been sent to your email address.
        </p>
      </div>
    </div>
  );
}
```

### Get Session (Server)

```typescript
import { auth } from "@/auth";
import { redirect } from "next/navigation";

// In Server Component
export default async function DashboardPage() {
  const session = await auth();

  if (!session?.user) {
    redirect("/auth/signin");
  }

  return <div>Hello {session.user.name}</div>;
}

// In API Route
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export async function GET() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    return new Response("Unauthorized", { status: 401 });
  }

  // ...
}
```

### Get Session (Client)

```tsx
"use client";

import { useSession } from "next-auth/react";

export function UserMenu() {
  const { data: session, status } = useSession();

  if (status === "loading") return <div>Loading...</div>;
  if (!session) return <SignInButton />;

  return <div>Welcome {session.user?.name}</div>;
}
```

### Session Provider

Wrap app in `app/layout.tsx`:

```tsx
import { SessionProvider } from "next-auth/react";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <SessionProvider>{children}</SessionProvider>
      </body>
    </html>
  );
}
```

### Sign Out

```tsx
"use client";

import { signOut } from "next-auth/react";

export function SignOutButton() {
  return (
    <button onClick={() => signOut({ callbackUrl: "/" })}>
      Sign Out
    </button>
  );
}
```

---

## Option B: NextAuth.js v5 (Auth.js Beta)

⚠️ **Use only if you DON'T need middleware protection with Prisma.**

See official docs: https://authjs.dev

Key differences from v4:
- Uses `@auth/prisma-adapter` instead of `@next-auth/prisma-adapter`
- Uses `AUTH_SECRET` instead of `NEXTAUTH_SECRET`
- Exports `{ handlers, signIn, signOut, auth }` from NextAuth()
- Middleware uses `auth()` wrapper (fails with Prisma adapter)

```bash
npm install next-auth@beta @auth/prisma-adapter
```

**Known Issues:**
- `auth()` in middleware requires Edge-compatible adapter
- Prisma is NOT Edge-compatible
- Workaround: Don't use middleware for auth, use `auth()` in layouts/pages instead

---

## Option C: Clerk

### Install

```bash
npm install @clerk/nextjs
```

### Environment

```env
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_xxxxx
CLERK_SECRET_KEY=sk_xxxxx

# Optional: Custom routes
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/login
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/signup
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard
```

### Provider

Update `app/layout.tsx`:

```tsx
import { ClerkProvider } from "@clerk/nextjs";

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### Middleware

Create `middleware.ts`:

```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/settings(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};
```

### Sign In/Up Pages

Create `app/login/[[...sign-in]]/page.tsx`:

```tsx
import { SignIn } from "@clerk/nextjs";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
```

Create `app/signup/[[...sign-up]]/page.tsx`:

```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
```

### Get User (Server)

```typescript
import { currentUser, auth } from "@clerk/nextjs/server";

// Get full user object
export default async function DashboardPage() {
  const user = await currentUser();
  return <div>Hello {user?.firstName}</div>;
}

// Just check auth
export async function GET() {
  const { userId } = await auth();

  if (!userId) {
    return new Response("Unauthorized", { status: 401 });
  }

  // ...
}
```

### Get User (Client)

```tsx
"use client";

import { useUser, useAuth, SignedIn, SignedOut } from "@clerk/nextjs";

export function UserMenu() {
  const { user, isLoaded } = useUser();
  const { signOut } = useAuth();

  if (!isLoaded) return <div>Loading...</div>;

  return (
    <>
      <SignedIn>
        <div>Welcome {user?.firstName}</div>
        <button onClick={() => signOut()}>Sign Out</button>
      </SignedIn>
      <SignedOut>
        <a href="/login">Sign In</a>
      </SignedOut>
    </>
  );
}
```

### User Button (Pre-built)

```tsx
import { UserButton } from "@clerk/nextjs";

export function Header() {
  return (
    <header>
      <UserButton afterSignOutUrl="/" />
    </header>
  );
}
```

### Sync Clerk User to Database

Create webhook handler `app/api/webhooks/clerk/route.ts`:

```typescript
import { Webhook } from "svix";
import { headers } from "next/headers";
import { WebhookEvent } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;

  if (!WEBHOOK_SECRET) {
    throw new Error("Missing CLERK_WEBHOOK_SECRET");
  }

  const headerPayload = await headers();
  const svix_id = headerPayload.get("svix-id");
  const svix_timestamp = headerPayload.get("svix-timestamp");
  const svix_signature = headerPayload.get("svix-signature");

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return new Response("Missing svix headers", { status: 400 });
  }

  const payload = await req.json();
  const body = JSON.stringify(payload);

  const wh = new Webhook(WEBHOOK_SECRET);
  let evt: WebhookEvent;

  try {
    evt = wh.verify(body, {
      "svix-id": svix_id,
      "svix-timestamp": svix_timestamp,
      "svix-signature": svix_signature,
    }) as WebhookEvent;
  } catch (err) {
    return new Response("Invalid signature", { status: 400 });
  }

  switch (evt.type) {
    case "user.created":
      await prisma.user.create({
        data: {
          clerkId: evt.data.id,
          email: evt.data.email_addresses[0]?.email_address,
          name: `${evt.data.first_name} ${evt.data.last_name}`.trim(),
        },
      });
      break;

    case "user.updated":
      await prisma.user.update({
        where: { clerkId: evt.data.id },
        data: {
          email: evt.data.email_addresses[0]?.email_address,
          name: `${evt.data.first_name} ${evt.data.last_name}`.trim(),
        },
      });
      break;

    case "user.deleted":
      await prisma.user.delete({
        where: { clerkId: evt.data.id },
      });
      break;
  }

  return new Response("OK", { status: 200 });
}
```

---

## OAuth Provider Setup

### Google Cloud Console
1. Go to console.cloud.google.com
2. Create/select project
3. APIs & Services > Credentials
4. Create OAuth 2.0 Client ID
5. Authorized redirect URIs:
   - NextAuth: `http://localhost:3000/api/auth/callback/google`
   - Clerk: Configure in Clerk dashboard

### GitHub
1. Go to github.com/settings/developers
2. New OAuth App
3. Authorization callback URL:
   - NextAuth: `http://localhost:3000/api/auth/callback/github`
   - Clerk: Configure in Clerk dashboard

---

## Comparison

| Feature | NextAuth v4 | NextAuth v5 | Clerk |
|---------|-------------|-------------|-------|
| Stability | ✅ Stable | ⚠️ Beta | ✅ Stable |
| Prisma + Middleware | ✅ Works | ❌ Edge issue | ✅ Works |
| Hosting | Self-hosted | Self-hosted | Hosted |
| Setup time | Medium | Medium | Fast |
| Customization | Full control | Full control | Limited |
| Pricing | Free | Free | Free tier + paid |

**Choose NextAuth v4 if:** Production app with Prisma, need middleware auth, want stability.

**Choose NextAuth v5 if:** No middleware auth needed, willing to work around Edge issues, want latest API.

**Choose Clerk if:** Fastest setup, don't want to manage auth, need user management dashboard.

---

## Checklist

### NextAuth v4 (Recommended)
- [ ] Dependencies: `next-auth@4 @next-auth/prisma-adapter nodemailer@7`
- [ ] NEXTAUTH_SECRET generated and set
- [ ] NEXTAUTH_URL set (no port in production!)
- [ ] Prisma schema updated with auth models
- [ ] Migration run
- [ ] `src/lib/auth.ts` with authOptions
- [ ] `src/types/next-auth.d.ts` for TypeScript
- [ ] API route: `app/api/auth/[...nextauth]/route.ts`
- [ ] Middleware uses `getToken` (NOT `auth()`)
- [ ] Login page uses `next-auth/react` signIn
- [ ] SessionProvider in layout
- [ ] Email provider configured (SMTP/SES)

### Clerk
- [ ] @clerk/nextjs installed
- [ ] Clerk account created, keys obtained
- [ ] ClerkProvider added to layout
- [ ] Middleware configured
- [ ] Sign in/up pages created
- [ ] (Optional) Webhook for DB sync
- [ ] OAuth providers enabled in Clerk dashboard

---

## Troubleshooting

### "PrismaClient is not configured to run in Edge Runtime"

**Cause:** Using `auth()` wrapper in middleware with Prisma adapter.

**Fix:** Use `getToken` from `next-auth/jwt` instead:

```typescript
// ❌ WRONG - uses Prisma under the hood
import { auth } from "@/auth";
export default auth((req) => { ... });

// ✅ CORRECT - just verifies JWT, no DB access
import { getToken } from "next-auth/jwt";
const token = await getToken({ req: request });
```

### MIDDLEWARE_INVOCATION_FAILED

Usually means Edge runtime issue. Check:
1. Middleware isn't importing Prisma
2. Using `getToken` not `auth()`
3. No server-only code in middleware

### Token not found / redirect loop

Check:
1. `NEXTAUTH_URL` matches actual URL (no `:3000` in prod!)
2. `NEXTAUTH_SECRET` is set
3. Cookies are being set (check dev tools)
4. Provider ID matches: `signIn("email")` not `signIn("resend")`

### Magic link email not sending

Check:
1. Email provider env vars set correctly
2. Domain verified in email service (SES, etc.)
3. SPF/DKIM records configured
4. Check spam folder

### 3+ fix attempts not working?

**STOP.** Look for a working reference implementation.
Don't iterate on broken foundation - step back and rethink.
