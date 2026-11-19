{{ config(materialized='table') }}

WITH date_spine AS (

    SELECT date_day
    FROM UNNEST(
        GENERATE_DATE_ARRAY(
            DATE('{{ var("date_spine_start_date", "2020-01-01") }}'),
            DATE('{{ var("date_spine_end_date", "2035-12-31") }}'),
            INTERVAL 1 DAY
        )
    ) AS date_day

)

SELECT
    date_day,
    EXTRACT(YEAR FROM date_day) AS year_number,
    EXTRACT(QUARTER FROM date_day) AS quarter_number,
    EXTRACT(MONTH FROM date_day) AS month_number,
    FORMAT_DATE('%B', date_day) AS month_name,
    FORMAT_DATE('%Y-%m', date_day) AS year_month,
    EXTRACT(ISOWEEK FROM date_day) AS iso_week_number,
    EXTRACT(ISOYEAR FROM date_day) AS iso_year_number,
    DATE_TRUNC(date_day, WEEK(MONDAY)) AS week_start_date,
    DATE_TRUNC(date_day, MONTH) AS month_start_date,
    DATE_TRUNC(date_day, QUARTER) AS quarter_start_date,
    DATE_TRUNC(date_day, YEAR) AS year_start_date,
    FORMAT_DATE('%A', date_day) AS day_name,
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week_number,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(DAYOFYEAR FROM date_day) AS day_of_year,
    EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) AS is_weekend
FROM date_spine
