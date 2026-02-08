# Robyn backend best practices for Python services

This guide is prioritized by operational impact and aligned to `robyn-config` generated patterns.
Each rule includes: why it matters, anti-pattern, preferred pattern, and verification checks.

## P0.1 Architecture boundaries and consistency

### Why it matters
Boundary drift is the fastest way to make generated templates hard to maintain, especially when `robyn-config add` continues mutating expected files.

### Anti-pattern
- Mixing DB writes, request parsing, and email/cache logic in one route function across designs.
- Bypassing established route registries and repository interfaces.

### Preferred pattern (robyn-config aligned)
- DDD: keep boundary order `presentation -> operational -> domain -> infrastructure`.
- MVC: keep request/response logic in views, data access in model repositories, shared mechanics in middlewares/utils.
- Keep route registration centralized (`presentation/__init__.py` or `urls.py`).

### Verification checks
- No direct database calls in DDD presentation modules.
- No orphan route files that are not registered.
- `robyn-config add` can still insert imports and registrations cleanly.

## P0.2 Config and environment safety

### Why it matters
Misconfigured environment handling causes startup failures, secret leaks, and environment drift between local and compose.

### Anti-pattern
- Hardcoded hostnames, credentials, or protocol settings inside business modules.
- Ad hoc env var reads with inconsistent naming.

### Preferred pattern (robyn-config aligned)
- Centralize runtime settings under `config` using `pydantic-settings`.
- Use `SETTINGS__` prefix and nested keys consistently.
- Keep environment-specific values in `.env` or deploy-time env injection.

### Verification checks
- All runtime knobs are represented in settings models.
- No direct `os.getenv` calls scattered through service logic.
- Compose/local env values map cleanly to settings fields.

## P0.3 Auth, token, and session correctness

### Why it matters
Auth mistakes create security defects that are expensive to detect late.

### Anti-pattern
- Optional token verification on protected endpoints.
- Returning inconsistent auth errors or leaking token parsing internals.
- Storing mutable session state without integrity protection.

### Preferred pattern (robyn-config aligned)
- Use `auth_required=True` and a single `JWTAuthenticationHandler` integration point.
- Keep token encode/decode paths centralized and deterministic.
- Keep signed cookie session middleware with strict validation and minimal stored state.

### Verification checks
- Protected endpoints fail without valid bearer token.
- Invalid and expired tokens map to stable 401 responses.
- Session cookie tampering invalidates session state.

## P1.1 Transaction boundaries and repository usage

### Why it matters
Transaction scope determines data integrity and failure recovery semantics.

### Anti-pattern
- Mixing transactional and non-transactional writes in a single use case.
- Calling repository methods outside expected transaction context.

### Preferred pattern (robyn-config aligned)
- Wrap write workflows in `transaction()` contexts.
- Use repository methods as persistence boundary, not ad hoc query logic.
- Map DB exceptions into stable domain/application errors.

### Verification checks
- Write paths are wrapped in transaction contexts.
- Repository interfaces are used for create/update/get flows.
- Integrity failures are surfaced as controlled API errors.

## P1.2 Input/output contract validation and envelope consistency

### Why it matters
Uniform payloads reduce client coupling and improve observability and testability.

### Anti-pattern
- Per-route custom response shapes.
- Raw dict parsing without schema validation.

### Preferred pattern (robyn-config aligned)
- Parse request bodies via shared parser and Pydantic contract models.
- Keep success envelope as `{ "result": ... }`.
- Keep error envelope as `{ "error": ... }`.
- Serialize with consistent model alias behavior.

### Verification checks
- All public routes use contract models.
- Success and error envelopes are consistent across modules.
- JSON decode and validation errors return deterministic status and message shape.

## P1.3 Async I/O integration discipline (cache, mail, DB)

### Why it matters
Unmanaged async resources cause connection leaks and flaky behavior under load.

### Anti-pattern
- Shared global mutable clients without lifecycle boundaries.
- Blocking or fire-and-forget I/O inside critical request paths.

### Preferred pattern (robyn-config aligned)
- Use context-managed cache repositories for get/set/delete flows.
- Keep email sending in dedicated service modules.
- Keep DB access in async repository abstractions.

### Verification checks
- Cache and DB resources are opened and closed predictably.
- Mail/caching side effects are explicit in workflow functions.
- No blocking sync I/O appears in async route handlers.

## P1.4 Migration discipline and startup ordering

### Why it matters
Schema drift between code and database is a common cause of startup incidents.

### Anti-pattern
- Running app before applying pending migrations.
- Manually mutating schema in production without migration history.

### Preferred pattern (robyn-config aligned)
- SQLAlchemy: generate Alembic revisions and apply `upgrade head` before server start.
- Tortoise: use Aerich migration flow before server start.
- Keep compose entry scripts applying migrations first.

### Verification checks
- CI or deployment flow applies migrations before app process starts.
- New schema changes always include migration artifacts.
- Startup scripts fail fast when migration step fails.

## P2.1 Observability, logging, and debug controls

### Why it matters
Production troubleshooting quality depends on predictable logs and signal-to-noise.

### Anti-pattern
- Mixed logging styles across modules.
- SQL debug logs enabled in production by default.

### Preferred pattern (robyn-config aligned)
- Use centralized Loguru settings and stable log path.
- Gate verbose SQL/migration logs behind debug settings.
- Keep endpoint and workflow logs concise and structured.

### Verification checks
- Log file rotation and compression are configured.
- Debug toggles reduce low-value SQL verbosity in non-debug mode.
- Error logs contain actionable context without secret leakage.

## P2.2 Local, compose, and production parity

### Why it matters
Parity gaps create environment-specific bugs and slow incident resolution.

### Anti-pattern
- Separate undocumented command paths for local and compose.
- Different default drivers or host assumptions without explicit overrides.

### Preferred pattern (robyn-config aligned)
- Use Makefile targets as canonical operator interface.
- Keep `.env` and compose overrides aligned with settings keys.
- Keep container startup behavior close to local run sequence.

### Verification checks
- Core run, migrate, lint, and test commands work via Make targets.
- Compose environment variables map directly to settings fields.
- Service starts with same contract in local and containerized flows.

## P2.3 Testing strategy (unit, integration, e2e)

### Why it matters
Template-based generators need both isolated correctness and stack-level validation.

### Anti-pattern
- Only unit tests for utility functions.
- No tests for generated-project behavior.

### Preferred pattern (robyn-config aligned)
- Unit tests for helper utilities and mutation functions.
- Integration tests for `create` and `add` generated structure and lintability.
- E2E tests for generated service endpoints and compose stack behavior.

### Verification checks
- `create` and `add` workflows are covered across design/ORM combinations.
- Generated files pass lint checks for inserted modules.
- End-to-end flow verifies auth and generated entity endpoints.
