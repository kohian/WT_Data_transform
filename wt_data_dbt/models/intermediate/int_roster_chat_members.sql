SELECT
    r.roster_id,
    chat_member_id
FROM {{ ref('stg_fs_rosters') }} AS r
CROSS JOIN UNNEST(r.chat_member_ids) AS chat_member_id