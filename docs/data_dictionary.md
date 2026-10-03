# Data Dictionary

Source: Olist Brazilian E-commerce dataset. Grain = what one row represents.

## orders
**Grain:** one row per order (99,441 rows)
| Column | Notes |
|---|---|
| order_id | Primary key |
| customer_id | Per-order ID — use `customer_unique_id` (via customers table) to identify the actual person |
| order_status | delivered (97%), shipped, canceled, unavailable, invoiced, processing, created, approved |
| is_late | 1 if delivered after estimated date. Only meaningful when status = delivered |
| is_date_anomaly | 1 if delivery date is logically inconsistent (23 rows) — excluded from delay calculations |
| delay_days | Actual delivery date − estimated date. Negative = early |

## order_items
**Grain:** one row per item within an order (112,650 rows)
| Column | Notes |
|---|---|
| order_id + order_item_id | Composite primary key |
| price | Used as the revenue figure throughout (freight excluded) |
| freight_value | Can be 0 (free shipping on some items) |

## order_payments
**Grain:** one row per payment installment/split (103,886 rows)
| Column | Notes |
|---|---|
| order_id | One order can have multiple payment rows (installments, vouchers) |
| payment_type | credit_card, boleto, voucher, debit_card, unknown |
| payment_value | Not a revenue source — used only for payment-mix analysis |

## order_reviews
**Grain:** one row per review, deduplicated to one per order in the clean layer (98,673 orders have a review)
| Column | Notes |
|---|---|
| order_id | ~768 orders have no review at all |
| review_score | 1–5, bimodal distribution (most reviews are 1 or 5) |
| review_id | Not unique — can repeat across 2–3 orders (known Olist system behavior) |

## products
**Grain:** one row per product (32,951 rows)
| Column | Notes |
|---|---|
| product_id | Primary key |
| category_pt / category_english | ~610 products have no category — set to "Unknown" |
| weight_g | 4 products have weight = 0 (invalid, flagged) |

## sellers
**Grain:** one row per seller (3,095 rows) — clean, no issues found.

## customers
**Grain:** one row per order-customer link (99,441 rows); `customer_unique_id` is the real person and is the join key for anything customer-level.

## geolocation
**Grain:** one row per postal-code prefix after cleaning (aggregated from ~1M raw rows with GPS noise to 19,015).

## category_name_translation
**Grain:** one row per category (71 original + 2 added manually for untranslated categories).

---

## Star Schema (built from the tables above)

| Table | Type | Grain |
|---|---|---|
| fact_orders | Fact | one row per order |
| fact_order_items | Fact | one row per order item |
| dim_customer | Dimension | one row per `customer_unique_id` |
| dim_product | Dimension | one row per product |
| dim_seller | Dimension | one row per seller |
| dim_date | Dimension | one row per calendar date |

Every dimension includes an "Unknown" row (surrogate key = -1) to catch any unmatched fact row safely.
