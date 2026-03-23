---
name: file-uploads
description: Sets up file uploads in Next.js projects. Supports Supabase Storage (default), S3, or Uploadthing. Covers images, documents, and presigned URLs.
---

# File Uploads Setup

## Ask First

1. **Storage provider?**
   - Supabase Storage (recommended if already using Supabase)
   - AWS S3 / S3-compatible (Cloudflare R2, etc.)
   - Uploadthing (simplest, hosted solution)

2. **File types?**
   - Images only
   - Documents (PDF, etc.)
   - Any files

3. **Access control?**
   - Public (anyone can view)
   - Private (authenticated users only)
   - Mixed (some public, some private)

## Provider: Supabase Storage (Recommended)

### Setup Storage Bucket

In Supabase Dashboard > Storage:
1. Create bucket (e.g., "uploads")
2. Set public/private
3. Configure file size limits

Or via SQL:

```sql
-- Create public bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('uploads', 'uploads', true);

-- Create private bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('private-files', 'private-files', false);
```

### RLS Policies

```sql
-- Allow authenticated users to upload
CREATE POLICY "Users can upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to read their own files
CREATE POLICY "Users can view own files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own files
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Public bucket: anyone can read
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'public-uploads');
```

### Upload Utility

Create `lib/storage.ts`:

```typescript
import { createClient } from "@/lib/supabase/client";

export async function uploadFile(
  file: File,
  bucket: string = "uploads",
  path?: string
) {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) throw new Error("Not authenticated");

  // Create unique filename
  const fileExt = file.name.split(".").pop();
  const fileName = `${Date.now()}-${Math.random().toString(36).slice(2)}.${fileExt}`;
  const filePath = path ? `${user.id}/${path}/${fileName}` : `${user.id}/${fileName}`;

  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(filePath, file, {
      cacheControl: "3600",
      upsert: false,
    });

  if (error) throw error;

  // Get public URL (for public buckets)
  const { data: { publicUrl } } = supabase.storage
    .from(bucket)
    .getPublicUrl(data.path);

  return { path: data.path, url: publicUrl };
}

export async function deleteFile(path: string, bucket: string = "uploads") {
  const supabase = createClient();

  const { error } = await supabase.storage.from(bucket).remove([path]);

  if (error) throw error;
}

export async function getSignedUrl(
  path: string,
  bucket: string = "uploads",
  expiresIn: number = 3600
) {
  const supabase = createClient();

  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, expiresIn);

  if (error) throw error;

  return data.signedUrl;
}
```

### Upload Component

```tsx
"use client";

import { useState, useRef } from "react";
import { uploadFile } from "@/lib/storage";

interface FileUploadProps {
  onUpload: (url: string, path: string) => void;
  accept?: string;
  maxSize?: number; // in MB
}

export function FileUpload({
  onUpload,
  accept = "image/*",
  maxSize = 5,
}: FileUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate size
    if (file.size > maxSize * 1024 * 1024) {
      setError(`File size must be less than ${maxSize}MB`);
      return;
    }

    setUploading(true);
    setError(null);

    try {
      const { url, path } = await uploadFile(file);
      onUpload(url, path);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed");
    } finally {
      setUploading(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  };

  return (
    <div>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        onChange={handleUpload}
        disabled={uploading}
      />
      {uploading && <p>Uploading...</p>}
      {error && <p className="text-red-500">{error}</p>}
    </div>
  );
}
```

### Drag & Drop Upload

```tsx
"use client";

import { useState, useCallback } from "react";
import { uploadFile } from "@/lib/storage";

interface DropzoneProps {
  onUpload: (url: string, path: string) => void;
  accept?: string[];
  maxSize?: number;
}

export function Dropzone({
  onUpload,
  accept = ["image/jpeg", "image/png", "image/webp"],
  maxSize = 5,
}: DropzoneProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [uploading, setUploading] = useState(false);

  const handleDrop = useCallback(
    async (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);

      const file = e.dataTransfer.files[0];
      if (!file) return;

      if (!accept.includes(file.type)) {
        alert("Invalid file type");
        return;
      }

      if (file.size > maxSize * 1024 * 1024) {
        alert(`File must be less than ${maxSize}MB`);
        return;
      }

      setUploading(true);
      try {
        const { url, path } = await uploadFile(file);
        onUpload(url, path);
      } catch (err) {
        console.error(err);
      } finally {
        setUploading(false);
      }
    },
    [accept, maxSize, onUpload]
  );

  return (
    <div
      onDragOver={(e) => {
        e.preventDefault();
        setIsDragging(true);
      }}
      onDragLeave={() => setIsDragging(false)}
      onDrop={handleDrop}
      className={`
        border-2 border-dashed rounded-lg p-8 text-center cursor-pointer
        ${isDragging ? "border-blue-500 bg-blue-50" : "border-gray-300"}
        ${uploading ? "opacity-50" : ""}
      `}
    >
      {uploading ? "Uploading..." : "Drop file here or click to upload"}
    </div>
  );
}
```

## Provider: AWS S3 / S3-Compatible

### Install

```bash
npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
```

### Environment

```env
AWS_ACCESS_KEY_ID=xxxxx
AWS_SECRET_ACCESS_KEY=xxxxx
AWS_REGION=us-east-1
AWS_S3_BUCKET=my-bucket

# For S3-compatible (Cloudflare R2, etc.)
# AWS_ENDPOINT=https://xxx.r2.cloudflarestorage.com
```

### S3 Client

Create `lib/s3.ts`:

```typescript
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

export const s3 = new S3Client({
  region: process.env.AWS_REGION!,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
  // Uncomment for S3-compatible services
  // endpoint: process.env.AWS_ENDPOINT,
  // forcePathStyle: true,
});

export async function uploadToS3(
  file: Buffer,
  key: string,
  contentType: string
) {
  await s3.send(
    new PutObjectCommand({
      Bucket: process.env.AWS_S3_BUCKET!,
      Key: key,
      Body: file,
      ContentType: contentType,
    })
  );

  return `https://${process.env.AWS_S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
}

export async function deleteFromS3(key: string) {
  await s3.send(
    new DeleteObjectCommand({
      Bucket: process.env.AWS_S3_BUCKET!,
      Key: key,
    })
  );
}

export async function getPresignedUploadUrl(
  key: string,
  contentType: string,
  expiresIn: number = 3600
) {
  const command = new PutObjectCommand({
    Bucket: process.env.AWS_S3_BUCKET!,
    Key: key,
    ContentType: contentType,
  });

  return getSignedUrl(s3, command, { expiresIn });
}

export async function getPresignedDownloadUrl(
  key: string,
  expiresIn: number = 3600
) {
  const command = new GetObjectCommand({
    Bucket: process.env.AWS_S3_BUCKET!,
    Key: key,
  });

  return getSignedUrl(s3, command, { expiresIn });
}
```

### Presigned Upload API Route

Create `app/api/upload/presign/route.ts`:

```typescript
import { getPresignedUploadUrl } from "@/lib/s3";
import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { filename, contentType } = await request.json();

  const key = `${user.id}/${Date.now()}-${filename}`;
  const url = await getPresignedUploadUrl(key, contentType);

  return NextResponse.json({ url, key });
}
```

### Client-Side Upload with Presigned URL

```typescript
async function uploadWithPresignedUrl(file: File) {
  // Get presigned URL
  const response = await fetch("/api/upload/presign", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      filename: file.name,
      contentType: file.type,
    }),
  });

  const { url, key } = await response.json();

  // Upload directly to S3
  await fetch(url, {
    method: "PUT",
    body: file,
    headers: { "Content-Type": file.type },
  });

  return key;
}
```

## Provider: Uploadthing

### Install

```bash
npm install uploadthing @uploadthing/react
```

### Environment

```env
UPLOADTHING_SECRET=sk_live_xxxxx
UPLOADTHING_APP_ID=xxxxx
```

### Core Setup

Create `lib/uploadthing.ts`:

```typescript
import { createUploadthing, type FileRouter } from "uploadthing/next";

const f = createUploadthing();

export const ourFileRouter = {
  imageUploader: f({ image: { maxFileSize: "4MB", maxFileCount: 1 } })
    .middleware(async ({ req }) => {
      // Auth check here
      return { userId: "user_123" };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      console.log("Upload complete:", file.url);
      return { url: file.url };
    }),

  documentUploader: f({ pdf: { maxFileSize: "16MB" } })
    .middleware(async ({ req }) => {
      return { userId: "user_123" };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      return { url: file.url };
    }),
} satisfies FileRouter;

export type OurFileRouter = typeof ourFileRouter;
```

### API Route

Create `app/api/uploadthing/route.ts`:

```typescript
import { createRouteHandler } from "uploadthing/next";
import { ourFileRouter } from "@/lib/uploadthing";

export const { GET, POST } = createRouteHandler({
  router: ourFileRouter,
});
```

### Upload Component

```tsx
"use client";

import { UploadButton } from "@uploadthing/react";
import type { OurFileRouter } from "@/lib/uploadthing";

export function ImageUploader() {
  return (
    <UploadButton<OurFileRouter, "imageUploader">
      endpoint="imageUploader"
      onClientUploadComplete={(res) => {
        console.log("Files:", res);
      }}
      onUploadError={(error: Error) => {
        console.error("Error:", error.message);
      }}
    />
  );
}
```

## Image Optimization

### With Next.js Image

```tsx
import Image from "next/image";

// For Supabase Storage
<Image
  src={`${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/uploads/${path}`}
  alt="Uploaded image"
  width={300}
  height={200}
/>

// Add to next.config.js
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
      {
        protocol: 'https',
        hostname: '*.amazonaws.com',
      },
    ],
  },
};
```

### Image Resize on Upload

```typescript
// Using sharp (server-side only)
import sharp from "sharp";

async function resizeImage(buffer: Buffer, maxWidth: number = 1200) {
  return sharp(buffer)
    .resize(maxWidth, null, { withoutEnlargement: true })
    .jpeg({ quality: 80 })
    .toBuffer();
}
```

## Server Action Upload

```typescript
"use server";

import { createClient } from "@/lib/supabase/server";

export async function uploadAction(formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) throw new Error("Not authenticated");

  const file = formData.get("file") as File;
  if (!file) throw new Error("No file provided");

  const buffer = Buffer.from(await file.arrayBuffer());
  const fileName = `${user.id}/${Date.now()}-${file.name}`;

  const { data, error } = await supabase.storage
    .from("uploads")
    .upload(fileName, buffer, {
      contentType: file.type,
    });

  if (error) throw error;

  const { data: { publicUrl } } = supabase.storage
    .from("uploads")
    .getPublicUrl(data.path);

  return { url: publicUrl, path: data.path };
}
```

## Common Patterns

### Avatar Upload

```tsx
"use client";

import { useState } from "react";
import Image from "next/image";
import { uploadFile } from "@/lib/storage";

export function AvatarUpload({
  currentUrl,
  onUpdate,
}: {
  currentUrl?: string;
  onUpdate: (url: string) => void;
}) {
  const [preview, setPreview] = useState(currentUrl);

  const handleChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Show preview immediately
    setPreview(URL.createObjectURL(file));

    const { url } = await uploadFile(file, "avatars");
    onUpdate(url);
  };

  return (
    <label className="cursor-pointer">
      <div className="w-24 h-24 rounded-full overflow-hidden bg-gray-200">
        {preview && (
          <Image src={preview} alt="Avatar" width={96} height={96} className="object-cover" />
        )}
      </div>
      <input type="file" accept="image/*" onChange={handleChange} className="hidden" />
    </label>
  );
}
```

### Multi-File Upload

```typescript
async function uploadMultiple(files: File[]) {
  const results = await Promise.all(
    files.map((file) => uploadFile(file))
  );
  return results;
}
```

## Checklist

- [ ] Storage provider chosen
- [ ] Environment variables set
- [ ] Storage bucket/bucket created
- [ ] Access policies configured (RLS for Supabase)
- [ ] Upload utility created
- [ ] Upload component built
- [ ] (Optional) Image optimization configured
- [ ] (Optional) Presigned URLs for large files
- [ ] next.config.js updated for remote images
- [ ] File size limits enforced
- [ ] File type validation implemented
