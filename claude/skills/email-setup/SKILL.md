---
name: email-setup
description: Sets up transactional email in Next.js projects. Supports Resend (default), SendGrid, or Postmark. Includes templates and React Email integration.
---

# Email Setup

## Ask First

Before implementing, clarify:
1. **Provider preference?** (Resend recommended, also: SendGrid, Postmark)
2. **React Email?** (component-based templates - recommended)
3. **Email types needed?** (welcome, password reset, notifications, etc.)

## Provider: Resend (Recommended)

### Install
```bash
npm install resend
# Optional: React Email for templates
npm install @react-email/components
```

### Environment
```env
RESEND_API_KEY=re_xxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com
```

### Basic Setup

Create `lib/email/index.ts`:

```typescript
import { Resend } from "resend";

export const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendEmail({
  to,
  subject,
  html,
  react,
}: {
  to: string | string[];
  subject: string;
  html?: string;
  react?: React.ReactElement;
}) {
  try {
    const { data, error } = await resend.emails.send({
      from: process.env.EMAIL_FROM!,
      to,
      subject,
      html,
      react,
    });

    if (error) {
      console.error("Email error:", error);
      return { success: false, error };
    }

    return { success: true, id: data?.id };
  } catch (error) {
    console.error("Email error:", error);
    return { success: false, error };
  }
}
```

## Provider: SendGrid

### Install
```bash
npm install @sendgrid/mail
```

### Environment
```env
SENDGRID_API_KEY=SG.xxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com
```

### Setup

```typescript
import sgMail from "@sendgrid/mail";

sgMail.setApiKey(process.env.SENDGRID_API_KEY!);

export async function sendEmail({
  to,
  subject,
  html,
  text,
}: {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
}) {
  try {
    await sgMail.send({
      to,
      from: process.env.EMAIL_FROM!,
      subject,
      html,
      text,
    });
    return { success: true };
  } catch (error) {
    console.error("Email error:", error);
    return { success: false, error };
  }
}
```

## Provider: Postmark

### Install
```bash
npm install postmark
```

### Environment
```env
POSTMARK_API_KEY=xxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com
```

### Setup

```typescript
import { ServerClient } from "postmark";

const client = new ServerClient(process.env.POSTMARK_API_KEY!);

export async function sendEmail({
  to,
  subject,
  htmlBody,
  textBody,
}: {
  to: string;
  subject: string;
  htmlBody: string;
  textBody?: string;
}) {
  try {
    const response = await client.sendEmail({
      From: process.env.EMAIL_FROM!,
      To: to,
      Subject: subject,
      HtmlBody: htmlBody,
      TextBody: textBody,
    });
    return { success: true, id: response.MessageID };
  } catch (error) {
    console.error("Email error:", error);
    return { success: false, error };
  }
}
```

## React Email Templates

### Structure
```
emails/
  welcome.tsx
  password-reset.tsx
  notification.tsx
```

### Base Template

Create `emails/components/base.tsx`:

```tsx
import {
  Body,
  Container,
  Head,
  Html,
  Preview,
  Section,
} from "@react-email/components";

interface BaseEmailProps {
  preview: string;
  children: React.ReactNode;
}

export function BaseEmail({ preview, children }: BaseEmailProps) {
  return (
    <Html>
      <Head />
      <Preview>{preview}</Preview>
      <Body style={main}>
        <Container style={container}>
          {children}
        </Container>
      </Body>
    </Html>
  );
}

const main = {
  backgroundColor: "#f6f9fc",
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif',
};

const container = {
  backgroundColor: "#ffffff",
  margin: "0 auto",
  padding: "20px 0 48px",
  marginBottom: "64px",
};
```

### Welcome Email Example

Create `emails/welcome.tsx`:

```tsx
import { Button, Heading, Text } from "@react-email/components";
import { BaseEmail } from "./components/base";

interface WelcomeEmailProps {
  name: string;
  loginUrl: string;
}

export function WelcomeEmail({ name, loginUrl }: WelcomeEmailProps) {
  return (
    <BaseEmail preview={`Welcome to the app, ${name}!`}>
      <Heading style={heading}>Welcome, {name}!</Heading>
      <Text style={text}>
        Thanks for signing up. We're excited to have you on board.
      </Text>
      <Button style={button} href={loginUrl}>
        Get Started
      </Button>
    </BaseEmail>
  );
}

const heading = {
  fontSize: "24px",
  fontWeight: "bold",
  marginBottom: "20px",
};

const text = {
  fontSize: "16px",
  lineHeight: "26px",
  marginBottom: "20px",
};

const button = {
  backgroundColor: "#000",
  borderRadius: "4px",
  color: "#fff",
  fontSize: "16px",
  textDecoration: "none",
  textAlign: "center" as const,
  display: "block",
  padding: "12px 20px",
};

export default WelcomeEmail;
```

### Password Reset Email

Create `emails/password-reset.tsx`:

```tsx
import { Button, Heading, Text } from "@react-email/components";
import { BaseEmail } from "./components/base";

interface PasswordResetEmailProps {
  resetUrl: string;
  expiresIn?: string;
}

export function PasswordResetEmail({
  resetUrl,
  expiresIn = "1 hour",
}: PasswordResetEmailProps) {
  return (
    <BaseEmail preview="Reset your password">
      <Heading style={heading}>Reset Your Password</Heading>
      <Text style={text}>
        Click the button below to reset your password. This link expires in {expiresIn}.
      </Text>
      <Button style={button} href={resetUrl}>
        Reset Password
      </Button>
      <Text style={muted}>
        If you didn't request this, you can safely ignore this email.
      </Text>
    </BaseEmail>
  );
}

const heading = { fontSize: "24px", fontWeight: "bold", marginBottom: "20px" };
const text = { fontSize: "16px", lineHeight: "26px", marginBottom: "20px" };
const muted = { fontSize: "14px", color: "#666", marginTop: "20px" };
const button = {
  backgroundColor: "#000",
  borderRadius: "4px",
  color: "#fff",
  fontSize: "16px",
  textDecoration: "none",
  textAlign: "center" as const,
  display: "block",
  padding: "12px 20px",
};

export default PasswordResetEmail;
```

## Usage Examples

### Send welcome email
```typescript
import { sendEmail } from "@/lib/email";
import { WelcomeEmail } from "@/emails/welcome";

await sendEmail({
  to: user.email,
  subject: "Welcome to the app!",
  react: <WelcomeEmail name={user.name} loginUrl="https://app.com/login" />,
});
```

### Send from Server Action
```typescript
"use server";

import { sendEmail } from "@/lib/email";
import { WelcomeEmail } from "@/emails/welcome";

export async function sendWelcomeEmail(email: string, name: string) {
  return sendEmail({
    to: email,
    subject: "Welcome!",
    react: <WelcomeEmail name={name} loginUrl={`${process.env.NEXT_PUBLIC_SITE_URL}/login`} />,
  });
}
```

### Send from API Route
```typescript
import { sendEmail } from "@/lib/email";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const { email, name } = await request.json();

  const result = await sendEmail({
    to: email,
    subject: "Hello!",
    html: `<h1>Hello ${name}!</h1>`,
  });

  if (!result.success) {
    return NextResponse.json({ error: "Failed to send" }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
```

## Preview Emails Locally

With React Email:

```bash
npx react-email dev
```

Opens browser at localhost:3001 with live preview of templates.

## Domain Verification

### Resend
1. Go to resend.com/domains
2. Add your domain
3. Add DNS records (DKIM, SPF)
4. Wait for verification

### SendGrid
1. Settings > Sender Authentication
2. Authenticate domain
3. Add DNS records

### Postmark
1. Sender Signatures
2. Add domain
3. Add DNS records

## Checklist

- [ ] Provider chosen and API key obtained
- [ ] Environment variables set
- [ ] Email utility created (lib/email/)
- [ ] (Optional) React Email installed
- [ ] (Optional) Email templates created
- [ ] Domain verified in provider dashboard
- [ ] Test email sent successfully
