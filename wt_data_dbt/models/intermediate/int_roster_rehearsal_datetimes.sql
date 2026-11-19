WITH unnested_rehearsal_datetimes AS (

    SELECT
        r.roster_id,
        rehearsal_offset,
        rehearsal_datetime
    FROM {{ ref('stg_fs_rosters') }} AS r
    CROSS JOIN UNNEST(r.rehearsal_datetime) AS rehearsal_datetime
    WITH OFFSET AS rehearsal_offset

)

SELECT
    roster_id,
    rehearsal_offset,

    SAFE_CAST(
        JSON_VALUE(rehearsal_datetime, '$.date')
        AS DATE
    ) AS rehearsal_date,

    SAFE.PARSE_TIME(
        '%H:%M',
        TRIM(JSON_VALUE(rehearsal_datetime, '$.startTime'))
    ) AS rehearsal_start_time,

    SAFE.PARSE_TIME(
        '%H:%M',
        TRIM(JSON_VALUE(rehearsal_datetime, '$.endTime'))
    ) AS rehearsal_end_time,

    DATETIME(
        SAFE_CAST(JSON_VALUE(rehearsal_datetime, '$.date') AS DATE),
        SAFE.PARSE_TIME(
            '%H:%M',
            TRIM(JSON_VALUE(rehearsal_datetime, '$.startTime'))
        )
    ) AS rehearsal_start_at,

    DATETIME(
        SAFE_CAST(JSON_VALUE(rehearsal_datetime, '$.date') AS DATE),
        SAFE.PARSE_TIME(
            '%H:%M',
            TRIM(JSON_VALUE(rehearsal_datetime, '$.endTime'))
        )
    ) AS rehearsal_end_at

FROM unnested_rehearsal_datetimes