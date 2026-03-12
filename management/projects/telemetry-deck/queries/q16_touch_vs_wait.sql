-- Q16: Touch time vs wait time decomposition
-- For human-worked requests, break down time spent in each status
-- "Active" statuses = someone is working (Logging, Fulfillment, QC In Progress)
-- "Queue" statuses = sitting in a pile (Redo Logging, Back To Logging, etc.)
-- "Hold" statuses = explicitly paused (On Hold, Exception, Correspondence)
with transitions as (
    select
        es.erequest_id,
        rs.status_desc,
        es.state_timestamp,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_timestamp,
        lead(rs2.status_desc) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_status
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    left join connex.erequest_status_dynamic es2 on es.erequest_id = es2.erequest_id
    left join connex.request_status rs2 on es2.status_id = rs2.status_id
    where es.state_timestamp >= dateadd('day', -90, current_date())
),
-- simpler: just get each status duration
status_durations as (
    select
        es.erequest_id,
        rs.status_desc,
        es.state_timestamp,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_timestamp
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where es.state_timestamp >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
),
categorized as (
    select
        erequest_id,
        status_desc,
        datediff('second', state_timestamp, next_timestamp) as duration_sec,
        case
            when status_desc in ('Logging', 'Fulfillment', 'QC In Progress', 'Redo Logging') then 'Active Work'
            when status_desc in ('Logging On Hold', 'Logging Exception', 'Logging Correspondence',
                                 'Fulfillment On Hold', 'Fulfillment Exception') then 'Hold/Exception'
            when status_desc in ('Back To Logging', 'Back To Fulfillment') then 'Sent Back (Queue)'
            else 'Other/Transit'
        end as time_category
    from status_durations
    where next_timestamp is not null
      and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
)
select
    status_desc,
    time_category,
    count(*) as transitions,
    count(distinct erequest_id) as unique_requests,
    round(median(duration_sec), 1) as median_sec,
    round(avg(duration_sec), 1) as avg_sec,
    round(percentile_cont(0.25) within group (order by duration_sec), 1) as p25_sec,
    round(percentile_cont(0.75) within group (order by duration_sec), 1) as p75_sec,
    round(percentile_cont(0.95) within group (order by duration_sec), 1) as p95_sec
from categorized
group by status_desc, time_category
order by transitions desc
limit 30;
