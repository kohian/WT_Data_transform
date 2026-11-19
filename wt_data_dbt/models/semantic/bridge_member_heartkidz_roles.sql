{{ config(materialized='table') }}

SELECT
    member_id,
    heartkidz_role
FROM {{ ref('int_member_heartkidz_roles') }}
