# Implementation Overview

Fix three failing CI jobs in `.github/workflows/ci.yml` by correcting three invalid file path references. The `lint` job references a non-existent `scripts/*.sh` glob (should be `.ai-setup/scripts/*.sh`), and both Smoke matrix jobs reference `./scripts/test-ci.sh` (should be `./.ai-setup/scripts/test-ci.sh`). Changes are strictly limited to this single workflow file with exactly three path corrections.

# Technical Design

## Root Cause Analysis

1. **Lint job (lines 38, 41):** `shfmt` and `shellcheck` commands reference `scripts/*.sh`, but the `scripts/` directory does not exist at the repository root. Shell scripts live under `.ai-setup/scripts/`.
2. **Smoke jobs (line 77):** The smoke test step references `./scripts/test-ci.sh`, but the script is located at `./.ai-setup/scripts/test-ci.sh`.

## Fix Strategy

Three surgical edits to `.github/workflows/ci.yml`:

| Line | Current | Fixed |
|------|---------|-------|
| 38 | `shfmt -d init.sh scripts/*.sh` | `shfmt -d init.sh .ai-setup/scripts/*.sh` |
| 41 | `shellcheck init.sh scripts/*.sh` | `shellcheck init.sh .ai-setup/scripts/*.sh` |
| 77 | `./scripts/test-ci.sh` | `./.ai-setup/scripts/test-ci.sh` |

No other files, jobs, or steps are modified.

# Implementation Phases

## Phase 1: Verify Preconditions

### Objective
Confirm root causes and validate that target files exist at expected paths before making changes.

### Tasks
- [ ] Confirm `scripts/` directory does NOT exist at repository root
- [ ] Confirm `.ai-setup/scripts/` directory exists and contains `.sh` files
- [ ] Confirm `.ai-setup/scripts/test-ci.sh` exists and is executable
- [ ] Confirm `init.sh` exists at repository root
- [ ] Read `.github/workflows/ci.yml` and verify lines 38, 41, 77 contain the exact strings from the spec

### Validation
All file existence checks match expected state. Workflow file lines match spec's "current" column exactly.

## Phase 2: Apply Path Corrections

### Objective
Edit the three invalid path references in `.github/workflows/ci.yml`.

### Tasks
- [ ] Edit line 38: change `shfmt -d init.sh scripts/*.sh` to `shfmt -d init.sh .ai-setup/scripts/*.sh`
- [ ] Edit line 41: change `shellcheck init.sh scripts/*.sh` to `shellcheck init.sh .ai-setup/scripts/*.sh`
- [ ] Edit line 77: change `./scripts/test-ci.sh` to `./.ai-setup/scripts/test-ci.sh`
- [ ] Read back the modified file and verify only the three target lines changed
- [ ] Run `git diff .github/workflows/ci.yml` to confirm the diff contains exactly three changed lines with no unintended modifications

### Validation
- `git diff` shows exactly three lines changed, matching the fix table above
- No other lines, whitespace, or formatting changes present
- No workaround patterns (`continue-on-error`, `|| true`, `exit 0`) introduced

## Phase 3: Local Validation

### Objective
Run the corrected commands locally to verify they succeed before pushing to CI.

### Tasks
- [ ] Run `shfmt -d init.sh .ai-setup/scripts/*.sh` locally (expect exit code 0)
- [ ] Run `shellcheck init.sh .ai-setup/scripts/*.sh` locally (expect exit code 0)
- [ ] Run `./.ai-setup/scripts/test-ci.sh` locally (expect exit code 0, or document if local environment lacks required toolchain)
- [ ] If any local tool is missing (`shfmt`, `shellcheck`), note it and proceed to Phase 4 — CI validation is authoritative

### Validation
All available commands exit with code 0. Any skipped commands are documented with reason.

## Phase 4: Commit, Push, and CI Validation

### Objective
Trigger CI workflow and verify all target jobs pass in the same run.

### Tasks
- [ ] Commit changes to branch `4-fix-lint-job` with a message referencing issue #5
- [ ] Push to remote to trigger GitHub Actions workflow
- [ ] Monitor workflow run until all jobs reach terminal state
- [ ] Verify `lint` job passes (exit code 0)
- [ ] Verify `Smoke (ubuntu-latest)` job passes (exit code 0)
- [ ] Verify `Smoke (macos-latest)` job passes (exit code 0)
- [ ] Verify `test` job remains passing and was not modified
- [ ] If any target job fails, diagnose the failure and return to Phase 2

### Validation
- All four jobs (`lint`, `Smoke (ubuntu-latest)`, `Smoke (macos-latest)`, `test`) pass in a single workflow run
- No jobs were disabled, skipped, renamed, or removed
- AC1-AC8 from the spec are satisfied

## Phase 5: Consecutive Run Validation

### Objective
Satisfy the reliability NFR by confirming three consecutive passing runs on the same commit.

### Tasks
- [ ] Trigger two additional workflow runs on the same commit (via `workflow_dispatch` or re-push)
- [ ] Verify all target jobs pass in each of the three total runs
- [ ] If any run fails due to infrastructure flake (not code), re-trigger from the beginning of the 3-run sequence
- [ ] If the same non-code failure recurs 3 times, mark validation as blocked per spec

### Validation
Three consecutive workflow runs on the same commit all pass all target jobs.

# Rollout / Migration Strategy

## Pre-merge
- All acceptance criteria (AC1-AC8) verified via CI
- Three consecutive passing runs completed
- `git diff` confirms only `.github/workflows/ci.yml` modified with exactly three path corrections

## Merge
- Merge branch `4-fix-lint-job` to `main` via pull request
- No migration steps required — this is a CI config fix with no application impact

## Post-merge
- Monitor first workflow run on `main` to confirm all jobs pass
- No rollback plan needed beyond standard git revert if issues arise

# Risks / Blockers

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `.ai-setup/scripts/*.sh` glob matches files with lint violations | Low | Medium | Phase 3 local validation catches this before CI |
| `test-ci.sh` depends on toolchain not yet bootstrapped at line 77 | Very Low | High | Smoke job already runs `make bootstrap` and `make agents` in prior steps |
| Local environment missing `shfmt`/`shellcheck` | Medium | Low | Phase 3 allows skipping local validation; CI is authoritative |
| GitHub Actions infrastructure outage blocks validation | Low | High | Per spec: mark validation as blocked, do not work around |

# Open Questions

None. Root causes are confirmed from the referenced failing workflow run, file paths are verified against repository structure, and the spec provides clear resolution for all edge cases.
