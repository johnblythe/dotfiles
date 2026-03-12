-- Q35: Weekend/off-hours queue gap — exceptions created during off-hours vs business hours
-- and their resolution time difference
with exception_timing as (
    select
        es.erequest_id,
        es.state_timestamp,
        dayofweek(es.state_timestamp) as dow,  -- 0=Mon, 6=Sun
        hour(es.state_timestamp) as hr,
        case
            when dayofweek(es.state_timestamp) in (5, 6) then 'Weekend'
            when hour(es.state_timestamp) < 7 or hour(es.state_timestamp) >= 19 then 'Off-Hours'
            else 'Business Hours'
        end as shift,
        datediff('minute', es.state_timestamp,
            lead(es.state_timestamp) over (partition by es.erequest_id order by es.state_timestamp)
        ) as duration_min
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc in ('Logging Exception', 'Fulfillment Exception',
                             'Back To Logging', 'Back To Fulfillment')
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and es.state_timestamp >= dateadd('day', -90, current_date())
)
select
    shift,
    count(*) as occurrences_90d,
    round(median(duration_min) / 60.0, 1) as median_hours,
    round(percentile_cont(0.75) within group (order by duration_min) / 60.0, 1) as p75_hours,
    round(sum(duration_min) / 60.0, 0) as total_hours_90d,
    round(sum(duration_min) / 60.0 * 4 / 2080, 1) as annualized_ftes,
    -- If we could cut weekend/off-hours resolution to business hours median
    round(sum(case when duration_min > 222 then duration_min - 222 else 0 end) / 60.0, 0) as excess_hours_vs_biz_median_90d
from exception_timing
where duration_min > 0 and duration_min < 43200
group by shift
order by median_hours desc;
