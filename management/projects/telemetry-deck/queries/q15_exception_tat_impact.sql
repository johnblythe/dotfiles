-- Q15: Exception TAT impact - how long do exception requests take vs clean?
-- Join exceptions to logging time to quantify the cost
with logging_times as (
    select
        es.erequest_id,
        rs.status_desc,
        es.state_timestamp,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_state_timestamp
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    where rs.status_desc in ('Logging', 'Logging Exception')
      and es.state_timestamp >= dateadd('day', -90, current_date())
),
request_totals as (
    select
        erequest_id,
        count(case when status_desc = 'Logging Exception' then 1 end) as exception_visits,
        sum(case when next_state_timestamp is not null
            then datediff('second', state_timestamp, next_state_timestamp) else 0 end) as total_logging_sec
    from logging_times
    group by erequest_id
)
select
    case when rt.exception_visits > 0 then 'Had exception' else 'No exception' end as exception_flag,
    ex.exception_reason,
    count(*) as cnt,
    round(median(rt.total_logging_sec), 1) as median_total_sec,
    round(percentile_cont(0.75) within group (order by rt.total_logging_sec), 1) as p75_sec,
    round(percentile_cont(0.95) within group (order by rt.total_logging_sec), 1) as p95_sec
from request_totals rt
join connex.erequest_dynamic e on rt.erequest_id = e.erequest_id
left join (
    select erequest_id, max(exception_reason) as exception_reason
    from connex.erequest_exception
    where created_date >= dateadd('day', -90, current_date())
    group by erequest_id
) ex on rt.erequest_id = ex.erequest_id
where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
  and rt.total_logging_sec between 1 and 259200
group by 1, 2
having count(*) >= 20
order by cnt desc
limit 30;
