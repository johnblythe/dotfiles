---
name: stripe-payments
description: Sets up Stripe payments in Next.js projects. Covers one-time payments, subscriptions, webhooks, and customer portal.
---

# Stripe Payments Setup

## Ask First

1. **Payment model?**
   - One-time payments (checkout sessions)
   - Subscriptions (recurring billing)
   - Both

2. **Need customer portal?** (manage subscriptions, update payment method)

3. **Pricing tiers?** (helps set up products/prices)

## Install

```bash
npm install stripe @stripe/stripe-js
```

## Environment Variables

```env
# Secret key (server-side only)
STRIPE_SECRET_KEY=sk_test_xxxxx

# Publishable key (client-safe)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx

# Webhook secret (from Stripe dashboard or CLI)
STRIPE_WEBHOOK_SECRET=whsec_xxxxx

# For customer portal redirects
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

## Core Setup

### Stripe Server Client

Create `lib/stripe.ts`:

```typescript
import Stripe from "stripe";

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2024-06-20",
  typescript: true,
});
```

### Stripe Client (Browser)

Create `lib/stripe-client.ts`:

```typescript
import { loadStripe } from "@stripe/stripe-js";

export const getStripe = () => {
  return loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!);
};
```

## One-Time Payments

### Create Checkout Session API Route

Create `app/api/checkout/route.ts`:

```typescript
import { stripe } from "@/lib/stripe";
import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  try {
    const { priceId, quantity = 1 } = await request.json();

    // Optional: Get user for metadata
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      line_items: [
        {
          price: priceId,
          quantity,
        },
      ],
      success_url: `${process.env.NEXT_PUBLIC_SITE_URL}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.NEXT_PUBLIC_SITE_URL}/checkout/cancel`,
      metadata: {
        userId: user?.id || "",
      },
    });

    return NextResponse.json({ url: session.url });
  } catch (error) {
    console.error("Checkout error:", error);
    return NextResponse.json(
      { error: "Failed to create checkout session" },
      { status: 500 }
    );
  }
}
```

### Checkout Button Component

```tsx
"use client";

import { useState } from "react";
import { getStripe } from "@/lib/stripe-client";

export function CheckoutButton({ priceId }: { priceId: string }) {
  const [loading, setLoading] = useState(false);

  const handleCheckout = async () => {
    setLoading(true);
    try {
      const response = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ priceId }),
      });

      const { url } = await response.json();
      window.location.href = url;
    } catch (error) {
      console.error("Checkout error:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button onClick={handleCheckout} disabled={loading}>
      {loading ? "Loading..." : "Buy Now"}
    </button>
  );
}
```

## Subscriptions

### Create Subscription Checkout

Create `app/api/subscribe/route.ts`:

```typescript
import { stripe } from "@/lib/stripe";
import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  try {
    const { priceId } = await request.json();

    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Get or create Stripe customer
    let customerId = await getStripeCustomerId(user.id);

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { userId: user.id },
      });
      customerId = customer.id;
      await saveStripeCustomerId(user.id, customerId);
    }

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${process.env.NEXT_PUBLIC_SITE_URL}/dashboard?success=true`,
      cancel_url: `${process.env.NEXT_PUBLIC_SITE_URL}/pricing`,
      subscription_data: {
        metadata: { userId: user.id },
      },
    });

    return NextResponse.json({ url: session.url });
  } catch (error) {
    console.error("Subscription error:", error);
    return NextResponse.json(
      { error: "Failed to create subscription" },
      { status: 500 }
    );
  }
}

// Implement these based on your DB setup (Prisma/Drizzle/Supabase)
async function getStripeCustomerId(userId: string): Promise<string | null> {
  // TODO: Query your database
  return null;
}

async function saveStripeCustomerId(userId: string, customerId: string) {
  // TODO: Save to your database
}
```

### Database Schema Addition

For Prisma, add to schema:

```prisma
model User {
  id               String   @id
  stripeCustomerId String?  @unique @map("stripe_customer_id")
  subscriptionId   String?  @map("subscription_id")
  subscriptionStatus String? @map("subscription_status")
  priceId          String?  @map("price_id")
  currentPeriodEnd DateTime? @map("current_period_end")

  @@map("users")
}
```

For Drizzle:

```typescript
export const users = pgTable("users", {
  id: text("id").primaryKey(),
  stripeCustomerId: text("stripe_customer_id").unique(),
  subscriptionId: text("subscription_id"),
  subscriptionStatus: text("subscription_status"),
  priceId: text("price_id"),
  currentPeriodEnd: timestamp("current_period_end"),
});
```

## Webhooks

### Webhook Handler

Create `app/api/webhooks/stripe/route.ts`:

```typescript
import { stripe } from "@/lib/stripe";
import { headers } from "next/headers";
import { NextResponse } from "next/server";
import Stripe from "stripe";

export async function POST(request: Request) {
  const body = await request.text();
  const headersList = await headers();
  const signature = headersList.get("stripe-signature")!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (error) {
    console.error("Webhook signature verification failed");
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        await handleCheckoutComplete(session);
        break;
      }

      case "customer.subscription.created":
      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        await handleSubscriptionChange(subscription);
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        await handleSubscriptionCanceled(subscription);
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        await handlePaymentFailed(invoice);
        break;
      }
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error("Webhook handler error:", error);
    return NextResponse.json(
      { error: "Webhook handler failed" },
      { status: 500 }
    );
  }
}

async function handleCheckoutComplete(session: Stripe.Checkout.Session) {
  const userId = session.metadata?.userId;
  if (!userId) return;

  if (session.mode === "subscription") {
    // Subscription will be handled by subscription.created event
    return;
  }

  // Handle one-time payment
  // TODO: Grant access, send confirmation email, etc.
  console.log(`One-time payment completed for user ${userId}`);
}

async function handleSubscriptionChange(subscription: Stripe.Subscription) {
  const userId = subscription.metadata.userId;
  if (!userId) return;

  // TODO: Update user's subscription status in database
  const update = {
    subscriptionId: subscription.id,
    subscriptionStatus: subscription.status,
    priceId: subscription.items.data[0]?.price.id,
    currentPeriodEnd: new Date(subscription.current_period_end * 1000),
  };

  console.log(`Subscription updated for user ${userId}:`, update);
  // await db.user.update({ where: { id: userId }, data: update });
}

async function handleSubscriptionCanceled(subscription: Stripe.Subscription) {
  const userId = subscription.metadata.userId;
  if (!userId) return;

  // TODO: Revoke access, send cancellation email
  console.log(`Subscription canceled for user ${userId}`);
}

async function handlePaymentFailed(invoice: Stripe.Invoice) {
  const customerId = invoice.customer as string;
  // TODO: Notify user of failed payment
  console.log(`Payment failed for customer ${customerId}`);
}
```

## Customer Portal

### Portal Session API

Create `app/api/portal/route.ts`:

```typescript
import { stripe } from "@/lib/stripe";
import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST() {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const customerId = await getStripeCustomerId(user.id);

    if (!customerId) {
      return NextResponse.json(
        { error: "No billing account found" },
        { status: 400 }
      );
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${process.env.NEXT_PUBLIC_SITE_URL}/dashboard`,
    });

    return NextResponse.json({ url: session.url });
  } catch (error) {
    console.error("Portal error:", error);
    return NextResponse.json(
      { error: "Failed to create portal session" },
      { status: 500 }
    );
  }
}

async function getStripeCustomerId(userId: string): Promise<string | null> {
  // TODO: Query your database
  return null;
}
```

### Portal Button

```tsx
"use client";

export function ManageSubscriptionButton() {
  const handleClick = async () => {
    const response = await fetch("/api/portal", { method: "POST" });
    const { url } = await response.json();
    window.location.href = url;
  };

  return <button onClick={handleClick}>Manage Subscription</button>;
}
```

## Subscription Status Check

### Helper Function

```typescript
// lib/subscription.ts
import { createClient } from "@/lib/supabase/server";

export async function getSubscription() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return null;

  // TODO: Fetch from your database
  // const subscription = await db.user.findUnique({
  //   where: { id: user.id },
  //   select: { subscriptionStatus: true, priceId: true, currentPeriodEnd: true }
  // });

  return null;
}

export async function hasActiveSubscription(): Promise<boolean> {
  const subscription = await getSubscription();
  return subscription?.subscriptionStatus === "active";
}
```

### Protect Routes/Features

```typescript
// In a Server Component
import { hasActiveSubscription } from "@/lib/subscription";
import { redirect } from "next/navigation";

export default async function PremiumPage() {
  const isSubscribed = await hasActiveSubscription();

  if (!isSubscribed) {
    redirect("/pricing");
  }

  return <div>Premium content here</div>;
}
```

## Local Development

### Stripe CLI for Webhooks

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to localhost
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Copy the webhook signing secret (whsec_...) to .env.local
```

### Test Cards

- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- Requires auth: `4000 0025 0000 3155`

## Stripe Dashboard Setup

1. **Create Products** at stripe.com/dashboard/products
2. **Add Prices** (one-time or recurring)
3. **Configure Customer Portal** at stripe.com/dashboard/settings/billing/portal
4. **Add Webhook Endpoint** at stripe.com/dashboard/webhooks
   - URL: `https://yourdomain.com/api/webhooks/stripe`
   - Events: `checkout.session.completed`, `customer.subscription.*`, `invoice.payment_failed`

## Checklist

- [ ] Stripe account created
- [ ] Dependencies installed (stripe, @stripe/stripe-js)
- [ ] Environment variables set
- [ ] Stripe server client created
- [ ] Checkout/subscription routes created
- [ ] Webhook handler implemented
- [ ] Database schema updated for Stripe fields
- [ ] Customer portal configured (if subscriptions)
- [ ] Products/prices created in Stripe dashboard
- [ ] Webhook endpoint added in Stripe dashboard
- [ ] Local webhook forwarding tested with Stripe CLI
