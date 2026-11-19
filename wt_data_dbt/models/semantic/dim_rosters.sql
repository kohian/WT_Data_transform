{{ config(materialized='table') }}

WITH service_summary AS (

    SELECT
        roster_id,
        COUNT(*) AS service_count,
        MIN(service_start_at) AS first_service_start_at,
        MAX(service_end_at) AS last_service_end_at,

        ARRAY_AGG(
            DISTINCT service_date
            ORDER BY service_date
        ) AS service_dates

    FROM {{ ref('int_roster_service_datetimes') }}

    GROUP BY roster_id

),

service_formatted AS (

    SELECT
        roster_id,
        service_count,
        first_service_start_at,
        last_service_end_at,
        service_dates,

        -- CASE
        --     -- At least one Saturday and one Sunday
        --     WHEN EXISTS (
        --         SELECT 1
        --         FROM UNNEST(service_dates) AS service_date
        --         WHERE EXTRACT(DAYOFWEEK FROM service_date) = 7
        --     )
        --     AND EXISTS (
        --         SELECT 1
        --         FROM UNNEST(service_dates) AS service_date
        --         WHERE EXTRACT(DAYOFWEEK FROM service_date) = 1
        --     )
        --         THEN 'Weekend'

        --     -- All service dates are Saturdays
        --     WHEN (
        --         SELECT COUNTIF(
        --             EXTRACT(DAYOFWEEK FROM service_date) != 7
        --         )
        --         FROM UNNEST(service_dates) AS service_date
        --     ) = 0
        --         THEN 'Saturday'

        --     -- All service dates are Sundays
        --     WHEN (
        --         SELECT COUNTIF(
        --             EXTRACT(DAYOFWEEK FROM service_date) != 1
        --         )
        --         FROM UNNEST(service_dates) AS service_date
        --     ) = 0
        --         THEN 'Sunday'

        --     -- Fallback for other weekdays
        --     ELSE FORMAT_DATE(
        --         '%A',
        --         service_dates[SAFE_OFFSET(0)]
        --     )
        -- END AS service_day_label,

        CASE
            -- Exactly one service date: return its weekday name
            WHEN ARRAY_LENGTH(service_dates) = 1
                THEN FORMAT_DATE(
                    '%A',
                    service_dates[SAFE_OFFSET(0)]
                )

            -- Exactly two service dates, one Saturday and one Sunday
            WHEN ARRAY_LENGTH(service_dates) = 2
                AND EXISTS (
                    SELECT 1
                    FROM UNNEST(service_dates) AS service_date
                    WHERE EXTRACT(DAYOFWEEK FROM service_date) = 7
                )
                AND EXISTS (
                    SELECT 1
                    FROM UNNEST(service_dates) AS service_date
                    WHERE EXTRACT(DAYOFWEEK FROM service_date) = 1
                )
                THEN 'Weekend'

            -- Two non-weekend dates, or more than two dates
            ELSE NULL
        END AS service_day_label,        

        CASE
            -- All service dates are within the same month
            WHEN DATE_TRUNC(
                service_dates[SAFE_OFFSET(0)],
                MONTH
            ) = DATE_TRUNC(
                service_dates[
                    SAFE_OFFSET(ARRAY_LENGTH(service_dates) - 1)
                ],
                MONTH
            )
            THEN CONCAT(
                ARRAY_TO_STRING(
                    ARRAY(
                        SELECT CAST(
                            EXTRACT(DAY FROM service_date)
                            AS STRING
                        )
                        FROM UNNEST(service_dates) AS service_date
                        ORDER BY service_date
                    ),
                    ', '
                ),
                ' ',
                FORMAT_DATE(
                    '%B %Y',
                    service_dates[SAFE_OFFSET(0)]
                )
            )

            -- Service dates cross different months
            ELSE ARRAY_TO_STRING(
                ARRAY(
                    SELECT TRIM(
                        FORMAT_DATE('%e %B %Y', service_date)
                    )
                    FROM UNNEST(service_dates) AS service_date
                    ORDER BY service_date
                ),
                ', '
            )
        END AS service_date_label

    FROM service_summary

),

rehearsal_summary AS (

    SELECT
        roster_id,
        COUNT(*) AS rehearsal_count,
        MIN(rehearsal_start_at) AS first_rehearsal_start_at,
        MAX(rehearsal_end_at) AS last_rehearsal_end_at

    FROM {{ ref('int_roster_rehearsal_datetimes') }}

    GROUP BY roster_id

),

assignment_summary AS (

    SELECT
        roster_id,
        COUNT(DISTINCT member_id) AS assigned_member_count,
        COUNT(DISTINCT role) AS assigned_role_count,
        COUNT(*) AS assignment_count

    FROM {{ ref('int_roster_assigned_members_roles') }}

    GROUP BY roster_id

),

rosters_enriched AS (

    SELECT
        r.roster_id,

        /*
        Examples:

        Main WT, Weekend, 18, 19 July 2026
        HeartKidz, Saturday, WT 11 July 2026
        */
        -- CASE
        --     WHEN s.roster_id IS NULL
        --         THEN NULL

        --     WHEN LOWER(TRIM(r.svc_team)) = 'main'
        --         THEN CONCAT(
        --             'Main WT, ',
        --             s.service_day_label,
        --             ', ',
        --             s.service_date_label
        --         )

        --     WHEN LOWER(TRIM(r.svc_team)) IN (
        --         'heartkidz',
        --         'heart kidz',
        --         'hkz'
        --     )
        --         THEN CONCAT(
        --             'HeartKidz WT, ',
        --             s.service_day_label,
        --             ', ',
        --             s.service_date_label
        --         )

        --     ELSE CONCAT(
        --         COALESCE(NULLIF(TRIM(r.svc_team), ''), 'Service'),
        --         ', ',
        --         s.service_day_label,
        --         ', WT ',
        --         s.service_date_label
        --     )
        -- END AS roster_title,

        CASE
            WHEN s.roster_id IS NULL
                THEN NULL

            WHEN LOWER(TRIM(r.svc_team)) = 'main'
                THEN CONCAT(
                    'Main WT',
                    COALESCE(CONCAT(', ', s.service_day_label), ''),
                    COALESCE(CONCAT(', ', s.service_date_label), '')
                )

            WHEN LOWER(TRIM(r.svc_team)) IN (
                'heartkidz',
                'heart kidz',
                'hkz'
            )
                THEN CONCAT(
                    'HeartKidz WT',
                    COALESCE(CONCAT(', ', s.service_day_label), ''),
                    COALESCE(CONCAT(', ', s.service_date_label), '')
                )
            ELSE CONCAT(
                COALESCE(NULLIF(TRIM(r.svc_team), ''), 'Service'),
                COALESCE(CONCAT(', ', s.service_day_label), ''),
                COALESCE(CONCAT(', ', s.service_date_label), '')
            )
        END AS roster_title,


        /*
        Removes dates, numbers, month names, team words,
        weekday words, WT and punctuation from chat_title.

        Also removes HKZ.

        If the cleaned value is null, "Service", or "Svc",
        use a team-specific default service name.
        */
        CASE
            WHEN NULLIF(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                    r.chat_title,
                                    r'(?i)\b(?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec|wt|main|heart\s*kidz|heartkidz|hkz|saturday|sunday|sat|sun|weekend)\b',
                                    ' '
                                ),
                                r'(?i)\d+(?:st|nd|rd|th)?',
                                ' '
                            ),
                            r'[^\p{L}\s]',
                            ' '
                        ),
                        r'\s+',
                        ' '
                    )
                ),
                ''
            ) IS NULL
            OR LOWER(
                NULLIF(
                    TRIM(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                    REGEXP_REPLACE(
                                        r.chat_title,
                                        r'(?i)\b(?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec|wt|main|heart\s*kidz|heartkidz|hkz|saturday|sunday|sat|sun|weekend)\b',
                                        ' '
                                    ),
                                    r'(?i)\d+(?:st|nd|rd|th)?',
                                    ' '
                                ),
                                r'[^\p{L}\s]',
                                ' '
                            ),
                            r'\s+',
                            ' '
                        )
                    ),
                    ''
                )
            ) IN ('service', 'svc')
            THEN CASE
                WHEN LOWER(TRIM(r.svc_team)) IN (
                    'heartkidz',
                    'heart kidz',
                    'hkz'
                )
                    THEN 'HeartKidz Service'
                ELSE 'Main Service'
            END

            ELSE NULLIF(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                    r.chat_title,
                                    r'(?i)\b(?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec|wt|main|heart\s*kidz|heartkidz|hkz|saturday|sunday|sat|sun|weekend)\b',
                                    ' '
                                ),
                                r'(?i)\d+(?:st|nd|rd|th)?',
                                ' '
                            ),
                            r'[^\p{L}\s]',
                            ' '
                        ),
                        r'\s+',
                        ' '
                    )
                ),
                ''
            )
        END AS service_name,

        /*
        Combines description_text and notes_text with a newline.

        Empty or null values are excluded so no unnecessary
        blank line is produced.
        */
        NULLIF(
            ARRAY_TO_STRING(
                ARRAY(
                    SELECT text_value
                    FROM UNNEST([
                        NULLIF(TRIM(r.description_text), ''),
                        NULLIF(TRIM(r.notes_text), '')
                    ]) AS text_value
                    WHERE text_value IS NOT NULL
                ),
                '\n'
            ),
            ''
        ) AS roster_details,

        r.status,
        r.svc_team AS service_team,
        r.first_svc_date AS first_service_date,

        COALESCE(s.service_count, 0) AS service_count,
        s.first_service_start_at,
        s.last_service_end_at,

        COALESCE(reh.rehearsal_count, 0) AS rehearsal_count,
        reh.first_rehearsal_start_at,
        reh.last_rehearsal_end_at,

        COALESCE(a.assigned_member_count, 0)
            AS assigned_member_count,

        COALESCE(a.assigned_role_count, 0)
            AS assigned_role_count,

        COALESCE(a.assignment_count, 0)
            AS assignment_count,

        r.source_created_at,
        r.source_updated_at,
        r.ingested_at,
        r.batch_id

    FROM {{ ref('stg_fs_rosters') }} AS r

    LEFT JOIN service_formatted AS s
        ON r.roster_id = s.roster_id

    LEFT JOIN rehearsal_summary AS reh
        ON r.roster_id = reh.roster_id

    LEFT JOIN assignment_summary AS a
        ON r.roster_id = a.roster_id

)

SELECT *
FROM rosters_enriched