SELECT
    r.roster_id,
    member_id
FROM {{ ref('stg_fs_rosters') }} AS r
CROSS JOIN UNNEST(r.assigned_member_ids) AS member_id