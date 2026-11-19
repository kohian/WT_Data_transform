WITH unnested_service_datetimes AS (

    SELECT
        r.roster_id,
        service_offset,
        service_datetime
    FROM {{ ref('stg_fs_rosters') }} AS r
    CROSS JOIN UNNEST(r.svc_datetime) AS service_datetime
    WITH OFFSET AS service_offset

)

SELECT
    roster_id,
    service_offset,

    SAFE_CAST(
        JSON_VALUE(service_datetime, '$.date')
        AS DATE
    ) AS service_date,

    SAFE.PARSE_TIME(
        '%H:%M',
        TRIM(JSON_VALUE(service_datetime, '$.startTime'))
    ) AS service_start_time,

    SAFE.PARSE_TIME(
        '%H:%M',
        TRIM(JSON_VALUE(service_datetime, '$.endTime'))
    ) AS service_end_time,

    DATETIME(
        SAFE_CAST(JSON_VALUE(service_datetime, '$.date') AS DATE),
        SAFE.PARSE_TIME(
            '%H:%M',
            TRIM(JSON_VALUE(service_datetime, '$.startTime'))
        )
    ) AS service_start_at,

    DATETIME(
        SAFE_CAST(JSON_VALUE(service_datetime, '$.date') AS DATE),
        SAFE.PARSE_TIME(
            '%H:%M',
            TRIM(JSON_VALUE(service_datetime, '$.endTime'))
        )
    ) AS service_end_at

FROM unnested_service_datetimes