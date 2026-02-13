# DECISIONS

## 2026-02-13
- Use Caddy as reverse proxy for simple local path routing (`/` Mattermost, `/vikunja` Vikunja) to keep dev bootstrap friction low.
- Use one Postgres service with separate logical DBs/users for Mattermost and Vikunja via init script.
- Keep automation services optional and profile-gated (`full`/`prod`) with lightweight placeholder workers until feature tasks wire real code.
- Keep stack self-contained under one compose file and profiles for predictable onboarding.

## 2026-02-13 (T3)
- Bootstrap should be rerunnable and idempotent; seed scripts must check for existing resources and skip when present.
- Keep per-system seed scripts separate (Mattermost/Vikunja/OpenClaw/automation) for easier troubleshooting.

## 2026-02-13 (T4)
- Define one declarative org config (`templates/org.sample.json`) and a single apply entrypoint (`scripts/apply-config.sh`).
- Treat Vikunja "templates" as idempotent task-template stubs (`TEMPLATE: <name>`) until native template API wiring is added.
- Provide dry-run mode (`DRY_RUN=1`) for safe config plan checks before apply.

## 2026-02-13 (OSS T1)
- Adopt MIT license for broad reuse and low-friction external contributions.
- Add explicit contributor/security/process docs and GitHub templates before public launch to reduce triage ambiguity and improve first-time contributor experience.

## 2026-02-13 (OSS T2)
- Build website as static HTML/CSS in-repo (`website/`) for fast load and easy deployment on any static host.
- Prioritize visual clarity/accessibility over JS-heavy effects to keep performance and maintainability high.

## 2026-02-13 (Installer T1)
- Installer uses release tarballs + checksum verification (no `git clone`) to keep install UX fast and supply-chain checks explicit.
- Support both interactive and non-interactive (`--yes`) installer paths for trial users and automation contexts.
