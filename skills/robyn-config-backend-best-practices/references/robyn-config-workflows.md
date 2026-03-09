# robyn-config operator workflows

Use these playbooks for day-to-day operations with generated Robyn services.

## 1) Create a new service

## Command template

```bash
robyn-config create <service-name> --design <ddd|mvc> --orm <sqlalchemy|tortoise> --package-manager <uv|poetry> <destination>
```

## Stack matrix

| Design | ORM | Package manager | Example |
| --- | --- | --- | --- |
| ddd | sqlalchemy | uv | `robyn-config create orders --design ddd --orm sqlalchemy --package-manager uv ./orders` |
| ddd | sqlalchemy | poetry | `robyn-config create orders --design ddd --orm sqlalchemy --package-manager poetry ./orders` |
| ddd | tortoise | uv | `robyn-config create orders --design ddd --orm tortoise --package-manager uv ./orders` |
| ddd | tortoise | poetry | `robyn-config create orders --design ddd --orm tortoise --package-manager poetry ./orders` |
| mvc | sqlalchemy | uv | `robyn-config create orders --design mvc --orm sqlalchemy --package-manager uv ./orders` |
| mvc | sqlalchemy | poetry | `robyn-config create orders --design mvc --orm sqlalchemy --package-manager poetry ./orders` |
| mvc | tortoise | uv | `robyn-config create orders --design mvc --orm tortoise --package-manager uv ./orders` |
| mvc | tortoise | poetry | `robyn-config create orders --design mvc --orm tortoise --package-manager poetry ./orders` |

## Post-create baseline checks
- `pyproject.toml` includes `[tool.robyn-config]` with selected values.
- `src/app` matches design shape.
- lock file exists for selected manager.
- migration tool is present for selected ORM.

## 2) Add a new domain/entity module

## Basic command

```bash
robyn-config add <entity-name> <project-path>
```

## Customize add target paths (optional)

### DDD example (`pyproject.toml`)

```toml
[tool.robyn-config.add]
domain_path = "src/app/domain"
operational_path = "src/app/operational"
presentation_path = "src/app/presentation"
database_repository_path = "src/app/infrastructure/database/repository"
database_table_path = "src/app/infrastructure/database/tables/__init__.py"
```

### MVC example (`pyproject.toml`)

```toml
[tool.robyn-config.add]
views_path = "src/app/views"
database_repository_path = "src/app/models/repository.py"
database_table_path = "src/app/models/tables/__init__.py"
urls_path = "src/app/urls.py"
```

## Post-add checks
- expected files were created in configured paths
- route import and `register(app)` call were inserted
- model or table definitions include the new entity
- repository exports are updated
- lint passes on changed files

## 3) Add admin panel scaffolding

## Basic command

```bash
robyn-config adminpanel <project-path>
```

## Custom superadmin credentials

```bash
robyn-config adminpanel -u <admin-username> -p <admin-password> <project-path>
```

## What this command adds
- Registers an `adminpanel` module in the generated application.
- Provides a modern admin interface with dark/light theme support.
- Auto-discovers project models and surfaces them in `/admin/models`.
- Enables CRUD operations for discovered model tables.
- Bootstraps admin authentication with configurable superadmin credentials.
- Ensures required dependencies exist: `jinja2`, `aiosqlite`, `pandas`, `openpyxl`.

## Post-adminpanel checks
- `/admin/login` works with configured credentials.
- `/admin/models` lists discovered project models.
- CRUD flow works for at least one application model.
- `pyproject.toml` contains `[tool.robyn-config.adminpanel]` with `created = true`.
- route wiring includes `adminpanel.register(...)` exactly once.

## 4) Rollback expectations for failed commands

## `create` rollback behavior
- If destination directory was created by `create`, failure removes that directory.
- If destination existed before, failure removes only newly generated artifacts.

## `add` rollback behavior
- Command takes a full temp backup before mutation.
- On failure, project content is restored from backup.

## `adminpanel` rollback behavior
- Command takes a full temp backup before mutation.
- On failure, project content is restored from backup.

## Operator recommendation
Even with built-in rollback, run command in a clean git state so final differences are easy to inspect.

## 5) Migration flow by ORM

## SQLAlchemy + Alembic

```bash
make makemigration MIGRATION_MESSAGE="describe_change"
make migrate
```

Equivalent direct commands:

```bash
alembic revision --autogenerate -m "describe_change"
alembic upgrade head
```

## Tortoise + Aerich

```bash
make makemigration MIGRATION_MESSAGE="describe_change"
make migrate
```

Equivalent direct commands:

```bash
aerich migrate --name describe_change --offline
aerich upgrade
```

## 6) Runbook commands for local and compose

## Local setup and checks

```bash
make install.dev
make check
make tests.coverage
```

## Local run

```bash
make run.dev
```

## Compose run

```bash
make run.compose
```

## Compose operations

```bash
make backend.status
make backend.update
make backend.stop
```

## Suggested workflow order
1. `create`
2. dependency install and checks
3. migration bootstrap
4. run app locally
5. add modules with `add`
6. scaffold admin UI with `adminpanel` (when needed)
7. rerun checks and migrations
8. validate in compose

## 7) Sync skills when a new `robyn-config` release is available

## Command

```bash
./skills/robyn-config-backend-best-practices/scripts/update-if-new-robyn-config.sh
```

## What it does
- Checks installed `robyn-config` version against the latest PyPI version.
- If a newer version exists, upgrades `robyn-config`.
- Runs `npx skills update` after a successful package upgrade.
- If already up to date, exits without changing local installation.
