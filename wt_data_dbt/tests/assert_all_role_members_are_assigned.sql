{{ config(severity='warn') }}

SELECT
    amr.roster_id,
    amr.member_id,
    am.member_id,
    amr.role
FROM {{ ref('int_roster_assigned_members_roles') }} AS amr
LEFT JOIN {{ ref('int_roster_assigned_members') }} AS am
    ON amr.roster_id = am.roster_id
   AND amr.member_id = am.member_id
WHERE am.member_id IS NULL