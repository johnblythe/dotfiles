---
name: api-scaffold
description: Checklist and boilerplate for new API endpoints. Covers auth, validation, error handling, and typing.
---

# API Scaffold

Structured approach for creating new API endpoints. Ensures consistency, security, and proper error handling.

## When to Use

- Creating new API route
- Adding endpoint to existing route
- Reviewing API implementation

## Pre-Implementation Checklist

Before writing code, answer these:

```markdown
## API Design

**Endpoint:** `{METHOD} /api/{path}`
**Purpose:** {one sentence}

### Questions
1. **Auth required?** Yes / No / Partial (some operations)
2. **Who can access?** Anyone / Logged in / Owner only / Admin
3. **Input source?** Body / Query params / Path params / Headers
4. **What's returned?** Object / Array / Void / Stream
5. **Error cases?** List expected errors
6. **Rate limit needed?** Yes (limit: X/min) / No
7. **Webhook/callback?** Yes / No
```

## File Structure

```
app/api/
  {resource}/
    route.ts           # GET /api/resource, POST /api/resource
    [id]/
      route.ts         # GET/PUT/DELETE /api/resource/:id
    {action}/
      route.ts         # POST /api/resource/action
```

## Route Template

### Basic Route (Next.js App Router)

```typescript
// app/api/{resource}/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/auth';
import { prisma } from '@/lib/prisma';
import { z } from 'zod';

// Input validation schema
const CreateResourceSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional(),
});

// GET /api/resource
export async function GET(request: NextRequest) {
  try {
    // Auth check (if required)
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Query params
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '10');
    const offset = parseInt(searchParams.get('offset') || '0');

    // Fetch data
    const resources = await prisma.resource.findMany({
      where: { userId: session.user.id },
      take: limit,
      skip: offset,
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json({ data: resources });
  } catch (error) {
    console.error('GET /api/resource error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST /api/resource
export async function POST(request: NextRequest) {
  try {
    // Auth check
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Parse and validate body
    const body = await request.json();
    const parsed = CreateResourceSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Validation failed', details: parsed.error.flatten() },
        { status: 400 }
      );
    }

    // Create resource
    const resource = await prisma.resource.create({
      data: {
        ...parsed.data,
        userId: session.user.id,
      },
    });

    return NextResponse.json({ data: resource }, { status: 201 });
  } catch (error) {
    console.error('POST /api/resource error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

### Route with Path Params

```typescript
// app/api/{resource}/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

type Params = { params: { id: string } };

// GET /api/resource/:id
export async function GET(request: NextRequest, { params }: Params) {
  const { id } = params;

  // Validate ID format
  if (!id || typeof id !== 'string') {
    return NextResponse.json(
      { error: 'Invalid ID' },
      { status: 400 }
    );
  }

  // Fetch and return
  const resource = await prisma.resource.findUnique({
    where: { id },
  });

  if (!resource) {
    return NextResponse.json(
      { error: 'Not found' },
      { status: 404 }
    );
  }

  return NextResponse.json({ data: resource });
}

// PUT /api/resource/:id
export async function PUT(request: NextRequest, { params }: Params) {
  // Similar pattern...
}

// DELETE /api/resource/:id
export async function DELETE(request: NextRequest, { params }: Params) {
  // Similar pattern...
}
```

## Validation with Zod

```typescript
import { z } from 'zod';

// Reusable schemas
const PaginationSchema = z.object({
  limit: z.coerce.number().min(1).max(100).default(10),
  offset: z.coerce.number().min(0).default(0),
});

const IdSchema = z.string().cuid();

// Resource-specific schemas
const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

const UpdateUserSchema = CreateUserSchema.partial();

// Usage
const parsed = CreateUserSchema.safeParse(body);
if (!parsed.success) {
  return NextResponse.json({
    error: 'Validation failed',
    details: parsed.error.flatten(),
  }, { status: 400 });
}
```

## Error Response Format

Consistent error structure:

```typescript
// Standard error response
type ErrorResponse = {
  error: string;           // Human-readable message
  code?: string;           // Machine-readable code (optional)
  details?: unknown;       // Validation errors, etc (optional)
};

// Status codes
// 400 - Bad Request (validation failed, malformed)
// 401 - Unauthorized (not logged in)
// 403 - Forbidden (logged in but not allowed)
// 404 - Not Found
// 409 - Conflict (duplicate, already exists)
// 422 - Unprocessable Entity (valid syntax but can't process)
// 429 - Too Many Requests (rate limited)
// 500 - Internal Server Error
```

## Auth Patterns

### Session-based (NextAuth)

```typescript
import { getServerSession } from 'next-auth';
import { authOptions } from '@/auth';

const session = await getServerSession(authOptions);

if (!session?.user) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
}

// Access user
const userId = session.user.id;
```

### Owner Check

```typescript
const resource = await prisma.resource.findUnique({ where: { id } });

if (resource.userId !== session.user.id) {
  return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
}
```

### API Key (for external services)

```typescript
const apiKey = request.headers.get('x-api-key');

if (apiKey !== process.env.API_KEY) {
  return NextResponse.json({ error: 'Invalid API key' }, { status: 401 });
}
```

## Webhook Endpoints

```typescript
// app/api/webhooks/{service}/route.ts
import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

export async function POST(request: NextRequest) {
  // Get raw body for signature verification
  const body = await request.text();
  const signature = request.headers.get('x-signature');

  // Verify signature
  const expectedSig = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET!)
    .update(body)
    .digest('hex');

  if (signature !== expectedSig) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }

  // Parse and process
  const payload = JSON.parse(body);

  // Handle webhook event
  switch (payload.type) {
    case 'event.created':
      await handleEventCreated(payload);
      break;
    // ... other events
  }

  return NextResponse.json({ received: true });
}
```

## Streaming Responses

```typescript
import { StreamingTextResponse } from 'ai';

export async function POST(request: NextRequest) {
  const stream = await generateStream(input);
  return new StreamingTextResponse(stream);
}
```

## Testing API Routes

```typescript
// tests/api/resource.test.ts
import { describe, it, expect } from 'vitest';

describe('POST /api/resource', () => {
  it('should create resource with valid input', async () => {
    const response = await fetch('/api/resource', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test' }),
    });

    expect(response.status).toBe(201);
    const data = await response.json();
    expect(data.data.name).toBe('Test');
  });

  it('should return 400 for invalid input', async () => {
    const response = await fetch('/api/resource', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });

    expect(response.status).toBe(400);
  });

  it('should return 401 without auth', async () => {
    // Test without session
    const response = await fetch('/api/resource');
    expect(response.status).toBe(401);
  });
});
```

## Checklist Before PR

- [ ] Auth check implemented (if required)
- [ ] Input validation with Zod
- [ ] Proper error responses (400, 401, 403, 404, 500)
- [ ] Owner/permission checks
- [ ] Logging for errors
- [ ] TypeScript types for request/response
- [ ] Tests for happy path
- [ ] Tests for error cases
- [ ] Rate limiting (if needed)
- [ ] No sensitive data in responses
- [ ] No N+1 queries
