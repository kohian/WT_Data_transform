SELECT
    m.member_id,
    heartkidz_role
FROM {{ ref('stg_fs_members_patched') }} AS m
CROSS JOIN UNNEST(m.heartkidz_roles) AS heartkidz_role