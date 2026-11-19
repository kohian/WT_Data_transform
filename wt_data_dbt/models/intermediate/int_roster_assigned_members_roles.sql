WITH assignment_roles AS (

    SELECT
        r.roster_id,
        r.assignments,
        role
    FROM {{ ref('stg_fs_rosters') }} AS r
    CROSS JOIN UNNEST(JSON_KEYS(r.assignments)) AS role

),

flattened_assignments AS (

    SELECT
        roster_id,
        member_id,
        role
    FROM assignment_roles
    CROSS JOIN UNNEST(
        JSON_VALUE_ARRAY(assignments[role])
    ) AS member_id

)

SELECT
    roster_id,
    member_id,
    role
FROM flattened_assignments