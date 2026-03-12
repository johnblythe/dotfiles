-- Q38: Worst sites — exception reason distribution vs population
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
    select dds_site_id from site_stats
    order by (rework_cnt + exception_cnt) * 1.0 / total_requests desc
    limit 5
),
-- Exception reasons for worst sites
site_exceptions as (
    select
        'WORST_5' as cohort,
        er.exception_reason_desc,
        count(*) as cnt
    from connex.erequest_exception ex
    join connex.erequest_exception_reason er on ex.exception_reason_id = er.erequest_exception_reason_id
    join connex.erequest_dynamic e on ex.erequest_id = e.erequest_id
    where e.dds_site_id in (select dds_site_id from worst_sites)
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and ex.created_dt >= dateadd('day', -90, current_date())
    group by er.exception_reason_desc
),
-- Exception reasons for population
pop_exceptions as (
    select
        'POPULATION' as cohort,
        er.exception_reason_desc,
        count(*) as cnt
    from connex.erequest_exception ex
    join connex.erequest_exception_reason er on ex.exception_reason_id = er.erequest_exception_reason_id
    join connex.erequest_dynamic e on ex.erequest_id = e.erequest_id
    where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and ex.created_dt >= dateadd('day', -90, current_date())
    group by er.exception_reason_desc
)
select cohort, exception_reason_desc, cnt,
    round(cnt * 100.0 / sum(cnt) over (partition by cohort), 1) as pct
from (select * from site_exceptions union all select * from pop_exceptions)
order by cohort, cnt desc;
