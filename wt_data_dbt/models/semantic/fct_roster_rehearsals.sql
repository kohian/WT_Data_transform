{{ config(materialized='table') }}

SELECT
    CONCAT(
        rh.roster_id,
        '_',
        CAST(rh.rehearsal_offset AS STRING)
    ) AS rehearsal_occurrence_id,

    rh.roster_id,
    rh.rehearsal_offset,
    rh.rehearsal_date,
    rh.rehearsal_start_time,
    rh.rehearsal_end_time,
    rh.rehearsal_start_at,
    rh.rehearsal_end_at,

    DATETIME_DIFF(
        rh.rehearsal_end_at,
        rh.rehearsal_start_at,
        MINUTE
    ) AS rehearsal_duration_minutes,

    r.service_team,
    r.status AS roster_status,
    r.roster_title,
    r.service_name,
    r.roster_details,

    CURRENT_TIMESTAMP() AS dbt_updated_at

FROM {{ ref('int_roster_rehearsal_datetimes') }} AS rh

LEFT JOIN {{ ref('dim_rosters') }} AS r
    ON rh.roster_id = r.roster_id