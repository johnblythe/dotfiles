-- End-to-end: date_received → delivered_dt
select
    e.major_class,
    e.source_type,
    e.delivery_method,
    count(*) as request_count,
    round(avg(datediff('minute', e.date_received, e.delivered_dt)), 1) as avg_min,
    round(median(datediff('minute', e.date_received, e.delivered_dt)), 1) as median_min,
    round(percentile_cont(0.25) within group (order by datediff('minute', e.date_received, e.delivered_dt)), 1) as p25_min,
    round(percentile_cont(0.75) within group (order by datediff('minute', e.date_received, e.delivered_dt)), 1) as p75_min,
    round(percentile_cont(0.95) within group (order by datediff('minute', e.date_received, e.delivered_dt)), 1) as p95_min
from connex.erequest_dynamic e
where e.delivered_dt is not null
  and e.date_received is not null
  and e.delivered_dt > e.date_received
  and datediff('day', e.date_received, e.delivered_dt) between 0 and 90
  and e.date_received >= dateadd('day', -90, current_date())
group by e.major_class, e.source_type, e.delivery_method
having count(*) >= 50
order by request_count desc
limit 30;
