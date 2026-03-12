-- Q21: What audit events happen DURING redo logging?
-- After a request enters Redo Logging, what does the processor actually change?
-- This reveals what fields/actions are being corrected.
with redo_windows as (
    select
        es.erequest_id,
        es.state_timestamp as redo_start,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as redo_end
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc = 'Redo Logging'
      and es.state_timestamp >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
),
redo_actions as (
    select
        at.erequest_id,
        at.audit_type,
        at.audit_description,
        at.audit_timestamp
    from connex.erequest_audit_trail_dynamic at
    join redo_windows rw on at.erequest_id = rw.erequest_id
    where at.audit_timestamp between rw.redo_start and coalesce(rw.redo_end, dateadd('day', 7, rw.redo_start))
      and at.audit_timestamp >= dateadd('day', -90, current_date())
)
select
    audit_type,
    count(*) as occurrences,
    count(distinct erequest_id) as unique_requests,
    max(audit_description) as sample_desc_1,
    min(audit_description) as sample_desc_2
from redo_actions
group by audit_type
order by occurrences desc
limit 30;
