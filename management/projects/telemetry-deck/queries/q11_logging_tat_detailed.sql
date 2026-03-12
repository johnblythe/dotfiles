-- Q11: Detailed logging TAT by major_class for human-worked channels
-- Full distribution with percentiles per major class
with status_transitions as (
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
    where es.state_timestamp >= dateadd('day', -90, current_date())
      and rs.status_desc = 'Logging'
),
human_logging as (
    select
        st.erequest_id,
        e.major_class,
        e.source_type,
        datediff('second', st.state_timestamp, st.next_state_timestamp) as logging_sec
    from status_transitions st
    join connex.erequest_dynamic e on st.erequest_id = e.erequest_id
    where st.next_state_timestamp is not null
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and datediff('second', st.state_timestamp, st.next_state_timestamp) between 10 and 86400
)
select
    major_class,
    count(*) as request_count,
    round(avg(logging_sec) / 60, 1) as avg_min,
    round(percentile_cont(0.25) within group (order by logging_sec) / 60, 1) as p25_min,
    round(median(logging_sec) / 60, 1) as median_min,
    round(percentile_cont(0.75) within group (order by logging_sec) / 60, 1) as p75_min,
    round(percentile_cont(0.90) within group (order by logging_sec) / 60, 1) as p90_min,
    round(percentile_cont(0.95) within group (order by logging_sec) / 60, 1) as p95_min
from human_logging
group by major_class
having count(*) >= 100
order by request_count desc;
