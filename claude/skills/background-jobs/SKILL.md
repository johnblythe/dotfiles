---
name: background-jobs
description: Sets up background jobs and async task processing in Next.js projects. Covers Inngest (recommended), Trigger.dev, Vercel Cron, and QStash.
---

# Background Jobs

## Ask First

1. **What type of work?**
   - Long-running tasks (AI generation, PDF processing)
   - Scheduled/cron jobs
   - Event-driven workflows
   - Webhooks that need processing

2. **Hosting?**
   - Vercel (some limitations)
   - Other (more flexibility)

3. **Complexity?**
   - Simple cron → Vercel Cron
   - Event-driven workflows → Inngest
   - Complex pipelines → Trigger.dev

---

## Option A: Inngest (Recommended)

Best for: Event-driven workflows, retries, long-running functions, fan-out.

### Install

```bash
npm install inngest
```

### Environment

```env
# Optional for local dev, required for production
INNGEST_SIGNING_KEY=xxxxx
INNGEST_EVENT_KEY=xxxxx
```

### Setup Client

Create `lib/inngest/client.ts`:

```typescript
import { Inngest } from "inngest";

export const inngest = new Inngest({
  id: "my-app",
  // Optional: schema validation
  // schemas: new EventSchemas().fromRecord<Events>(),
});
```

### Define Functions

Create `lib/inngest/functions.ts`:

```typescript
import { inngest } from "./client";

// Simple background function
export const processUpload = inngest.createFunction(
  { id: "process-upload" },
  { event: "upload/created" },
  async ({ event, step }) => {
    const { fileId, userId } = event.data;

    // Step 1: Download file
    const file = await step.run("download-file", async () => {
      return downloadFile(fileId);
    });

    // Step 2: Process (e.g., generate thumbnails)
    const processed = await step.run("process-file", async () => {
      return processFile(file);
    });

    // Step 3: Update database
    await step.run("update-db", async () => {
      return updateFileRecord(fileId, processed);
    });

    return { success: true };
  }
);

// Long-running AI function with automatic retries
export const generateAIContent = inngest.createFunction(
  {
    id: "generate-ai-content",
    retries: 3,
  },
  { event: "ai/generate" },
  async ({ event, step }) => {
    const { prompt, userId } = event.data;

    const result = await step.run("call-ai", async () => {
      // This can take 30+ seconds
      return generateWithAI(prompt);
    });

    await step.run("save-result", async () => {
      return saveResult(userId, result);
    });

    // Optionally send notification
    await step.sendEvent("notification/send", {
      data: { userId, message: "Your content is ready!" },
    });

    return result;
  }
);

// Scheduled function (cron)
export const dailyCleanup = inngest.createFunction(
  { id: "daily-cleanup" },
  { cron: "0 2 * * *" }, // 2 AM daily
  async ({ step }) => {
    await step.run("cleanup-expired", async () => {
      return deleteExpiredRecords();
    });

    await step.run("send-report", async () => {
      return sendCleanupReport();
    });
  }
);

// Fan-out: Process many items in parallel
export const processBatch = inngest.createFunction(
  { id: "process-batch" },
  { event: "batch/process" },
  async ({ event, step }) => {
    const { items } = event.data;

    // Fan out to process each item
    const results = await Promise.all(
      items.map((item, i) =>
        step.run(`process-item-${i}`, async () => {
          return processItem(item);
        })
      )
    );

    return { processed: results.length };
  }
);

// Delayed function
export const sendReminder = inngest.createFunction(
  { id: "send-reminder" },
  { event: "reminder/schedule" },
  async ({ event, step }) => {
    // Wait for specified delay
    await step.sleep("wait-for-reminder", event.data.delay);

    await step.run("send", async () => {
      return sendEmail(event.data.userId, event.data.message);
    });
  }
);
```

### API Route

Create `app/api/inngest/route.ts`:

```typescript
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest/client";
import {
  processUpload,
  generateAIContent,
  dailyCleanup,
  processBatch,
  sendReminder,
} from "@/lib/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    processUpload,
    generateAIContent,
    dailyCleanup,
    processBatch,
    sendReminder,
  ],
});
```

### Trigger Events

```typescript
import { inngest } from "@/lib/inngest/client";

// From API route
export async function POST(request: Request) {
  const { fileId, userId } = await request.json();

  // Send event to trigger background job
  await inngest.send({
    name: "upload/created",
    data: { fileId, userId },
  });

  return Response.json({ queued: true });
}

// From Server Action
export async function uploadFile(formData: FormData) {
  const file = formData.get("file");
  const savedFile = await saveFile(file);

  // Trigger background processing
  await inngest.send({
    name: "upload/created",
    data: { fileId: savedFile.id, userId: getCurrentUserId() },
  });

  return { success: true };
}
```

### Local Development

```bash
# Run Inngest dev server
npx inngest-cli@latest dev
```

Opens dashboard at http://localhost:8288 to view/debug functions.

---

## Option B: Trigger.dev

Best for: Complex workflows, visibility, integrations.

### Install

```bash
npm install @trigger.dev/sdk @trigger.dev/nextjs
```

### Setup

Create `trigger.config.ts`:

```typescript
import { defineConfig } from "@trigger.dev/sdk/v3";

export default defineConfig({
  project: "your-project-id",
  runtime: "node",
  logLevel: "log",
  retries: {
    enabledInDev: true,
    default: {
      maxAttempts: 3,
      minTimeoutInMs: 1000,
      maxTimeoutInMs: 10000,
      factor: 2,
    },
  },
});
```

### Define Tasks

Create `trigger/tasks.ts`:

```typescript
import { task, wait } from "@trigger.dev/sdk/v3";

export const processUpload = task({
  id: "process-upload",
  run: async (payload: { fileId: string; userId: string }) => {
    const file = await downloadFile(payload.fileId);
    const processed = await processFile(file);
    await updateFileRecord(payload.fileId, processed);
    return { success: true };
  },
});

export const generateAIContent = task({
  id: "generate-ai-content",
  run: async (payload: { prompt: string; userId: string }) => {
    const result = await generateWithAI(payload.prompt);
    await saveResult(payload.userId, result);
    return result;
  },
});

// Scheduled task
export const dailyCleanup = task({
  id: "daily-cleanup",
  // Cron configured in dashboard or trigger.config.ts
  run: async () => {
    await deleteExpiredRecords();
    await sendCleanupReport();
  },
});
```

### Trigger Tasks

```typescript
import { processUpload } from "@/trigger/tasks";

// Trigger and wait
const result = await processUpload.triggerAndWait({
  fileId: "123",
  userId: "456",
});

// Trigger and don't wait (fire and forget)
await processUpload.trigger({
  fileId: "123",
  userId: "456",
});

// Trigger with delay
await processUpload.trigger(
  { fileId: "123", userId: "456" },
  { delay: "1h" }
);
```

---

## Option C: Vercel Cron (Simple Scheduled Jobs)

Best for: Simple periodic tasks on Vercel.

### vercel.json

```json
{
  "crons": [
    {
      "path": "/api/cron/daily-cleanup",
      "schedule": "0 2 * * *"
    },
    {
      "path": "/api/cron/hourly-sync",
      "schedule": "0 * * * *"
    }
  ]
}
```

### Cron Route

Create `app/api/cron/daily-cleanup/route.ts`:

```typescript
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  // Verify cron secret (recommended)
  const authHeader = request.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    await deleteExpiredRecords();
    await sendCleanupReport();

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Cron error:", error);
    return NextResponse.json({ error: "Failed" }, { status: 500 });
  }
}
```

### Limitations

- Max 60 second execution on Hobby
- Max 300 seconds on Pro
- No retries built-in
- No event-driven, cron only

---

## Option D: QStash (Upstash)

Best for: Simple queue with Vercel, HTTP-based.

### Install

```bash
npm install @upstash/qstash
```

### Environment

```env
QSTASH_TOKEN=xxxxx
QSTASH_CURRENT_SIGNING_KEY=xxxxx
QSTASH_NEXT_SIGNING_KEY=xxxxx
```

### Publish Message

```typescript
import { Client } from "@upstash/qstash";

const qstash = new Client({
  token: process.env.QSTASH_TOKEN!,
});

// Send to your endpoint
await qstash.publishJSON({
  url: "https://your-app.vercel.app/api/process",
  body: { fileId: "123", userId: "456" },
  retries: 3,
});

// With delay
await qstash.publishJSON({
  url: "https://your-app.vercel.app/api/process",
  body: { data: "..." },
  delay: 60, // seconds
});

// Scheduled
await qstash.publishJSON({
  url: "https://your-app.vercel.app/api/process",
  body: { data: "..." },
  cron: "0 * * * *", // hourly
});
```

### Receive Handler

Create `app/api/process/route.ts`:

```typescript
import { verifySignatureAppRouter } from "@upstash/qstash/nextjs";

async function handler(request: Request) {
  const body = await request.json();

  // Process the job
  await processJob(body);

  return new Response("OK");
}

// Wrap with signature verification
export const POST = verifySignatureAppRouter(handler);
```

---

## Comparison

| Feature | Inngest | Trigger.dev | Vercel Cron | QStash |
|---------|---------|-------------|-------------|--------|
| Event-driven | Yes | Yes | No | Yes |
| Cron | Yes | Yes | Yes | Yes |
| Retries | Built-in | Built-in | Manual | Built-in |
| Long-running | Yes (hours) | Yes | Limited | Limited |
| Steps/Workflow | Yes | Yes | No | No |
| Fan-out | Yes | Yes | No | No |
| Local dev | Yes | Yes | No | No |
| Dashboard | Yes | Yes | No | Yes |
| Pricing | Free tier | Free tier | Free* | Free tier |

**Recommendation:**
- Simple cron → Vercel Cron
- Event-driven/workflows → Inngest
- Complex pipelines → Trigger.dev

---

## Common Patterns

### Webhook Processing

```typescript
// Inngest
export const handleStripeWebhook = inngest.createFunction(
  { id: "stripe-webhook" },
  { event: "stripe/webhook" },
  async ({ event, step }) => {
    const { type, data } = event.data;

    switch (type) {
      case "checkout.session.completed":
        await step.run("fulfill-order", async () => {
          return fulfillOrder(data);
        });
        break;
      case "customer.subscription.updated":
        await step.run("update-subscription", async () => {
          return updateSubscription(data);
        });
        break;
    }
  }
);

// In webhook route
await inngest.send({
  name: "stripe/webhook",
  data: stripeEvent,
});

return new Response("OK");
```

### AI with Progress Updates

```typescript
export const generateReport = inngest.createFunction(
  { id: "generate-report" },
  { event: "report/generate" },
  async ({ event, step }) => {
    const { userId, reportType } = event.data;

    // Update progress in DB so UI can poll
    await step.run("set-progress-10", async () => {
      await updateProgress(userId, 10, "Gathering data...");
    });

    const data = await step.run("gather-data", async () => {
      return gatherReportData(reportType);
    });

    await step.run("set-progress-50", async () => {
      await updateProgress(userId, 50, "Analyzing...");
    });

    const analysis = await step.run("analyze", async () => {
      return analyzeWithAI(data);
    });

    await step.run("set-progress-90", async () => {
      await updateProgress(userId, 90, "Generating PDF...");
    });

    const pdf = await step.run("generate-pdf", async () => {
      return generatePDF(analysis);
    });

    await step.run("complete", async () => {
      await updateProgress(userId, 100, "Complete");
      await saveReport(userId, pdf);
    });

    return { reportId: pdf.id };
  }
);
```

---

## Checklist

### Inngest
- [ ] Package installed
- [ ] Client created
- [ ] Functions defined
- [ ] API route set up
- [ ] Events being sent
- [ ] Local dev server running
- [ ] Production keys configured (when deploying)

### Vercel Cron
- [ ] vercel.json configured
- [ ] Cron routes created
- [ ] CRON_SECRET set (for auth)
- [ ] Tested in preview deployment

### Trigger.dev / QStash
- [ ] Package installed
- [ ] Account/project created
- [ ] Config file set up
- [ ] Tasks/handlers defined
- [ ] API keys configured
