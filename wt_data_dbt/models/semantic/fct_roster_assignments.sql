{{ config(materialized='table') }}

WITH assignment_notes AS (

    SELECT
        roster_id,
        member_id,
        role,
        ANY_VALUE(assignment_note) AS assignment_note
    FROM {{ ref('int_roster_assignment_notes') }}
    GROUP BY
        roster_id,
        member_id,
        role

),

shift_exception_summary AS (

    SELECT
        roster_id,
        member_id,
        role,
        COUNT(DISTINCT exception_date) AS shift_exception_count,
        ARRAY_AGG(
            DISTINCT exception_date
            IGNORE NULLS
            ORDER BY exception_date
        ) AS shift_exception_dates
    FROM {{ ref('int_roster_shift_exceptions') }}
    GROUP BY
        roster_id,
        member_id,
        role

)

SELECT
    a.roster_id,

    r.roster_title,
    r.service_name,
    r.roster_details,

    r.service_team,
    r.status AS roster_status,
    r.first_service_date,

    a.role,
    a.member_id,
    m.full_name AS member_name,
    m.is_active AS member_is_active,

    n.assignment_note,

    COALESCE(e.shift_exception_count, 0)
        AS shift_exception_count,

    COALESCE(
        e.shift_exception_dates,
        ARRAY<DATE>[]
    ) AS shift_exception_dates,

    CURRENT_TIMESTAMP() AS dbt_updated_at

FROM {{ ref('int_roster_assigned_members_roles') }} AS a

LEFT JOIN {{ ref('dim_rosters') }} AS r
    ON a.roster_id = r.roster_id

LEFT JOIN {{ ref('dim_members') }} AS m
    ON a.member_id = m.member_id

LEFT JOIN assignment_notes AS n
    ON a.roster_id = n.roster_id
    AND a.member_id = n.member_id
    AND a.role = n.role

LEFT JOIN shift_exception_summary AS e
    ON a.roster_id = e.roster_id
    AND a.member_id = e.member_id
    AND a.role = e.role