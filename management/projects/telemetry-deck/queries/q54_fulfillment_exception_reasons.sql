-- Q54: Fulfillment-only exception breakdown by reason
-- Category is encoded in reason_code prefix: FFEC001_FFER* = fulfillment
USE ROLE ENG_PROVIDER;
USE DATABASE HEALTHSOURCE;
USE SCHEMA CONNEX;

SELECT
    r.EXCEPTION_REASON_DESC,
    r.EXCEPTION_REASON_CODE,
    COUNT(*) AS exception_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct,
    COUNT(DISTINCT e.EREQUEST_ID) AS unique_requests,
    SUM(CASE WHEN e.IS_REMOVED = 1 THEN 1 ELSE 0 END) AS resolved_count,
    ROUND(SUM(CASE WHEN e.IS_REMOVED = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 1) AS resolved_pct
FROM erequest_exception e
JOIN erequest_exception_reason r
    ON e.EXCEPTION_REASON_ID = r.EREQUEST_EXCEPTION_REASON_ID
WHERE r.EXCEPTION_REASON_CODE LIKE 'FFEC001_%'
  AND e.CREATED_DT >= DATEADD(day, -90, CURRENT_DATE())
GROUP BY r.EXCEPTION_REASON_DESC, r.EXCEPTION_REASON_CODE
ORDER BY exception_count DESC;
