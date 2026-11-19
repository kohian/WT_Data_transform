{{ config(materialized='table') }}

SELECT
    member_id,
    main_role
FROM {{ ref('int_member_main_roles') }}
