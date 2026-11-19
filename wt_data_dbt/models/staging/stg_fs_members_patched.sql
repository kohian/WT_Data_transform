WITH real_members AS (

    SELECT
        member_id,
        full_name,
        birthday,
        is_active,
        life_stage,
        remarks,
        blockout_admin_email,
        hkz_onboarding_status,
        uw_session_status,
        photo_url,
        email,
        mobile,
        telegram_handle,
        telegram_id,
        telegram_hash,
        svc_teams,
        main_roles,
        heartkidz_roles,
        source_system,
        source_application,
        source_project,
        source_database,
        source_collection,
        source_created_at,
        source_updated_at,
        ingested_at,
        batch_id
    FROM {{ ref('stg_fs_members') }}

),

placeholder_members AS (

    SELECT
        CAST(member_id AS STRING) AS member_id,

        CAST(full_name AS STRING) AS full_name,

        SAFE_CAST(
            NULLIF(TRIM(CAST(birthday AS STRING)), '')
            AS DATE
        ) AS birthday,

        SAFE_CAST(is_active AS BOOL) AS is_active,

        NULLIF(TRIM(CAST(life_stage AS STRING)), '')
            AS life_stage,

        NULLIF(TRIM(CAST(remarks AS STRING)), '')
            AS remarks,

        NULLIF(TRIM(CAST(blockout_admin_email AS STRING)), '')
            AS blockout_admin_email,

        NULLIF(TRIM(CAST(hkz_onboarding_status AS STRING)), '')
            AS hkz_onboarding_status,

        NULLIF(TRIM(CAST(uw_session_status AS STRING)), '')
            AS uw_session_status,

        NULLIF(TRIM(CAST(photo_url AS STRING)), '')
            AS photo_url,

        NULLIF(TRIM(CAST(email AS STRING)), '')
            AS email,

        NULLIF(TRIM(CAST(mobile AS STRING)), '')
            AS mobile,

        NULLIF(TRIM(CAST(telegram_handle AS STRING)), '')
            AS telegram_handle,

        NULLIF(TRIM(CAST(telegram_id AS STRING)), '')
            AS telegram_id,

        NULLIF(TRIM(CAST(telegram_hash AS STRING)), '')
            AS telegram_hash,

        COALESCE(
            JSON_VALUE_ARRAY(
                SAFE.PARSE_JSON(CAST(svc_teams AS STRING))
            ),
            CAST([] AS ARRAY<STRING>)
        ) AS svc_teams,

        COALESCE(
            JSON_VALUE_ARRAY(
                SAFE.PARSE_JSON(CAST(main_roles AS STRING))
            ),
            CAST([] AS ARRAY<STRING>)
        ) AS main_roles,

        COALESCE(
            JSON_VALUE_ARRAY(
                SAFE.PARSE_JSON(CAST(heartkidz_roles AS STRING))
            ),
            CAST([] AS ARRAY<STRING>)
        ) AS heartkidz_roles,

        CAST(source_system AS STRING)
            AS source_system,

        NULLIF(TRIM(CAST(source_application AS STRING)), '')
            AS source_application,

        NULLIF(TRIM(CAST(source_project AS STRING)), '')
            AS source_project,

        NULLIF(TRIM(CAST(source_database AS STRING)), '')
            AS source_database,

        CAST(source_collection AS STRING)
            AS source_collection,

        SAFE_CAST(
            NULLIF(TRIM(CAST(source_created_at AS STRING)), '')
            AS TIMESTAMP
        ) AS source_created_at,

        SAFE_CAST(
            NULLIF(TRIM(CAST(source_updated_at AS STRING)), '')
            AS TIMESTAMP
        ) AS source_updated_at,

        SAFE_CAST(ingested_at AS TIMESTAMP)
            AS ingested_at,

        CAST(batch_id AS STRING)
            AS batch_id

    FROM {{ ref('deleted_member_patch') }}

),

deduplicated_placeholders AS (

    SELECT p.*
    FROM placeholder_members AS p
    WHERE NOT EXISTS (
        SELECT 1
        FROM real_members AS r
        WHERE r.member_id = p.member_id
    )

)

SELECT *
FROM real_members

UNION ALL

SELECT *
FROM deduplicated_placeholders