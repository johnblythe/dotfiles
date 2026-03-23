---
name: ui-exploration
description: Create isolated test pages for UI/UX experiments. Use when comparing design options before changing production code. Creates /dev routes with toggleable variants.
---

# UI Exploration Pages

Create isolated "dummy pages" to test and compare UI/UX designs before implementing in production.

## When to Use

- Comparing 2+ design approaches for a component
- User asks to "test" or "try out" different designs
- Before making visual changes to production components
- When discussing redesigns or polish work
- Referenced issue involves UI/UX improvement

## Rules

1. **Always create at least 3 options** - Current (reference) + 2 alternatives
2. **Create in `/dev` routes** - Isolated from production
3. **Include option switcher** - Easy A/B/C toggle at top
4. **Use real-ish data** - Not placeholder text
5. **Document trade-offs** - Each option describes pros/cons
6. **Mobile + Desktop** - Test both viewports
7. **Include test notes** - What to look for when evaluating

## File Structure

```
src/app/dev/
├── page.tsx              # Index of all exploration pages
├── [feature-name]/
│   └── page.tsx          # Multi-option test page
└── [another-feature]/
    └── page.tsx
```

## Page Template

```tsx
'use client';

import { useState } from 'react';

// Mock data matching production
const MOCK_DATA = [/* ... */];

// ============================================
// OPTION A: Current Design (Reference)
// ============================================
function OptionACurrent({ data }: { data: typeof MOCK_DATA }) {
  return (/* Current implementation */);
}

// ============================================
// OPTION B: [Descriptive Name]
// ============================================
function OptionBName({ data }: { data: typeof MOCK_DATA }) {
  return (/* Alternative implementation */);
}

// ============================================
// OPTION C: [Descriptive Name]
// ============================================
function OptionCName({ data }: { data: typeof MOCK_DATA }) {
  return (/* Another alternative */);
}

// ============================================
// Main Page
// ============================================
export default function FeatureExplorationPage() {
  const [activeOption, setActiveOption] = useState<'A' | 'B' | 'C'>('A');

  return (
    <div className="min-h-screen bg-[#F8FAFC] py-8 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <a href="/dev" className="text-sm text-[#94A3B8] hover:text-[#FF6B6B] mb-2 inline-block">← Back to Dev</a>
          <h1 className="text-2xl font-bold text-[#0F172A] mb-2">[Feature Name] - Design Options (#XXX)</h1>
          <p className="text-[#475569]">[Brief description of what's being tested]</p>
        </div>

        {/* Option Selector */}
        <div className="flex gap-2 mb-6 p-1 bg-white rounded-xl border border-[#E2E8F0]">
          {(['A', 'B', 'C'] as const).map((opt) => (
            <button
              key={opt}
              onClick={() => setActiveOption(opt)}
              className={`flex-1 py-2 px-4 rounded-lg font-medium text-sm transition-colors ${
                activeOption === opt
                  ? 'bg-[#0F172A] text-white'
                  : 'text-[#475569] hover:bg-[#F8FAFC]'
              }`}
            >
              Option {opt}
            </button>
          ))}
        </div>

        {/* Description */}
        <div className="mb-6 p-4 bg-white rounded-xl border border-[#E2E8F0]">
          {activeOption === 'A' && (
            <>
              <h3 className="font-semibold text-[#0F172A] mb-1">Option A: Current Design (Reference)</h3>
              <p className="text-sm text-[#475569]">[Description of current implementation]</p>
            </>
          )}
          {activeOption === 'B' && (
            <>
              <h3 className="font-semibold text-[#0F172A] mb-1">Option B: [Name]</h3>
              <p className="text-sm text-[#475569]">[What's different and why]</p>
            </>
          )}
          {activeOption === 'C' && (
            <>
              <h3 className="font-semibold text-[#0F172A] mb-1">Option C: [Name]</h3>
              <p className="text-sm text-[#475569]">[What's different and why]</p>
            </>
          )}
        </div>

        {/* Demo */}
        <div className="mb-8">
          {activeOption === 'A' && <OptionACurrent data={MOCK_DATA} />}
          {activeOption === 'B' && <OptionBName data={MOCK_DATA} />}
          {activeOption === 'C' && <OptionCName data={MOCK_DATA} />}
        </div>

        {/* Test Notes */}
        <div className="p-4 bg-[#FEF3C7]/50 rounded-xl border border-[#FEF3C7]">
          <h4 className="font-semibold text-[#92400E] mb-2">Test Notes</h4>
          <ul className="text-sm text-[#92400E] space-y-1">
            <li>• [What to focus on when evaluating]</li>
            <li>• [Specific interactions to test]</li>
            <li>• [Device/viewport considerations]</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
```

## Dev Index Page Template

Create `src/app/dev/page.tsx`:

```tsx
'use client';

import Link from 'next/link';

const DEV_PAGES = [
  {
    path: '/dev/feature-name',
    title: 'Feature Name (#XXX)',
    description: 'Brief description of exploration',
    status: 'ready' | 'wip',
  },
  // Add more as created
];

export default function DevIndexPage() {
  return (
    <div className="min-h-screen bg-[#0F172A] py-12 px-4">
      <div className="max-w-3xl mx-auto">
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-3 h-3 rounded-full bg-[#FF6B6B] animate-pulse" />
            <span className="text-xs text-[#FF6B6B] font-mono uppercase tracking-wider">Dev Mode</span>
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">UI Exploration Pages</h1>
          <p className="text-[#94A3B8]">
            Dummy pages for testing UI/UX changes before implementing in production.
          </p>
        </div>

        <div className="space-y-4">
          {DEV_PAGES.map((page) => (
            <Link
              key={page.path}
              href={page.path}
              className="block p-6 rounded-xl bg-[#1E293B] border border-[#334155] hover:border-[#FF6B6B]/50 transition-all group"
            >
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-white group-hover:text-[#FF6B6B] transition-colors mb-1">
                    {page.title}
                  </h2>
                  <p className="text-sm text-[#94A3B8]">{page.description}</p>
                </div>
                {page.status === 'ready' && (
                  <span className="text-xs px-2 py-1 rounded-full bg-emerald-500/20 text-emerald-400">
                    Ready
                  </span>
                )}
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
```

## Design Option Patterns

### When comparing visual treatments:
- Option A: Current (reference baseline)
- Option B: Subtle refinement (small changes)
- Option C: Bold redesign (bigger change)

### When comparing layouts:
- Option A: Current layout
- Option B: Different structure
- Option C: Alternative flow

### When comparing interactions:
- Include motion/animation differences
- Test click/tap targets
- Show expanded/collapsed states

## Evaluation Checklist

After creating exploration page, verify:

- [ ] Current design included as Option A
- [ ] 2+ alternatives with clear differentiation
- [ ] Each option has description explaining approach
- [ ] Mock data is realistic
- [ ] Works on mobile viewport
- [ ] Test notes explain what to evaluate
- [ ] Link to related GitHub issue in title

## Workflow

1. User asks to compare designs or polish UI
2. Create `/dev/[feature]/page.tsx` with options
3. Add to dev index page
4. Share URL: `localhost:3001/dev/[feature]`
5. Get feedback, iterate
6. Once approved, implement winner in production
7. Optionally remove dev page (or keep for reference)

## Naming Conventions

- Route: `/dev/[component-or-feature]`
- File: `src/app/dev/[component-or-feature]/page.tsx`
- Options: Always A = Current, B/C/D = Alternatives
- Include issue number in page title when available
