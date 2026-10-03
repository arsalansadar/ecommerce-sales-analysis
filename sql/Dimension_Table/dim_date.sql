use Olist_Raw_Data;

CREATE TABLE dim_date (
    date_key        INT PRIMARY KEY,        -- YYYYMMDD format
    full_date       DATE NOT NULL,
    year            INT,
    month           INT,
    month_name      VARCHAR(20),
    quarter         INT,
    day_of_week     INT,
    day_name        VARCHAR(20),
    is_weekend      BIT
);

DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate   DATE = '2018-12-31';

;WITH DateSeries AS (
    SELECT @StartDate AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM DateSeries
    WHERE full_date < @EndDate
)
INSERT INTO dim_date (date_key, full_date, year, month, month_name, quarter, day_of_week, day_name, is_weekend)
SELECT
    CAST(FORMAT(full_date, 'yyyyMMdd') AS INT) AS date_key,
    full_date,
    YEAR(full_date)                             AS year,
    MONTH(full_date)                            AS month,
    DATENAME(MONTH, full_date)                  AS month_name,
    DATEPART(QUARTER, full_date)                AS quarter,
    DATEPART(WEEKDAY, full_date)                AS day_of_week,
    DATENAME(WEEKDAY, full_date)                AS day_name,
    CASE WHEN DATEPART(WEEKDAY, full_date) IN (1,7) THEN 1 ELSE 0 END AS is_weekend
FROM DateSeries
OPTION (MAXRECURSION 1500);   -- default recursion limit 100 hai, 3 saal ~1096 din ke liye badhana padega

-- Unknown row (missing/invalid dates ke liye)
INSERT INTO dim_date (date_key, full_date, year, month, month_name, quarter, day_of_week, day_name, is_weekend)
VALUES (-1, '1900-01-01', NULL, NULL, 'Unknown', NULL, NULL, 'Unknown', NULL);

select * from dim_date;

SELECT COUNT(*) AS total_rows, MIN(full_date) AS first_date, MAX(full_date) AS last_date
FROM dim_date;

DELETE FROM dim_date WHERE date_key = -1;