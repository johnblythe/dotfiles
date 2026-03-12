# Claude Workflow Starter Templates — DW Team

These are ready-to-use prompts the team can try on 2-3 tickets this sprint.
Each one maps to a real ticket type from the current sprint.

---

## Workflow 1: Migration DDL Generator

**Maps to:** PDC-6952 (Ben's tracking table), PDC-6758/6759 (Daniel's migration)
**Saves:** 70-80% of mechanical work

### Prompt Template

```
I need a database migration for our Java/MyBatis application.

**Table Spec:**
[Paste the schema from your ticket description - columns, types, constraints]

**Generate:**
1. Flyway SQL migration file (V{next_version}__create_{table_name}.sql)
   - Include CREATE TABLE with all constraints
   - Include CREATE INDEX for foreign keys and common query columns
   - Include COMMENT ON TABLE and COMMENT ON COLUMN
2. MyBatis mapper additions (XML format)
   - INSERT method
   - SELECT by primary key
   - SELECT by foreign key (e.g., REQUEST_ID)
   - UPDATE method
3. Java POJO class
   - Fields matching all columns with appropriate Java types
   - NUMBER → Long, VARCHAR2 → String, DATE → LocalDateTime
   - Lombok @Data annotation
   - Builder pattern

**Conventions:**
- Table prefix: EREQUEST_ (for request-related tables)
- Sequence naming: SEQ_{TABLE_NAME}
- MyBatis namespace matches DAO interface name
- DAO interface in com.ciox.eip.dao package
- POJO in com.ciox.eip.model package
```

### Example Input (from PDC-6952)

```sql
CREATE TABLE EREQUEST_DF_RETRY (
  ID NUMBER PRIMARY KEY,
  REQUEST_ID NUMBER NOT NULL,
  RETRY_COUNT NUMBER DEFAULT 0,
  LAST_RETRY_DATE DATE,
  STATUS VARCHAR2(50) NOT NULL,
  ERROR_MESSAGE VARCHAR2(4000),
  CREATED_DATE DATE DEFAULT SYSDATE,
  MODIFIED_DATE DATE DEFAULT SYSDATE
);
```

### What Claude Produces vs What You Review
| Claude Generates | You Verify |
|-----------------|------------|
| DDL with constraints | Business logic for defaults |
| MyBatis CRUD methods | Query performance (indexes) |
| POJO with annotations | Field naming conventions |
| Sequence creation | Rollback migration |

---

## Workflow 2: Test Scaffold Generator

**Maps to:** PDC-6708 (Gene's E2E tests), PDC-6951 (Ben's endpoint tests)
**Saves:** 50-60% of test setup boilerplate

### Prompt Template

```
Generate a test scaffold for the following Java service method.

**Class:** [ClassName]
**Method Signature:**
[Paste the method signature]

**Method Description:**
[What does this method do? Key business rules?]

**Dependencies to Mock:**
[List DAOs, services, or external calls this method uses]

**Generate:**
1. JUnit 5 test class with @ExtendWith(MockitoExtension.class)
2. @Mock annotations for each dependency
3. @InjectMocks for the class under test
4. Test methods for:
   - Happy path (valid input → expected output)
   - Null/empty input handling
   - Each business rule branch
   - Exception cases
5. Use @DisplayName with clear descriptions
6. Use AssertJ assertions (assertThat style)

**Conventions:**
- Test class: {ClassName}Test.java
- Package: same as source + no separate test package
- Each test method: test_{scenario}_{expectedResult}
- Use @BeforeEach for common setup
```

### Example Input

```java
// Class: WorkflowWebServiceImpl
// Method:
public DfRetryEligibilityResponse checkDfRetryEligibility(
    Long requestId, String userId) throws ServiceException

// Description: Checks if a request is eligible for DF retry.
// Rules: Must have status COMPLETED_WITH_ERROR, retry count < 3,
//        last retry > 24h ago. Returns eligibility + reason.

// Mocks needed: RequestServiceDAO, DfRetryDAO, AuditTrailService
```

### What Claude Produces vs What You Review
| Claude Generates | You Verify |
|-----------------|------------|
| Test class structure | Business rule coverage |
| Mock setup | Edge cases specific to domain |
| Happy path test | Integration test needs |
| Exception tests | Test data realism |

---

## Workflow 3: Code Review Accelerator

**Maps to:** PDC-5111 (Pryce's rename), PDC-6641 (transparency tags)
**Saves:** 1-2h per stuck review

### Prompt Template

```
Review this PR for correctness and suggest improvements.

**PR Description:**
[Paste the PR description or ticket summary]

**Changed Files:**
[Paste the file diff or list of changed files with key changes]

**Review Focus:**
1. Does the change match what the ticket asks for?
2. Are there any regressions? (removed functionality, changed signatures)
3. Are there missing null checks or error handling?
4. Are new methods tested?
5. Does the naming follow existing conventions?
6. Any performance concerns? (N+1 queries, unnecessary loops)

**Our Conventions:**
- Java: camelCase methods, PascalCase classes
- MyBatis: XML mappers, not annotations
- Angular: OnPush change detection preferred
- Tests: JUnit 5 + Mockito + AssertJ
```

### What Claude Produces vs What You Review
| Claude Generates | You Verify |
|-----------------|------------|
| Line-by-line review comments | Architectural fit |
| Convention violations | Domain logic correctness |
| Missing test coverage flags | Performance at scale |
| Suggested fixes | Cross-service impact |

---

## Workflow 4: Config Pattern Applicator

**Maps to:** PDC-5974/5975 (cache policies), PDC-6569 (deploy config)
**Saves:** 1h per endpoint when pattern exists

### Prompt Template

```
Apply an existing code pattern to a new context.

**Reference Implementation (the pattern):**
[Paste the file/code that represents the established pattern]

**New Context:**
[Which endpoint/service/config needs the same pattern applied?]

**Differences:**
[What's different? New table name, different field names, etc.]

**Generate:**
The same pattern applied to the new context, with:
- All names updated to match the new context
- Same structure and conventions as the reference
- Comments where the new context might need different behavior
```

### Example Input (from PDC-5974)

```
Reference: PDC-6276 (completed) - cache policy for /request/search endpoint
  File: RequestConfigDataCache.java, lines 45-89
  Pattern: @Cacheable annotation + TTL config + invalidation on write

New context: Apply same cache policy to /request/details endpoint
  Endpoint: RequestDetailsWebService.getRequestDetails()
  Differences: Different cache key (requestId vs searchCriteria),
               longer TTL acceptable (data changes less often)
```

---

## How to Start

### This Sprint (pick 2-3)
1. **Ben:** Use Workflow 1 for PDC-6952 (tracking table migration)
2. **Gene:** Use Workflow 2 for PDC-6708 (E2E test scaffold)
3. **Edd:** Use Workflow 4 for PDC-5974/5975 (cache policy application)

### Feedback Loop
After trying a workflow:
- Did it save time? Estimate how much.
- What did Claude get wrong? (helps calibrate prompts)
- What would you add to the template?

We'll iterate the templates based on real usage.

---

## What Claude Won't Do (Important)

- Won't make architectural decisions (which service owns what)
- Won't know your deploy pipeline (feature flags, env configs)
- Won't understand undocumented tribal knowledge
- Won't replace design thinking or code review judgment
- **Will** handle: scaffolding, boilerplate, pattern repetition, find-replace, test stubs

**The human writes the recipe. Claude does the prep work.**
