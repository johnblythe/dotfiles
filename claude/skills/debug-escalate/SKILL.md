---
name: debug-escalate
description: Triggered after 3+ failed fix attempts. Systematic escalation to find working solutions. Prevents "push and pray" loops.
---

# Debug Escalate

Stop spinning. Find a working reference. This skill triggers when you've tried 3+ approaches and the problem persists.

## When to Use (Automatic Trigger)

Use this skill when:
- 3+ fix attempts haven't resolved the issue
- Same error keeps appearing with variations
- You're about to try "one more thing"
- You catch yourself thinking "this should work"

**Red flag phrases:**
- "Let me try..."
- "Maybe if we..."
- "One more attempt..."
- "This is strange..."

## The Rule

From CLAUDE.md:
> If 3+ attempts don't fix something: STOP. Look for working reference impl.
> "Push and pray" = sign you don't understand the problem.

## Escalation Steps

### Step 1: STOP and Document

Before trying anything else:

```markdown
## Debug Status

**Problem:** {one sentence}
**Attempts so far:**
1. {what you tried} → {what happened}
2. {what you tried} → {what happened}
3. {what you tried} → {what happened}

**Error signature:** {exact error message or behavior}
**Files involved:** {list}
```

### Step 2: Search for Reference Implementation

```bash
# In codebase - find similar working code
grep -r "similar_pattern" --include="*.tsx" --include="*.ts"

# Find where this works elsewhere
grep -rn "functionName\|ClassName\|pattern" src/

# Check test files for expected usage
grep -rn "pattern" tests/ __tests__/
```

**Ask:** Where does this already work in the codebase?

### Step 3: Check for Applicable Skills

Review available skills:
- `frontend-design` - UI/component patterns
- `nextjs-bootstrap` - Next.js setup issues
- `auth-setup` - Authentication problems
- `email-setup` - Email delivery issues
- `stripe-payments` - Payment integration
- `ai-integration` - LLM/API issues

**Ask:** Is there a skill that covers this problem domain?

### Step 4: Web Search for Working Examples

```
Search: "{technology} {specific error or pattern}" site:github.com
Search: "{framework} {what you're trying to do}" example
Search: "{exact error message}"
```

Look for:
- GitHub issues with solutions
- Stack Overflow accepted answers
- Official docs examples
- Working repos to reference

### Step 5: Isolate the Problem

Create minimal reproduction:

```typescript
// test-reproduction.ts
// Minimal code that shows the problem

// Expected: X
// Actual: Y
```

Run in isolation. Does it still fail?

### Step 6: Check Assumptions

Common false assumptions:
| Assumption | Reality Check |
|------------|---------------|
| "The data is correct" | `console.log(JSON.stringify(data))` |
| "This function is called" | Add logging at entry point |
| "The type is X" | `typeof x`, `Array.isArray(x)` |
| "The env var is set" | `console.log(process.env.VAR)` |
| "The import is correct" | Check the actual export |
| "This worked before" | `git log -p -- file.ts` |

### Step 7: Ask User

If steps 1-6 don't resolve:

```markdown
## Stuck: Need Input

**Problem:** {description}

**Tried:**
1. {attempt 1} - didn't work because {reason}
2. {attempt 2} - didn't work because {reason}
3. {attempt 3} - didn't work because {reason}

**Reference search:** {what you found or didn't find}

**Current hypothesis:** {what you think is wrong}

**Options:**
1. {approach A} - {tradeoff}
2. {approach B} - {tradeoff}
3. Skip this and work on something else

Which direction?
```

## Anti-Patterns (Don't Do These)

❌ **Push and pray** - Committing untested "fixes"
❌ **Shotgun debugging** - Changing random things
❌ **Copy-paste without understanding** - Stack Overflow cargo cult
❌ **"It works on my machine"** - Not verifying in target env
❌ **Ignoring error messages** - They usually tell you what's wrong

## Output When Triggered

```markdown
🛑 **Debug Escalation Triggered**

Attempt count: {N}

## Problem Summary
{one line}

## Attempts Log
| # | Approach | Result |
|---|----------|--------|
| 1 | {approach} | {result} |
| 2 | {approach} | {result} |
| 3 | {approach} | {result} |

## Escalation Actions
- [ ] Search codebase for reference impl
- [ ] Check applicable skills
- [ ] Web search for solutions
- [ ] Isolate to minimal repro
- [ ] Verify assumptions
- [ ] Ask user for direction

## Next Step
{what you're doing now based on escalation}
```

## Remember

- Understanding > trial-and-error
- Working reference > clever solution
- Ask early > spin endlessly
- It's okay to not know - it's not okay to pretend
