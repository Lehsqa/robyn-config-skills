# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions and references that extend agent capabilities for specific engineering workflows.

Skills follow the [Agent Skills](https://agentskills.io/) format.

## Available Skills

### robyn-config-backend-best-practices

Robyn backend scaffolding and architecture guidance for teams using `robyn-config`. Covers stack selection, safe code generation, architecture audits, and skill authoring patterns for Robyn-focused agent workflows.

**Use when:**
- Scaffolding a new Robyn backend with `robyn-config create`
- Choosing between DDD and MVC architecture
- Choosing between SQLAlchemy and Tortoise ORM
- Extending a service with `robyn-config add`
- Auditing backend quality, configuration safety, and operational readiness
- Creating or improving Robyn engineering `SKILL.md` files

**Categories covered:**
- `robyn-config` source behavior and generation model
- Robyn backend best practices by priority (P0/P1/P2)
- Operator workflows (`create`, `add`, migrations, local/compose runbooks)
- DDD vs MVC architecture decisions
- SQLAlchemy vs Tortoise tradeoffs
- Skill authoring patterns and progressive disclosure
- Reusable rule-system design patterns adapted from React guidelines

## Installation

Install this repository as a skills source:

```bash
npx skills add Lehsqa/robyn-config-skills
```

## Usage

Once installed, the agent can automatically use skills when tasks match their triggers.

**Examples:**

```text
Scaffold a new DDD Robyn service with SQLAlchemy and uv
```

```text
Add a product entity to my existing MVC + Tortoise project
```

```text
Review my Robyn backend architecture and suggest fixes
```

## Skill Structure

Each skill contains:
- `SKILL.md` - Main instructions and routing workflow
- `agents/openai.yaml` - UI metadata for skill surfaces (optional)
- `references/` - Supporting technical documentation (optional)
- `scripts/` - Helper automation scripts (optional)
- `assets/` - Output assets or templates (optional)
