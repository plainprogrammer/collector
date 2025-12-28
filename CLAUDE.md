# Collector - Claude Code Instructions

## Project Overview

Collector is a Magic: The Gathering collection management application built with Rails 8.1 and SQLite. The project serves as an experiment in AI-augmented development, with Claude Code as the primary code writer and James providing architectural guidance.

**Stack**: Rails 8.1, SQLite, Turbo, Stimulus, Tailwind CSS, ViewComponent, RSpec

## Constitution (Non-Negotiable Principles)

### 1. Authoritative Documentation

The planning documents in `docs/plans/` are the source of truth. Before implementing any feature:

- Read the relevant sections of these documents
- Follow the patterns and decisions documented
- If something seems wrong or unclear, **ask before deviating**

| Document | Purpose |
|----------|---------|
| `CORE_DATA_MODEL.md` | Entity relationships, model attributes, validations |
| `ROADMAP.md` | Feature specifications and acceptance criteria |
| `UI_ARCHITECTURE.md` | ViewComponent patterns, naming conventions |
| `TURBO_STIMULUS_PATTERNS.md` | Frontend interaction patterns |
| `TESTING_STRATEGY.md` | RSpec patterns, factory conventions |
| `ERROR_HANDLING.md` | Error handling patterns |

### 2. Test-Driven Development

All feature work follows TDD discipline:

1. **Write the test first** — it must fail (red)
2. **Write minimal code** to make the test pass (green)
3. **Refactor** while keeping tests green
4. **Commit** after each meaningful unit of work

Never write implementation code without a failing test covering it.

### 3. Individual Card Tracking

Per CORE_DATA_MODEL.md: one Item row per physical card by default. The `quantity` field exists for bulk/unsorted scenarios but is not the primary workflow.

### 4. Sensible Defaults

- Condition defaults to "near_mint"
- Finish defaults to "nonfoil"
- Language defaults to "EN"
- Minimize required fields during item creation

### 5. SQLite Only

No external database dependencies. All data storage uses SQLite, including FTS5 for search.

### 6. No External Service Dependencies

The application must function offline. MTGJSON data is imported locally. Images are hotlinked from Scryfall CDN (allowed per their policy) but gracefully degrade when offline.

## Feature Development Workflow

### Phase 1: Task Generation (Collaborative)

When starting a new feature:

1. Read the relevant ROADMAP.md section and related planning docs
2. Generate a `tasks.md` file in `specs/features/###-feature-name/`
3. Present the task list for review and approval
4. **Do not begin implementation until tasks are approved**

### Phase 2: Implementation (Autonomous)

After task approval:

1. Work through tasks in order
2. Follow TDD for each task
3. Commit after completing each task (or logical group)
4. If blocked or uncertain, **stop and ask** rather than guessing

### Task File Format

Task files use markdown checkboxes organized by phase:

```markdown
# Feature: [Name]

Reference: docs/plans/ROADMAP.md § [Section]

## Summary
Brief description of what this feature accomplishes.

## Tasks

### Setup / Infrastructure
- [ ] T001: [Description] `path/to/file.rb`

### Models (if applicable)
- [ ] T002: Write model spec for [Model] `spec/models/model_spec.rb`
- [ ] T003: Implement [Model] with validations `app/models/model.rb`

### Services / Business Logic
- [ ] T004: Write spec for [Service] `spec/services/service_spec.rb`
- [ ] T005: Implement [Service] `app/services/service.rb`

### Controllers / Views (if applicable)
- [ ] T006: Write request spec for [action] `spec/requests/resource_spec.rb`
- [ ] T007: Implement [controller/action] `app/controllers/resource_controller.rb`

### Integration / System Tests
- [ ] T008: Write system spec for [user journey] `spec/system/journey_spec.rb`

## Checkpoints
- [ ] All tests pass (`bundle exec rspec`)
- [ ] No linting errors (`bundle exec rubocop`)
- [ ] Feature meets acceptance criteria from ROADMAP.md
```

## Commit Discipline

### Message Format

```
[T###] Brief description of what was done

- Detail 1
- Detail 2

Refs: #issue (if applicable)
```

### Commit Granularity

- One commit per task (or tightly related task group)
- Tests and implementation for the same unit can be one commit
- Infrastructure/setup tasks can be grouped logically
- **Never commit failing tests** (except explicit red-green-refactor WIP)

### Pre-Commit Verification

**CRITICAL**: Before creating any commit, run `bin/ci` and ensure all checks pass:

```bash
bin/ci
```

This runs:
- Setup checks
- RuboCop style checks
- Bundler security audit
- Importmap vulnerability audit
- Brakeman security analysis

**Do not commit if any CI step fails.** Fix issues first, then commit.

## Code Style & Patterns

### Models

- Use UUIDs for primary keys
- Define associations explicitly per CORE_DATA_MODEL.md
- Validations go in the model, not the database (SQLite limitation workarounds)
- Use `delegated_type` for Item details per the documented pattern

### Testing

- Follow factory patterns in TESTING_STRATEGY.md
- Use `let` for test data, `let!` only when eager evaluation needed
- One assertion per test when practical (multiple assertions okay for related checks)
- System specs only for critical user journeys

### ViewComponents

- Follow domain namespacing: `Catalog::`, `Collection::`, `Storage::`, `UI::`
- Components in `app/components/{domain}/`
- Specs in `spec/components/{domain}/`

### Controllers

- Thin controllers; push logic to models or service objects
- Return `status: :unprocessable_entity` for validation failures
- Use Turbo Frame responses per TURBO_STIMULUS_PATTERNS.md

## Asking Questions

When uncertain:

- **Architecture/design decisions**: Ask before proceeding
- **Unclear acceptance criteria**: Ask for clarification
- **Multiple valid approaches**: Present options with tradeoffs
- **Potential scope creep**: Flag it and get confirmation

Do not invent requirements or make assumptions about unstated behavior.

## Current Project State

<!-- Update this section as the project progresses -->

**Completed Features**: None (bootstrapping)

**In Progress**: Project setup and infrastructure

**Next Up**: Phase 0 - Foundation (see ROADMAP.md)
