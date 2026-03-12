-- Q22: What audit events are specific to QC process?
-- Find all QC-related events to understand the QC feedback mechanism
select
    audit_type,
    count(*) as cnt,
    count(distinct erequest_id) as unique_requests,
    max(audit_description) as sample_desc
from connex.erequest_audit_trail_dynamic
where audit_timestamp >= dateadd('day', -90, current_date())
  and (
    audit_type ilike '%QC%'
    or audit_type ilike '%quality%'
    or audit_type ilike '%review%'
    or audit_type ilike '%reject%'
    or audit_type ilike '%redo%'
    or audit_type ilike '%correction%'
    or audit_type ilike '%validation%'
  )
group by audit_type
order by cnt desc
limit 30;
