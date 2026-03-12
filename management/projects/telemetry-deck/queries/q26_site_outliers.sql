-- Q26: Site-level outlier analysis
-- Which sites have the highest/lowest rework rates and TAT?
with site_metrics as (
    select
        e.site_id,
        count(distinct e.erequest_id) as total_requests,
        count(distinct case when es_redo.erequest_id is not null then e.erequest_id end) as redo_requests,
        count(distinct case when ex.erequest_id is not null then e.erequest_id end) as exception_requests
    from connex.erequest_dynamic e
    left join (
        select distinct es.erequest_id
        from connex.erequest_status_dynamic es
        join connex.request_status rs on es.status_id = rs.status_id
        where rs.status_desc = 'Redo Logging'
          and es.state_timestamp >= dateadd('day', -90, current_date())
    ) es_redo on e.erequest_id = es_redo.erequest_id
    left join (
        select distinct erequest_id
        from connex.erequest_exception
        where created_dt >= dateadd('day', -90, current_date())
    ) ex on e.erequest_id = ex.erequest_id
    where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and e.created_dt >= dateadd('day', -90, current_date())
    group by e.site_id
    having total_requests >= 100
),
site_tat as (
    select
        e.site_id,
        median(datediff('second', es1.state_timestamp, es2.state_timestamp) / 3600.0) as median_logging_hrs
    from connex.erequest_dynamic e
    join connex.erequest_status_dynamic es1 on e.erequest_id = es1.erequest_id
    join connex.request_status rs1 on es1.status_id = rs1.status_id
    join connex.erequest_status_dynamic es2 on e.erequest_id = es2.erequest_id
    join connex.request_status rs2 on es2.status_id = rs2.status_id
    where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and rs1.status_desc = 'Logging'
      and rs2.status_desc in ('Fulfillment', 'QC In Progress', 'Digital Auth Review')
      and es2.state_timestamp > es1.state_timestamp
      and es1.state_timestamp >= dateadd('day', -90, current_date())
      and datediff('second', es1.state_timestamp, es2.state_timestamp) between 60 and 604800
    group by e.site_id
)
select
    sm.site_id,
    sm.total_requests,
    sm.redo_requests,
    round(sm.redo_requests * 100.0 / sm.total_requests, 1) as redo_pct,
    sm.exception_requests,
    round(sm.exception_requests * 100.0 / sm.total_requests, 1) as exception_pct,
    round(st.median_logging_hrs, 2) as median_logging_hrs
from site_metrics sm
left join site_tat st on sm.site_id = st.site_id
order by total_requests desc
limit 50;
