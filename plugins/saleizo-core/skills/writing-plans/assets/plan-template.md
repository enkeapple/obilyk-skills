# Plan Template

The header goes once at the top; the task block repeats per task. Keep `- [ ]` checkbox syntax so execution can track progress. Every code step shows real code; every command step shows the exact command + expected output.

## Header

```markdown
# <Feature> Implementation Plan

**Goal:** <one sentence>
**Architecture:** <2-3 sentences>
**Tech stack:** <key technologies>

## Global constraints
<project-wide requirements copied verbatim from the spec — one line each>

---
```

## Task block

````markdown
### Task N: <Component>

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:123-145`
- Test: `exact/path/to/file.test.ext`

**Interfaces:**
- Consumes: <exact signatures used from earlier tasks>
- Produces: <exact names, param + return types later tasks rely on>

- [ ] **Step 1: Write the failing test**
```ts
// real test code
```

- [ ] **Step 2: Run the test, confirm it fails**
Run: `<exact command>`
Expected: FAIL — `<the specific error you expect>`

- [ ] **Step 3: Write the minimal implementation**
```ts
// real implementation code
```

- [ ] **Step 4: Run the test, confirm it passes**
Run: `<exact command>`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add <paths> && git commit -m "<message>"
```
````

## Filled example (one task)

A concrete reference for the level of detail expected. Language and commands are illustrative — match your repo's stack.

````markdown
### Task 1: listUsers cursor pagination

**Files:**
- Modify: `api/users.ts`
- Test: `api/users.test.ts`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `listUsers(cursor?: string): Promise<{ users: User[]; nextCursor: string | null }>`

- [ ] **Step 1: Write the failing test**
```ts
import { listUsers } from "./users";

test("first page returns users and a nextCursor", async () => {
  const page = await listUsers();
  expect(page.users.length).toBe(20);
  expect(typeof page.nextCursor).toBe("string");
});

test("last page returns nextCursor null", async () => {
  const page = await listUsers("cursor-for-final-page");
  expect(page.nextCursor).toBeNull();
});
```

- [ ] **Step 2: Run the test, confirm it fails**
Run: `npm test -- api/users.test.ts`
Expected: FAIL — `listUsers is not a function` (not yet exported).

- [ ] **Step 3: Write the minimal implementation**
```ts
const PAGE_SIZE = 20;

export async function listUsers(
  cursor?: string,
): Promise<{ users: User[]; nextCursor: string | null }> {
  const rows = await db.users({ after: cursor, limit: PAGE_SIZE + 1 });
  const users = rows.slice(0, PAGE_SIZE);
  const nextCursor = rows.length > PAGE_SIZE ? rows[PAGE_SIZE - 1].id : null;
  return { users, nextCursor };
}
```

- [ ] **Step 4: Run the test, confirm it passes**
Run: `npm test -- api/users.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add api/users.ts api/users.test.ts && git commit -m "feat(api): cursor pagination for listUsers"
```
````
