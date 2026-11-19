SELECT
    member_id,
    'Main' IN UNNEST(svc_teams) AS is_main_team,
    'HeartKidz' IN UNNEST(svc_teams) AS is_heartkidz_team
FROM {{ ref('stg_fs_members_patched') }}