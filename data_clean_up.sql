-- ===========================
-- 1) Clean PRODUCTS
-- ===========================
CREATE OR REPLACE VIEW `upheld-terminus-471904-k3.sql_practice.products_clean` AS
WITH base AS (
  SELECT
    SAFE_CAST(product_id AS INT64)            AS product_id,
    CAST(product_name AS STRING)              AS product_name,
    CAST(category AS STRING)                  AS category_raw,
    SAFE_CAST(price AS NUMERIC)               AS price
  FROM `upheld-terminus-471904-k3.sql_practice.products`
),
std AS (
  SELECT
    product_id,
    product_name,
    -- Normalize category to a small controlled set
    CASE
      WHEN LOWER(category_raw) LIKE '%books%'             THEN 'Books'
      WHEN LOWER(category_raw) LIKE '%clothing%'          THEN 'Clothing'
      WHEN LOWER(category_raw) LIKE '%home%'              THEN 'Home'
      WHEN LOWER(category_raw) LIKE '%home appliances%'   THEN 'Home'
      WHEN LOWER(category_raw) LIKE '%sports%'            THEN 'Sports'
      WHEN LOWER(category_raw) LIKE '%electronics%'       THEN 'Electronics'
      WHEN LOWER(category_raw) LIKE '%beauty%'            THEN 'Beauty'
      ELSE 'Other'
    END AS category,
    price
  FROM base
)
SELECT *
FROM std
WHERE price IS NOT NULL AND price > 0;

-- ===========================
-- 2) Clean CUSTOMERS
-- ===========================
CREATE OR REPLACE VIEW `upheld-terminus-471904-k3.sql_practice.customers_clean` AS
WITH base AS (
  SELECT
    SAFE_CAST(customer_id AS INT64) AS customer_id,
    CAST(first_name AS STRING)            AS first_name,
    CAST(email AS STRING)           AS email,
    -- Keep join_date if it parses as DATE or TIMESTAMP; otherwise NULL
    COALESCE(
      SAFE_CAST(join_date AS DATE),
      DATE(SAFE_CAST(join_date AS TIMESTAMP))
    ) AS join_date
  FROM `upheld-terminus-471904-k3.sql_practice.customers`
),
dedup AS (
  -- If duplicates exist, keep the latest join_date (or any deterministic row)
  SELECT *
  FROM (
    SELECT b.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY join_date DESC NULLS LAST) AS rn
    FROM base b
  )
  WHERE rn = 1
)
SELECT *
FROM dedup
WHERE customer_id IS NOT NULL;

-- ===========================
-- 3) Clean ORDERS  (date rules + valid FKs + positive qty/price)
-- ===========================
CREATE OR REPLACE VIEW `upheld-terminus-471904-k3.sql_practice.orders_clean` AS
WITH raw_cast AS (
  SELECT
    SAFE_CAST(order_id AS INT64)   AS order_id,
    SAFE_CAST(customer_id AS INT64)AS customer_id,
    SAFE_CAST(product_id AS INT64) AS product_id,
    SAFE_CAST(quantity AS INT64)   AS quantity,

    -- Robust date parsing: try DATE first, then TIMESTAMP -> DATE
    COALESCE(
      SAFE_CAST(order_date AS DATE),
      DATE(SAFE_CAST(order_date AS TIMESTAMP))
    ) AS order_date,

    COALESCE(
      SAFE_CAST(ship_date AS DATE),
      DATE(SAFE_CAST(ship_date AS TIMESTAMP))
    ) AS ship_date,

    COALESCE(
      SAFE_CAST(delivery_date AS DATE),
      DATE(SAFE_CAST(delivery_date AS TIMESTAMP))
    ) AS delivery_date
  FROM `upheld-terminus-471904-k3.sql_practice.orders`
),
dedup AS (
  -- Define duplicates as same order_id; keep the most recent order_date
  SELECT *
  FROM (
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date DESC NULLS LAST) AS rn
    FROM raw_cast r
  )
  WHERE rn = 1
),
valid_fk AS (
  -- Keep only rows whose customer & product exist in the cleaned dims
  SELECT d.*
  FROM dedup d
  JOIN `upheld-terminus-471904-k3.sql_practice.customers_clean` c
    ON d.customer_id = c.customer_id
  JOIN `upheld-terminus-471904-k3.sql_practice.products_clean`  p
    ON d.product_id  = p.product_id
),
value_rules AS (
  -- Positive quantities; allow ship/delivery to be NULL
  -- Enforce order_date ≤ ship_date ≤ delivery_date when present
  -- Also block future dates vs CURRENT_DATE()
  SELECT *
  FROM valid_fk
  WHERE quantity IS NOT NULL AND quantity > 0
    AND order_date IS NOT NULL
    AND (ship_date     IS NULL OR ship_date     >= order_date)
    AND (delivery_date IS NULL OR delivery_date >= ship_date)
    AND order_date     <= CURRENT_DATE()
    AND (ship_date     IS NULL OR ship_date     <= CURRENT_DATE())
    AND (delivery_date IS NULL OR delivery_date <= CURRENT_DATE())
),
priced AS (
  -- Recompute price & totals from the cleaned products table (protects from bad raw prices)
  SELECT
    v.order_id,
    v.customer_id,
    v.product_id,
    v.quantity,
    v.order_date,
    v.ship_date,
    v.delivery_date,
    p.price,
    ROUND(v.quantity * p.price, 2) AS total_price,
    p.category
  FROM value_rules v
  JOIN `upheld-terminus-471904-k3.sql_practice.products_clean` p
    ON v.product_id = p.product_id
)
SELECT *
FROM priced;


SELECT * FROM `upheld-terminus-471904-k3.sql_practice.orders_clean` LIMIT 100;



