-- Logging time ONLY for human-worked requests (UPLOAD + CENTRAL INTAKE)
-- With finer-grained bucketing
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
),
human_logging as (
    select
        st.erequest_id,
        e.major_class,
        e.source_type,
        datediff('second', st.state_timestamp, st.next_state_timestamp) as logging_sec
    from status_transitions st
    join connex.erequest_dynamic e on st.erequest_id = e.erequest_id
    where st.status_desc = 'Logging'
      and st.next_state_timestamp is not null
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and datediff('second', st.state_timestamp, st.next_state_timestamp) between 10 and 86400
)
select
    case
        when logging_sec < 60 then '< 1 min'
        when logging_sec < 300 then '1-5 min'
        when logging_sec < 600 then '5-10 min'
        when logging_sec < 1800 then '10-30 min'
        when logging_sec < 3600 then '30-60 min'
        when logging_sec < 7200 then '1-2 hrs'
        when logging_sec < 14400 then '2-4 hrs'
        when logging_sec < 28800 then '4-8 hrs'
        else '8-24 hrs'
    end as time_bucket,
    case
        when logging_sec < 60 then 1
        when logging_sec < 300 then 2
        when logging_sec < 600 then 3
        when logging_sec < 1800 then 4
        when logging_sec < 3600 then 5
        when logging_sec < 7200 then 6
        when logging_sec < 14400 then 7
        when logging_sec < 28800 then 8
        else 9
    end as sort_order,
    count(*) as request_count,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct_of_total,
    round(avg(logging_sec), 0) as avg_sec_in_bucket,
    major_class
from human_logging
group by 1, 2, major_class
order by major_class, sort_order;
