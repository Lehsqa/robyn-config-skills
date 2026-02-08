# SQLAlchemy vs Tortoise in robyn-config

This guide compares how `robyn-config` templates implement each ORM stack.

## Engine and session lifecycle

## SQLAlchemy stack
- Creates async engine via `create_async_engine(...)`.
- Caches engine creation (`lru_cache`).
- Creates `AsyncSession` per transaction context.
- Uses context-local session (`ContextVar`) for repository access.

## Tortoise stack
- Builds `Tortoise` config dict and initializes lazily via `Tortoise.init(...)`.
- Keeps one-time initialization guard and async lock.
- Uses `in_transaction(...)` and context-local connection (`ContextVar`).
- Repository uses Tortoise querysets bound to active connection.

## Transaction semantics

## SQLAlchemy
- `transaction()` yields `AsyncSession`.
- Commits on success.
- Rolls back on database and integrity/invalid request errors.
- Closes session in `finally`.

## Tortoise
- `transaction()` yields active DB connection from `in_transaction`.
- Relies on transaction context for commit/rollback behavior.
- Maps integrity and operational exceptions to application `DatabaseError`.

## Repository behavior and failure mapping
- Both stacks expose similar repository interface and methods.
- Both convert low-level errors into app-level exception classes.
- Both convert ORM model instances into Pydantic entities for response safety.

Differences to watch:
- Query expression style and capability differ by ORM.
- Some template behavior may differ by design (for example login lookup patterns in shown repositories).

## Migration toolchain

## SQLAlchemy
- Migration framework: Alembic.
- Typical commands:

```bash
make makemigration MIGRATION_MESSAGE="describe_change"
make migrate
```

## Tortoise
- Migration framework: Aerich.
- Typical commands:

```bash
make makemigration MIGRATION_MESSAGE="describe_change"
make migrate
```

## Performance and operational tradeoffs

## SQLAlchemy strengths
- Rich query composition and broad ecosystem support.
- Strong fit for complex relational querying and explicit SQL control.

## Tortoise strengths
- Lightweight async ORM ergonomics and concise model/query API.
- Fast iteration for services that prefer Tortoise-native workflows.

## Selection guidance
Choose SQLAlchemy when:
- you need mature query expressiveness and advanced relational control.
- team already standardizes on Alembic and SQLAlchemy patterns.

Choose Tortoise when:
- you want simpler async ORM ergonomics with Aerich migration flow.
- service domain is straightforward and team prefers Tortoise idioms.

## Checklist before final ORM choice
- Confirm migration toolchain comfort (Alembic vs Aerich).
- Confirm team familiarity with repository/query style.
- Confirm existing operational tooling and CI expectations.
- Confirm performance and maintainability requirements.
