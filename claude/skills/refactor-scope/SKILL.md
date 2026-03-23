---
name: refactor-scope
description: Pre-refactor documentation and scoping. Prevents scope creep and ensures test coverage before changes.
---

# Refactor Scope

Document what you're changing and why BEFORE refactoring. Prevents runaway refactors and regressions.

## When to Use

- "Let's clean this up"
- "This code is messy"
- "We should refactor X"
- Touching code that works but isn't pretty
- Any change that doesn't add features or fix bugs

## The Rule

**Refactors should be boring.** If a refactor surprises you, scope was wrong.

From CLAUDE.md:
> Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.
> Don't add features, refactor code, or make "improvements" beyond what was asked.

## Pre-Refactor Documentation

Before any refactor, document:

```markdown
## Refactor: {Name}

### Why
{One sentence explaining why this refactor is needed}

### Scope
**Files to change:**
- `path/to/file1.ts` - {what's changing}
- `path/to/file2.ts` - {what's changing}

**Files NOT changing:**
- `path/to/related.ts` - {why leaving alone}

### Before State
{Brief description of current structure}

### After State
{Brief description of target structure}

### What's NOT Changing
- Behavior: {exactly the same inputs/outputs}
- API: {same function signatures}
- Tests: {should still pass}

### Test Coverage Check
- [ ] Existing tests cover this code
- [ ] Tests pass before refactor
- [ ] Tests will verify refactor didn't break anything
```

## Scope Boundaries

### In Scope (Allowed)

- Rename variables for clarity
- Extract function from long function
- Combine duplicate code
- Simplify conditionals
- Fix obvious code smells in touched code

### Out of Scope (Resist)

- "While I'm here, let me also..."
- Adding new features
- Changing behavior
- Updating unrelated files
- Adding new abstractions "for the future"
- Reformatting files you're not changing

## Test Coverage Requirements

**Before refactoring, verify tests exist:**

```bash
# Check if file has test coverage
grep -r "filename" tests/ __tests__/

# Run tests for the module
npm run test -- path/to/module.test.ts

# Check coverage
npm run test -- --coverage path/to/module.ts
```

**If no tests exist:**
1. Write tests FIRST (characterization tests)
2. Verify tests pass
3. Then refactor
4. Verify tests still pass

```typescript
// Characterization test - captures current behavior
describe('existingFunction', () => {
  it('returns expected output for known input', () => {
    // This test documents current behavior
    // If refactor breaks it, you'll know
    expect(existingFunction(input)).toEqual(currentOutput);
  });
});
```

## Refactor Patterns

### Extract Function

**Before:**
```typescript
function processOrder(order: Order) {
  // 50 lines of validation
  if (!order.items) throw new Error('No items');
  if (order.items.length === 0) throw new Error('Empty order');
  // ... more validation

  // 50 lines of calculation
  let total = 0;
  for (const item of order.items) {
    total += item.price * item.quantity;
  }
  // ... more calculation

  return { validated: true, total };
}
```

**After:**
```typescript
function validateOrder(order: Order): void {
  if (!order.items) throw new Error('No items');
  if (order.items.length === 0) throw new Error('Empty order');
  // ... validation
}

function calculateTotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

function processOrder(order: Order) {
  validateOrder(order);
  const total = calculateTotal(order.items);
  return { validated: true, total };
}
```

### Remove Duplication

**Before:**
```typescript
// In file1.ts
function formatUserName(user: User) {
  return `${user.firstName} ${user.lastName}`.trim();
}

// In file2.ts (duplicate!)
function getUserDisplayName(user: User) {
  return `${user.firstName} ${user.lastName}`.trim();
}
```

**After:**
```typescript
// In lib/format.ts
export function formatName(first: string, last: string): string {
  return `${first} ${last}`.trim();
}

// Usage in both files
import { formatName } from '@/lib/format';
formatName(user.firstName, user.lastName);
```

### Simplify Conditionals

**Before:**
```typescript
if (user.role === 'admin') {
  if (user.isActive) {
    if (user.hasPermission('delete')) {
      return true;
    }
  }
}
return false;
```

**After:**
```typescript
const isActiveAdmin = user.role === 'admin' && user.isActive;
const canDelete = isActiveAdmin && user.hasPermission('delete');
return canDelete;
```

## Anti-Patterns

❌ **Big bang refactor** - Changing everything at once
❌ **Refactor while fixing** - Mix bug fix with cleanup
❌ **Speculative generalization** - "We might need this later"
❌ **Refactor without tests** - Flying blind
❌ **Perfectionism** - "Just one more improvement..."

## Commit Strategy

Separate commits for refactors:

```bash
# Commit 1: Pure refactor (no behavior change)
git commit -m "Refactor: Extract validation from processOrder"

# Commit 2: The actual feature/fix (if any)
git commit -m "Add order discount calculation (#123)"
```

This way, if refactor breaks something, easy to revert.

## Output When Applied

```markdown
## Refactor Scope: {Name}

### Motivation
{Why this refactor is needed}

### Boundaries

**Changing:**
| File | Change | Risk |
|------|--------|------|
| `src/utils/order.ts` | Extract validation | Low |
| `src/utils/order.ts` | Extract calculation | Low |

**Not changing:**
- `src/api/orders/route.ts` - Uses order utils, but not touching
- `src/types/order.ts` - Types unchanged

### Test Status
- [x] Tests exist: `tests/unit/order.test.ts` (24 tests)
- [x] All tests passing before refactor
- [ ] Will verify after refactor

### Definition of Done
- [ ] All existing tests pass
- [ ] No new features added
- [ ] No behavior changes
- [ ] Committed separately from feature work

### Rollback
If refactor causes issues:
```bash
git revert {refactor-commit-hash}
```
```

## When to Say No

Refuse refactor if:
- No tests cover the code
- Scope keeps expanding
- It's blocking a feature/fix
- "While we're at it..." appears
- You can't explain the benefit in one sentence
