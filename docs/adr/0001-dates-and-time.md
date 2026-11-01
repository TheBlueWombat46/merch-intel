# ADR 0001: Dates, time zones and effective dating

Status: Accepted (Milestone 0)

## Context
Sales are reported per business day. Locations and showcases change over time and
history must stay queryable. Off-by-one errors at window boundaries would make
pre/post comparisons wrong.

## Decision
- **Business dates are `DATE`, never timestamps.** `daily_sales.business_date` is the
  store's local business day as supplied by the source. No time-zone conversion is
  applied to it.
- **Each store has an IANA time zone** (`America/Chicago`). It is used only to decide
  what "today" means for that store (e.g. which post-window days are still incomplete).
- **Audit timestamps are `timestamptz`, stored in UTC** (`created_at`, `imported_at`).
- **Effective ranges are half-open: `[effective_from, effective_to)`.** `effective_from`
  is inclusive, `effective_to` exclusive, `NULL` means open-ended. A move on 2026-03-10
  closes the old row with `effective_to = 2026-03-10` and opens the new row with
  `effective_from = 2026-03-10`, with no gap or overlap.
- Overlap checks use PostgreSQL `daterange(effective_from, effective_to, '[)')`.
- **Showcase windows:** start date is day 1 of the post window. Pre window = the N days
  ending the day before start. Post days later than the store's last complete business
  day are excluded and flagged as incomplete.
- Fiscal calendars are out of scope for the POC; weeks are ISO weeks.

## Consequences
Range queries are simple (`from <= d AND (to IS NULL OR d < to)`) and adjacent ranges
never double-count a day. Every date-window rule gets a boundary test.
