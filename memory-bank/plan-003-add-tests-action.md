# Plan: Add Tests Action (Issue #3)

## Context

Tests (`go test ./...`) run only manually. This change adds a CI job so broken code cannot be merged to `main`. Spec: `memory-bank/spec-003-add-tests-action.md`.

## Files to Modify

- `.github/workflows/ci.yml` — add `test` job, update `on` block

## Steps

### Step 1 — Update `on` block (R2)

In `.github/workflows/ci.yml`, replace:

```yaml
on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:
```

with:

```yaml
on:
  pull_request:
  push:
  workflow_dispatch:
```

This removes `branches: [main]` so pushes to all branches trigger CI.

### Step 2 — Add `test` job (R1)

Append after the `smoke-bootstrap` job block (after line 79):

```yaml
  test:
    name: Test
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout
        uses: actions/checkout@93cb6efe18208431cddfb8368fd83d5badbf9bfd # v5.0.1

      - name: Setup Go
        uses: actions/setup-go@d35c59abb061a4a6fb18e82ac0862c26744d6ab5 # v5.5.0
        with:
          go-version-file: go.mod
          cache: true

      - name: Run tests
        run: go test ./...
```

Checkout SHA matches existing jobs. No `needs` — runs in parallel with `lint` and `smoke-bootstrap`.

### Step 3 — Verify invariants (I1–I7)

Read back the full file and confirm:

- Single workflow file (I1)
- `lint` and `smoke-bootstrap` job keys unchanged (I2)
- Job names `Lint` and `Smoke (${{ matrix.os }})` unchanged (I3)
- Existing jobs' steps/config untouched (I4)
- Top-level `permissions: contents: read` unchanged (I5)
- `concurrency` block unchanged (I6)
- No `needs` on `test` job (I7)

### Step 4 — Commit and push

Commit the `ci.yml` change, push to the current branch (`3-test-action-in-ci`).

### Step 5 — Wait for CI and verify `Test` job exists (R3.2 pre-check)

1. Wait for CI run to complete and get its ID:
   `gh run list --workflow=ci.yml --branch=3-test-action-in-ci --limit=1 --json databaseId,status,conclusion`
2. Verify `Test` appears in jobs (substitute the `databaseId` from step 1):
   `gh run view <databaseId> --json jobs --jq '.jobs[].name'`
3. If `Test` is not in the list — stop. Fix the YAML before proceeding.

### Step 6 — Set branch protection (R3)

1. Run `gh auth status` — stop if not authenticated.
2. Run:

```bash
gh api repos/asusikov/ai-setup/branches/main/protection \
  --method PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["Test"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF
```

3. Handle errors per R3.1 table in spec.

### Step 7 — Create PR and verify merge gate (R3.2)

1. Create a PR from `3-test-action-in-ci` to `main`:
   `gh pr create --base main --head 3-test-action-in-ci --title "Add test job to CI" --body "Closes #3"`
   (Skip if PR already exists — check with `gh pr list --head 3-test-action-in-ci`.)
2. Get the PR number and verify the `Test` check is visible:
   `gh pr list --head 3-test-action-in-ci --base main --json number --jq '.[0].number'`
   Then using the returned number:
   `gh pr checks <number>` — confirm `Test` is listed.
3. Verify branch protection requires `Test` by querying the rule directly:
   `gh api repos/asusikov/ai-setup/branches/main/protection/required_status_checks --jq '.contexts'`
   — output must include `Test`.

## Verification

- CI run on the branch shows four parallel jobs: `Lint`, `Smoke (ubuntu-latest)`, `Smoke (macos-latest)`, `Test`
- `Test` job runs `go test ./...` and passes
- Branch protection on `main` requires `Test` check
