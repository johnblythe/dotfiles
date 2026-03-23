---
name: analytics-setup
description: Sets up analytics in Next.js projects. Covers Vercel Analytics, Google Analytics 4, PostHog, and Plausible.
---

# Analytics Setup

## Ask First

1. **What do you need to track?**
   - Page views / traffic
   - Custom events (button clicks, form submissions)
   - User behavior / funnels
   - Feature flags / A/B testing

2. **Privacy requirements?**
   - GDPR compliance needed?
   - Cookie consent required?
   - Privacy-first (Plausible, PostHog self-host)

3. **Budget?**
   - Free: Vercel Analytics, GA4
   - Paid: PostHog Cloud, Plausible

---

## Option A: Vercel Analytics + Speed Insights (Simplest)

Best for: Basic traffic analytics on Vercel deployments.

### Install

```bash
npm install @vercel/analytics @vercel/speed-insights
```

### Setup

Update `app/layout.tsx`:

```tsx
import { Analytics } from "@vercel/analytics/react";
import { SpeedInsights } from "@vercel/speed-insights/next";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

### Custom Events

```typescript
import { track } from "@vercel/analytics";

// Track custom event
track("button_clicked", {
  button: "signup",
  location: "header",
});

// Track with component
<button onClick={() => track("cta_clicked", { variant: "primary" })}>
  Sign Up
</button>
```

### Enable in Vercel Dashboard

1. Go to project settings
2. Analytics tab
3. Enable Analytics
4. Enable Speed Insights (optional)

---

## Option B: Google Analytics 4

Best for: Comprehensive analytics, free, familiar.

### Environment

```env
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
```

### Script Component

Create `components/analytics/google-analytics.tsx`:

```tsx
"use client";

import Script from "next/script";
import { usePathname, useSearchParams } from "next/navigation";
import { useEffect, Suspense } from "react";

const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID;

function GoogleAnalyticsInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    if (!GA_MEASUREMENT_ID) return;

    const url = pathname + searchParams.toString();
    window.gtag?.("config", GA_MEASUREMENT_ID, {
      page_path: url,
    });
  }, [pathname, searchParams]);

  return null;
}

export function GoogleAnalytics() {
  if (!GA_MEASUREMENT_ID) return null;

  return (
    <>
      <Script
        strategy="afterInteractive"
        src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
      />
      <Script
        id="google-analytics"
        strategy="afterInteractive"
        dangerouslySetInnerHTML={{
          __html: `
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '${GA_MEASUREMENT_ID}');
          `,
        }}
      />
      <Suspense fallback={null}>
        <GoogleAnalyticsInner />
      </Suspense>
    </>
  );
}
```

### Add to Layout

```tsx
import { GoogleAnalytics } from "@/components/analytics/google-analytics";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <GoogleAnalytics />
      </body>
    </html>
  );
}
```

### Track Events

Create `lib/analytics.ts`:

```typescript
type GTagEvent = {
  action: string;
  category: string;
  label?: string;
  value?: number;
};

export function trackEvent({ action, category, label, value }: GTagEvent) {
  if (typeof window === "undefined" || !window.gtag) return;

  window.gtag("event", action, {
    event_category: category,
    event_label: label,
    value: value,
  });
}

// Typed event helpers
export const analytics = {
  buttonClick: (buttonName: string, location: string) => {
    trackEvent({
      action: "click",
      category: "button",
      label: `${buttonName}_${location}`,
    });
  },

  formSubmit: (formName: string) => {
    trackEvent({
      action: "submit",
      category: "form",
      label: formName,
    });
  },

  purchase: (value: number, itemId: string) => {
    trackEvent({
      action: "purchase",
      category: "ecommerce",
      label: itemId,
      value,
    });
  },

  signUp: (method: string) => {
    trackEvent({
      action: "sign_up",
      category: "engagement",
      label: method,
    });
  },
};
```

### TypeScript Declaration

Add to `types/global.d.ts`:

```typescript
declare global {
  interface Window {
    gtag?: (
      command: "config" | "event" | "js",
      targetId: string | Date,
      config?: Record<string, unknown>
    ) => void;
    dataLayer?: unknown[];
  }
}

export {};
```

---

## Option C: PostHog (Feature-Rich)

Best for: Product analytics, feature flags, session replay, A/B testing.

### Install

```bash
npm install posthog-js
```

### Environment

```env
NEXT_PUBLIC_POSTHOG_KEY=phc_xxxxx
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
```

### Provider

Create `components/analytics/posthog-provider.tsx`:

```tsx
"use client";

import posthog from "posthog-js";
import { PostHogProvider as PHProvider } from "posthog-js/react";
import { useEffect } from "react";

export function PostHogProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    if (!process.env.NEXT_PUBLIC_POSTHOG_KEY) return;

    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST,
      person_profiles: "identified_only",
      capture_pageview: false, // We'll handle manually for App Router
      capture_pageleave: true,
    });
  }, []);

  return <PHProvider client={posthog}>{children}</PHProvider>;
}
```

### Page View Tracking

Create `components/analytics/posthog-pageview.tsx`:

```tsx
"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { useEffect, Suspense } from "react";
import { usePostHog } from "posthog-js/react";

function PostHogPageViewInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const posthog = usePostHog();

  useEffect(() => {
    if (pathname && posthog) {
      let url = window.origin + pathname;
      if (searchParams.toString()) {
        url += `?${searchParams.toString()}`;
      }
      posthog.capture("$pageview", { $current_url: url });
    }
  }, [pathname, searchParams, posthog]);

  return null;
}

export function PostHogPageView() {
  return (
    <Suspense fallback={null}>
      <PostHogPageViewInner />
    </Suspense>
  );
}
```

### Add to Layout

```tsx
import { PostHogProvider } from "@/components/analytics/posthog-provider";
import { PostHogPageView } from "@/components/analytics/posthog-pageview";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <PostHogProvider>
          <PostHogPageView />
          {children}
        </PostHogProvider>
      </body>
    </html>
  );
}
```

### Track Events

```tsx
"use client";

import { usePostHog } from "posthog-js/react";

export function SignUpButton() {
  const posthog = usePostHog();

  return (
    <button
      onClick={() => {
        posthog.capture("signup_clicked", {
          location: "header",
          variant: "primary",
        });
      }}
    >
      Sign Up
    </button>
  );
}
```

### Identify Users

```typescript
import { usePostHog } from "posthog-js/react";

// After login
const posthog = usePostHog();
posthog.identify(user.id, {
  email: user.email,
  name: user.name,
  plan: user.plan,
});

// On logout
posthog.reset();
```

### Feature Flags

```tsx
"use client";

import { useFeatureFlagEnabled } from "posthog-js/react";

export function NewFeature() {
  const showNewFeature = useFeatureFlagEnabled("new-feature");

  if (!showNewFeature) return null;

  return <div>New Feature!</div>;
}
```

### Server-Side Feature Flags

```typescript
import { PostHog } from "posthog-node";

const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: process.env.NEXT_PUBLIC_POSTHOG_HOST,
});

export async function getFeatureFlag(userId: string, flag: string) {
  const isEnabled = await posthog.isFeatureEnabled(flag, userId);
  return isEnabled;
}
```

---

## Option D: Plausible (Privacy-First)

Best for: Simple, privacy-focused, GDPR-compliant without consent.

### Script Method

```tsx
import Script from "next/script";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Script
          defer
          data-domain="yourdomain.com"
          src="https://plausible.io/js/script.js"
        />
      </body>
    </html>
  );
}
```

### Custom Events

```typescript
declare global {
  interface Window {
    plausible?: (event: string, options?: { props?: Record<string, string> }) => void;
  }
}

export function trackEvent(event: string, props?: Record<string, string>) {
  window.plausible?.(event, { props });
}

// Usage
trackEvent("Signup", { method: "google" });
```

---

## Dual Analytics Wrapper

Combine Vercel + GA4 (common pattern):

Create `lib/analytics.ts`:

```typescript
import { track as vercelTrack } from "@vercel/analytics";

const GA_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID;

export function trackEvent(
  name: string,
  properties?: Record<string, string | number>
) {
  // Vercel Analytics
  vercelTrack(name, properties);

  // Google Analytics
  if (typeof window !== "undefined" && window.gtag && GA_ID) {
    window.gtag("event", name, properties);
  }
}

// Typed helpers
export const analytics = {
  pageView: (url: string) => {
    if (window.gtag && GA_ID) {
      window.gtag("config", GA_ID, { page_path: url });
    }
  },

  signUp: (method: string) => {
    trackEvent("sign_up", { method });
  },

  buttonClick: (button: string, location: string) => {
    trackEvent("button_click", { button, location });
  },

  purchase: (value: number, currency: string = "USD") => {
    trackEvent("purchase", { value, currency });
  },

  featureUsed: (feature: string) => {
    trackEvent("feature_used", { feature });
  },
};
```

---

## Cookie Consent (GDPR)

Simple consent banner pattern:

```tsx
"use client";

import { useState, useEffect } from "react";

export function CookieConsent() {
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    const consent = localStorage.getItem("cookie-consent");
    if (!consent) setShowBanner(true);
  }, []);

  const acceptAll = () => {
    localStorage.setItem("cookie-consent", "all");
    setShowBanner(false);
    // Initialize analytics here if waiting for consent
  };

  const acceptNecessary = () => {
    localStorage.setItem("cookie-consent", "necessary");
    setShowBanner(false);
  };

  if (!showBanner) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t p-4 shadow-lg">
      <div className="max-w-4xl mx-auto flex items-center justify-between gap-4">
        <p className="text-sm">
          We use cookies to improve your experience. 
        </p>
        <div className="flex gap-2">
          <button
            onClick={acceptNecessary}
            className="px-4 py-2 text-sm border rounded"
          >
            Necessary Only
          </button>
          <button
            onClick={acceptAll}
            className="px-4 py-2 text-sm bg-black text-white rounded"
          >
            Accept All
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## Comparison

| Feature | Vercel | GA4 | PostHog | Plausible |
|---------|--------|-----|---------|-----------|
| Setup | Easiest | Easy | Medium | Easy |
| Pricing | Free* | Free | Free tier | Paid |
| Privacy | Good | Needs consent | Configurable | No consent needed |
| Custom events | Yes | Yes | Yes | Yes |
| Feature flags | No | No | Yes | No |
| Session replay | No | No | Yes | No |
| A/B testing | No | Limited | Yes | No |
| Self-host | No | No | Yes | Yes |

*Vercel Analytics free tier has limits

---

## Checklist

### Vercel Analytics
- [ ] Package installed
- [ ] Component added to layout
- [ ] Enabled in Vercel dashboard

### Google Analytics
- [ ] Measurement ID obtained
- [ ] Script component created
- [ ] Added to layout
- [ ] Custom events helper created
- [ ] TypeScript declarations added

### PostHog
- [ ] Package installed
- [ ] Project created, keys obtained
- [ ] Provider created
- [ ] Page view tracking added
- [ ] User identification set up
- [ ] Feature flags configured (optional)

### General
- [ ] Cookie consent banner (if required)
- [ ] Privacy policy updated
- [ ] Test events firing in dev
