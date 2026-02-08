# robyn-config source analysis

## Scope
This reference summarizes behavior from local source files under `../robyn-config/src` and related integration tests.

Primary sources:
- `src/cli.py`
- `src/create/utils.py`
- `src/add/utils.py`
- selected generated templates in `src/create/common`, `src/create/ddd`, `src/create/mvc`
- integration tests in `tests/integration`

## CLI behavior and failure rollback model

### `create` command
- Entry point: `src/cli.py:create(...)`.
- Validates package manager availability before generation.
- Collects existing destination items to detect overlap with generated files.
- Calls create pipeline (`prepare_destination`, `copy_template`, `apply_package_manager`).
- On failure, invokes `_cleanup_create_failure(...)`:
  - if destination directory was newly created by the command, removes it entirely;
  - otherwise removes only generated paths that did not exist before.

### `add` command
- Entry point: `src/cli.py:add(...)`.
- Creates a full project backup in a temp directory before mutating code.
- Runs `add_business_logic(...)`.
- On failure, restores backup into project directory.
- Always deletes temporary backup directory in `finally` block.

## Template copy and render pipeline (`create`)
- Template variant choices:
  - design: `ddd`, `mvc`
  - ORM: `sqlalchemy`, `tortoise`
  - package manager: `uv`, `poetry`
- Context is rendered through Jinja2 with `StrictUndefined`.
- Common files:
  - copied from `src/create/common`
  - `*.jinja2` rendered to target names
  - lock file and `alembic.ini` inclusion depend on package manager and ORM.
- App source tree:
  - design-specific tree copied into `src/app`
  - ORM-specific database subtree selected and copied.
- Compose app scripts:
  - resolves ORM-specific `dev` and `prod` scripts
  - writes normalized output names (`dev.sh`, `prod.py`, `Dockerfile`).
- Package manager lock generation:
  - `uv lock` for `uv`
  - `poetry lock --no-interaction --quiet` for `poetry`
  - fails hard if lock file is not produced.

## `add` command injection algorithm and path override model

### Project detection
- Reads `pyproject.toml` and requires `[tool.robyn-config]` section.
- Extracts `design` and `orm` from this section.

### Path resolution
- Default insertion paths are hardcoded per design.
- Optional overrides are read from `[tool.robyn-config.add]`:
  - DDD: domain, operational, presentation, database repository, database table path.
  - MVC: views, repository, table file, urls file.

### Mutation strategy
- Normalizes input entity name to `snake_case` and `PascalCase`.
- Renders Jinja2 templates under `src/add/...` into resolved target paths.
- Updates import blocks and `__all__` declarations by text mutation helpers.
- Injects route registration call into route registry files.

### Design-specific behavior
- DDD:
  - creates domain package, operational module, presentation package;
  - creates ORM-specific repository module;
  - appends generated table class into shared `tables.py`.
- MVC:
  - appends table and repository classes into existing model/repository files;
  - creates new view module;
  - updates `urls.py` with import and `register(app)` call.

## Generated app runtime model

### Settings and configuration
- Settings class uses `pydantic-settings` with:
  - `env_prefix="SETTINGS__"`
  - `env_nested_delimiter="__"`
  - `.env` file loading.
- Modular config includes database, cache, mailing, auth, CORS, logging, public API, integrations.

### App construction and routing
- DDD template:
  - uses app factory (`infrastructure/application/factory.py`)
  - registers middleware and routes via registrars.
- MVC template:
  - directly constructs `Robyn(__file__)`
  - configures exception handler, auth, middlewares, and routes in `server.py`.

### Auth and session model
- JWT auth implemented via `PyJWT` and `Robyn` `AuthenticationHandler`.
- `auth_required=True` protects selected endpoints.
- Signed-cookie session middleware uses HMAC SHA-256 and context-local session state.

### API envelope and validation
- JSON encoding uses `msgspec`.
- Success envelope is `{ "result": ... }`.
- Error envelope is `{ "error": ... }`.
- Request body parser decodes JSON and validates through Pydantic models.

### Data access and transactions
- SQLAlchemy and Tortoise implementations both expose:
  - transaction context manager
  - repository abstraction
  - typed model validation to Pydantic entities.

### Async integrations
- Cache repository supports fake Redis for dev (`fakeredis`) and real Redis/Valkey.
- Mailing service uses `aiosmtplib`.

## Operational differences by design, ORM, and package manager

### Design
- DDD layout separates domain, operational, presentation, and infrastructure.
- MVC layout keeps flow in views/controllers plus models/middlewares/utils.

### ORM
- SQLAlchemy stack:
  - async engine/session
  - Alembic migrations
  - table definitions via SQLAlchemy ORM.
- Tortoise stack:
  - `Tortoise.init` configuration
  - Aerich migrations
  - table definitions via Tortoise models.

### Package manager
- `uv` template uses `[project]` metadata and `uv.lock`.
- `poetry` template uses `[tool.poetry]` metadata and `poetry.lock`.

## Risks and caveats observed in templates
- Default auth secrets (`dev-secret`, `change-me`) are development placeholders and must be overridden.
- Session cookie helper does not set `Secure`; production deployments should enforce HTTPS-aware cookie policy.
- Default CORS allows `*` values; production should narrow origins and headers.
- `add` injection helpers are text-based and assume common import formatting; heavily customized files can reduce insertion reliability.
- `add` rollback uses full directory backup copy, which can be expensive for large repositories.
- Behavior differs between templates for user login lookup:
  - DDD repositories use username lookup in shown templates;
  - MVC repository lookup attempts both username and email.
- Key generation patterns differ between templates (`uuid.uuid3` with random namespace in DDD services, `uuid.uuid4` in MVC views), so token behavior can vary.
