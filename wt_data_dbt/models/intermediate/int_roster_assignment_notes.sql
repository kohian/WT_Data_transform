WITH note_keys AS (

    SELECT
        r.roster_id,
        r.assignment_notes,
        assignment_key
    FROM {{ ref('stg_fs_rosters') }} AS r
    CROSS JOIN UNNEST(JSON_KEYS(r.assignment_notes)) AS assignment_key
    WHERE JSON_TYPE(r.assignment_notes) = 'object'

)

SELECT
    roster_id,
    assignment_key,

    REGEXP_EXTRACT(
        assignment_key,
        r'^([^_]+)_'
    ) AS member_id,

    REGEXP_EXTRACT(
        assignment_key,
        r'^[^_]+_(.+)$'
    ) AS role,

    JSON_VALUE(
        assignment_notes[assignment_key]
    ) AS assignment_note

FROM note_keys