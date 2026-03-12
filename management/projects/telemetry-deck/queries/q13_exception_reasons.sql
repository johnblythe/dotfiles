-- Q13: Exception reason breakdown for human-worked requests
-- Top exception categories and reasons with volume + TAT impact
with exception_events as (
    select
        ex.erequest_id,
        ex.exception_reason,
        ex.created_date as exception_date,
        e.source_type,
        e.major_class
    from connex.erequest_exception ex
    join connex.erequest_dynamic e on ex.erequest_id = e.erequest_id
    where ex.created_date >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
)
select
    exception_reason,
    count(*) as occurrences,
    count(distinct erequest_id) as unique_requests,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct_of_total,
    count(case when source_type = 'UPLOAD' then 1 end) as upload_cnt,
    count(case when source_type = 'CENTRAL INTAKE' then 1 end) as central_cnt,
    count(case when major_class = 'CLIN' then 1 end) as clin_cnt,
    count(case when major_class = 'ATTY' then 1 end) as atty_cnt,
    count(case when major_class = 'PAT' then 1 end) as pat_cnt,
    count(case when major_class = 'INS' then 1 end) as ins_cnt,
    count(case when major_class = 'GOV' then 1 end) as gov_cnt
from exception_events
group by exception_reason
order by occurrences desc
limit 25;
