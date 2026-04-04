# robyn-config source analysis

## Scope
This reference summarizes behavior from local source files under `../robyn-config/src` and related integration tests.

Primary sources:
- `src/cli.py`
- `src/create/utils.py`
- `src/add/utils.py`
- `src/adminpanel/utils/*.py`
- `src/monitoring/utils/*.py`
- selected generated templates in `src/create/common`, `src/create/ddd`, `src/create/mvc`
- admin panel templates in `src/adminpanel/template`
- monitoring templates in `src/monitoring/template` and `src/monitoring/app`
- integration tests in `tests/integration` (`test_create_command.py`, `test_add_command.py`, `test_adminpanel_command.py`, `test_monitoring_command.py`)
- unit tests in `tests/unit` (`test_monitoring_dependencies.py`)

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

### `adminpanel` command
- Entry point: `src/cli.py:adminpanel(...)`.
- Validates non-empty admin username/password inputs.
- Checks `[tool.robyn-config.adminpanel].created`; if already created, prompts user before updating scaffolding.
- Creates a full project backup in a temp directory before mutation.
- Runs `add_adminpanel(...)`.
- On failure, restores backup into project directory.
- Always deletes temporary backup directory in `finally` block.

### `monitoring` command
- Entry point: `src/cli.py:monitoring(...)`.
- Creates a full project backup in a temp directory before mutation.
- Runs `add_monitoring(project_path)` from `src/monitoring/utils/__init__.py`.
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
  - creates or updates table module exports in shared tables package (`tables/__init__.py`), with legacy fallback support for `tables.py`.
- MVC:
  - appends table and repository classes into existing model/repository files;
  - creates new view module;
  - updates `urls.py` with import and `register(app)` call.

## `monitoring` command scaffolding model

### Orchestration (`src/monitoring/utils/__init__.py`)
1. Reads `pyproject.toml` with `read_project_config`.
2. Extracts `design` and `orm`.
3. Copies the entire `src/monitoring/template/` tree verbatim into the project root (`_copy_template_tree`).
4. Injects `metrics.py` into the correct presentation layer and registers the `/metrics` route (`_write_metrics_route`).
5. Installs `prometheus-client>=0.20.0` — tries live install (`uv add` or `poetry add`) first; falls back to pyproject.toml-only insertion on failure.

### Constants (`src/monitoring/utils/_constants.py`)
- `TEMPLATE_ROOT` — path to `src/monitoring/template/`.
- `MONITORING_DEPENDENCIES` — tuple of `(package, version_spec)` pairs currently containing `("prometheus-client", ">=0.20.0")`.

### Dependency handling (`src/monitoring/utils/_dependencies.py`)
- Fully self-contained; does not import from `adminpanel`.
- `_detect_package_manager` — reads `package_manager` from config or detects poetry by `[tool.poetry]` presence.
- `_ensure_poetry_dependency` / `_ensure_project_dependency` — insert dependency into `pyproject.toml` without re-installing.
- `_install_dependency` — runs `uv add dep>=version` or `poetry add dep>=version --no-interaction`; raises `RuntimeError` on non-zero exit.

### Metrics route injection (`src/monitoring/utils/_app.py`)
- `METRICS_SOURCE` — path to `src/monitoring/app/metrics.py`.
- `_write_metrics_route` — copies `metrics.py` to the presentation layer path:
  - DDD: `src/app/presentation/metrics.py`
  - MVC: `src/app/views/metrics.py`
- Calls `_register_routes_ddd` or `_register_routes_mvc` (reused from `add.utils._injection`) to wire `metrics.register(app)` into the route registry.

### Generated template structure
```
docker-compose.monitoring.yml
compose/monitoring/
  alloy/config.alloy          # Docker log collection + Prometheus scrape (job_name="app")
  prometheus/prometheus.yml   # Minimal config; metrics arrive via Alloy remote_write
  grafana/
    datasources/
      loki.yaml               # uid: loki, orgId: 1, X-Scope-OrgID header
      prometheus.yaml         # uid: prometheus, orgId: 1, httpMethod: POST
    provisioning/
      dashboards.yaml         # Points to /var/lib/grafana/dashboards
    dashboards/
      logs.json               # uid: robyn-app-logs; stream variable "All"=".*/"; search textbox
      metrics.json            # uid: robyn-app-metrics; CPU, memory, FDs, GC, process info
```

### Key design constraints
- Datasource UIDs are fixed (`uid: loki`, `uid: prometheus`) so dashboard panels reference them directly without template variables.
- `__inputs` and `${DS_LOKI}` / `${DS_PROMETHEUS}` template variables are intentionally absent from dashboard JSON.
- Alloy `prometheus.scrape` must set `job_name = "app"` — the component name alone would produce a mismatched label.
- Logs dashboard stream variable "All" option uses `value: ".*"` — empty string `""` would filter out all `stdout`/`stderr` streams.
- Both composes must run from the same project directory so they share the `{dirname}_default` Docker network and Alloy can reach `app:8000`.

## `adminpanel` command scaffolding and wiring model

### Project detection and compatibility
- Reads `pyproject.toml` and requires `[tool.robyn-config]` section.
- Uses project design (`ddd`/`mvc`) and ORM (`sqlalchemy`/`tortoise`) to select templates and wiring paths.

### Template rendering and target paths
- Copies and renders templates from `src/adminpanel/template`.
- DDD target root: `src/app/infrastructure/adminpanel`.
- MVC target root: `src/app/adminpanel`.
- Keeps generated module filenames ORM-agnostic while rendering ORM-specific internals.

### Route and app registration
- Ensures `adminpanel` import in `src/app/server.py`.
- DDD: injects `adminpanel.register` into route registrars when possible, with fallback call insertion.
- MVC: ensures `adminpanel.register(app)` call before main guard.

### Table integration and metadata
- Appends admin auth table exports (`Role`, `UserRole`) to configured database table path.
- Respects `[tool.robyn-config.add].database_table_path` overrides with fallback defaults.
- Sets `[tool.robyn-config.adminpanel].created = true` in `pyproject.toml`.

### Dependency management
- Ensures required dependencies in `pyproject.toml`: `jinja2`, `aiosqlite`, `pandas`, `openpyxl`.

### Runtime/admin UX behavior from generated templates
- Admin UI supports both dark and light themes.
- Project models are auto-discovered and presented in `/admin/models`.
- Generated admin routes support CRUD workflows for discovered model tables.
- Default superadmin credentials are `admin/admin`, overridable via CLI options.

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
- `adminpanel` also uses full-directory backup/restore; this can be expensive for large repositories.
- Default superadmin credentials (`admin/admin`) should be overridden in non-development environments.
- `monitoring` rollback also uses full-directory backup/restore, which can be expensive for large repositories.
- `prometheus-client` installation falls back to pyproject.toml-only insertion if the package manager binary is unavailable; the app will fail at startup until the dependency is manually installed.
- Grafana anonymous admin access (`GF_AUTH_ANONYMOUS_ORG_ROLE: Admin`) is enabled by default; disable this before exposing Grafana beyond localhost.
- Both docker-compose files must be started from the same project directory; a different working directory causes separate Docker networks and breaks Alloy→app connectivity.
- Behavior differs between templates for user login lookup:
  - DDD repositories use username lookup in shown templates;
  - MVC repository lookup attempts both username and email.
- Key generation patterns differ between templates (`uuid.uuid3` with random namespace in DDD services, `uuid.uuid4` in MVC views), so token behavior can vary.
