WITH simple_blockouts AS (

    SELECT
        blockout_id,
        CAST(NULL AS STRING) AS entry_id,
        CAST(NULL AS INT64) AS entry_offset,
        member_id,
        range_start_at,
        range_end_at,
        range_start_at AS period_start_at,
        range_end_at AS period_end_at,
        reason,
        type AS blockout_type,
        CAST(NULL AS BOOL) AS is_all_day

    FROM {{ ref('stg_fs_blockouts') }}
    WHERE type = 'Simple'

),

complex_blockouts AS (

    SELECT
        stg_b.blockout_id,
        cbf.entry_id,
        cbf.entry_offset,
        stg_b.member_id,
        stg_b.range_start_at,
        stg_b.range_end_at,
        cbf.entry_start_at AS period_start_at,
        cbf.entry_end_at AS period_end_at,
        stg_b.reason,
        stg_b.type AS blockout_type,
        cbf.is_all_day
    FROM {{ ref('int_complex_blockouts_flattened') }} AS cbf
    LEFT JOIN {{ ref('stg_fs_blockouts') }} AS stg_b
        ON cbf.blockout_id = stg_b.blockout_id

)

SELECT *
FROM simple_blockouts

UNION ALL

SELECT *
FROM complex_blockouts