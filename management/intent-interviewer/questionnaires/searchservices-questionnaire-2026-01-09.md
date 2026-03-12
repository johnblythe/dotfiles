# Intent Layer Questionnaire

**Service:** searchservices
**Date:** 2026-01-09
**SME:** _[Your name]_

---

## Instructions

Fill out as much as you can. "I don't know" or "N/A" are fine.
Quick answers are better than perfect answers - we're capturing tribal knowledge.

---

## 1. Scope & Boundaries

### 1.1 In one sentence, what does this service DO?
>

### 1.2 What does this service explicitly NOT handle that people often assume it does?
>

### 1.3 What would break if this service went down for 5 minutes?
>

### 1.4 What upstream services call into this? What downstream services does it call?
> Upstream (callers):
> Downstream (called):

---

## 2. Entry Points

### 2.1 What's the main entry point (class/method) for the most common use case?
>

### 2.2 Are there any "back doors" - things that trigger behavior not obvious from the API?
(Scheduled jobs, event listeners, async triggers, etc.)
>

### 2.3 What endpoints/methods should someone NEVER modify without extra review?
>

---

## 3. Patterns

### 3.1 What's the "right way" to add a new feature to this service?
>

### 3.2 What patterns exist here that aren't enforced by linters?
(Naming conventions, file organization, error handling patterns, etc.)
>

### 3.3 What would make you immediately reject a PR? "No, not like that."
>

---

## 4. Gotchas & Anti-patterns

### 4.1 What are the top 3 mistakes new engineers make in this service?
> 1.
> 2.
> 3.

### 4.2 What looks safe but isn't? Any hidden side effects?
>

### 4.3 What assumptions does this code make that aren't checked/enforced?
>

### 4.4 Are there any "haunted" areas - code everyone avoids touching?
>

---

## 5. State & Data

### 5.1 What shared state or singletons exist that affect behavior?
>

### 5.2 What caching exists? When does it cause stale data issues?
>

### 5.3 What data is this service the "source of truth" for?
>

---

## 6. External Dependencies

### 6.1 Which external APIs/services are flaky or slow?
>

### 6.2 What retry/timeout configs are critical to get right?
>

### 6.3 What auth/certs/tokens need periodic attention?
>

---

## 7. Testing

### 7.1 What's hard to test in this service? What do people skip?
>

### 7.2 What test data setup is required that isn't obvious?
>

---

## 8. History & War Stories

### 8.1 What major refactors or rewrites have happened? What's legacy vs current?
>

### 8.2 What incidents has this service caused? What was learned?
>

### 8.3 Anything else an AI agent (or new engineer) should know?
>

---

_Thanks! Return this file when complete._
