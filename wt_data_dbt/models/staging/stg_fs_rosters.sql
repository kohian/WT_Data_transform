WITH source AS (

    SELECT *
    FROM {{ source('wt_bigquery', 'fs_rosters') }}

),

renamed AS (

    SELECT
        document_id AS roster_id,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.title')),
            ''
        ) AS chat_title,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.description')),
            ''
        ) AS description_text,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.notes')),
            ''
        ) AS notes_text,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.status')),
            ''
        ) AS status,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.team')),
            ''
        ) AS svc_team,

        SAFE_CAST(
            JSON_VALUE(data, '$.firstDate')
            AS DATE
        ) AS first_svc_date,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.telegramChatId')),
            ''
        ) AS telegram_chat_id,

        COALESCE(
            JSON_VALUE_ARRAY(data, '$.allAssignedMemberIds'),
            ARRAY<STRING>[]
        ) AS assigned_member_ids,

        COALESCE( --coalesce so that no null just empty asignment
            JSON_QUERY(data, '$.assignments'),
            JSON '{}'
        ) AS assignments,

        JSON_QUERY( --allow null here.. means no notes
            data,
            '$.assignmentNotes'
        ) AS assignment_notes,

        JSON_QUERY( --allow null here.. means no exceptions
            data,
            '$.shiftExclusions'
        ) AS shift_exceptions,

        COALESCE(
            JSON_VALUE_ARRAY(data, '$.chatMembers'),
            ARRAY<STRING>[]
        ) AS chat_member_ids,

        COALESCE(
            JSON_QUERY_ARRAY(data, '$.dates'),
            ARRAY<JSON>[]
        ) AS svc_datetime,

        COALESCE(
            JSON_QUERY_ARRAY(data, '$.rehearsals'),
            ARRAY<JSON>[]
        ) AS rehearsal_datetime,

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

SELECT *
FROM renamed