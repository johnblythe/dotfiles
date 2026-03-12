-- Q12: Fulfillment TAT detailed - for dedicated slide
-- Breaks out human-worked vs auto, by source_type x major_class
-- Includes distribution buckets for chart
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
fulfill_times as (
    select
        st.erequest_id,
        e.major_class,
        e.source_type,
        e.is_emr,
        datediff('second', st.state_timestamp, st.next_state_timestamp) as fulfill_sec
    from status_transitions st
    join connex.erequest_dynamic e on st.erequest_id = e.erequest_id
    where st.status_desc = 'Fulfillment'
      and st.next_state_timestamp is not null
      and datediff('second', st.state_timestamp, st.next_state_timestamp) between 1 and 259200
)
select
    source_type,
    major_class,
    is_emr,
    count(*) as cnt,
    round(percentile_cont(0.25) within group (order by fulfill_sec), 1) as p25_sec,
    round(median(fulfill_sec), 1) as median_sec,
    round(percentile_cont(0.75) within group (order by fulfill_sec), 1) as p75_sec,
    round(percentile_cont(0.95) within group (order by fulfill_sec), 1) as p95_sec,
    round(avg(fulfill_sec), 1) as avg_sec,
    count(case when fulfill_sec < 10 then 1 end) as under_10s,
    count(case when fulfill_sec between 10 and 60 then 1 end) as bucket_10s_1m,
    count(case when fulfill_sec between 61 and 300 then 1 end) as bucket_1m_5m,
    count(case when fulfill_sec between 301 and 1800 then 1 end) as bucket_5m_30m,
    count(case when fulfill_sec between 1801 and 3600 then 1 end) as bucket_30m_1h,
    count(case when fulfill_sec between 3601 and 14400 then 1 end) as bucket_1h_4h,
    count(case when fulfill_sec between 14401 and 28800 then 1 end) as bucket_4h_8h,
    count(case when fulfill_sec > 28800 then 1 end) as bucket_8h_plus
from fulfill_times
group by source_type, major_class, is_emr
having count(*) >= 50
order by cnt desc
limit 40;
