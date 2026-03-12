-- Q31: Best performing sites (lowest issue rates)
with site_stats as (
    select
        e.dds_site_id,
        count(distinct e.erequest_id) as total_requests,
        count(distinct case when rs.status_desc = 'Redo Logging' then es.erequest_id end) as redo_cnt,
        count(distinct case when rs.status_desc = 'Logging Exception' then es.erequest_id end) as exception_cnt
    from connex.erequest_dynamic e
    join connex.erequest_status_dynamic es on e.erequest_id = es.erequest_id
    join connex.request_status rs on es.status_id = rs.status_id
    where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and e.created_dt >= dateadd('day', -90, current_date())
      and es.state_timestamp >= dateadd('day', -90, current_date())
    group by e.dds_site_id
    having total_requests >= 500
)
select
    dds_site_id,
    total_requests,
    redo_cnt,
    round(redo_cnt * 100.0 / total_requests, 1) as redo_pct,
    exception_cnt,
    round(exception_cnt * 100.0 / total_requests, 1) as exception_pct,
    round((redo_cnt + exception_cnt) * 100.0 / total_requests, 1) as combined_issue_pct
from site_stats
order by combined_issue_pct asc
limit 15;
