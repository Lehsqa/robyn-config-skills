# DDD vs MVC in robyn-config

Use this guide to choose architecture and plan refactors between generated stacks.

## Decision table

| Criterion | DDD | MVC |
| --- | --- | --- |
| Domain complexity | Better for complex domain logic and strict boundaries | Better for simpler CRUD-centric services |
| Team scaling | Clear boundaries help parallel ownership | Fast for small teams and short iteration loops |
| Abstraction style | Domain contracts and infrastructure adapters | Direct view-to-model orchestration |
| `add` output shape | Creates domain, operational, presentation, and infra files | Appends to models/repository and adds view file |
| Long-term maintainability | Higher upfront structure, better for large growth | Lower upfront overhead, can become crowded |

## Directory contracts

## DDD contract
- `config/`: runtime settings
- `infrastructure/`: db, cache, mailing, app wiring, low-level adapters
- `domain/`: entities, constants, service rules, repository interfaces
- `operational/`: use-case orchestration
- `presentation/`: route contracts and registrations

## MVC contract
- `config/`: runtime settings
- `models/`: ORM tables, repositories, transaction layer
- `views/`: route handlers and request/response contracts
- `middlewares/`: CORS and sessions
- `utils.py`: shared HTTP and error helpers
- `urls.py`: route registration

## Routing registration model

## DDD
- Routes are grouped by module and wired through `presentation.register_routes(app)`.
- Generated `add` flow inserts module import and `module.register(app)` call in `presentation/__init__.py`.

## MVC
- Routes are wired through `urls.register_routes(app)`.
- Generated `add` flow inserts view import and `module.register(app)` call in `urls.py`.

## Where business logic belongs

### DDD
- Request parsing and transport mapping: `presentation`.
- Use-case sequencing and orchestration: `operational`.
- Domain invariants and entity-level rules: `domain`.
- External side effects and persistence adapters: `infrastructure`.

### MVC
- Request parsing and endpoint flow: `views`.
- Persistence behavior: `models/repository`.
- Cross-cutting concerns: `middlewares` and shared helpers.

## Refactor path: MVC-style module to DDD-style module
1. Identify an MVC view with mixed concerns.
2. Extract request/response models into DDD `presentation/<module>/contracts.py`.
3. Extract use-case flow into `operational/<module>.py`.
4. Define domain entities and repository interface under `domain/<module>/`.
5. Move concrete persistence implementation into `infrastructure/database/repository/<module>.py`.
6. Keep route handlers thin and orchestration-only.
7. Update route registry to DDD presentation registration.
8. Add tests by layer boundary (presentation, operational, repository).

## Migration safety checklist
- Existing endpoint paths and payload shapes remain compatible.
- Auth and middleware registration order is preserved.
- Transaction boundaries are explicit after extraction.
- Generated `add` command still targets expected paths in `[tool.robyn-config.add]`.
