# Skill authoring patterns for Robyn engineering skills

This reference extracts rules from the local skill-creator guidance in the repository root `SKILL.md` and the system skill-creator workflow.

## Frontmatter constraints and trigger quality

## Required fields
- `name`
- `description`

## Trigger quality requirements
- `description` must explicitly state what the skill does and when to use it.
- Include concrete trigger scenarios, not vague labels.
- Keep skill name hyphen-case and stable.

## Quality pattern for trigger descriptions
Good trigger descriptions include:
- domain (`robyn-config`, Robyn backend architecture)
- action (`create`, `add`, audit, refactor)
- variant dimensions (`ddd|mvc`, `sqlalchemy|tortoise`, `uv|poetry`)

## Progressive disclosure strategy
Follow three levels:
1. metadata always loaded
2. `SKILL.md` body loaded on trigger
3. `references/`, `scripts/`, `assets/` loaded only when needed

Design principle:
- keep `SKILL.md` procedural and compact
- put detailed taxonomies, comparisons, and long playbooks in `references/`

## When to split into references, scripts, and assets

## Put content in `references/` when
- it is long-form guidance
- it contains variant-specific details
- it is not needed for every invocation

## Put content in `scripts/` when
- deterministic execution is better than rewriting steps
- repeated command generation or parsing is required

## Put content in `assets/` when
- files are output resources rather than reading context
- templates or static artifacts are reused directly

## Anti-bloat rules
Do not add auxiliary docs that are not part of skill execution surface:
- `README.md`
- `CHANGELOG.md`
- `INSTALLATION_GUIDE.md`
- similar process-only docs

Keep one-level reference routing from `SKILL.md` to specific files.

## Validation checklist before publishing

## Structural checks
- frontmatter valid and minimal
- all referenced files exist
- no placeholder text markers or template residue

## Trigger checks
- prompts about main scenarios clearly match skill description
- `SKILL.md` triage directs to the right reference files

## Content checks
- commands are executable and stack-aware
- branch-specific variants are explicit
- terminology is consistent

## Imperative writing style requirements
Use imperative or infinitive instruction style.
Examples:
- "Detect design and ORM from `pyproject.toml`."
- "Run migration commands before app startup."
- "Load only required reference files."

Avoid narrative prose that does not change operator behavior.
