# ADR 0002: Sales attribution across multiple homes

Status: Accepted (Milestone 0)

## Context
A SKU can sit in several homes at once (primary bay, end cap, showcase). Daily sales
are recorded per store and SKU, not per location, so the data cannot say which
display produced a sale.

## Decision
- **Sales belong to the SKU in a store, not to a location.** Store, department and
  category totals sum `daily_sales` once per store/SKU/date, never through assignments.
- **Location views show "SKU-linked sales"**: the full sales of each SKU assigned
  there, labelled as such, with a "SKU also in N other homes" warning when relevant.
  These figures are never summed across bays into a store total.
- **No allocation in the POC.** Any future split (equal share, by facings, by role) must
  be an explicit, named policy shown on screen, recorded in a new ADR.
- **Showcase analysis is observational.** Results are labelled "observed change",
  never "impact" or "uplift". Percentage change is undefined when the pre-window daily
  average is 0, and is displayed as "n/a (no baseline sales)".
- Space-productivity metrics are not shown until a spatial denominator is defined
  (front-elevation area is not floor square footage).

## Consequences
Totals always reconcile to imported sales. Bay-level views are less "complete-looking"
but honest. A test fixture with one SKU in two bays guards against double counting.
