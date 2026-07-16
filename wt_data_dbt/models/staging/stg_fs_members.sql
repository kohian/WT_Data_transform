WITH source AS (

    SELECT *
    FROM {{ source('wt_bigquery', 'fs_members') }}

),

renamed AS (

    SELECT
        document_id AS member_id,

        NULLIF(TRIM(JSON_VALUE(data, '$.name')), '') AS full_name,
        SAFE_CAST(JSON_VALUE(data, '$.birthday') AS DATE) AS birthday,
        SAFE_CAST(JSON_VALUE(data, '$.isActive') AS BOOL) AS is_active,

        NULLIF(TRIM(JSON_VALUE(data, '$.lifeStage')), '') AS life_stage,
        NULLIF(TRIM(JSON_VALUE(data, '$.notes')), '') AS remarks,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.blockoutAdmin')),
            ''
        ) AS blockout_admin_email,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.hkzOnboarding')),
            ''
        ) AS hkz_onboarding_status,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.uwSession')),
            ''
        ) AS uw_session_status,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.photoUrl')),
            ''
        ) AS photo_url,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.contactInfo.email')),
            ''
        ) AS email,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.contactInfo.mobile')),
            ''
        ) AS mobile,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.contactInfo.telegram')),
            ''
        ) AS telegram_handle,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.telegramData.id')),
            ''
        ) AS telegram_id,

        NULLIF(
            TRIM(JSON_VALUE(data, '$.telegramData.hash')),
            ''
        ) AS telegram_hash,

        COALESCE(
            JSON_VALUE_ARRAY(data, '$.teams'),
            ARRAY<STRING>[]
        ) AS teams,

        COALESCE(
            JSON_VALUE_ARRAY(data, '$.roles'),
            ARRAY<STRING>[]
        ) AS main_roles,

        COALESCE(
            JSON_VALUE_ARRAY(data, '$.heartKidzRoles'),
            ARRAY<STRING>[]
        ) AS heart_kidz_roles,

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