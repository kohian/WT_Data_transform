SELECT
    m.member_id,
    main_role
FROM {{ ref('stg_fs_members_patched') }} AS m
CROSS JOIN UNNEST(m.main_roles) AS main_role