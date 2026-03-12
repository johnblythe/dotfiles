-- Q57: What happens AFTER a fulfillment exception?
-- Where do requests go when they leave Fulfillment Exception status?
-- This reveals whether exceptions resolve forward (to fulfillment) or backward (to logging)
USE ROLE ENG_PROVIDER;
USE DATABASE HEALTHSOURCE;
USE SCHEMA CONNEX;

WITH exception_exits AS (
    SELECT
        s.EREQUEST_ID,
        s.STATE_TIMESTAMP AS exception_entered,
        rs_curr.STATUS_DESC AS from_status,
        LEAD(rs_next.STATUS_DESC) OVER (
            PARTITION BY s.EREQUEST_ID ORDER BY s.STATE_TIMESTAMP
        ) AS to_status,
        LEAD(s2.STATE_TIMESTAMP) OVER (
            PARTITION BY s.EREQUEST_ID ORDER BY s.STATE_TIMESTAMP
        ) AS exit_time
    FROM erequest_status_dynamic s
    JOIN request_status rs_curr ON s.STATUS_ID = rs_curr.STATUS_ID
    LEFT JOIN erequest_status_dynamic s2
        ON s.EREQUEST_ID = s2.EREQUEST_ID
    LEFT JOIN request_status rs_next ON s2.STATUS_ID = rs_next.STATUS_ID
    WHERE rs_curr.STATUS_DESC = 'Fulfillment Exception'
      AND s.STATE_TIMESTAMP >= DATEADD(day, -90, CURRENT_DATE())
)
SELECT
    to_status AS next_status_after_exception,
    COUNT(*) AS transitions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct,
    ROUND(MEDIAN(DATEDIFF(hour, exception_entered, exit_time)), 1) AS median_time_in_exception_hrs
FROM exception_exits
WHERE to_status IS NOT NULL
  AND to_status <> 'Fulfillment Exception'
GROUP BY to_status
ORDER BY transitions DESC;
