CREATE TABLE dim_customer (
    customer_key        INT IDENTITY(1,1) PRIMARY KEY,
    customer_unique_id   VARCHAR(50) NOT NULL,
    customer_city        VARCHAR(100),
    customer_state       VARCHAR(5)
);


-- Ek customer_unique_id ke multiple city/state ho sakte hain (agar alag address se order kiya)
-- Hum sabse recent order wala city/state lenge representative ke roop mein
INSERT INTO dim_customer (customer_unique_id, customer_city, customer_state)
SELECT customer_unique_id, customer_city, customer_state
FROM (
    SELECT c.customer_unique_id, c.customer_city, c.customer_state,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_ts DESC
        ) AS rn
    FROM clean.customers c
    JOIN clean.orders o ON o.customer_id = c.customer_id
) t
WHERE rn = 1;

-- Unknown row
INSERT INTO dim_customer (customer_unique_id, customer_city, customer_state)
VALUES ('UNKNOWN', 'Unknown', 'None');

select * from dim_customer;

-- validation
SELECT COUNT(*) FROM dim_customer;  -- expect ~96,096 + 1