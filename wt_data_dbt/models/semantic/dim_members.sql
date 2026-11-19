{{ config(materialized='table') }}

WITH members AS (

    SELECT *
    FROM {{ ref('stg_fs_members_patched') }}

)

SELECT
    m.member_id,
    m.full_name,
    m.birthday,
    m.is_active,
    m.life_stage,
    m.remarks,
    m.blockout_admin_email,
    -- admin.member_id AS blockout_admin_member_id,
    -- admin.full_name AS blockout_admin_full_name,
    m.hkz_onboarding_status,
    m.uw_session_status,
    m.photo_url,
    m.email,
    m.mobile,
    m.telegram_handle,
    m.telegram_id,
    m.svc_teams AS service_teams,
    m.main_roles,
    m.heartkidz_roles,
    COALESCE(f.is_main_team, FALSE) AS is_main_team,
    COALESCE(f.is_heartkidz_team, FALSE) AS is_heartkidz_team,
    m.source_created_at,
    m.source_updated_at,
    m.ingested_at,
    m.batch_id
FROM members AS m
LEFT JOIN {{ ref('int_member_svc_team_flags') }} AS f
    ON m.member_id = f.member_id
-- LEFT JOIN members AS admin
--     ON LOWER(TRIM(m.blockout_admin_email)) = LOWER(TRIM(admin.email))
