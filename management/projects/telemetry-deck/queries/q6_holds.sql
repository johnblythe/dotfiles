-- Logging hold and pend durations
with hold_events as (
    select
        es.erequest_id,
        rs.status_desc,
        es.state_timestamp as hold_start,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as hold_end
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    where rs.status_desc in ('Logging On Hold', 'Logging Exception', 'Logging Correspondence')
      and es.state_timestamp >= dateadd('day', -90, current_date())
)
select
    status_desc,
    count(*) as occurrences,
    count(distinct erequest_id) as unique_requests,
    round(avg(datediff('minute', hold_start, hold_end)), 1) as avg_min,
    round(median(datediff('minute', hold_start, hold_end)), 1) as median_min,
    round(percentile_cont(0.75) within group (order by datediff('minute', hold_start, hold_end)), 1) as p75_min,
    round(percentile_cont(0.95) within group (order by datediff('minute', hold_start, hold_end)), 1) as p95_min
from hold_events
where hold_end is not null
  and datediff('minute', hold_start, hold_end) >= 0
group by status_desc
order by occurrences desc;
