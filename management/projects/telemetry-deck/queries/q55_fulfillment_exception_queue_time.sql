-- Q55: Fulfillment exception queue time BY REASON
-- Simpler approach: use erequest_exception created vs removed timing
-- plus status transition for actual Fulfillment Exception duration
USE ROLE ENG_PROVIDER;
USE DATABASE HEALTHSOURCE;
USE SCHEMA CONNEX;

WITH fulfill_exc AS (
    SELECT
        e.EREQUEST_ID,
        r.EXCEPTION_REASON_DESC,
        e.CREATED_DT AS exc_created,
        -- Find the next status transition after this exception was created
        (SELECT MIN(s.STATE_TIMESTAMP)
         FROM erequest_status_dynamic s
         JOIN request_status rs ON s.STATUS_ID = rs.STATUS_ID
         WHERE s.EREQUEST_ID = e.EREQUEST_ID
           AND s.STATE_TIMESTAMP > e.CREATED_DT
           AND rs.STATUS_DESC <> 'Fulfillment Exception'
        ) AS exc_resolved
    FROM erequest_exception e
    JOIN erequest_exception_reason r
        ON e.EXCEPTION_REASON_ID = r.EREQUEST_EXCEPTION_REASON_ID
    WHERE r.EXCEPTION_REASON_CODE LIKE 'FFEC001_%'
      AND e.CREATED_DT >= DATEADD(day, -90, CURRENT_DATE())
)
SELECT
    EXCEPTION_REASON_DESC,
    COUNT(*) AS exceptions,
    ROUND(MEDIAN(DATEDIFF(hour, exc_created, exc_resolved)), 1) AS median_hrs,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY DATEDIFF(hour, exc_created, exc_resolved)), 1) AS p25_hrs,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY DATEDIFF(hour, exc_created, exc_resolved)), 1) AS p75_hrs,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY DATEDIFF(hour, exc_created, exc_resolved)), 1) AS p95_hrs
FROM fulfill_exc
WHERE exc_resolved IS NOT NULL
GROUP BY EXCEPTION_REASON_DESC
HAVING COUNT(*) >= 50
ORDER BY median_hrs DESC;
