---
name: test-first
description: Enforce TDD for bug fixes. Reproduce → write failing test → fix → verify. Prevents regression and proves the fix works.
---

# Test-First Bug Fixing

For bug fixes, write the failing test BEFORE the fix. This proves the bug exists and the fix works.

## When to Use

- Bug reports
- Regression issues
- "It used to work" problems
- Any fix that could break again

## The Rule

```
1. Reproduce the bug
2. Write a failing test that captures the bug
3. Fix the bug
4. Verify test passes
5. Commit test + fix together
```

**Never commit a fix without a test that would have caught the bug.**

## Workflow

### Step 1: Reproduce

Before writing any code:

```markdown
## Bug Reproduction

**Reported behavior:** {what user said}
**Steps to reproduce:**
1. {step 1}
2. {step 2}
3. {step 3}

**Expected:** {what should happen}
**Actual:** {what happens instead}

**Reproduced locally:** ✅ Yes / ❌ No
```

If you can't reproduce, STOP. Ask for more details.

### Step 2: Write Failing Test

Create test that captures the exact bug:

```typescript
// tests/unit/feature.test.ts

describe('featureName', () => {
  it('should handle edge case that was broken', () => {
    // Arrange - set up the buggy scenario
    const input = { /* exact data that causes bug */ };

    // Act - call the function
    const result = functionUnderTest(input);

    // Assert - what SHOULD happen
    expect(result).toBe(expectedValue);
  });
});
```

**Run the test - it MUST fail.**

```bash
npm run test -- tests/unit/feature.test.ts
```

If test passes, you haven't captured the bug correctly.

### Step 3: Fix the Bug

Now fix the code. Keep the fix minimal:
- Only change what's necessary
- Don't refactor surrounding code
- Don't add unrelated improvements

### Step 4: Verify

Run the test again:

```bash
npm run test -- tests/unit/feature.test.ts
```

**Test must pass now.**

Also run full test suite to check for regressions:

```bash
npm run test
```

### Step 5: Commit Together

Commit test and fix in same commit:

```bash
git add tests/unit/feature.test.ts src/feature.ts
git commit -m "Fix edge case in feature (#issue-number)

Add test for edge case, fix handling of X when Y."
```

## Test Naming Conventions

Use descriptive names that explain the bug:

```typescript
// ❌ Bad - vague
it('should work correctly')
it('handles edge case')

// ✅ Good - describes the scenario
it('should return empty array when input is null')
it('should preserve order when exercises have same category')
it('should use next year when date is in past')
```

## Test Structure

### Unit Test Template

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { functionUnderTest } from '@/path/to/module';

describe('functionUnderTest', () => {
  describe('when [condition]', () => {
    it('should [expected behavior]', () => {
      // Arrange
      const input = {};

      // Act
      const result = functionUnderTest(input);

      // Assert
      expect(result).toEqual(expected);
    });
  });

  describe('edge cases', () => {
    it('should handle null input', () => {
      expect(() => functionUnderTest(null)).toThrow();
    });

    it('should handle empty array', () => {
      expect(functionUnderTest([])).toEqual([]);
    });
  });
});
```

### Integration Test Template

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest';

describe('Feature Integration', () => {
  beforeAll(async () => {
    // Setup: seed data, start server, etc.
  });

  afterAll(async () => {
    // Cleanup
  });

  it('should complete full workflow', async () => {
    // Test the full flow
  });
});
```

## Common Bug Categories

### Data Handling
```typescript
it('should handle undefined optional fields', () => {
  const input = { required: 'value' }; // missing optional
  expect(() => process(input)).not.toThrow();
});

it('should coerce string numbers to integers', () => {
  expect(parseInput('42')).toBe(42);
});
```

### Array/Object Edge Cases
```typescript
it('should return empty array for empty input', () => {
  expect(processItems([])).toEqual([]);
});

it('should handle single item array', () => {
  expect(processItems([1])).toEqual([1]);
});
```

### Async/Timing
```typescript
it('should resolve after delay', async () => {
  const result = await asyncOperation();
  expect(result).toBeDefined();
});

it('should timeout after 5 seconds', async () => {
  await expect(slowOperation()).rejects.toThrow('timeout');
});
```

### Date/Time
```typescript
it('should use next occurrence for past dates', () => {
  // Mock current date
  vi.setSystemTime(new Date('2025-02-01'));

  const result = parseDate('January 15');
  expect(result.getFullYear()).toBe(2026); // next January
});
```

## Anti-Patterns

❌ **Fix first, test later** - Test might not capture the actual bug
❌ **Test passes before fix** - You didn't capture the bug
❌ **Too broad test** - Test should be specific to the bug
❌ **Skip test for "simple" fixes** - Simple fixes still regress
❌ **Mock too much** - Test should exercise real behavior

## Test File Organization

```
tests/
  unit/           # Fast, isolated tests
    schema.test.ts
    utils.test.ts
  integration/    # Slower, full-stack tests
    api.test.ts
    workflow.test.ts
  fixtures/       # Shared test data
    users.json
    programs.json
```

## Quick Commands

```bash
# Run single test file
npm run test -- tests/unit/specific.test.ts

# Run tests matching pattern
npm run test -- -t "should handle null"

# Run with coverage
npm run test -- --coverage

# Watch mode during development
npm run test:watch
```

## Output When Applied

```markdown
## Test-First Bug Fix

**Bug:** {description}

**Reproduction:**
✅ Reproduced locally with: {steps}

**Test added:**
`tests/unit/{file}.test.ts` - "{test name}"

**Test status:**
- Before fix: ❌ FAIL
- After fix: ✅ PASS
- Full suite: ✅ 267 passed

**Files changed:**
- `tests/unit/{file}.test.ts` (new test)
- `src/{file}.ts` (fix)

Ready to commit test + fix together.
```
