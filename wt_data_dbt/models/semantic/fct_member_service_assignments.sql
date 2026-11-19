{{ config(materialized='table') }}

WITH member_service_assignments AS (

    SELECT
        s.service_occurrence_id,
        s.roster_id,
        s.service_offset,
        s.service_date,
        s.service_start_at,
        s.service_end_at,

        s.roster_title,
        s.service_name,
        s.roster_details,

        s.service_team,
        s.roster_status,

        a.role,
        a.member_id,
        a.member_name,
        a.assignment_note,

        EXISTS (
            SELECT 1
            FROM UNNEST(a.shift_exception_dates) AS exception_date
            WHERE exception_date = s.service_date
        ) AS has_shift_exception

    FROM {{ ref('fct_roster_assignments') }} AS a

    INNER JOIN {{ ref('fct_roster_services') }} AS s
        ON a.roster_id = s.roster_id

)

SELECT
    CONCAT(
        service_occurrence_id,
        '_',
        role,
        '_',
        member_id
    ) AS member_service_assignment_id,

    service_occurrence_id,
    roster_id,
    service_offset,
    service_date,
    service_start_at,
    service_end_at,

    roster_title,
    service_name,
    roster_details,

    service_team,
    roster_status,

    role,
    member_id,
    member_name,
    assignment_note,

    TRUE AS is_rostered,
    has_shift_exception,
    NOT has_shift_exception AS is_expected_to_serve,

    CURRENT_TIMESTAMP() AS dbt_updated_at

FROM member_service_assignments