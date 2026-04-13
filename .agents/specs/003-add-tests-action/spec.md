# Specification: Add Tests Action

- **Brief:** [Issue #3](https://github.com/asusikov/ai-setup/issues/3)

## Problem

Tests (`go test ./...`) run only manually. No automated gate prevents merging broken code.

## Constraints

- CI must use GitHub Actions (org policy).
- Go 1.26.2 (from `go.mod`).

### Invariants

The existing `.github/workflows/ci.yml` must not be altered beyond adding the `test` job and changing the `on` block. Any violation is a failed implementation.

| # | Invariant |
|---|-----------|
| I1 | Single workflow file — do not create a second one. |
| I2 | Job keys `lint` and `smoke-bootstrap` unchanged. |
| I3 | Job names `Lint` and `Smoke (${{ matrix.os }})` unchanged. |
| I4 | Existing jobs' `runs-on`, `timeout-minutes`, `strategy`, `env`, `permissions`, `steps` unchanged. |
| I5 | Top-level `permissions: contents: read` unchanged. |
| I6 | `concurrency` block unchanged. New job inherits it. |
| I7 | No `needs` between `test` and existing jobs. All run in parallel. |

## In Scope

1. GitHub Actions job running `go test ./...`.
2. Push triggers on all branches.
3. Branch protection on `main` requiring the test job.
4. Test results visible in PR Checks tab.

## Out of Scope

Adding new tests, coverage reporting, notifications, deployment.

## R1 — Test Job

Add to `.github/workflows/ci.yml`. Job key: `test`, name: `Test`. GitHub uses `name` as the status check context — branch protection (R3) references this exact string.

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

**Key decisions:** Checkout SHA matches existing jobs. `setup-go` with `cache: true` handles module and build cache — no separate cache step. Go version read from `go.mod` (single source of truth).

## R2 — Triggers

Replace the `on` block:

```yaml
on:
  pull_request:
  push:
  workflow_dispatch:
```

Only change: removed `branches: [main]` under `push`. Now pushes to all branches trigger the workflow.

## R3 — Branch Protection

Required check context: **`Test`** (must match R1 job `name` exactly).

**Precondition:** Run `gh auth status`. If it fails — stop, do not attempt the PUT.

**API call:**

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
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

`strict: false` — PRs don't need to be up-to-date. `enforce_admins: true` — admins can't bypass. `null` fields — reviews and push restrictions are out of scope.

The PUT is **idempotent** — it replaces the entire rule. "Rule already exists" is not an error.

### R3.1 — Error States

| # | Condition | Detection | Action | Retry? |
|---|-----------|-----------|--------|--------|
| 1 | `gh` not authenticated | `gh auth status` exits non-zero | Stop. "Run `gh auth login` and retry." | No |
| 2 | No admin rights | 403 response | Stop. "Admin must run this command." | No |
| 3 | Branch `main` missing | 404 response | Stop. "Push a commit to `main` first." | No |
| 4 | Rule exists, same settings | 200 | Idempotent success. | N/A |
| 5 | Rule exists, different settings | 200 | Success (overwritten). | N/A |
| 6 | Network/transient error | 5xx or timeout | Retry once, then stop. | Yes (1x) |
| 7 | Check name doesn't match job | 200 (API accepts any string) | Caught by post-verification (R3.2). | N/A |

### R3.2 — Post-Verification

The API silently accepts non-existent check names. After pushing the workflow change:

1. Confirm a CI run completed: `gh run list --workflow=ci.yml --limit=1 --json status,conclusion`
2. Verify `Test` appears in jobs: `gh run view <run-id> --json jobs --jq '.jobs[].name'`
3. On a test PR, confirm `Test` gates the merge button.

**If `Test` doesn't appear:** name mismatch — PRs will be permanently blocked. Fix the YAML or protection rule. Do not remove branch protection as a workaround.

## R4 — Visibility

Automatic — GitHub surfaces job logs in the PR Checks tab. No additional integration needed.

## Edge Cases

| # | Scenario | Behavior |
|---|----------|----------|
| 1 | No test files in a package | `go test ./...` skips it — passes. |
| 2 | Build error in test | Exits non-zero — fails, merge blocked. |
| 3 | Test panics | Reported as FAIL — merge blocked. |
| 4 | Infinite loop | `timeout-minutes: 10` kills runner — fails. |
| 5 | Push to feature branch (no PR) | Runs, result in commit status. No merge gate. |
| 6 | PR from fork | Runs with read-only permissions. |
| 7 | Rapid pushes | Concurrency group cancels in-progress, runs latest. |
| 8 | Module download fails | Step fails. Retry via "Re-run jobs". |
| 9 | Admin merges with failing checks | Blocked (`enforce_admins: true`). |
| 10 | `gh` not authenticated (setup) | Caught by precondition (R3.1 #1). |
| 11 | No admin rights (setup) | 403 — stop (R3.1 #2). |
| 12 | Protection already configured | Idempotent overwrite (R3.1 #4/#5). |
| 13 | Check name typo | Silently accepted; caught by R3.2. |

## Acceptance Criteria

1. **AC1:** Every push to any branch runs `go test ./...` and reports check **`Test`**.
2. **AC2:** Every PR shows `Test` in the Checks tab.
3. **AC3:** PR to `main` with failing `Test` cannot be merged (including admins).
4. **AC4:** PR to `main` with passing `Test` can be merged.
5. **AC5:** CI Go version matches `go.mod` (1.26.2).
6. **AC6:** Invariants I1–I7 hold.
7. **AC7:** Workflow completes in under 10 minutes.

## Implementation Checklist

- [ ] Add `test` job to `ci.yml` — exact YAML from R1.
- [ ] Replace `on` block — exact YAML from R2.
- [ ] Run `gh auth status` (R3.1 precondition).
- [ ] Run `gh api` command from R3.
- [ ] Push and wait for CI run.
- [ ] Post-verify per R3.2: `Test` appears in run, gates PR merge.
