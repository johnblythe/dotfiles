-- Q19: What audit events happen immediately before a Redo Logging transition?
-- This tells us what QC does right before sending a request back.
with redo_transitions as (
    select
        es.erequest_id,
        es.state_timestamp as redo_time
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc = 'Redo Logging'
      and es.state_timestamp >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
),
-- Get audit events in the 30 min window before each redo transition
pre_redo_events as (
    select
        at.erequest_id,
        at.audit_type,
        at.event_dt,
        at.audit_message,
        rt.redo_time,
        datediff('second', at.event_dt, rt.redo_time) as sec_before_redo
    from connex.erequest_audit_trail_dynamic at
    join redo_transitions rt on at.erequest_id = rt.erequest_id
    where at.event_dt between dateadd('minute', -30, rt.redo_time) and rt.redo_time
)
select
    audit_type,
    count(*) as occurrences,
    count(distinct erequest_id) as unique_requests,
    round(median(sec_before_redo), 0) as median_sec_before,
    max(audit_message) as sample_message
from pre_redo_events
group by audit_type
order by occurrences desc
limit 30;
