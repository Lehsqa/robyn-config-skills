# Reusable rule-system pattern from react-best-practices

This reference adapts structural patterns from `react-best-practices` for Robyn backend guidance.

## Section taxonomy and priority model
`react-best-practices/rules/_sections.md` defines:
- explicit section ordering
- impact level per section
- filename prefix per section

Reusable pattern:
- choose stable section prefixes
- attach impact class to each section
- keep descriptions short and action-oriented

## One-rule-per-file template pattern
`react-best-practices/rules/_template.md` uses a consistent shape:
- frontmatter (`title`, `impact`, `tags`)
- concise explanation
- incorrect example
- correct example
- reference link

Reusable pattern for backend rules:
- keep each rule independent and composable
- require anti-pattern and preferred-pattern examples
- force explicit impact labeling for prioritization

## Naming convention and discoverability
Observed pattern:
- filenames use `<prefix>-<slug>.md`
- special files start with `_`
- section inferred from prefix

Adaptation guidance:
- reserve prefixes by concern area
- avoid overloaded prefixes
- ensure file names are descriptive, short, and stable

## Incorrect versus correct example style
Observed pattern emphasizes side-by-side contrast.

Adaptation guidance for Robyn:
- incorrect: show boundary violations, migration omissions, unsafe defaults
- correct: show stack-aligned patterns from generated templates
- include short reason plus verification checks

## Proposed Robyn rule taxonomy for future expansion

| Priority | Prefix | Category | Intent |
| --- | --- | --- | --- |
| P0 | `arch-` | architecture boundaries | prevent design drift between layers |
| P0 | `config-` | settings and secrets | enforce safe env configuration |
| P0 | `auth-` | authentication and sessions | prevent auth and token misuse |
| P1 | `tx-` | transactions and repositories | enforce integrity-safe data workflows |
| P1 | `contract-` | request/response contracts | enforce schema and envelope consistency |
| P1 | `io-` | async integrations | standardize cache, mail, and db I/O |
| P1 | `migrate-` | migrations and startup order | keep schema and runtime synchronized |
| P2 | `ops-` | observability and runtime ops | improve diagnostics and parity |
| P2 | `test-` | testing strategy | enforce unit/integration/e2e coverage |
| P2 | `skill-` | skill authoring quality | standardize agent guidance quality |

## Suggested starter rules
- `arch-ddd-boundaries.md`
- `arch-mvc-controller-scope.md`
- `config-settings-nested-env.md`
- `auth-jwt-handler-single-source.md`
- `tx-write-path-transaction.md`
- `contract-uniform-envelope.md`
- `migrate-before-startup.md`
- `ops-debug-log-guardrails.md`
- `test-generated-project-matrix.md`
- `skill-progressive-disclosure.md`

Use this taxonomy only when splitting the current modular references into a larger rule library.
