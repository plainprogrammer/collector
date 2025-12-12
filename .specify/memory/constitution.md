<!--
  Sync Impact Report
  ===================
  Version change: 0.0.0 → 1.0.0 (initial constitution ratification)

  Modified principles: N/A (initial version)

  Added sections:
    - 7 Core Principles (I-VII)
    - Technology Stack section
    - Quality Gates section
    - Governance section

  Removed sections: N/A (initial version)

  Templates requiring updates:
    - .specify/templates/plan-template.md: ✅ No updates needed (Constitution Check section exists)
    - .specify/templates/spec-template.md: ✅ No updates needed (Requirements align with principles)
    - .specify/templates/tasks-template.md: ✅ No updates needed (Test-first workflow documented)
    - .specify/templates/agent-file-template.md: ✅ No updates needed (Generic template)
    - .specify/templates/checklist-template.md: ✅ No updates needed (Generic template)

  Follow-up TODOs: None
-->

# Collector Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

All new functionality MUST be developed using test-driven development (TDD):

- Tests MUST be written before implementation code
- Tests MUST fail before implementation begins (red phase)
- Implementation MUST make tests pass with minimal code (green phase)
- Code MUST be refactored only after tests pass (refactor phase)
- Full test suite (`bin/rspec`) MUST pass before any commit

**Rationale**: TDD ensures code correctness, provides living documentation, and prevents
regression. The red-green-refactor cycle enforces deliberate, incremental development.

### II. Rails Conventions (Omakase)

Development MUST follow Rails conventions and the "Omakase" philosophy:

- Use Rails defaults and conventions over custom solutions
- Follow `rubocop-rails-omakase` style guidelines without exception
- Prefer Rails built-in solutions (Solid Cache, Solid Queue, Solid Cable) over external gems
- Use Hotwire (Turbo + Stimulus) for interactive features, not heavy JavaScript frameworks
- Model naming MUST follow Rails inflection rules (e.g., `MTGJSON::Card` not `Mtgjson::Card`)

**Rationale**: Conventions reduce cognitive load, improve maintainability, and ensure
consistency across the codebase. Rails Omakase provides opinionated defaults that work well
together.

### III. Read-Only MTGJSON Integrity

The MTGJSON database MUST remain strictly read-only:

- All MTGJSON models MUST inherit from `MTGJSON::Base`
- Write operations (create, update, destroy) MUST raise `ActiveRecord::ReadOnlyRecord`
- Cross-database foreign keys MUST NOT be created; use UUID references only
- MTGJSON data updates MUST only occur via `bin/rails mtgjson:refresh`

**Rationale**: MTGJSON is external reference data that must not be modified by the
application. Enforcing read-only at the model level prevents accidental corruption and
maintains data integrity.

### IV. CI-First Quality

All code changes MUST pass the complete CI pipeline locally before commit:

- `bin/ci` MUST pass (linting, security scans, full test suite)
- RuboCop violations MUST be fixed, not suppressed
- Security scans (Brakeman, bundler-audit, importmap audit) MUST show no vulnerabilities
- System tests MUST pass with headless Chrome

**Rationale**: Local CI validation prevents broken commits, reduces feedback loops, and
ensures the main branch always remains in a deployable state.

### V. Multi-Database Separation

The dual-database architecture MUST maintain strict separation:

- Application data (collections, items) MUST reside in the primary database only
- Reference data (cards, sets) MUST reside in the mtgjson database only
- Cross-database queries MUST NOT use ActiveRecord associations; use UUID lookups
- Migrations MUST only exist for the primary database (`db/migrate/`)
- Database connections MUST be explicitly managed via model inheritance

**Rationale**: SQLite files are separate and cannot have foreign key constraints between
them. Clean separation ensures data integrity and simplifies database management.

### VI. Simplicity (YAGNI)

Development MUST favor simplicity and avoid over-engineering:

- Implement only what is explicitly required; no speculative features
- Prefer three similar lines of code over a premature abstraction
- Do not add error handling for scenarios that cannot occur
- Do not create helpers or utilities for one-time operations
- Remove unused code completely; no backward-compatibility hacks

**Rationale**: Unnecessary complexity increases maintenance burden, introduces bugs, and
obscures intent. Simple code is easier to understand, test, and modify.

### VII. Security by Default

All code MUST follow secure development practices:

- Validate all external input (user input, API responses) at system boundaries
- Never commit secrets (.env files, credentials, API keys)
- Use Rails built-in security features (CSRF protection, parameter filtering)
- Address Brakeman warnings immediately; do not suppress without documented justification
- Follow OWASP Top 10 guidelines for web application security

**Rationale**: Security vulnerabilities can compromise user data and application integrity.
Proactive security practices prevent incidents before they occur.

## Technology Stack

This section defines the required technologies for the Collector project.

### Backend Requirements

- **Ruby**: Version 3.4 (as specified in `.ruby-version`)
- **Rails**: Version 8.1 with multi-database support
- **Database**: SQLite3 for both primary and mtgjson databases
- **Background Jobs**: Solid Queue (database-backed)
- **Caching**: Solid Cache (database-backed)
- **WebSockets**: Solid Cable (database-backed)

### Frontend Requirements

- **JavaScript**: Importmap (no webpack/esbuild)
- **Reactivity**: Hotwire (Turbo + Stimulus)
- **Styling**: Tailwind CSS
- **Assets**: Propshaft pipeline

### Testing Requirements

- **Framework**: RSpec 8.0 (not Minitest)
- **System Tests**: Capybara with Selenium WebDriver
- **Browser**: Headless Chrome/Chromium

### Deployment Requirements

- **Containerization**: Kamal for Docker-based deployment
- **HTTP Proxy**: Thruster for HTTP/2 and caching

## Quality Gates

All code MUST pass these quality gates before merging to main.

### Pre-Commit Gate

Run `bin/ci` which executes:

1. **Setup Verification**: Ensures all dependencies are installed
2. **Linting**: RuboCop with `rubocop-rails-omakase` rules
3. **Security Scans**:
   - `bin/brakeman` - Static analysis for security issues
   - `bin/bundler-audit` - Gem vulnerability scanning
   - `bin/importmap audit` - JavaScript dependency scanning
4. **Test Suite**: Full RSpec suite including system tests

### Code Review Gate

- All PRs MUST be reviewed before merge
- Reviewers MUST verify Constitution compliance
- CI MUST pass on the PR branch

### Merge Gate

- Main branch MUST always be deployable
- No force pushes to main
- Squash merges preferred for clean history

## Governance

This Constitution supersedes all other development practices for the Collector project.

### Amendment Process

1. Propose changes via PR with rationale
2. Review period of at least 24 hours
3. All active contributors must approve
4. Update version following semantic versioning:
   - MAJOR: Principle removal or incompatible redefinition
   - MINOR: New principle or section added
   - PATCH: Clarifications, wording fixes
5. Document changes in Sync Impact Report

### Compliance

- All PRs MUST verify compliance with Core Principles
- Violations MUST be flagged in code review
- Exceptions require documented justification and team approval

### Reference Documents

- Primary guidance: `CLAUDE.md` for development workflow
- MTGJSON details: `docs/MTGJSON_INTEGRATION.md`
- Rails conventions: https://guides.rubyonrails.org/

**Version**: 1.0.0 | **Ratified**: 2025-12-11 | **Last Amended**: 2025-12-11
