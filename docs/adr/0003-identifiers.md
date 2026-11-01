# ADR 0003: Identifiers

Status: Accepted (Milestone 0)

## Context
The design documents describe the SKU three different ways: "store-specific",
"unique within catalog" and "retailer-specific (default)". Imports need a stable key.

## Decision
- **The POC models one retailer.** `product.sku` is the retailer's SKU text, unique
  across the database, shared by all stores. It is stored exactly as imported
  (trimmed, case preserved, leading zeros kept: always text, never a number).
- **Internal surrogate keys** (`bigint` identity) are used for all foreign keys. SKUs
  can be corrected without rewriting history.
- **Natural keys get unique constraints**: `store.code`, `product.sku`,
  `department.name`, `(store_id, aisle.label)`, `(aisle_id, bay.label)`, and so on.
- **Imports match on natural keys** (store code, SKU), never on internal IDs.
- Multi-retailer support (a `retailer` table and `(retailer_id, sku)` uniqueness) is a
  post-POC backlog item and can be added with one migration.

## Consequences
Synthetic CSVs stay human-readable. Leading-zero SKUs ("000123") survive round trips,
including CSV export to Power BI (exports quote SKU columns).
