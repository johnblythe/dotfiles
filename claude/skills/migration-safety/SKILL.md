---
name: migration-safety
description: Database migration safety checklist. Covers reversibility, data loss prevention, and deployment strategies.
---

# Migration Safety

Checklist and patterns for safe database migrations. Prevents data loss and production outages.

## When to Use

- Creating Prisma/Drizzle migrations
- Altering table schemas
- Backfilling data
- Renaming columns/tables
- Changing column types

## Risk Assessment

Before writing migration, assess risk:

| Change Type | Risk | Reversible? | Downtime? |
|-------------|------|-------------|-----------|
| Add nullable column | Low | Yes (drop) | No |
| Add column with default | Low | Yes | No |
| Add index | Low-Med | Yes | No* |
| Drop column | **High** | **No** | No |
| Rename column | **High** | Manual | Maybe |
| Change type | Med-High | Depends | Maybe |
| Drop table | **Critical** | **No** | No |
| Add NOT NULL | Med | Yes | No |
| Add foreign key | Med | Yes | No |

*Large tables may lock during index creation

## Pre-Migration Checklist

```markdown
## Migration: {name}

### What's changing?
- [ ] Adding column(s): {list}
- [ ] Removing column(s): {list}
- [ ] Modifying column(s): {list}
- [ ] Adding index(es): {list}
- [ ] Adding constraint(s): {list}
- [ ] Other: {describe}

### Risk Assessment
- **Risk level:** Low / Medium / High / Critical
- **Reversible:** Yes / Partially / No
- **Data loss possible:** Yes / No
- **Downtime required:** Yes / No

### Prerequisites
- [ ] Backup taken (if High/Critical risk)
- [ ] Tested on staging
- [ ] Rollback plan documented
- [ ] Team notified (if production)

### Rollback Plan
{How to undo if something goes wrong}
```

## Safe Patterns

### Adding Nullable Column (Safe)

```prisma
// schema.prisma
model User {
  id        String   @id
  email     String
  nickname  String?  // New nullable column - safe
}
```

```bash
npx prisma migrate dev --name add_user_nickname
```

### Adding Column with Default (Safe)

```prisma
model User {
  isActive Boolean @default(true)  // Safe - existing rows get default
}
```

### Adding Index (Usually Safe)

```prisma
model Post {
  @@index([authorId, createdAt])  // Safe on small-medium tables
}
```

For large tables (1M+ rows), create concurrently:

```sql
-- Manual migration
CREATE INDEX CONCURRENTLY idx_posts_author_date ON posts(author_id, created_at);
```

### Removing Column (Dangerous)

**Never drop columns directly.** Use this process:

1. **Stop writing** - Remove code that writes to column
2. **Deploy** - Ensure no new writes
3. **Stop reading** - Remove code that reads column
4. **Deploy** - Ensure no reads
5. **Drop column** - Now safe

```prisma
// Step 1-4: Column still exists but unused
model User {
  legacyField String?  // TODO: Remove after confirming no usage
}

// Step 5: After confirming no usage
// Remove from schema, run migration
```

### Renaming Column (Dangerous)

Don't rename directly. Instead:

1. Add new column
2. Backfill data: `UPDATE users SET new_name = old_name`
3. Update code to use new column
4. Deploy and verify
5. Drop old column (following removal process)

```prisma
// Step 1: Add new
model User {
  userName String?  // Old
  username String?  // New (temporary both exist)
}

// Step 5: After migration complete
model User {
  username String
}
```

### Changing Column Type

```prisma
// Risky: String -> Int
// Safe approach: Add new column, migrate data, swap

// Step 1: Add new column
model Product {
  priceString String   // Old: "19.99"
  priceCents  Int?     // New: 1999
}

// Step 2: Backfill
// UPDATE products SET price_cents = CAST(REPLACE(price_string, '.', '') AS INT)

// Step 3: Make new column required, remove old
model Product {
  priceCents Int
}
```

### Adding NOT NULL Constraint

Don't add NOT NULL to existing column with nulls. Instead:

1. Backfill null values
2. Add NOT NULL constraint

```sql
-- Step 1: Backfill
UPDATE users SET nickname = 'Anonymous' WHERE nickname IS NULL;

-- Step 2: Add constraint
ALTER TABLE users ALTER COLUMN nickname SET NOT NULL;
```

Or in Prisma:

```prisma
// Before: String?
// After backfill: String @default("Anonymous")
```

## Environment-Specific Concerns

### Local Development

```bash
# Safe to reset
npx prisma migrate reset

# Apply migrations
npx prisma migrate dev
```

### Staging

```bash
# Apply migrations
npx prisma migrate deploy

# Verify before production
```

### Production

```bash
# Never use migrate dev in production!
# Only deploy
npx prisma migrate deploy
```

### Connection Pooling (Supabase, Neon)

```env
# .env
# Pooled connection (port 6543) - for queries
DATABASE_URL="postgresql://...@host:6543/db?pgbouncer=true"

# Direct connection (port 5432) - for migrations
DIRECT_URL="postgresql://...@host:5432/db"
```

Prisma schema:

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}
```

## Backfill Patterns

### Small Table (<100k rows)

```typescript
// In migration or script
await prisma.$executeRaw`
  UPDATE users SET new_field = compute_value(old_field)
`;
```

### Large Table (Batched)

```typescript
const BATCH_SIZE = 1000;
let processed = 0;

while (true) {
  const batch = await prisma.user.findMany({
    where: { newField: null },
    take: BATCH_SIZE,
  });

  if (batch.length === 0) break;

  await prisma.$transaction(
    batch.map(user =>
      prisma.user.update({
        where: { id: user.id },
        data: { newField: computeValue(user.oldField) },
      })
    )
  );

  processed += batch.length;
  console.log(`Processed ${processed} rows`);
}
```

## Rollback Strategies

### Prisma Rollback

```bash
# Rollback last migration (dev only)
npx prisma migrate reset

# Mark migration as rolled back (production)
npx prisma migrate resolve --rolled-back {migration_name}
```

### Manual Rollback

Create explicit down migration:

```sql
-- migrations/rollback_add_nickname.sql
ALTER TABLE users DROP COLUMN nickname;
```

### Point-in-Time Recovery

For critical data loss, use database backup:

```bash
# Neon: Branch from point in time
# Supabase: Restore from backup
# Self-hosted: pg_restore
```

## Output When Applied

```markdown
## Migration Safety Check

**Migration:** `20250104_add_user_preferences`

### Changes
- Add `preferences` column (JSON, nullable)
- Add index on `users.email`

### Risk Assessment
| Aspect | Status |
|--------|--------|
| Risk level | Low |
| Reversible | ✅ Yes |
| Data loss | ✅ None |
| Downtime | ✅ None |

### Checklist
- [x] Tested locally
- [x] Migration is additive (no drops)
- [ ] Tested on staging
- [ ] Team notified

### Rollback Plan
```sql
ALTER TABLE users DROP COLUMN preferences;
DROP INDEX idx_users_email;
```

**Ready to apply:** ✅ Yes
```

## Red Flags

🚨 **Stop and ask** if migration includes:
- `DROP TABLE`
- `DROP COLUMN` without removal process
- `ALTER COLUMN` type change
- `NOT NULL` on column with existing nulls
- Any change to production without staging test
