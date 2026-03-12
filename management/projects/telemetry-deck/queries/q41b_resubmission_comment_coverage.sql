-- Q41b: How much of resubmission comments does our categorization cover?
with resub as (
    select
        a.event_comments,
        case
            when a.event_comments is null or trim(a.event_comments) = '' then 'NO_COMMENT'
            when lower(a.event_comments) like '%mrn%' then 'MRN_CORRECTION'
            when lower(a.event_comments) like '%site%' then 'SITE_CHANGE'
            when lower(a.event_comments) like '%dar%' then 'DAR_UPDATE'
            when lower(a.event_comments) like '%split%' then 'SPLIT'
            when lower(a.event_comments) like '%redo%' then 'REDO'
            when lower(a.event_comments) like '%second review%' then 'SECOND_REVIEW'
            when lower(a.event_comments) like '%coc%' then 'COC'
            when lower(a.event_comments) like '%date%' or lower(a.event_comments) like '%dob%' then 'DATE_CORRECTION'
            when lower(a.event_comments) like '%patient%' then 'PATIENT_INFO'
            when lower(a.event_comments) like '%auth%' then 'AUTH'
            when lower(a.event_comments) like '%requester%' then 'REQUESTER_INFO'
            when lower(a.event_comments) like '%duplicate%' then 'DUPLICATE'
            when lower(a.event_comments) like '%address%' then 'ADDRESS'
            else 'UNCATEGORIZED'
        end as category
    from connex.erequest_audit_trail_dynamic a
    join connex.erequest_dynamic e on a.erequest_id = e.erequest_id
    where a.audit_type = 'RequestResubmittedToLogging'
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and a.event_dt >= dateadd('day', -90, current_date())
)
select category, count(*) as cnt,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from resub
group by category
order by cnt desc;
