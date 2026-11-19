{{ config(materialized='table') }}

SELECT
    CONCAT(
        s.roster_id,
        '_',
        CAST(s.service_offset AS STRING)
    ) AS service_occurrence_id,

    s.roster_id,
    s.service_offset,
    s.service_date,
    s.service_start_time,
    s.service_end_time,
    s.service_start_at,
    s.service_end_at,

    DATETIME_DIFF(
        s.service_end_at,
        s.service_start_at,
        MINUTE
    ) AS service_duration_minutes,

    r.service_team,
    r.status AS roster_status,
    r.roster_title,
    r.service_name,
    r.roster_details,

    CURRENT_TIMESTAMP() AS dbt_updated_at

FROM {{ ref('int_roster_service_datetimes') }} AS s

LEFT JOIN {{ ref('dim_rosters') }} AS r
    ON s.roster_id = r.roster_id