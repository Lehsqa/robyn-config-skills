---
name: robyn-config-backend-best-practices
description: Robyn backend scaffolding and architecture guidance for projects using robyn-config. Use when creating or evolving Robyn services, choosing DDD vs MVC, choosing SQLAlchemy vs Tortoise, adding new entities/routes/repositories with robyn-config add, auditing Robyn backend quality, or authoring and improving skill markdown for Robyn engineering workflows.
---

# Robyn Config Backend Best Practices

## Overview and intent
Use this skill to work effectively with `robyn-config` and production-oriented Robyn backend patterns.

This skill is optimized for four task groups:
- scaffold a new service with `robyn-config create`
- extend an existing service with `robyn-config add`
- audit and improve architecture and operational readiness
- author high-quality skill files for Robyn engineering work

Do not load every reference file by default. Load only the files required for the current task.

## Fast triage workflow
1. Detect project metadata in `pyproject.toml`:
   - `[tool.robyn-config].design` (`ddd` or `mvc`)
   - `[tool.robyn-config].orm` (`sqlalchemy` or `tortoise`)
   - `[tool.robyn-config].package_manager` (`uv` or `poetry`)
2. Classify requested work:
   - bootstrap
   - extension
   - architecture or operations audit
   - skill authoring
3. Select references from the routing table in this file.
4. Produce branch-specific guidance for design, ORM, and package manager.
5. End with a validation checklist and concrete commands.

## Workflow A: bootstrap from `robyn-config create`
1. Select stack options: design, ORM, package manager.
2. Generate service:

```bash
robyn-config create <service-name> --design <ddd|mvc> --orm <sqlalchemy|tortoise> --package-manager <uv|poetry> <destination>
```

3. Confirm output baseline:
   - `pyproject.toml` contains `[tool.robyn-config]`
   - `src/app` layout matches selected design
   - lock file matches package manager (`uv.lock` or `poetry.lock`)
4. Execute ORM-specific migration bootstrap before app start.
5. Run lint, type checks, and tests, then report exact failures with file paths.

## Workflow B: evolve project with `robyn-config add`
1. Ensure target project is a `robyn-config` project by checking `[tool.robyn-config]`.
2. Read optional path overrides under `[tool.robyn-config.add]`.
3. Add module:

```bash
robyn-config add <entity-name> <project-path>
```

4. Verify generated updates:
   - new files in expected layer paths
   - route registration inserted in the right registry file
   - repository exports and tables updated
   - no duplicate symbols or broken imports
5. Regenerate migrations if schema changed.
6. Run checks and confirm command rollback behavior if failures occur.

## Workflow C: review and improve architecture and ops readiness
1. Validate architecture boundaries for selected design.
2. Validate runtime safety:
   - settings and env overrides
   - auth, session, CORS behavior
   - transaction boundaries and error mapping
3. Validate operations:
   - migration startup order
   - compose and local parity
   - logging and debug posture
4. Prioritize recommendations:
   - P0 correctness and security
   - P1 reliability and consistency
   - P2 maintainability and performance
5. Provide file-targeted, diff-ready changes.

## Workflow D: author and update skill files for Robyn engineering
1. Keep `SKILL.md` concise and procedural.
2. Put deep detail into `references/` and load on demand.
3. Write frontmatter with explicit trigger contexts.
4. Reuse rule patterns from `react-best-practices` where useful.
5. Validate skill structure before delivering:
   - no placeholder markers
   - all referenced files exist
   - no extra docs such as README or changelog inside skill folder

## Reference routing table
Open only the file needed for the task:

- `references/robyn-config-src-analysis.md`
  - Use for `robyn-config` internals and generation/injection behavior.
- `references/robyn-backend-best-practices.md`
  - Use for prioritized engineering guidance and review criteria.
- `references/robyn-config-workflows.md`
  - Use for operator playbooks and command sequences.
- `references/architecture-ddd-vs-mvc.md`
  - Use for architecture selection and refactor planning.
- `references/orm-sqlalchemy-vs-tortoise.md`
  - Use for ORM tradeoffs and migration/session behavior.
- `references/skill-authoring-patterns.md`
  - Use for writing and validating high-quality skill markdown.
- `references/react-style-rule-system.md`
  - Use for reusable rule-library design patterns and taxonomy.

## Output requirements
Always:
1. Include concrete executable commands.
2. Include design and ORM branch-specific instructions.
3. Include package-manager-aware instructions (`uv` and `poetry`).
4. Include a validation checklist covering structure, behavior, and checks.
5. State assumptions explicitly when repository context is incomplete.
