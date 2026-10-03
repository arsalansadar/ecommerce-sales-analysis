CREATE TABLE dim_product (
    product_key             INT IDENTITY(1,1) PRIMARY KEY,
    product_id              VARCHAR(50) NOT NULL,
    category_english        VARCHAR(100),
    weight_g                INT,
    length_cm               INT,
    height_cm               INT,
    width_cm                INT,
    is_incomplete_listing   BIT
);

INSERT INTO dim_product (product_id, category_english, weight_g, length_cm, height_cm, width_cm, is_incomplete_listing)
SELECT product_id, category_en, weight_g, length_cm, height_cm, width_cm, is_incomplete_listing
FROM clean.products_with_category;

-- Unknown row
INSERT INTO dim_product (product_id, category_english, weight_g, length_cm, height_cm, width_cm, is_incomplete_listing)
VALUES ('UNKNOWN', 'Unknown', NULL, NULL, NULL, NULL, 1);

SELECT COUNT(*) FROM dim_product;  -- expect 32,951 + 1