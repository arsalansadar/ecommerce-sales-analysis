CREATE TABLE dim_seller (
    seller_key      INT IDENTITY(1,1) PRIMARY KEY,
    seller_id       VARCHAR(50) NOT NULL,
    seller_city     VARCHAR(100),
    seller_state    VARCHAR(5)
);

INSERT INTO dim_seller (seller_id, seller_city, seller_state)
SELECT seller_id, seller_city, seller_state
FROM clean.sellers;

-- Unknown row
INSERT INTO dim_seller (seller_id, seller_city, seller_state)
VALUES ('UNKNOWN', 'Unknown', 'None');

SELECT COUNT(*) FROM dim_seller;  -- expect 3,095 + 1


-- for checking purpose
-- Sample check: har dimension ke top 3 rows dekho
SELECT TOP 3 * FROM dim_customer;
SELECT TOP 3 * FROM dim_product;
SELECT TOP 3 * FROM dim_seller;
SELECT TOP 3 * FROM dim_date;