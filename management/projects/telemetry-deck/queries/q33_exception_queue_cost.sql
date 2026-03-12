-- Q33: Exception queue hours — how much time requests sit in exception statuses
with exception_durations as (
    select
        es.erequest_id,
        rs.status_desc,
        datediff('minute', es.state_timestamp,
            lead(es.state_timestamp) over (partition by es.erequest_id order by es.state_timestamp)
        ) as duration_min
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc in ('Logging Exception', 'Fulfillment Exception',
                             'Logging On Hold', 'Fulfillment On Hold',
                             'Logging Correspondence')
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and es.state_timestamp >= dateadd('day', -90, current_date())
)
select
    status_desc,
    count(*) as occurrences_90d,
    round(count(*) * 4, 0) as annualized,
    round(median(duration_min) / 60.0, 1) as median_hours,
    round(avg(duration_min) / 60.0, 1) as avg_hours,
    round(percentile_cont(0.75) within group (order by duration_min) / 60.0, 1) as p75_hours,
    round(sum(duration_min) / 60.0, 0) as total_hours_90d,
    round(sum(duration_min) / 60.0 * 4, 0) as annualized_hours,
    round(sum(duration_min) / 60.0 * 4 / 2080, 1) as annualized_ftes
from exception_durations
where duration_min > 0 and duration_min < 43200  -- <30 days
group by status_desc
order by total_hours_90d desc;
