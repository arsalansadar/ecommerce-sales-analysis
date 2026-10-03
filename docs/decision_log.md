# Decision Log

Short, scannable record of every non-obvious decision made in this project and why. Organized by phase.

## Scope & Definitions
- Revenue = SUM(item price), freight excluded, canceled/unavailable orders excluded (unless stated otherwise).
- Customer identity = `customer_unique_id`, not `customer_id` (which is generated per order).
- Analysis range for trend charts: Jan 2017–Aug 2018. Data outside this is sparse/incomplete at both edges of collection.

## Profiling Decisions
- 23 orders with impossible delivery-date logic → flagged (`is_date_anomaly`), not deleted. Excluded from delay calculations.
- 8 "delivered" orders missing a delivery date → flagged.
- 775 orders with no line items → mostly explained by cancellation/unavailability before item assignment. 1 "shipped" order with no item is a genuine anomaly, kept but flagged.
- 1 order with zero payment rows → excluded from payment-value analysis.
- 9 zero-value payment rows: 5 explained (multi-row voucher splits), 3 are a genuine gap (single row, type "unknown") → excluded from payment-value analysis.
- 2 payment rows with `installments = 0` but value > 0 → corrected to 1 (data-entry error).
- 789 shared `review_id`s across orders → confirmed as a known Olist behavior, not an error. Reviews deduplicated to 1/order (latest kept).
- 610 products missing category + photos → set category to "Unknown", row kept.
- 2 categories with no English translation → added manually.
- 4 products with weight = 0 → flagged, excluded from weight-based analysis.
- 1 "ghost" product (all fields blank except ID) → kept, since it has 17 real orders against it.
- Geolocation table (~1M rows, GPS noise) → aggregated to 1 row per zip prefix (19,015 rows).

## Cleaning Layer
- All transformations done as SQL views over raw tables — raw tables never edited directly.
- Anomalies are flagged with boolean columns, never silently dropped.
- Row counts reconciled against raw source after every view; all matched except reviews and geolocation (intentionally deduplicated/aggregated).

## Star Schema
- Two fact tables (not one) to avoid grain mismatch: `fact_orders` (order-level) and `fact_order_items` (item-level). Order-level metrics (review, delivery days) would double-count if stored at item grain.
- `dim_customer` built on `customer_unique_id`.
- Every dimension has an "Unknown" row (key = -1) for unmatched fact rows.
- Fixed a performance issue: a correlated subquery for customer lookup (minutes to run) was replaced with a two-step equi-join (seconds).
- Switched nested subqueries to CTEs in `fact_orders` once the query had 3+ helper aggregations, for readability (no performance difference — CTEs and subqueries compile the same way).
- Validated: `fact_orders` revenue total matches `order_items` total exactly; zero orphaned dimension keys.

## Analysis — Delivery vs. Review
- Scope: delivered orders, with a review, excluding date anomalies.
- Used Mann-Whitney U test (not t-test) — review scores are a non-normal, discrete ordinal scale.
- Ran a category-level confounding check before trusting the overall result — pattern held in every category.
- Noted but did not over-interpret: high variance at 30+ day delays (23% still rated 4–5★) — no refund/communication data available to explain it.

## Analysis — Cohort Retention
- Used all order activity (not filtered by status) — a deliberate scope difference from revenue-based analyses, documented so the two aren't mistakenly compared.
- Month-1 retention computed as a customer-weighted average across cohorts, not a simple average of percentages.
- Excluded the October 2018 cohort (1 customer) — censored, no future month exists in the data to measure it against.

## Analysis — RFM Segmentation
- Frequency scored with a business rule (1 / 2 / 3+ orders), not `NTILE(5)`, because 97% of customers have exactly 1 order and an even 5-way split would be meaningless.
- Recency and Monetary scored with `NTILE(5)` (both have real spread).
- Validated: segment totals reconcile exactly to the RFM base (94,983 customers, ₹13,494,400.74).

## Analysis — Pareto / Category
- Revenue ranked by category; Top N filters in Power BI use `ALL()` in DAX so the 80% cumulative line is calculated across all 74 categories regardless of how many are displayed.

## Final Validation
- Found and explained an 8-order gap between `fact_orders` valid-order count (98,207) and RFM's order count (98,199): 8 valid-status orders have no line items, so they have no revenue and are naturally excluded from RFM.
- Confirmed zero orphaned purchase/delivery dates against `dim_date`.

## Power BI / DAX
- Import mode used (not DirectQuery) — dataset is small and static.
- Only the clean/modeled layer imported, never raw tables.
- `Total Orders` must be measured from `fact_orders` with `DISTINCTCOUNT`, not from the item-grain table — an early mismatch here caused a wrong AOV.
- Every ratio measure uses `DIVIDE()`, never raw `/`.
- Month-name fields need an explicit numeric sort-key column — Power BI sorts text alphabetically by default, which breaks chronological charts.
- Category comparison charts need the same minimum-sample-size filter (≥30 orders) used in SQL, or small categories appear misleadingly alongside high-volume ones.
