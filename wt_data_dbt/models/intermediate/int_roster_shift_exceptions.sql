WITH exception_keys AS (

    SELECT
        r.roster_id,
        r.shift_exceptions,
        assignment_key
    FROM {{ ref('stg_fs_rosters') }} AS r
    CROSS JOIN UNNEST(JSON_KEYS(r.shift_exceptions)) AS assignment_key
    WHERE JSON_TYPE(r.shift_exceptions) = 'object'

),

exception_dates AS (

    SELECT
        roster_id,
        assignment_key,
        exception_date_text
    FROM exception_keys
    CROSS JOIN UNNEST(
        JSON_VALUE_ARRAY(
            shift_exceptions[assignment_key]
            )
    ) AS exception_date_text

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

    SAFE_CAST(exception_date_text AS DATE) AS exception_date

FROM exception_dates