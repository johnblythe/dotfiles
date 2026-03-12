-- Q5b: Rework rate for HUMAN-WORKED requests only (UPLOAD + CENTRAL INTAKE)
-- This removes the auto-transition noise that inflates "clean pass"
with logging_visits as (
    select
        es.erequest_id,
        es.state_timestamp,
        rs.status_desc,
        e.source_type,
        e.major_class,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_timestamp
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc in ('Logging', 'Redo Logging', 'Back To Logging', 'Logging Exception', 'Logging On Hold')
      and es.state_timestamp >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
),
request_logging_summary as (
    select
        erequest_id,
        max(source_type) as source_type,
        max(major_class) as major_class,
        count(case when status_desc = 'Logging' then 1 end) as logging_visits,
        count(case when status_desc = 'Redo Logging' then 1 end) as redo_count,
        count(case when status_desc = 'Back To Logging' then 1 end) as back_to_logging_count,
        count(case when status_desc = 'Logging Exception' then 1 end) as exception_count,
        count(case when status_desc = 'Logging On Hold' then 1 end) as hold_count,
        sum(case when status_desc = 'Logging' and next_timestamp is not null
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as total_logging_seconds
    from logging_visits
    group by erequest_id
)
select
    case
        when logging_visits = 1 and redo_count = 0 and back_to_logging_count = 0 then 'Clean pass'
        when redo_count > 0 then 'Had redo'
        when back_to_logging_count > 0 then 'Sent back'
        when exception_count > 0 then 'Had exception'
        when hold_count > 0 then 'Had hold'
        else 'Other'
    end as logging_journey,
    count(*) as request_count,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct_of_total,
    round(avg(total_logging_seconds), 1) as avg_total_logging_sec,
    round(median(total_logging_seconds), 1) as median_total_logging_sec,
    round(percentile_cont(0.95) within group (order by total_logging_seconds), 1) as p95_sec,
    round(avg(logging_visits), 2) as avg_logging_visits
from request_logging_summary
group by 1
order by request_count desc;
