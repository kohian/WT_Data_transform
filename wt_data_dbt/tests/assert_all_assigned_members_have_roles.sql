{{ config(severity='warn') }}

SELECT
    am.roster_id,
    am.member_id,
    amr.member_id
FROM {{ ref('int_roster_assigned_members') }} AS am
LEFT JOIN {{ ref('int_roster_assigned_members_roles') }} AS amr
    ON am.roster_id = amr.roster_id
   AND am.member_id = amr.member_id
WHERE amr.member_id IS NULL