-- Q18: Compare touch vs wait for CLEAN vs REWORK requests
-- Side-by-side: how does the time decomposition differ?
with request_journeys as (
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
per_request as (
    select
        erequest_id,
        max(case when status_desc = 'Redo Logging' then 1 else 0 end) as had_redo,
        max(case when status_desc = 'Back To Logging' then 1 else 0 end) as had_sentback,
        max(case when status_desc = 'Logging Exception' then 1 else 0 end) as had_exception,
        -- Logging stage time only
        sum(case when status_desc = 'Logging'
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as logging_active_sec,
        sum(case when status_desc = 'Redo Logging'
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as redo_sec,
        sum(case when status_desc = 'Back To Logging'
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as sentback_sec,
        sum(case when status_desc in ('Logging On Hold', 'Logging Exception', 'Logging Correspondence')
                 and next_timestamp is not null
                 and datediff('second', state_timestamp, next_timestamp) between 1 and 604800
            then datediff('second', state_timestamp, next_timestamp) else 0 end) as hold_sec,
        count(distinct status_desc) as distinct_statuses
    from request_journeys
    group by erequest_id
    having logging_active_sec > 0
)
select
    case
        when had_redo = 1 then 'Had Redo'
        when had_sentback = 1 then 'Sent Back'
        when had_exception = 1 then 'Had Exception'
        else 'Clean Pass'
    end as journey_type,
    count(*) as cnt,
    round(median(logging_active_sec / 3600.0), 2) as median_logging_hrs,
    round(median(redo_sec / 3600.0), 2) as median_redo_hrs,
    round(median(sentback_sec / 3600.0), 2) as median_sentback_hrs,
    round(median(hold_sec / 3600.0), 2) as median_hold_hrs,
    round(median((logging_active_sec + redo_sec + sentback_sec + hold_sec) / 3600.0), 2) as median_total_hrs,
    round(avg(distinct_statuses), 1) as avg_distinct_statuses
from per_request
group by 1
order by cnt desc;
