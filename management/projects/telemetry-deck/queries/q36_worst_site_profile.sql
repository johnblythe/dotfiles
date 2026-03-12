-- Q36: Worst sites full profile — mix, EMR, source type, exception reasons
-- Compare worst 5 sites vs population average
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
    select dds_site_id
    from site_stats
    order by (rework_cnt + exception_cnt) * 1.0 / total_requests desc
    limit 5
)
-- Profile: major_class mix
select
    case when w.dds_site_id is not null then e.dds_site_id else 'POPULATION' end as site_group,
    e.major_class,
    count(*) as cnt,
    round(count(*) * 100.0 / sum(count(*)) over (partition by case when w.dds_site_id is not null then e.dds_site_id else 'POPULATION' end), 1) as pct
from connex.erequest_dynamic e
left join worst_sites w on e.dds_site_id = w.dds_site_id
where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
  and e.created_dt >= dateadd('day', -90, current_date())
  and (w.dds_site_id is not null or e.dds_site_id is not null)
group by 1, 2
order by 1, cnt desc;
