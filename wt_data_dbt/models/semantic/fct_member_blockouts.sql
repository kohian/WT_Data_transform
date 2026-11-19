{{ config(materialized='table') }}

SELECT
    b.blockout_id,
    b.entry_id,
    b.entry_offset,
    b.member_id,
    m.full_name AS member_name,
    m.is_active AS member_is_active,
    b.blockout_type,
    b.reason,
    b.period_start_at,
    b.period_end_at,
    DATE(b.period_start_at) AS blockout_start_date,
    DATE(b.period_end_at) AS blockout_end_date,
    b.is_all_day,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM {{ ref('int_blockouts_consolidated') }} AS b
LEFT JOIN {{ ref('dim_members') }} AS m
    ON b.member_id = m.member_id
