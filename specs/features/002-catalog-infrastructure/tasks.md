# Feature: Catalog Infrastructure

Reference: docs/plans/ROADMAP.md § 0.2

## Summary

Create the catalog abstraction layer using the adapter pattern to support multiple data sources (MTGJSON, API-based, custom). This establishes the foundation for catalog entry management and enables future extensibility to comics, books, and other collectible types.

## Tasks

### Models

- [ ] T011: Write migration for Catalog model `db/migrate/TIMESTAMP_create_catalogs.rb`
- [ ] T012: Write Catalog model spec `spec/models/catalog_spec.rb`
- [ ] T013: Implement Catalog model with validations `app/models/catalog.rb`
- [ ] T014: Create Catalog factory `spec/factories/catalogs.rb`

### Adapter Pattern Infrastructure

- [ ] T015: Write CatalogAdapter base class spec `spec/adapters/catalog_adapter_spec.rb`
- [ ] T016: Implement CatalogAdapter base class `app/adapters/catalog_adapter.rb`
- [ ] T017: Write MTGJSONAdapter spec `spec/adapters/mtgjson_adapter_spec.rb`
- [ ] T018: Implement MTGJSONAdapter (placeholder methods) `app/adapters/mtgjson_adapter.rb`

### Catalog Initialization

- [ ] T019: Write spec for catalog:initialize rake task `spec/lib/tasks/catalog_rake_spec.rb`
- [ ] T020: Implement catalog:initialize rake task `lib/tasks/catalog.rake`

### Integration

- [ ] T021: Write integration spec for Catalog with adapter `spec/integration/catalog_adapter_integration_spec.rb`
- [ ] T022: Add Catalog accessor method to retrieve adapter instance `app/models/catalog.rb`

## Acceptance Criteria

Per ROADMAP.md § 0.2:

- [ ] Catalog model exists with name, source_type, source_config fields
- [ ] Catalog model uses UUID primary key
- [ ] Catalog belongs_to Collection (association will be added in Phase 0.4)
- [ ] CatalogAdapter base class defines interface: search, fetch_entry, bulk_import, refresh
- [ ] MTGJSONAdapter implements CatalogAdapter interface
- [ ] MTGJSONAdapter methods raise NotImplementedError (full implementation in Phase 0.3)
- [ ] Rake task catalog:initialize creates default MTGJSON catalog
- [ ] All model specs pass
- [ ] All adapter specs pass
- [ ] RuboCop style checks pass
- [ ] Brakeman security analysis passes

## Notes

- Catalog <-> Collection relationship will be completed in Phase 0.4 when Collection model is created
- MTGJSONAdapter will have placeholder implementations; full import logic comes in Phase 0.3
- Adapter pattern enables future API-based catalogs for comics, books, etc.
- source_config (jsonb) allows adapter-specific configuration storage

## Checkpoints

- [ ] All tests pass (`bundle exec rspec`)
- [ ] No linting errors (`bundle exec rubocop`)
- [ ] No security warnings (`bin/ci`)
- [ ] Feature meets acceptance criteria from ROADMAP.md § 0.2
