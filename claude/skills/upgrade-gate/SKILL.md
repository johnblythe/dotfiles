---
name: upgrade-gate
description: Free/paid tier UX patterns. Position CTAs at "moment of desire", show locked features with visual indicators.
---

# Upgrade Gate

Patterns for free/paid tier UX. From CLAUDE.md:
> Position at "moment of desire" not "moment of block"
> Show locked features with visual indicators (🔒, grayed), not errors
> Free tier must deliver real value, not be crippled demo

## Core Principles

### 1. Moment of Desire, Not Block

**Bad:** User hits wall, sees error
```
❌ "Upgrade to continue"
❌ "You've reached your limit"
❌ "This feature is not available on your plan"
```

**Good:** User sees value, wants more
```
✅ "You've used 3 of 5 free exports. Unlock unlimited →"
✅ "Love this? Get 10x more with Pro"
✅ "See what [feature] can do" + preview
```

### 2. Show, Don't Hide

**Bad:** Premium features invisible to free users
- User doesn't know what they're missing
- No motivation to upgrade

**Good:** Premium features visible but gated
- User sees the value
- Clear path to access
- Builds desire

### 3. Free Tier = Real Value

**Bad:** Crippled demo
- Frustrating limitations
- Basic features broken
- Feels like trial

**Good:** Genuinely useful free tier
- Core functionality works great
- Upgrades enhance, not enable
- Users succeed before upgrading

## Visual Patterns

### Locked Feature Indicator

```tsx
// Locked badge
<div className="relative">
  <FeatureCard />
  <div className="absolute top-2 right-2">
    <Badge variant="secondary" className="gap-1">
      <Lock className="w-3 h-3" />
      Pro
    </Badge>
  </div>
</div>

// Grayed with overlay
<div className="relative opacity-60 pointer-events-none">
  <FeatureCard />
  <div className="absolute inset-0 flex items-center justify-center bg-background/50">
    <Button>Unlock with Pro</Button>
  </div>
</div>
```

### Usage Meter

```tsx
// Progress toward limit
<div className="space-y-2">
  <div className="flex justify-between text-sm">
    <span>Exports this month</span>
    <span className={used >= limit ? 'text-amber-500' : ''}>
      {used} / {limit}
    </span>
  </div>
  <Progress value={(used / limit) * 100} />
  {used >= limit * 0.8 && (
    <p className="text-xs text-muted-foreground">
      Running low? <Link href="/upgrade">Get unlimited →</Link>
    </p>
  )}
</div>
```

### Feature Comparison

```tsx
// Inline comparison
<div className="grid grid-cols-2 gap-4">
  <div className="p-4 border rounded-lg">
    <h3 className="font-medium">Free</h3>
    <ul className="mt-2 space-y-1 text-sm">
      <li>✓ 5 projects</li>
      <li>✓ Basic analytics</li>
      <li className="text-muted-foreground">✗ Custom domains</li>
      <li className="text-muted-foreground">✗ Team members</li>
    </ul>
  </div>
  <div className="p-4 border-2 border-primary rounded-lg">
    <h3 className="font-medium">Pro</h3>
    <ul className="mt-2 space-y-1 text-sm">
      <li>✓ Unlimited projects</li>
      <li>✓ Advanced analytics</li>
      <li>✓ Custom domains</li>
      <li>✓ 5 team members</li>
    </ul>
    <Button className="w-full mt-4">Upgrade</Button>
  </div>
</div>
```

## Gate Placement

### Good Placement (Moment of Desire)

```tsx
// After successful action
<Dialog open={showUpgradePrompt}>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Nice work! 🎉</DialogTitle>
      <DialogDescription>
        You've created {count} programs. Want to unlock advanced features?
      </DialogDescription>
    </DialogHeader>
    <ul className="space-y-2">
      <li>📊 Detailed progress tracking</li>
      <li>🎯 Custom workout templates</li>
      <li>📱 Offline access</li>
    </ul>
    <DialogFooter>
      <Button variant="outline" onClick={dismiss}>Maybe later</Button>
      <Button onClick={upgrade}>See Pro features</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

### Bad Placement (Moment of Block)

```tsx
// ❌ Don't do this - frustrating
{!isPro && (
  <div className="text-red-500">
    Error: This feature requires Pro subscription.
    <Button>Upgrade now</Button>
  </div>
)}
```

## Implementation Patterns

### Feature Flag Check

```typescript
// lib/features.ts
export const FEATURES = {
  unlimitedProjects: 'pro',
  customDomains: 'pro',
  teamMembers: 'pro',
  analytics: 'free',        // Available to all
  advancedAnalytics: 'pro',
} as const;

export function hasFeature(
  userTier: 'free' | 'pro',
  feature: keyof typeof FEATURES
): boolean {
  const required = FEATURES[feature];
  if (required === 'free') return true;
  return userTier === 'pro';
}
```

### Upgrade Gate Component

```tsx
// components/upgrade-gate.tsx
interface UpgradeGateProps {
  feature: keyof typeof FEATURES;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export function UpgradeGate({ feature, children, fallback }: UpgradeGateProps) {
  const { user } = useAuth();
  const hasAccess = hasFeature(user?.tier ?? 'free', feature);

  if (hasAccess) {
    return <>{children}</>;
  }

  if (fallback) {
    return <>{fallback}</>;
  }

  return (
    <LockedFeature
      feature={feature}
      preview={children}
    />
  );
}

// Usage
<UpgradeGate feature="advancedAnalytics">
  <AdvancedAnalyticsDashboard />
</UpgradeGate>
```

### Soft Gate (Show Preview)

```tsx
// Show feature with upgrade prompt
function LockedFeature({ feature, preview }) {
  return (
    <div className="relative">
      {/* Blurred/dimmed preview */}
      <div className="opacity-50 blur-sm pointer-events-none">
        {preview}
      </div>

      {/* Overlay with CTA */}
      <div className="absolute inset-0 flex items-center justify-center">
        <Card className="p-6 text-center max-w-sm">
          <Lock className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
          <h3 className="font-medium">Unlock {featureNames[feature]}</h3>
          <p className="text-sm text-muted-foreground mt-1">
            {featureDescriptions[feature]}
          </p>
          <Button className="mt-4">
            Upgrade to Pro
          </Button>
        </Card>
      </div>
    </div>
  );
}
```

### Usage Limit Gate

```tsx
// Track and display usage
function UsageLimitGate({
  resource,
  limit,
  children,
  onLimitReached
}: Props) {
  const usage = useUsage(resource);
  const remaining = limit - usage.count;
  const nearLimit = remaining <= Math.ceil(limit * 0.2);

  if (usage.count >= limit) {
    return (
      <LimitReachedCard
        resource={resource}
        onUpgrade={onLimitReached}
      />
    );
  }

  return (
    <>
      {children}
      {nearLimit && (
        <UsageWarning remaining={remaining} resource={resource} />
      )}
    </>
  );
}
```

## Copy Guidelines

### Upgrade CTAs

**Positive framing:**
- "Unlock more"
- "Get unlimited"
- "Level up"
- "Go Pro"

**Avoid:**
- "Buy now"
- "Pay to access"
- "Restricted"
- "Not available"

### Limit Messages

**Before limit:**
```
"3 of 5 projects used"
"2 exports remaining this month"
```

**At limit:**
```
"You've maxed out your free projects! 🎉 Ready for unlimited?"
"This month's exports are used up. Unlock more?"
```

### Feature Descriptions

Focus on benefit, not feature:
- ❌ "Access to API"
- ✅ "Build custom integrations"

- ❌ "Team members feature"
- ✅ "Collaborate with your team"

## Anti-Patterns

❌ **Dark patterns**
- Hiding free options
- Pre-selected upsells
- Confusing pricing

❌ **Frustration-based**
- Error messages for gated features
- Constant popups
- Breaking core functionality

❌ **Invisible value**
- Not showing what Pro offers
- No previews
- Hidden pricing

## Checklist

When implementing upgrade gates:

- [ ] Free tier provides real standalone value
- [ ] Premium features visible to free users
- [ ] Visual indicators (🔒, badge) not errors
- [ ] CTAs at moment of desire, not block
- [ ] Preview/sample of premium features
- [ ] Easy dismissal of prompts
- [ ] Usage meters before limits hit
- [ ] Positive, not punitive copy
- [ ] Mobile-friendly gate UI
- [ ] A/B testable placement
