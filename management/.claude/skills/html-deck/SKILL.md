---
name: html-deck
description: Creates self-contained HTML slide decks with personality, visual punch, and smooth navigation. Invoke when the user wants a presentation, slide deck, pitch deck, or training session built as HTML.
---

# HTML Slide Deck Builder

Build single-file HTML presentations with strong typography, smooth animations, and personality. No external dependencies except optional Google Fonts.

## Usage

```
/html-deck                              # Start with interview
/html-deck Q2 capacity pitch            # Start with topic context
/html-deck --dark                       # Dark theme variant
/html-deck --scroll                     # Scroll-based (vs click-nav)
```

<HARD-GATE>
Do NOT start building slides until the interview phase is complete and the user has approved the outline. Every deck goes through: Interview -> Outline -> Design Approval -> Build -> Review.
</HARD-GATE>

## Phase 1: Interview

Ask these one at a time. Don't dump them all at once.

1. **Audience** — "Who's in the room? (execs, engineers, mixed, external?)"
2. **Goal** — "What should they think/feel/do after this deck?"
3. **Vibe** — "What's the vibe? Pick one or describe your own: formal, clean, dark, tech, modern, editorial, playful, moody, minimal, bold"
4. **Tone** — "How serious is this? Pick one: boardroom serious / professional but human / personality showing / we're having fun / unhinged"
5. **Content style** — "What carries the message? Pick what applies: data heavy, quote-driven, visual metaphors, storytelling, comparison/contrast, before-after"
6. **Humor** — "Any humor? (none / light touches / a joke slide / sprinkled throughout / Tiger Kings energy)"
7. **Content** — "What are the key messages? Dump everything — bullet points, data, vibes, whatever you've got."
8. **Length** — "How many slides roughly? (5-8 tight, 10-15 standard, 15-20 deep dive)"
9. **Visual direction** — "Light/dark/warm? Gradients? Specific color preferences? Reference a deck or site you like?"

If the user provides context with the command (e.g. `/html-deck reorg pitch for my VP`), extract what you can and only ask for what's missing.

## Phase 2: Outline

Present a slide-by-slide arc:

```
Slide Arc (12 slides)
─────────────────────
 1. [Title]       The Opportunity Window — date, subtitle
 2. [Context]     A Lot Is Changing — timeline of events
 3. [Problem]     One Team, Two Worlds — two-col contrast
 4. [Evidence]    What the Data Shows — big numbers + table
 5. [Options]     Three Paths Forward — option cards
 6. [Vision]      The New Identity — card + bullets
 7. [Roadmap]     How We Get There — phase cards
 8. [Humor]       The Ideal Org Structure — joke slide
 9. [Ask]         The Ask — numbered action items
```

Each line: slide number, section label, title, primary component type.

Get approval or iterate before building.

## Phase 3: Build

### Navigation Mode

Choose based on context:

**Click-nav (default for pitches, short decks):**
- Arrow keys, click, touch swipe
- One slide visible at a time with fade transition
- Fixed nav buttons bottom-right, progress bar top
- Best for: pitches, proposals, short presentations

**Scroll-based (for training, longer decks):**
- Full-page sections, scroll between them
- Fixed navbar with progress bar and slide counter
- IntersectionObserver for reveal animations
- Arrow keys snap to next/prev section
- Best for: training sessions, deep dives, reference decks

### HTML Structure

Single self-contained `.html` file. Structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[Deck Title]</title>
<style>
  /* Optional: Google Fonts import for themed decks */
  /* :root variables */
  /* Reset + body */
  /* Slide styles */
  /* Component styles */
  /* Navigation */
  /* Animations */
  /* Responsive */
</style>
</head>
<body>
  <!-- Progress bar -->
  <!-- Slides -->
  <!-- Navigation -->
  <script>/* Nav logic */</script>
</body>
</html>
```

### Color Themes

Define in `:root`. Three reference palettes:

**Light (corporate-friendly but not boring):**
```css
:root {
  --bg: #ffffff; --surface: #edf0f7; --accent: #1d4ed8;
  --accent2: #15803d; --accent3: #b45309; --warn: #b91c1c;
  --text: #0f172a; --muted: #475569; --border: #cbd5e1;
}
```

**Dark (terminal/engineering feel):**
```css
:root {
  --bg: #0f0f13; --surface: #1a1a24; --surface-2: #22222e;
  --border: #2d2d3d; --text: #e4e4ed; --text-muted: #8888a0;
  --accent: #d97706; --terminal-green: #4ade80;
  --terminal-blue: #60a5fa; --terminal-purple: #c084fc;
}
```

**Warm (editorial/magazine feel):**
```css
:root {
  --cream: #faf6f0; --paper: #fff9f2; --ink: #1c1917;
  --ink-soft: #44403c; --ink-muted: #78716c;
  --amber: #c2410c; --teal: #0d9488; --coral: #e11d48;
}
```

Adapt and remix these. Don't copy verbatim every time.

### Typography

System fonts as default. Google Fonts for themed decks.

```css
/* Default */
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;

/* Themed dark deck */
font-family: 'Inter', -apple-system, sans-serif;
/* + JetBrains Mono for monospace elements */

/* Themed warm/editorial deck */
font-family: 'DM Sans', -apple-system, sans-serif;
/* + Fraunces for headings (serif with character) */
```

Typography does heavy lifting:
- `h1`: `clamp(2.5rem, 5vw, 4rem)`, weight 700-900, tight line-height (1.05-1.15), negative letter-spacing
- `h2`: `clamp(1.8rem, 3.5vw, 2.8rem)`, weight 600-700
- Section labels: small caps, monospace, letter-spacing 0.1-0.15em, accent color
- Big statements should FEEL big — font-size, weight, and spacing all contribute

### Component Library

Use these as building blocks. Mix and match per slide.

**Section Label** — above every slide title:
```html
<div class="section-label">Context</div>
```

**Big Number:**
```html
<div class="big-number-row">
  <div class="big-number-item">
    <div class="big-number" style="color: var(--accent);">65</div>
    <div class="big-number-label">Tickets analyzed</div>
  </div>
</div>
```

**Quote:**
```html
<div class="quote">
  Text here. Can include <span class="highlight">emphasis</span>.
</div>
```

**Two-Column:**
```html
<div class="two-col">
  <div><!-- Left content --></div>
  <div><!-- Right content --></div>
</div>
```

**Card:**
```html
<div class="card">
  <h3>Title</h3>
  <p>Content</p>
</div>
```

**Card Grid:**
```html
<div class="card-grid">
  <div class="card"><h4>Title</h4><p>Content</p></div>
  <div class="card"><h4>Title</h4><p>Content</p></div>
</div>
```

**Option Cards (decision slides):**
```html
<div class="option-cards">
  <div class="option-card"><!-- Option A --></div>
  <div class="option-card recommended"><!-- Recommended --></div>
  <div class="option-card"><!-- Option C --></div>
</div>
```

**Timeline:**
```html
<div class="timeline">
  <div class="timeline-item done">
    <div class="timeline-date">January</div>
    <div class="timeline-title">Event</div>
    <div class="timeline-desc">Description</div>
  </div>
</div>
```

**Table:**
```html
<table>
  <thead><tr><th>Col</th><th>Col</th></tr></thead>
  <tbody><tr><td>Data</td><td>Data</td></tr></tbody>
</table>
```

**Tags:**
```html
<span class="tag tag-good">Positive</span>
<span class="tag tag-warn">Caution</span>
<span class="tag tag-bad">Problem</span>
<span class="tag tag-info">Info</span>
```

**Semantic Color Spans:**
```html
<span class="highlight">Blue emphasis</span>
<span class="good">Green positive</span>
<span class="warn">Amber caution</span>
<span class="bad">Red negative</span>
```

**Bar Chart (horizontal):**
```html
<div class="bar-chart">
  <div class="bar-row">
    <div class="bar-label">Label</div>
    <div class="bar-track">
      <div class="bar-fill" style="width: 75%; background: var(--accent);">75</div>
    </div>
  </div>
</div>
```

**Flow Diagram:**
```html
<div class="flow">
  <div class="flow-step"><div class="step-icon">icon</div><div class="step-label">Step</div></div>
  <div class="flow-arrow">&rarr;</div>
  <!-- more steps -->
</div>
```

**Callout:**
```html
<div class="callout">
  <div class="callout-icon">icon</div>
  <div class="callout-text"><strong>Key point.</strong> Supporting text.</div>
</div>
```

**Comparison (before/after):**
```html
<div class="comparison">
  <div class="comparison-box before"><div class="big-number">Old</div></div>
  <div class="comparison-arrow">&rarr;</div>
  <div class="comparison-box after"><div class="big-number">New</div></div>
</div>
```

**Terminal Mock (for technical/demo slides):**
```html
<div class="terminal">
  <div class="terminal-header">
    <div class="terminal-dot red"></div>
    <div class="terminal-dot yellow"></div>
    <div class="terminal-dot green"></div>
    <div class="terminal-title">~/code/project</div>
  </div>
  <div class="terminal-body">
    <div class="term-line"><span class="term-prompt">command here</span></div>
    <div class="term-line"><span class="term-success">output</span></div>
  </div>
</div>
```

**Code File Mock:**
```html
<div class="code-file">
  <div class="code-header">
    <span class="code-filename">path/to/file.ext</span>
  </div>
  <div class="code-body"><!-- syntax-highlighted content --></div>
</div>
```

### Click-Nav JavaScript

```javascript
let current = 0;
const slides = document.querySelectorAll('.slide');
const total = slides.length;
const progress = document.getElementById('progress');
const counter = document.getElementById('counter');

function show(n) {
  slides[current].classList.remove('active');
  current = Math.max(0, Math.min(n, total - 1));
  slides[current].classList.add('active');
  progress.style.width = ((current + 1) / total * 100) + '%';
  counter.textContent = (current + 1) + ' / ' + total;
}

function next() { show(current + 1); }
function prev() { show(current - 1); }

document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowRight' || e.key === ' ') { e.preventDefault(); next(); }
  if (e.key === 'ArrowLeft') { e.preventDefault(); prev(); }
  if (e.key === 'Home') { e.preventDefault(); show(0); }
  if (e.key === 'End') { e.preventDefault(); show(total - 1); }
});

let touchStart = 0;
document.addEventListener('touchstart', (e) => { touchStart = e.touches[0].clientX; });
document.addEventListener('touchend', (e) => {
  const diff = touchStart - e.changedTouches[0].clientX;
  if (Math.abs(diff) > 50) { diff > 0 ? next() : prev(); }
});

show(0);
```

### Scroll-Nav JavaScript

```javascript
const slides = document.querySelectorAll('.slide');
const progressBar = document.getElementById('progressBar');
const slideCounter = document.getElementById('slideCounter');
const totalSlides = slides.length;

function updateProgress() {
  const scrollTop = window.scrollY;
  const docHeight = document.documentElement.scrollHeight - window.innerHeight;
  const progress = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
  progressBar.style.width = progress + '%';
  let current = 1;
  slides.forEach((slide, i) => {
    if (slide.getBoundingClientRect().top < window.innerHeight / 2) current = i + 1;
  });
  slideCounter.textContent = current + ' / ' + totalSlides;
}

window.addEventListener('scroll', updateProgress);
updateProgress();

// Reveal animations
const reveals = document.querySelectorAll('.reveal');
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) entry.target.classList.add('visible');
  });
}, { threshold: 0.15 });
reveals.forEach(el => observer.observe(el));

// Keyboard nav
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowDown' || e.key === ' ' || e.key === 'PageDown') {
    e.preventDefault(); navigateSlide(1);
  } else if (e.key === 'ArrowUp' || e.key === 'PageUp') {
    e.preventDefault(); navigateSlide(-1);
  }
});

function navigateSlide(dir) {
  let idx = 0;
  slides.forEach((s, i) => {
    if (s.getBoundingClientRect().top < window.innerHeight / 2) idx = i;
  });
  const next = Math.max(0, Math.min(totalSlides - 1, idx + dir));
  slides[next].scrollIntoView({ behavior: 'smooth' });
}
```

### Animation Patterns

**Fade-in (click-nav):**
```css
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
.slide { animation: fadeIn 0.3s ease; }
```

**Reveal (scroll-nav):**
```css
.reveal { opacity: 0; transform: translateY(24px); transition: opacity 0.5s ease, transform 0.5s ease; }
.reveal.visible { opacity: 1; transform: translateY(0); }
```

**Subtle float (mascots, decorative elements):**
```css
@keyframes bob { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-6px); } }
```

**Staggered reveals** — use `animation-delay` on child elements for sequential appearance.

### Slide Structure Patterns

**Title Slide:** Centered. Section badge or label, big h1, subtitle, optional stats row or date.

**Content Slide:** Section label, h2, lead paragraph, then components. Keep to 2-3 components max per slide.

**Data Slide:** Section label, h2, big-number-row or bar chart, supporting text below.

**Decision Slide:** Section label, h2, option-cards (2-3 options), quote or callout summarizing recommendation.

**Joke Slide:** Goes in the appendix or between serious sections. Same visual language but with playful content. Never forced.

**Closing Slide:** Centered. Callback to core message. 1-3 word summary or repeated motif. Date or "thank you" optional.

## Phase 4: Review

After building, open in browser:
```bash
open /path/to/deck.html
```

Ask: "How's it looking? Anything to adjust — content, layout, colors, ordering?"

Iterate until the user is satisfied.

## Design Principles

1. **Not corporate-bland.** Every deck should have personality. If it looks like it came from a template gallery, add more character.
2. **Typography does the heavy lifting.** Big statements should feel big. Use size, weight, and spacing aggressively.
3. **Data should pop.** Never let numbers sit in plain text. Use big-number, bar charts, colored spans, comparison boxes.
4. **Subtle animations only.** Staggered reveals, smooth fades. Nothing that distracts from content.
5. **Humor is welcome.** The user likes to have fun. A well-placed joke slide or cheeky subtitle lands better than corporate polish.
6. **Dark backgrounds work.** Gradients are fine. Don't default to white just because it's "safe."
7. **Each deck gets its own visual identity.** Reuse patterns, not exact styles. Different decks should feel like siblings, not clones.
8. **Avoid the AI layout trap.** Perfectly balanced two-column grids with matching bullet counts screams generated. Real presentations have visual variety: a slide with one giant number, then a slide with a full-bleed quote, then a dense data slide. Rhythm and contrast matter more than consistency.

## Output Conventions

- **Training sessions:** `~/code/management/training/sessions/<nn>-<slug>.html`
- **Pitches/proposals:** `~/code/management/scratchpad/<project-dir>/<slug>.html`
- **Standalone:** `~/code/management/scratchpad/<slug>.html`
- Filename should be descriptive: `reorg-deck.html`, `monitoring-gap.html`, `q2-capacity.html`

## Responsive Requirements

Every deck must work on:
- Projector/external display (1920px+)
- Laptop (1280-1440px)
- Tablet (768-1024px)

Use `clamp()` for heading sizes. Use grid with `auto-fit`/`minmax()` for card layouts. Add `@media (max-width: 768px)` breakpoints for anything that uses fixed column counts.
