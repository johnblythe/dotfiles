-- Q27: Chart image rejection deep dive
-- What happens around RequestRejectedInCf events? What context exists?
-- Check audit_message, event_comments, and surrounding events
with rejections as (
    select
        erequest_id,
        event_dt as reject_time,
        audit_message,
        event_comments,
        user_id,
        created_by
    from connex.erequest_audit_trail_dynamic
    where audit_type = 'RequestRejectedInCf'
      and event_dt >= dateadd('day', -30, current_date())
),
rejection_context as (
    select
        r.erequest_id,
        e.source_type,
        e.major_class,
        e.dds_site_id,
        r.reject_time
    from rejections r
    join connex.erequest_dynamic e on r.erequest_id = e.erequest_id
)
select
    source_type,
    major_class,
    count(*) as rejections,
    count(distinct erequest_id) as unique_requests
from rejection_context
group by source_type, major_class
order by rejections desc
limit 20;
