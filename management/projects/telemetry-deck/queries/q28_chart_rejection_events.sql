-- Q28: What audit events happen around chart rejections?
-- For rejected requests, what events occur in the 5 min before rejection?
with sample_rejections as (
    select erequest_id, event_dt as reject_time
    from connex.erequest_audit_trail_dynamic
    where audit_type = 'RequestRejectedInCf'
      and event_dt >= dateadd('day', -7, current_date())
    limit 50000
),
surrounding as (
    select
        at.erequest_id,
        at.audit_type,
        at.audit_message,
        at.event_dt,
        sr.reject_time,
        datediff('second', at.event_dt, sr.reject_time) as sec_before_reject
    from connex.erequest_audit_trail_dynamic at
    join sample_rejections sr on at.erequest_id = sr.erequest_id
    where at.event_dt between dateadd('minute', -5, sr.reject_time) and dateadd('minute', 5, sr.reject_time)
      and at.audit_type != 'RequestRejectedInCf'
)
select
    audit_type,
    count(*) as occurrences,
    count(distinct erequest_id) as unique_requests,
    round(median(abs(sec_before_reject)), 0) as median_sec_offset,
    max(left(audit_message, 120)) as sample_msg
from surrounding
group by audit_type
order by occurrences desc
limit 25;
