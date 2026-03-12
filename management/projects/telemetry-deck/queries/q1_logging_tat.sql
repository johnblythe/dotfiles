-- Logging time-on-task: "Logging" → next status transition
-- Stratified by major_class, source_type
with status_transitions as (
    select
        es.erequest_id,
        rs.status_desc,
        es.state_timestamp,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_state_timestamp,
        lead(rs2.status_desc) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_status_desc
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    left join connex.erequest_status_dynamic es2
        on es.erequest_id = es2.erequest_id
    left join connex.request_status rs2 on es2.status_id = rs2.status_id
    where es.state_timestamp >= dateadd('day', -90, current_date())
)
select
    e.major_class,
    e.source_type,
    count(*) as request_count,
    round(avg(datediff('second', st.state_timestamp, st.next_state_timestamp)), 1) as avg_sec,
    round(median(datediff('second', st.state_timestamp, st.next_state_timestamp)), 1) as median_sec,
    round(percentile_cont(0.25) within group (order by datediff('second', st.state_timestamp, st.next_state_timestamp)), 1) as p25_sec,
    round(percentile_cont(0.75) within group (order by datediff('second', st.state_timestamp, st.next_state_timestamp)), 1) as p75_sec,
    round(percentile_cont(0.95) within group (order by datediff('second', st.state_timestamp, st.next_state_timestamp)), 1) as p95_sec
from status_transitions st
join connex.erequest_dynamic e on st.erequest_id = e.erequest_id
where st.status_desc = 'Logging'
  and st.next_state_timestamp is not null
  and datediff('second', st.state_timestamp, st.next_state_timestamp) between 1 and 86400
group by e.major_class, e.source_type
having count(*) >= 10
order by request_count desc
limit 30;
