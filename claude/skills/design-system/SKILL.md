---
name: design-system
description: Per-project design tokens, patterns, and component conventions. Use when building UI to ensure consistency.
---

# Design System

Project-specific design tokens and patterns. This skill provides the foundation for consistent UI across a project.

## When to Use

- Building new UI components
- Styling existing components
- Reviewing design consistency
- Onboarding to a project's visual language

## How to Use

This is a **template skill**. Each project should have its own design system documented. When working on a project:

1. Check if project has `DESIGN_SYSTEM.md` or similar in root
2. If not, extract patterns from existing code
3. Document discovered patterns here for reuse

## Design System Template

Create `DESIGN_SYSTEM.md` in project root:

```markdown
# {Project} Design System

## Color Palette

### Primary Colors
```css
--primary: {hsl value};        /* Main brand color */
--primary-foreground: {hsl};   /* Text on primary */
```

### Semantic Colors
```css
--background: {hsl};           /* Page background */
--foreground: {hsl};           /* Default text */
--card: {hsl};                 /* Card backgrounds */
--card-foreground: {hsl};      /* Text on cards */
--muted: {hsl};                /* Muted backgrounds */
--muted-foreground: {hsl};     /* Muted text */
--accent: {hsl};               /* Accent elements */
--destructive: {hsl};          /* Errors, delete actions */
--border: {hsl};               /* Borders */
```

### Project-Specific Colors
```css
/* Example from baisics v2a: */
--navy: #0F172A;               /* CTAs only, not backgrounds */
--coral: #FF6B6B;              /* Accent borders, hover states */
--slate: #94A3B8;              /* Muted text */
```

## Typography

### Font Stack
```css
--font-sans: {font family};
--font-mono: {font family};    /* Code, numbers */
```

### Scale
| Name | Size | Weight | Use Case |
|------|------|--------|----------|
| h1 | 2.5rem | 700 | Page titles |
| h2 | 1.875rem | 600 | Section headers |
| h3 | 1.5rem | 600 | Card titles |
| body | 1rem | 400 | Default text |
| small | 0.875rem | 400 | Secondary text |
| xs | 0.75rem | 500 | Labels, badges |

## Spacing

Use consistent spacing scale:
```
4px  (1)   - Tight spacing
8px  (2)   - Default gap
12px (3)   - Comfortable gap
16px (4)   - Section spacing
24px (6)   - Large spacing
32px (8)   - Section margins
48px (12)  - Page sections
```

## Border Radius

```css
--radius-sm: 0.25rem;   /* 4px - inputs, small elements */
--radius: 0.5rem;       /* 8px - cards, buttons */
--radius-lg: 0.75rem;   /* 12px - modals, large cards */
--radius-full: 9999px;  /* Pills, avatars */
```

## Shadows

```css
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
--shadow: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
--shadow-md: 0 4px 6px rgba(0,0,0,0.1), 0 2px 4px rgba(0,0,0,0.06);
--shadow-lg: 0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05);
```

## Component Patterns

### Cards
```tsx
<div className="bg-card rounded-lg border shadow-sm p-4">
  {/* Standard card */}
</div>

<div className="bg-white border-l-4 border-l-primary rounded-lg shadow-md p-4">
  {/* Accent card (left border) */}
</div>
```

### Buttons
```tsx
// Primary
<Button className="bg-primary text-primary-foreground">Action</Button>

// Secondary
<Button variant="outline">Secondary</Button>

// Destructive
<Button variant="destructive">Delete</Button>
```

### Form Inputs
```tsx
<Input className="border-border focus:ring-2 focus:ring-primary/20" />
```

### Status Indicators
| Status | Color | Use |
|--------|-------|-----|
| Success | green-500 | Completed, confirmed |
| Warning | amber-500 | Attention needed |
| Error | red-500 | Failures, destructive |
| Info | blue-500 | Informational |
| Muted | slate-400 | Disabled, inactive |

## Layout Patterns

### Page Structure
```tsx
// Standard page
<main className="container mx-auto px-4 py-8">
  <h1 className="text-2xl font-bold mb-6">{title}</h1>
  {content}
</main>
```

### Grid Layouts
```tsx
// Responsive grid
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">

// Sidebar + content (desktop)
<div className="flex">
  <aside className="w-64 shrink-0">{sidebar}</aside>
  <main className="flex-1">{content}</main>
</div>
```

### Avoid (per CLAUDE.md)
- 100% width vertical stacking for multi-component pages
- Full-screen single columns on desktop
- Making user scroll to see both input and output

## Animation

### Transitions
```css
--transition-fast: 150ms ease;
--transition: 200ms ease;
--transition-slow: 300ms ease;
```

### Hover States
```tsx
className="hover:bg-accent/10 transition-colors"
className="hover:scale-[1.02] transition-transform"
className="hover:shadow-md transition-shadow"
```

### Motion Preferences
```tsx
// Respect reduce-motion
className="motion-safe:animate-bounce"
```

## Dark Mode (if applicable)

```css
.dark {
  --background: {dark bg};
  --foreground: {light text};
  --card: {dark card};
  /* etc */
}
```
```

## Extracting Patterns from Existing Code

When joining a project, run these to discover patterns:

```bash
# Find color usage
grep -rh "bg-\[#\|text-\[#\|border-\[#" --include="*.tsx" | sort | uniq -c | sort -rn

# Find common class patterns
grep -roh 'className="[^"]*"' --include="*.tsx" | sort | uniq -c | sort -rn | head -30

# Check for CSS variables
grep -r "var(--" --include="*.css" --include="*.tsx"

# Find globals.css
cat app/globals.css styles/globals.css 2>/dev/null
```

## Integration with frontend-design Skill

If project has specific `frontend-design` skill (like Treehouse), that takes precedence for brand-specific patterns. This skill provides the structural foundation.

## Checklist for New Projects

- [ ] Primary color defined
- [ ] Background/foreground colors set
- [ ] Typography scale documented
- [ ] Spacing scale consistent
- [ ] Border radius consistent
- [ ] Shadow scale defined
- [ ] Card pattern established
- [ ] Button variants defined
- [ ] Form input styling consistent
- [ ] Status colors assigned
- [ ] Transition speeds defined
- [ ] Layout patterns documented
