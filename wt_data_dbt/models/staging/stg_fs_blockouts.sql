WITH source AS (

    SELECT
        *
    FROM {{ source('wt_bigquery', 'fs_blockouts') }}

),

renamed AS (

    SELECT
        document_id AS blockout_id,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.memberId')),
            ''
        ) AS member_id,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.memberName')),
            ''
        ) AS member_name,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.reason')),
            ''
        ) AS reason,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.type')),
            ''
        ) AS type,

        SAFE_CAST(
            JSON_VALUE(data, '$.rangeStart')
            AS DATETIME
        ) AS range_start_at,

        SAFE_CAST(
            JSON_VALUE(data, '$.rangeEnd')
            AS DATETIME
        ) AS range_end_at,

        JSON_QUERY_ARRAY(
            data,
            '$.entries'
        ) AS entries,

        source_system,
        source_application,
        source_project,
        source_database,
        source_collection,
        source_created_at,
        source_updated_at,
        ingested_at,
        batch_id

    FROM source

)

SELECT
    *
FROM renamed