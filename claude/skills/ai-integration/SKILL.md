---
name: ai-integration
description: Sets up AI/LLM integration in Next.js projects. Covers Anthropic Claude (default), OpenAI, prompt security, rate limiting, and streaming.
---

# AI Integration

## Ask First

1. **Provider?**
   - Anthropic Claude (recommended)
   - OpenAI
   - Both (for fallback/comparison)

2. **Features needed?**
   - Basic completion
   - Streaming responses
   - Prompt security/sanitization
   - Rate limiting
   - Token tracking/logging

## Provider: Anthropic Claude (Recommended)

### Install

```bash
npm install @anthropic-ai/sdk
```

### Environment

```env
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

### Singleton Client

Create `lib/anthropic.ts`:

```typescript
import Anthropic from "@anthropic-ai/sdk";

let _client: Anthropic | null = null;

export function getAnthropicClient(): Anthropic {
  if (!_client) {
    if (!process.env.ANTHROPIC_API_KEY) {
      throw new Error("ANTHROPIC_API_KEY is not set");
    }
    _client = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }
  return _client;
}

// Convenience export
export const anthropic = {
  get client() {
    return getAnthropicClient();
  },
};
```

### Basic Completion

```typescript
import { getAnthropicClient } from "@/lib/anthropic";

export async function generateResponse(prompt: string) {
  const client = getAnthropicClient();

  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1024,
    messages: [
      { role: "user", content: prompt }
    ],
  });

  // Extract text from response
  const text = response.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("");

  return {
    text,
    usage: {
      inputTokens: response.usage.input_tokens,
      outputTokens: response.usage.output_tokens,
    },
  };
}
```

### Streaming Response

```typescript
import { getAnthropicClient } from "@/lib/anthropic";

export async function* streamResponse(prompt: string) {
  const client = getAnthropicClient();

  const stream = await client.messages.stream({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1024,
    messages: [
      { role: "user", content: prompt }
    ],
  });

  for await (const event of stream) {
    if (
      event.type === "content_block_delta" &&
      event.delta.type === "text_delta"
    ) {
      yield event.delta.text;
    }
  }
}
```

### Streaming API Route

Create `app/api/ai/chat/route.ts`:

```typescript
import { getAnthropicClient } from "@/lib/anthropic";

export async function POST(request: Request) {
  const { prompt, systemPrompt } = await request.json();

  const client = getAnthropicClient();

  const stream = await client.messages.stream({
    model: "claude-sonnet-4-20250514",
    max_tokens: 2048,
    system: systemPrompt,
    messages: [{ role: "user", content: prompt }],
  });

  // Return as streaming response
  const encoder = new TextEncoder();
  const readable = new ReadableStream({
    async start(controller) {
      for await (const event of stream) {
        if (
          event.type === "content_block_delta" &&
          event.delta.type === "text_delta"
        ) {
          controller.enqueue(encoder.encode(event.delta.text));
        }
      }
      controller.close();
    },
  });

  return new Response(readable, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Transfer-Encoding": "chunked",
    },
  });
}
```

### Client-Side Streaming Hook

```typescript
"use client";

import { useState, useCallback } from "react";

export function useAIStream() {
  const [response, setResponse] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const generate = useCallback(async (prompt: string, systemPrompt?: string) => {
    setIsLoading(true);
    setResponse("");
    setError(null);

    try {
      const res = await fetch("/api/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt, systemPrompt }),
      });

      if (!res.ok) throw new Error("Failed to generate");

      const reader = res.body?.getReader();
      if (!reader) throw new Error("No reader");

      const decoder = new TextDecoder();

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value, { stream: true });
        setResponse((prev) => prev + chunk);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setIsLoading(false);
    }
  }, []);

  return { response, isLoading, error, generate };
}
```

## Provider: OpenAI

### Install

```bash
npm install openai
```

### Environment

```env
OPENAI_API_KEY=sk-xxxxx
```

### Singleton Client

Create `lib/openai.ts`:

```typescript
import OpenAI from "openai";

let _client: OpenAI | null = null;

export function getOpenAIClient(): OpenAI {
  if (!_client) {
    if (!process.env.OPENAI_API_KEY) {
      throw new Error("OPENAI_API_KEY is not set");
    }
    _client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }
  return _client;
}
```

### Basic Completion

```typescript
import { getOpenAIClient } from "@/lib/openai";

export async function generateResponse(prompt: string) {
  const client = getOpenAIClient();

  const response = await client.chat.completions.create({
    model: "gpt-4o",
    messages: [{ role: "user", content: prompt }],
  });

  return {
    text: response.choices[0]?.message?.content || "",
    usage: {
      inputTokens: response.usage?.prompt_tokens,
      outputTokens: response.usage?.completion_tokens,
    },
  };
}
```

## Prompt Security

### Prompt Sanitizer

Create `lib/ai/prompt-security.ts`:

```typescript
export type RiskLevel = "none" | "low" | "medium" | "high";

interface SanitizeResult {
  sanitized: string;
  riskLevel: RiskLevel;
  flagged: string[];
}

// Patterns that indicate potential prompt injection
const INJECTION_PATTERNS = [
  // Direct instruction override attempts
  /ignore\s+(all\s+)?(previous|prior|above)/i,
  /disregard\s+(all\s+)?(previous|prior|above)/i,
  /forget\s+(all\s+)?(previous|prior|above)/i,
  
  // Role manipulation
  /you\s+are\s+now/i,
  /act\s+as\s+(if\s+you\s+are|a)/i,
  /pretend\s+(to\s+be|you\s+are)/i,
  /roleplay\s+as/i,
  
  // System prompt extraction
  /what\s+(is|are)\s+your\s+(system|initial)\s+(prompt|instructions)/i,
  /show\s+(me\s+)?your\s+(system|initial)\s+prompt/i,
  /reveal\s+your\s+(instructions|prompt)/i,
  
  // Delimiter injection
  /```\s*(system|assistant)/i,
  /<\/?system>/i,
  /\[INST\]/i,
  /\[\/INST\]/i,
  
  // Jailbreak attempts
  /DAN\s+mode/i,
  /developer\s+mode/i,
  /bypass\s+(safety|filter|restriction)/i,
];

// Characters that could be used for encoding attacks
const SUSPICIOUS_CHARS = /[\u200B-\u200D\uFEFF\u00AD]/g; // Zero-width chars

export function sanitizePrompt(input: string): SanitizeResult {
  const flagged: string[] = [];
  let riskLevel: RiskLevel = "none";

  // Check for injection patterns
  for (const pattern of INJECTION_PATTERNS) {
    if (pattern.test(input)) {
      flagged.push(`Pattern match: ${pattern.source.slice(0, 30)}...`);
    }
  }

  // Check for suspicious characters
  if (SUSPICIOUS_CHARS.test(input)) {
    flagged.push("Suspicious zero-width characters detected");
  }

  // Check for excessive special characters
  const specialCharRatio = (input.match(/[^a-zA-Z0-9\s.,!?'"()-]/g)?.length || 0) / input.length;
  if (specialCharRatio > 0.3) {
    flagged.push("High ratio of special characters");
  }

  // Determine risk level
  if (flagged.length === 0) {
    riskLevel = "none";
  } else if (flagged.length === 1) {
    riskLevel = "low";
  } else if (flagged.length <= 3) {
    riskLevel = "medium";
  } else {
    riskLevel = "high";
  }

  // Sanitize the input
  let sanitized = input
    // Remove zero-width characters
    .replace(SUSPICIOUS_CHARS, "")
    // Normalize whitespace
    .replace(/\s+/g, " ")
    .trim();

  // For high-risk inputs, wrap in delimiters to isolate
  if (riskLevel === "high" || riskLevel === "medium") {
    sanitized = `[USER_INPUT_START]\n${sanitized}\n[USER_INPUT_END]`;
  }

  return { sanitized, riskLevel, flagged };
}

// Simple sanitize that just returns clean string
export function cleanPrompt(input: string): string {
  return input
    .replace(SUSPICIOUS_CHARS, "")
    .replace(/\s+/g, " ")
    .trim();
}
```

### Using Prompt Security

```typescript
import { sanitizePrompt } from "@/lib/ai/prompt-security";

export async function handleUserPrompt(userInput: string) {
  const { sanitized, riskLevel, flagged } = sanitizePrompt(userInput);

  // Log suspicious inputs
  if (riskLevel !== "none") {
    console.warn("Suspicious prompt detected:", {
      riskLevel,
      flagged,
      preview: userInput.slice(0, 100),
    });
  }

  // Block high-risk inputs
  if (riskLevel === "high") {
    throw new Error("Input contains potentially harmful content");
  }

  // Use sanitized input
  return generateResponse(sanitized);
}
```

## Rate Limiting

### In-Memory Rate Limiter

Create `lib/ai/rate-limit.ts`:

```typescript
interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const store = new Map<string, RateLimitEntry>();

interface RateLimitConfig {
  windowMs: number;  // Time window in milliseconds
  maxRequests: number;
}

const DEFAULT_CONFIG: RateLimitConfig = {
  windowMs: 60 * 1000,  // 1 minute
  maxRequests: 10,
};

export function checkRateLimit(
  key: string,
  config: RateLimitConfig = DEFAULT_CONFIG
): { allowed: boolean; remaining: number; resetAt: number } {
  const now = Date.now();
  const entry = store.get(key);

  // Clean up expired entries periodically
  if (Math.random() < 0.01) {
    for (const [k, v] of store.entries()) {
      if (v.resetAt < now) store.delete(k);
    }
  }

  if (!entry || entry.resetAt < now) {
    // New window
    store.set(key, { count: 1, resetAt: now + config.windowMs });
    return { allowed: true, remaining: config.maxRequests - 1, resetAt: now + config.windowMs };
  }

  if (entry.count >= config.maxRequests) {
    return { allowed: false, remaining: 0, resetAt: entry.resetAt };
  }

  entry.count++;
  return { allowed: true, remaining: config.maxRequests - entry.count, resetAt: entry.resetAt };
}

// Get rate limit key from request
export function getRateLimitKey(request: Request, prefix: string = "ai"): string {
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0] ||
    request.headers.get("x-real-ip") ||
    "unknown";
  return `${prefix}:${ip}`;
}
```

### Rate Limited API Route

```typescript
import { checkRateLimit, getRateLimitKey } from "@/lib/ai/rate-limit";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  // Check rate limit
  const key = getRateLimitKey(request);
  const { allowed, remaining, resetAt } = checkRateLimit(key, {
    windowMs: 60 * 1000,
    maxRequests: 20,
  });

  if (!allowed) {
    return NextResponse.json(
      { error: "Rate limit exceeded" },
      {
        status: 429,
        headers: {
          "X-RateLimit-Remaining": "0",
          "X-RateLimit-Reset": resetAt.toString(),
          "Retry-After": Math.ceil((resetAt - Date.now()) / 1000).toString(),
        },
      }
    );
  }

  // Continue with AI request...
  const { prompt } = await request.json();
  
  // ... generate response ...

  return NextResponse.json(
    { result: "..." },
    {
      headers: {
        "X-RateLimit-Remaining": remaining.toString(),
        "X-RateLimit-Reset": resetAt.toString(),
      },
    }
  );
}
```

## Token Tracking

### Usage Logger

Create `lib/ai/usage.ts`:

```typescript
interface UsageLog {
  timestamp: Date;
  model: string;
  inputTokens: number;
  outputTokens: number;
  userId?: string;
  route?: string;
  cost?: number;
}

// Pricing per 1M tokens (update as needed)
const PRICING = {
  "claude-sonnet-4-20250514": { input: 3.0, output: 15.0 },
  "claude-3-haiku-20240307": { input: 0.25, output: 1.25 },
  "gpt-4o": { input: 2.5, output: 10.0 },
  "gpt-4o-mini": { input: 0.15, output: 0.6 },
} as const;

export function calculateCost(
  model: string,
  inputTokens: number,
  outputTokens: number
): number {
  const pricing = PRICING[model as keyof typeof PRICING];
  if (!pricing) return 0;

  return (
    (inputTokens / 1_000_000) * pricing.input +
    (outputTokens / 1_000_000) * pricing.output
  );
}

export function logUsage(log: UsageLog) {
  const cost = log.cost ?? calculateCost(log.model, log.inputTokens, log.outputTokens);

  // Console log for dev
  if (process.env.NODE_ENV === "development") {
    console.log("[AI Usage]", {
      ...log,
      cost: `$${cost.toFixed(6)}`,
    });
  }

  // TODO: Store in database for production tracking
  // await db.aiUsage.create({ data: { ...log, cost } });
}
```

### Using Token Tracking

```typescript
import { getAnthropicClient } from "@/lib/anthropic";
import { logUsage } from "@/lib/ai/usage";

export async function generateWithTracking(prompt: string, userId?: string) {
  const client = getAnthropicClient();
  const model = "claude-sonnet-4-20250514";

  const response = await client.messages.create({
    model,
    max_tokens: 1024,
    messages: [{ role: "user", content: prompt }],
  });

  // Log usage
  logUsage({
    timestamp: new Date(),
    model,
    inputTokens: response.usage.input_tokens,
    outputTokens: response.usage.output_tokens,
    userId,
    route: "/api/ai/generate",
  });

  return response;
}
```

## Vercel Config for AI Routes

Add to `vercel.json`:

```json
{
  "functions": {
    "app/api/ai/**/*.ts": {
      "maxDuration": 60
    }
  }
}
```

## System Prompts

### System Prompt Pattern

Create `lib/ai/prompts.ts`:

```typescript
export const SYSTEM_PROMPTS = {
  default: `You are a helpful assistant. Be concise and accurate.`,

  codeReview: `You are an expert code reviewer. Analyze code for:
- Bugs and potential issues
- Performance improvements
- Security vulnerabilities
- Best practices
Be specific and provide actionable feedback.`,

  contentWriter: `You are a professional content writer. Write clear, engaging content.
- Match the requested tone and style
- Be concise but thorough
- Use proper formatting`,
} as const;

export type SystemPromptKey = keyof typeof SYSTEM_PROMPTS;
```

## Checklist

- [ ] Provider chosen (Anthropic/OpenAI)
- [ ] API key obtained and set in env
- [ ] Singleton client created
- [ ] Basic completion working
- [ ] (Optional) Streaming implemented
- [ ] (Optional) Prompt security added
- [ ] (Optional) Rate limiting configured
- [ ] (Optional) Token tracking set up
- [ ] Vercel function timeout extended for AI routes
- [ ] Error handling in place
