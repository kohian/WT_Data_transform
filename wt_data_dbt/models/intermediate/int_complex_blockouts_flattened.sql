WITH unnested_entries AS (

    SELECT
        b.blockout_id,
        entry_offset,
        entry
    FROM {{ ref('stg_fs_blockouts') }} AS b
    CROSS JOIN UNNEST(b.entries) AS entry
    WITH OFFSET AS entry_offset
    WHERE b.type = 'Complex'

)

SELECT
    blockout_id,
    entry_offset,
    JSON_VALUE(entry, '$.id') AS entry_id,

    DATETIME(
        SAFE_CAST(JSON_VALUE(entry, '$.start') AS DATE),
        SAFE.PARSE_TIME(
            '%H:%M',
            TRIM(JSON_VALUE(entry, '$.startTime'))
        )
    ) AS entry_start_at,

    DATETIME(
        SAFE_CAST(JSON_VALUE(entry, '$.end') AS DATE),
        SAFE.PARSE_TIME(
            '%H:%M',
            TRIM(JSON_VALUE(entry, '$.endTime'))
        )
    ) AS entry_end_at,

    SAFE_CAST(
        JSON_VALUE(entry, '$.isAllDay')
        AS BOOL
    ) AS is_all_day

FROM unnested_entries