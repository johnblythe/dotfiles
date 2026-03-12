# Self-Service SFTP Provisioning for Health System Artifacts

## Product Requirements Document

### Executive Summary

Today, onboarding a health system to the Artifacts SFTP requires an engineer to modify Terraform, add IP whitelist rules, manually attach SSH keys, and run `terraform apply`. This creates a 1–3 day turnaround bottleneck for what is fundamentally a configuration task.

This initiative moves SFTP user provisioning into the RCS Portal so PSLs and Digital Operations can onboard health systems themselves — zero engineering involvement.

### Problem Statement

- **14 health systems** currently onboarded; pipeline is growing
- Every new customer requires a `#support-digital-workflows` post → engineer picks it up → Terraform PR → review → apply
- Key rotation follows the same path — manual, slow, undocumented
- IP whitelist changes require code changes to security group rules
- No audit trail for who provisioned what, when

### Personas

| Persona | Need |
|---------|------|
| **PSL / Digital Ops** | Onboard a health system to SFTP in minutes, not days |
| **Health System IT** | Clear connection info and confirmation that setup is complete |
| **Engineering** | Stop doing config-as-code for what should be a portal action |

### User Stories

1. As a PSL, I can create an SFTP user for a health system from the Portal so I don't need to file an engineering request.
2. As a PSL, I can upload a health system's SSH public key so they can authenticate to our SFTP server.
3. As a PSL, I can add/remove source IP addresses for a health system so their network can reach our SFTP server.
4. As a PSL, I can rotate a health system's SSH key when they generate a new one.
5. As a PSL, I can view the current SFTP configuration (username, IPs, key fingerprint, last connection) for any health system.
6. As an engineer, I no longer receive provisioning requests in `#support-digital-workflows` for SFTP setup.

### Scope

**In scope:**
- SFTP user CRUD via Portal UI
- SSH public key upload and rotation
- Source IP allowlisting (add/remove)
- Connection status dashboard (last successful connection timestamp)
- Audit log of all provisioning actions

**Out of scope (v1):**
- Migrating existing 14 users out of Terraform (manual cutover later)
- File format parsers for Epic/Cerner exports (separate initiative)
- Automated file processing pipelines
- Customer-facing self-service portal

### Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Time to onboard new HS to SFTP | 1–3 days | < 15 minutes |
| Engineering tickets for SFTP provisioning | ~2/month | 0 |
| Key rotation turnaround | 1–2 days | < 5 minutes |

### Risks

| Risk | Mitigation |
|------|------------|
| Security — portal users modifying network ACLs | Restrict to PSL/Admin roles; audit log all changes; IP validation (no 0.0.0.0/0) |
| Existing Terraform users drift from portal-managed users | v1 only manages new users; cutover plan for existing 14 in v2 |
| AWS API rate limits on Transfer Family | Low volume (~1-2 provisions/week); not a concern |

---

## Technical Specification

### System Context

```
┌─────────────────────────────────────────────────────┐
│                    RCS Portal                        │
│  ┌─────────────┐    ┌──────────────────────────┐    │
│  │ Artifacts    │    │ SFTP Provisioning UI     │    │
│  │ Tab (exists) │    │ (NEW)                    │    │
│  └─────────────┘    └──────────┬───────────────┘    │
│                                │                     │
└────────────────────────────────┼─────────────────────┘
                                 │ REST API
                                 ▼
┌──────────────────────────────────────────────────────┐
│              worker_pod / ehr_connection_health       │
│  ┌──────────────────────────────────────────────┐    │
│  │ /sftp-provisioning (NEW router)              │    │
│  │   POST   /users/{client_id}                  │    │
│  │   GET    /users/{client_id}                  │    │
│  │   DELETE /users/{client_id}                  │    │
│  │   PUT    /users/{client_id}/ssh-key          │    │
│  │   PUT    /users/{client_id}/allowed-ips      │    │
│  │   GET    /users/{client_id}/status           │    │
│  └──────────────────┬───────────────────────────┘    │
│                     │                                │
└─────────────────────┼────────────────────────────────┘
                      │ boto3
                      ▼
┌──────────────────────────────────────────────────────┐
│                  AWS                                  │
│  ┌────────────────┐  ┌───────────┐  ┌────────────┐  │
│  │ Transfer Family │  │ EC2 / SG  │  │ CloudWatch │  │
│  │ (SFTP server)   │  │ (IP ACLs) │  │ (audit)    │  │
│  └────────────────┘  └───────────┘  └────────────┘  │
│  ┌────────────────┐                                  │
│  │ S3 (artifacts)  │                                  │
│  └────────────────┘                                  │
└──────────────────────────────────────────────────────┘
```

### Design Goals

1. **No Terraform in the loop** — all provisioning via AWS SDK (`boto3`)
2. **Idempotent operations** — re-running create for existing user is safe
3. **Auditable** — every action logged with actor, timestamp, and change
4. **Minimal blast radius** — new service doesn't touch existing Terraform-managed users

### API Design

#### `POST /sftp-provisioning/users/{client_id}`

Create SFTP user + home directory mapping.

**Request:**
```json
{
  "ssh_public_key": "ssh-rsa AAAAB3...",
  "allowed_ips": ["204.139.85.250", "204.139.85.158"],
  "provisioned_by": "jane.doe@datavant.com"
}
```

**What it does:**
1. Calls `transfer_client.create_user()` with:
   - `ServerId`: from config/env
   - `UserName`: `{client_id}`
   - `Role`: existing `no_delete_role` ARN
   - `HomeDirectoryType`: `LOGICAL`
   - `HomeDirectoryMappings`: `[{"Entry": "/", "Target": "/{bucket}/{client_id}"}]`
2. Calls `transfer_client.import_ssh_public_key()` with the provided key
3. Calls `ec2_client.authorize_security_group_ingress()` for each IP (port 22, tagged with client_id)
4. Logs action to CloudWatch + audit table

**Response:** `201 Created`
```json
{
  "username": "newcustomer",
  "sftp_url": "health-system-artifacts-sftp.datavant.com",
  "port": 22,
  "key_fingerprint": "SHA256:abc123...",
  "allowed_ips": ["204.139.85.250"],
  "created_at": "2026-02-26T14:00:00Z",
  "created_by": "jane.doe@datavant.com"
}
```

#### `GET /sftp-provisioning/users/{client_id}`

Returns current config: username, key fingerprint, allowed IPs, last connection time.

**Implementation:** Calls `transfer_client.describe_user()` + `list_tags_for_resource()` + `ec2_client.describe_security_group_rules()` filtered by client_id tag.

#### `PUT /sftp-provisioning/users/{client_id}/ssh-key`

Rotate SSH key. Deletes old key, imports new one.

**Request:**
```json
{
  "ssh_public_key": "ssh-rsa AAAAB3...",
  "rotated_by": "jane.doe@datavant.com"
}
```

**Implementation:**
1. `transfer_client.list_ssh_public_keys()` → get existing key ID
2. `transfer_client.delete_ssh_public_key()` → remove old
3. `transfer_client.import_ssh_public_key()` → add new
4. Log rotation event

#### `PUT /sftp-provisioning/users/{client_id}/allowed-ips`

Replace IP allowlist. Revokes old rules, adds new ones.

**Request:**
```json
{
  "allowed_ips": ["10.0.0.1", "10.0.0.2"],
  "updated_by": "jane.doe@datavant.com"
}
```

**Validation:**
- Must be valid IPv4 addresses
- No `0.0.0.0/0` or overly broad CIDRs
- Max 20 IPs per customer

#### `DELETE /sftp-provisioning/users/{client_id}`

Decommissions user. Removes SFTP user, SSH keys, and IP rules. Does NOT delete S3 data (artifacts persist per retention policy).

#### `GET /sftp-provisioning/users/{client_id}/status`

Returns connection health: last successful auth timestamp, total files uploaded, last file upload time. Sourced from CloudWatch Transfer Family structured logs.

### Data Model

No new database tables. State lives in AWS:
- **User config** → AWS Transfer Family (source of truth)
- **IP rules** → EC2 Security Group rules (tagged with `client_id`)
- **Audit log** → CloudWatch log group + optional DynamoDB audit table
- **Files** → S3 (existing bucket, unchanged)

### Security Considerations

- **Portal auth**: Existing RCS Portal auth; restrict SFTP provisioning endpoints to PSL/Admin roles
- **SSH key validation**: Validate key format (RSA/ED25519, min 2048-bit) before import
- **IP validation**: Block RFC 1918 unless explicitly allowed; block /0 CIDRs; max 20 IPs per customer
- **Audit**: Every mutation logged with actor email, timestamp, before/after state
- **No credential exposure**: SSH private keys never touch our system; we only store public keys (already the case)

### Rollout Plan

**Phase 1 — API + Portal UI (this spec)**
- New `/sftp-provisioning` router in `ehr_connection_health`
- Portal UI tab under Health System Settings → Artifacts → SFTP Config
- New users only; existing 14 remain Terraform-managed

**Phase 2 — Migration (future)**
- Import existing 14 users into API-managed state
- Remove hardcoded Terraform user blocks and IP rules
- Terraform manages only the server infrastructure, not per-customer config

### Size Estimate

| Component | Effort |
|-----------|--------|
| API router + boto3 integration | 3–5 pts |
| Input validation + error handling | 2 pts |
| Portal UI (SFTP config panel) | 3–5 pts |
| Audit logging | 1–2 pts |
| Testing (unit + integration) | 2–3 pts |
| **Total** | **~13–17 pts** |

### Dependencies

- AWS Transfer Family server ID (already deployed, available in env config)
- Security group ID for the SFTP VPC endpoint (already exists in Terraform outputs)
- IAM permissions for the worker_pod service role to call Transfer Family + EC2 APIs
- Existing `no_delete_role` ARN for S3 access (reuse current role)

### Open Questions

1. Should we support CIDR ranges (e.g., `10.0.0.0/24`) or only individual IPs?
2. Do we want email notifications to PSL when a health system first successfully connects?
3. Should the existing 14 Terraform-managed users show as read-only in the Portal, or be hidden until Phase 2 migration?
