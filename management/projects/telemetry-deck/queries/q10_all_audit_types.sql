-- Q10: Full inventory of audit_type values and their frequency
-- To understand the complete landscape of what's already tracked
select
    audit_type,
    count(*) as event_count,
    count(distinct erequest_id) as unique_requests,
    min(event_dt) as earliest,
    max(event_dt) as latest
from connex.erequest_audit_trail_dynamic
where event_dt >= dateadd('day', -90, current_date())
group by audit_type
order by event_count desc;
