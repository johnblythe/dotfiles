-- Q41: Sample unclassified "Other" resubmission comments
-- These don't match the categories we built in the earlier analysis
with resubmissions as (
    select
        a.erequest_id,
        a.audit_message,
        a.event_comments,
        e.source_type,
        e.major_class
    from connex.erequest_audit_trail_dynamic a
    join connex.erequest_dynamic e on a.erequest_id = e.erequest_id
    where a.audit_type = 'RequestResubmittedToLogging'
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and a.event_dt >= dateadd('day', -90, current_date())
      and a.event_comments is not null
      and trim(a.event_comments) not in ('')
      -- Exclude already-categorized patterns
      and lower(a.event_comments) not like '%mrn%'
      and lower(a.event_comments) not like '%site%'
      and lower(a.event_comments) not like '%dar%'
      and lower(a.event_comments) not like '%split%'
      and lower(a.event_comments) not like '%redo%'
      and lower(a.event_comments) not like '%second review%'
      and lower(a.event_comments) not like '%coc%'
      and lower(a.event_comments) not like '%date%'
      and lower(a.event_comments) not like '%dob%'
      and lower(a.event_comments) not like '%patient%'
      and lower(a.event_comments) not like '%auth%'
      and lower(a.event_comments) not like '%requester%'
      and lower(a.event_comments) not like '%duplicate%'
      and lower(a.event_comments) not like '%address%'
)
select event_comments, count(*) as freq
from resubmissions
group by event_comments
order by freq desc
limit 100;
