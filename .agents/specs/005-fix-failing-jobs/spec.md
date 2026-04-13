# Feature Overview
- Fix three failing jobs in the GitHub Actions CI workflow (`.github/workflows/ci.yml`) by correcting invalid file path references.
- Affected jobs: `lint`, `Smoke (ubuntu-latest)`, `Smoke (macos-latest)`.
- Reference failing run: https://github.com/asusikov/ai-setup/actions/runs/24215211709
- Source brief: https://github.com/asusikov/ai-setup/issues/5

# Goal
- Restore CI so that all three currently failing jobs pass, allowing the pipeline to block broken code from merging to `main`.

# Scope
- Fix the `lint` job by replacing the invalid glob `scripts/*.sh` with `.ai-setup/scripts/*.sh` in shell linter commands (lines 38 and 41 of `.github/workflows/ci.yml`), so the shell scripts under `.ai-setup/scripts/` are covered by `shfmt` and `shellcheck`.
- Fix the `Smoke (ubuntu-latest)` and `Smoke (macos-latest)` jobs by replacing the invalid script path `./scripts/test-ci.sh` with `./.ai-setup/scripts/test-ci.sh` (line 77 of `.github/workflows/ci.yml`).
- Verify that fixes hold on both `ubuntu-latest` and `macos-latest` runners.

# Out of Scope
- Modifying, disabling, removing, renaming, or reordering any CI jobs that are currently passing (`test`).
- Disabling or skipping any of the three failing jobs as a workaround.
- Adding new CI jobs, workflows, or pipelines.
- Changing any file other than `.github/workflows/ci.yml`. If any other file must change, stop and create a spec revision before proceeding.
- Changes to branch protection rules or repository settings outside the workflow file.

# Invariants
These conditions must hold true before and after the change:
- Only `.github/workflows/ci.yml` may be modified.
- Existing passing jobs (`test`) must remain enabled, unchanged, and passing.
- No retry or ignore-workaround patterns (`continue-on-error`, `|| true`, `exit 0`, job/step disabling) may be introduced in `.github/workflows/ci.yml` or invoked scripts.
- No secrets or credentials may be added, logged, or exposed.
- No project structure changes are allowed (per `CLAUDE.md` constraint).

# Functional Requirements
- FR1: The `lint` job must complete successfully (exit code 0) in the CI workflow run.
- FR2: The `Smoke (ubuntu-latest)` job must complete successfully (exit code 0) in the CI workflow run.
- FR3: The `Smoke (macos-latest)` job must complete successfully (exit code 0) in the CI workflow run.
- FR4: All three target jobs must pass together within a single workflow run, without manual retries or intervention.
- FR5: The `test` job must continue to pass after the fix is applied.
- FR6: The only changes in the diff are corrections of the three invalid path references:
  - Line 38: `scripts/*.sh` → `.ai-setup/scripts/*.sh`
  - Line 41: `scripts/*.sh` → `.ai-setup/scripts/*.sh`
  - Line 77: `./scripts/test-ci.sh` → `./.ai-setup/scripts/test-ci.sh`

# Non-Functional Requirements
- Reliability: The same commit must pass the three target jobs in 3 consecutive workflow runs without manual retries.
- Correctness: The diff must only correct the three invalid path references identified above.
- Security: No secrets, tokens, or credentials may be introduced, logged, or exposed as part of the fix.
- Portability: Smoke job fixes must work on both Linux (`ubuntu-latest`) and macOS (`macos-latest`) runner images.

# API / Interface Changes
- No application API, event, schema, or database contract changes.
- Changes are limited to `.github/workflows/ci.yml` only.

# Edge Cases / Failure Scenarios
- A fix for one job must not regress another job in the same workflow. If any non-target job (`test`) fails in the validation run, the task fails acceptance and must not be merged.
- A failure is considered in-scope only if it is caused by the invalid path references `scripts/*.sh` (lines 38, 41) or `./scripts/test-ci.sh` (line 77). If any other file, step, or root cause must change, stop and create a spec revision before continuing.

# Validation Exceptions
- **CI run cannot be triggered**: Mark validation as blocked. Do not treat the task as complete. Do not change the implementation to work around the inability to trigger CI.
- **Target job name is missing or renamed**: Stop and create a spec revision. Do not modify the workflow to add or rename jobs.
- **GitHub Actions infrastructure or runner outage**: Mark validation as blocked. Do not treat the task as complete. Do not change the implementation to work around infrastructure failures.
- **Consecutive validation run fails for non-code reasons (infrastructure flake)**: Re-trigger the validation sequence from the beginning. If the same non-code failure recurs 3 times, mark validation as blocked.

# Dependencies / Constraints
- GitHub Actions as the CI platform, using `ubuntu-latest` and `macos-latest` runner images.
- Existing workflow definition: `.github/workflows/ci.yml`.
- Constraint from brief: do not modify jobs that are currently passing.
- Constraint from brief: do not disable any jobs.
- Only `.github/workflows/ci.yml` may be modified. If more files are required, the spec must be revised before implementation.
- Project stack constraint (from `CLAUDE.md`): project structure must not be changed without direct instruction.

# Assumptions
- The failures are deterministic and reproducible from the referenced workflow run, not transient GitHub infrastructure issues.
- The implementation branch for this work is `4-fix-lint-job`; fixes will be validated via CI on that branch before merge to `main`.

# Open Questions
None. Root causes have been identified from the referenced workflow run logs and confirmed against the repository file structure.

# Acceptance Criteria
- AC1: In a new CI workflow run on the implementation branch, the `lint` job reports success.
- AC2: In the same run, the `Smoke (ubuntu-latest)` job reports success.
- AC3: In the same run, the `Smoke (macos-latest)` job reports success.
- AC4: All three target jobs pass together within a single workflow run, without manual reruns.
- AC5: In the same workflow run, the `test` job reports success.
- AC6: No CI jobs have been disabled, skipped, renamed, or removed as part of the fix.
- AC7: The diff contains only the three path corrections specified in FR6 and no other changes.
- AC8: Only `.github/workflows/ci.yml` is modified.
