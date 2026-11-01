# Schema draft (for migration 0002, session 2)

Status: Draft. Not yet migrated; migration 0001 is an empty baseline.
Conventions: `bigint` identity PKs, `snake_case`, `created_at timestamptz default now()`
on every table, money as `numeric(14,2)`, quantities as `numeric(14,3)` (flooring sells
by the square foot, so units can be fractional). Dates follow ADR 0001.

## Changes from the design document
| # | Design doc | This draft | Why |
|---|---|---|---|
| 1 | One `DailySales` table | `sales_staging` (raw) + `daily_sales` (canonical) | Doc requires both raw batches and exactly one resolved row per store/SKU/date |
| 2 | `returns`, `price` accepted on import but no columns | Added `returns_amount`, `unit_price` | Otherwise imported data is silently dropped |
| 3 | `Product` has no department | `product.department_id` | Catalog CSV has `department`; dashboard needs department share |
| 4 | SKU scope inconsistent | Single retailer, `sku` unique | ADR 0003 |
| 5 | `Showcase.home_id` (one home) | `showcase_location` link table (home **or** bay) | Open decision asks for whole bays / several homes |
| 6 | `Assignment.store_id` | Removed; store derived from home | Avoids rows that disagree with their home's store |
| 7 | `Department(store_id, ...)` | Retailer-wide `department` | Same departments across stores; products reference them |

## Tables

**Locations**
- `store` (id, code UNIQUE, name, timezone)
- `department` (id, name UNIQUE, color)
- `aisle` (id, store_id FK, label; UNIQUE(store_id, label))
- `bay` (id, aisle_id FK, department_id FK NULL, label, x, y, width, height; UNIQUE(aisle_id, label))
- `shelf` (id, bay_id FK, level, width, height, depth NULL; UNIQUE(bay_id, level))
- `home` (id, shelf_id FK, label, x, y, width, height, depth NULL,
  type ENUM(primary, secondary, display, stock, showcase),
  capacity_mode ENUM(exclusive, shared) DEFAULT exclusive; UNIQUE(shelf_id, label))

**Catalog**
- `product` (id, sku TEXT UNIQUE, name, department_id FK NULL, category, active BOOL)

**Assignments**
- `assignment` (id, product_id FK, home_id FK, role ENUM(primary, secondary, display, stock, showcase),
  effective_from DATE, effective_to DATE NULL, note)
  - CHECK `effective_to IS NULL OR effective_to > effective_from`
  - EXCLUDE (product_id =, home_id =, daterange &&): same SKU can't be in the same home twice at once
  - Exclusive homes reject overlapping assignments of *different* SKUs. Enforced in the
    service layer with tests (needs the home's mode, so not a plain constraint).

**Showcases**
- `showcase` (id, store_id FK, name, start_date, end_date NULL, status ENUM(planned, active, completed), notes, updated_at)
- `showcase_location` (showcase_id FK, home_id FK NULL, bay_id FK NULL; CHECK exactly one set)
- `showcase_product` (showcase_id FK, product_id FK; PK both)
- Overlapping showcases are allowed and flagged in analysis, not blocked.

**Imports and sales**
- `import_batch` (id, kind ENUM(products, sales), filename, file_sha256, imported_at,
  status ENUM(previewed, committed, failed), row_count, error_count, errors JSONB)
- `sales_staging` (id, batch_id FK, row_number, raw JSONB, parsed columns NULL, error TEXT NULL)
  - Every input row is kept, valid or not, for the data-quality report.
- `daily_sales` (id, store_id FK, product_id FK, business_date DATE, units, net_sales,
  gross_profit NULL, returns_amount NULL, stock_on_hand NULL, promo_flag BOOL NULL,
  unit_price NULL, source_batch_id FK; UNIQUE(store_id, product_id, business_date))
  - **Correction policy:** a later committed batch replaces the row for the same
    store/SKU/date. Re-importing an identical file is a no-op (same values). The
    replaced batch remains in staging, so history is auditable.
  - Negative `units` / `net_sales` (net returns) are allowed and flagged.

## Deferred (noted, not in 0002)
- Dated product-department history, needed for the "changed department" quality flag (Milestone 3).
- Price and promotion history tables (backlog).
- Multi-retailer `retailer` table (ADR 0003).
