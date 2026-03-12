-- Q29: Temporal patterns - hour of day and day of week for queue times
-- When do exceptions sit longest? When are they resolved fastest?
with exception_durations as (
    select
        es.erequest_id,
        es.state_timestamp as exception_start,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as exception_end,
        dayofweek(es.state_timestamp) as dow,
        hour(es.state_timestamp) as hour_of_day
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc = 'Logging Exception'
      and es.state_timestamp >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
)
select
    dow,
    case dow
        when 0 then 'Mon' when 1 then 'Tue' when 2 then 'Wed'
        when 3 then 'Thu' when 4 then 'Fri' when 5 then 'Sat' when 6 then 'Sun'
    end as day_name,
    hour_of_day,
    count(*) as exceptions_created,
    round(median(datediff('second', exception_start, exception_end) / 3600.0), 2) as median_exception_hrs,
    round(avg(datediff('second', exception_start, exception_end) / 3600.0), 2) as avg_exception_hrs
from exception_durations
where exception_end is not null
  and datediff('second', exception_start, exception_end) between 60 and 604800
group by dow, day_name, hour_of_day
order by dow, hour_of_day;
