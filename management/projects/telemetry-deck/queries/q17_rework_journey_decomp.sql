-- Q17: Rework request journey decomposition
-- For requests that had Redo Logging, show the full timeline breakdown
-- How much is active work vs waiting in queue?
with rework_requests as (
    select distinct es.erequest_id
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc = 'Redo Logging'
      and es.state_timestamp >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
),
all_transitions as (
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
    where es.erequest_id in (select erequest_id from rework_requests)
      and es.state_timestamp >= dateadd('day', -180, current_date())
),
per_request as (
    select
        erequest_id,
        -- total wall clock
        datediff('second', min(state_timestamp), max(next_timestamp)) as total_wall_sec,
        -- time in active work statuses
        sum(case when status_desc in ('Logging', 'Redo Logging', 'Fulfillment', 'QC In Progress')
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as active_sec,
        -- time in hold/exception
        sum(case when status_desc in ('Logging On Hold', 'Logging Exception', 'Logging Correspondence',
                                      'Fulfillment On Hold', 'Fulfillment Exception')
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as hold_sec,
        -- time in sent-back queue
        sum(case when status_desc in ('Back To Logging', 'Back To Fulfillment')
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as sentback_queue_sec,
        -- count of status changes
        count(*) as transition_count
    from all_transitions
    group by erequest_id
    having total_wall_sec between 60 and 604800
)
select
    count(*) as request_count,
    round(median(total_wall_sec / 3600.0), 1) as median_wall_hrs,
    round(median(active_sec / 3600.0), 1) as median_active_hrs,
    round(median(hold_sec / 3600.0), 1) as median_hold_hrs,
    round(median(sentback_queue_sec / 3600.0), 1) as median_sentback_hrs,
    round(median(active_sec * 100.0 / nullif(total_wall_sec, 0)), 1) as median_pct_active,
    round(median(hold_sec * 100.0 / nullif(total_wall_sec, 0)), 1) as median_pct_hold,
    round(avg(transition_count), 1) as avg_transitions,
    -- also show percentiles
    round(percentile_cont(0.25) within group (order by active_sec * 100.0 / nullif(total_wall_sec, 0)), 1) as p25_pct_active,
    round(percentile_cont(0.75) within group (order by active_sec * 100.0 / nullif(total_wall_sec, 0)), 1) as p75_pct_active
from per_request;
