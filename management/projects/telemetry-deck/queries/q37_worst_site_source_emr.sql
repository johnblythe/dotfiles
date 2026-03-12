-- Q37: Worst sites — source type and EMR breakdown vs population
with site_stats as (
    select
        e.dds_site_id,
        count(distinct e.erequest_id) as total_requests,
        count(distinct case when rs.status_desc in ('Redo Logging','Back To Logging','Back To Fulfillment') then es.erequest_id end) as rework_cnt,
        count(distinct case when rs.status_desc like '%Exception%' then es.erequest_id end) as exception_cnt
    from connex.erequest_dynamic e
    join connex.erequest_status_dynamic es on e.erequest_id = es.erequest_id
    join connex.request_status rs on es.status_id = rs.status_id
    where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and e.created_dt >= dateadd('day', -90, current_date())
      and es.state_timestamp >= dateadd('day', -90, current_date())
    group by e.dds_site_id
    having total_requests >= 500
),
worst_sites as (
    select dds_site_id, total_requests, rework_cnt, exception_cnt,
        round((rework_cnt + exception_cnt) * 100.0 / total_requests, 1) as issue_pct
    from site_stats
    order by issue_pct desc
    limit 5
)
select
    w.dds_site_id,
    w.total_requests,
    w.issue_pct,
    e.source_type,
    e.is_emr,
    count(*) as cnt,
    round(count(*) * 100.0 / w.total_requests, 1) as pct_of_site
from connex.erequest_dynamic e
join worst_sites w on e.dds_site_id = w.dds_site_id
where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
  and e.created_dt >= dateadd('day', -90, current_date())
group by 1, 2, 3, 4, 5
order by w.issue_pct desc, cnt desc;
