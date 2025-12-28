# Feature: Core Domain Models

Reference: docs/plans/ROADMAP.md § 0.4

## Summary

Establish the collection layer models per the core data model. This phase implements Collection, StorageUnit, CollectionStorageUnit, Item, and MTGCardItemDetail models with full polymorphic associations and delegated types. After completion, the application will support creating collections, organizing items into storage units, and tracking physical card instances with detailed attributes.

## Tasks

### Models - Collection

- [ ] T053: Write migration for Collection model `db/migrate/TIMESTAMP_create_collections.rb`
- [ ] T054: Write Collection model spec `spec/models/collection_spec.rb`
- [ ] T055: Implement Collection model with validations `app/models/collection.rb`
- [ ] T056: Create Collection factory `spec/factories/collections.rb`

### Models - StorageUnit

- [ ] T057: Write migration for StorageUnit model `db/migrate/TIMESTAMP_create_storage_units.rb`
- [ ] T058: Write StorageUnit model spec (including nesting and scope validation) `spec/models/storage_unit_spec.rb`
- [ ] T059: Implement StorageUnit model with self-referential associations `app/models/storage_unit.rb`
- [ ] T060: Create StorageUnit factory with nesting traits `spec/factories/storage_units.rb`

### Models - CollectionStorageUnit

- [ ] T061: Write migration for CollectionStorageUnit join model `db/migrate/TIMESTAMP_create_collection_storage_units.rb`
- [ ] T062: Write CollectionStorageUnit model spec `spec/models/collection_storage_unit_spec.rb`
- [ ] T063: Implement CollectionStorageUnit model `app/models/collection_storage_unit.rb`
- [ ] T064: Create CollectionStorageUnit factory `spec/factories/collection_storage_units.rb`

### Models - Item

- [ ] T065: Write migration for Item model with polymorphic and delegated type fields `db/migrate/TIMESTAMP_create_items.rb`
- [ ] T066: Write Item model spec (including storage scope validation) `spec/models/item_spec.rb`
- [ ] T067: Implement Item model with polymorphic catalog_entry and delegated_type detail `app/models/item.rb`
- [ ] T068: Write custom validator for storage unit collection scope `app/validators/storage_unit_collection_validator.rb`
- [ ] T069: Create Item factory with delegated type setup `spec/factories/items.rb`

### Models - MTGCardItemDetail

- [ ] T070: Write migration for MTGCardItemDetail model `db/migrate/TIMESTAMP_create_mtg_card_item_details.rb`
- [ ] T071: Write MTGCardItemDetail model spec `spec/models/mtg_card_item_detail_spec.rb`
- [ ] T072: Implement MTGCardItemDetail model with defaults and validations `app/models/mtg_card_item_detail.rb`
- [ ] T073: Create MTGCardItemDetail factory with condition/finish traits `spec/factories/mtg_card_item_details.rb`

### Model Updates - MTGCard

- [ ] T074: Update MTGCard model to add items association `app/models/mtg_card.rb`
- [ ] T075: Write spec for MTGCard → Item association `spec/models/mtg_card_spec.rb`

### Model Updates - Catalog

- [ ] T076: Update Catalog model to add collection association `app/models/catalog.rb`
- [ ] T077: Write spec for Catalog → Collection association `spec/models/catalog_spec.rb`

### Validation Specs

- [ ] T078: Write spec for Item finish validation (must be valid for card) `spec/validators/finish_validator_spec.rb`
- [ ] T079: Implement finish validator `app/validators/finish_validator.rb`
- [ ] T080: Write spec for nested storage unit collection scope validation `spec/validators/nested_storage_scope_validator_spec.rb`
- [ ] T081: Implement nested storage scope validator `app/validators/nested_storage_scope_validator.rb`

### Default Data Setup

- [ ] T082: Write spec for default collection creation `spec/lib/tasks/setup_rake_spec.rb`
- [ ] T083: Implement rake task for default collection setup `lib/tasks/setup.rake`
- [ ] T084: Update seeds file to create default collection `db/seeds.rb`

### Integration & Validation

- [ ] T085: Write integration spec for Item creation with MTGCard `spec/integration/item_creation_integration_spec.rb`
- [ ] T086: Write integration spec for storage unit nesting and item assignment `spec/integration/storage_organization_integration_spec.rb`
- [ ] T087: Write integration spec for collection scope validation across nested storage `spec/integration/collection_scope_integration_spec.rb`
- [ ] T088: Write spec for Item delegated type behavior `spec/models/item_delegated_type_spec.rb`

## Acceptance Criteria

Per ROADMAP.md § 0.4:

- [ ] Collection model persists with catalog association
- [ ] StorageUnit supports arbitrary nesting (parent-child relationships)
- [ ] CollectionStorageUnit enables multi-collection storage
- [ ] Item model references catalog entries polymorphically (MTGCard)
- [ ] Item uses delegated type for MTGCardItemDetail
- [ ] Storage unit collection scope validation prevents invalid assignments
- [ ] Finish validation ensures item finish matches card's available finishes
- [ ] Default "My Collection" created and associated with MTGJSON catalog
- [ ] All model specs pass
- [ ] RuboCop style checks pass
- [ ] Brakeman security analysis passes

## Notes

- Collection has 1:1 relationship with Catalog (enforced at database level)
- StorageUnit supports self-referential nesting with parent_id
- CollectionStorageUnit join table has unique constraint on [collection_id, storage_unit_id]
- Item quantity defaults to 1 (one row per physical card)
- Item catalog_entry is polymorphic (MTGCard, future: CustomMTGCard, ComicEntry)
- Item detail is delegated type (MTGCardItemDetail, future: ComicItemDetail)
- MTGCardItemDetail defaults: condition="NM", finish="nonfoil", language="EN"
- Validation: Item's StorageUnit must belong to Item's Collection
- Validation: Child StorageUnit's collections must be subset of parent's collections
- Validation: Item's finish must be in catalog_entry.finishes array

## Checkpoints

- [ ] All tests pass (`bundle exec rspec`)
- [ ] No linting errors (`bundle exec rubocop`)
- [ ] No security warnings (`bin/ci`)
- [ ] Feature meets core acceptance criteria from ROADMAP.md § 0.4
- [ ] Default collection creation task runs successfully
- [ ] Can create items referencing MTGCards with MTGCardItemDetail

## Implementation Notes

Phase 0.4 establishes the foundational models for collection management. Key architectural decisions:

**Polymorphic Catalog Entry:**
Items reference their catalog entry (what card/comic/item this is) via polymorphic `catalog_entry` association. This allows Items to point to MTGCard, CustomMTGCard, or future types like ComicEntry.

**Delegated Type Detail:**
Physical-instance attributes specific to the item type are stored in delegated type models (MTGCardItemDetail for MTG cards). This keeps the Item table lean while supporting type-specific attributes.

**Storage Unit Flexibility:**
StorageUnit supports arbitrary nesting and multi-collection membership to model real-world storage scenarios (e.g., a shelf holding binders from different collections).

**Quantity Field:**
The default workflow creates one Item row per physical card (quantity: 1). The quantity field exists for bulk/unsorted storage scenarios where tracking individual cards isn't practical.

**Validation Strategy:**
Custom validators ensure referential integrity:
- StorageUnitCollectionValidator: Item's storage unit must belong to item's collection
- NestedStorageScopeValidator: Child storage unit's collections must be subset of parent's
- FinishValidator: Item's finish must be valid for the card printing
