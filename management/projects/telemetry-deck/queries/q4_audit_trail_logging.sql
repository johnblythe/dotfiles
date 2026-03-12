-- What audit events fire during logging sessions?
-- Find audit events that occur between "Logging" status entry and exit
with logging_windows as (
    select
        es.erequest_id,
        es.state_timestamp as logging_start,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as logging_end
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    where rs.status_desc = 'Logging'
      and es.state_timestamp >= dateadd('day', -90, current_date())
)
select
    at.audit_type,
    at.audit_message,
    count(*) as event_count,
    count(distinct at.erequest_id) as unique_requests,
    round(avg(datediff('second', lw.logging_start, at.event_dt)), 1) as avg_sec_into_logging,
    round(median(datediff('second', lw.logging_start, at.event_dt)), 1) as median_sec_into_logging
from connex.erequest_audit_trail_dynamic at
join logging_windows lw
    on at.erequest_id = lw.erequest_id
    and at.event_dt between lw.logging_start and coalesce(lw.logging_end, current_timestamp())
where lw.logging_end is not null
  and datediff('second', lw.logging_start, lw.logging_end) between 10 and 86400
group by at.audit_type, at.audit_message
having count(*) >= 100
order by event_count desc
limit 40;
