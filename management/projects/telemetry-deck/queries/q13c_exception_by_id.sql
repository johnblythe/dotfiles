-- Q13c: Exception breakdown by reason_id with volume + channel split
-- If no lookup table, we'll just use IDs and figure out names later
with exception_events as (
    select
        ex.erequest_id,
        ex.exception_reason_id,
        ex.exception_comment,
        ex.created_dt as exception_date,
        ex.is_removed,
        e.source_type,
        e.major_class
    from connex.erequest_exception ex
    join connex.erequest_dynamic e on ex.erequest_id = e.erequest_id
    where ex.created_dt >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
)
select
    exception_reason_id,
    count(*) as occurrences,
    count(distinct erequest_id) as unique_requests,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct_of_total,
    count(case when is_removed = 1 then 1 end) as resolved_cnt,
    count(case when source_type = 'UPLOAD' then 1 end) as upload_cnt,
    count(case when source_type = 'CENTRAL INTAKE' then 1 end) as central_cnt,
    count(case when major_class = 'CLIN' then 1 end) as clin_cnt,
    count(case when major_class = 'ATTY' then 1 end) as atty_cnt,
    count(case when major_class = 'PAT' then 1 end) as pat_cnt,
    count(case when major_class = 'INS' then 1 end) as ins_cnt,
    count(case when major_class = 'GOV' then 1 end) as gov_cnt,
    -- sample some comments to understand the reason
    max(exception_comment) as sample_comment
from exception_events
group by exception_reason_id
order by occurrences desc
limit 25;
