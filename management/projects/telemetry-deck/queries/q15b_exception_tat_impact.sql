-- Q15b: Exception TAT impact by reason - how much time do exceptions add?
-- Compare total fulfillment time for exception vs clean requests
with fulfill_transitions as (
    select
        es.erequest_id,
        rs.status_desc,
        es.state_timestamp,
        lead(es.state_timestamp) over (
            partition by es.erequest_id
            order by es.state_timestamp
        ) as next_state_timestamp
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    where es.state_timestamp >= dateadd('day', -90, current_date())
      and rs.status_desc = 'Fulfillment'
),
fulfill_times as (
    select
        ft.erequest_id,
        datediff('second', ft.state_timestamp, ft.next_state_timestamp) as fulfill_sec
    from fulfill_transitions ft
    where ft.next_state_timestamp is not null
      and datediff('second', ft.state_timestamp, ft.next_state_timestamp) between 1 and 259200
),
exceptions as (
    select
        ex.erequest_id,
        r.exception_reason_desc,
        row_number() over (partition by ex.erequest_id order by ex.created_dt desc) as rn
    from connex.erequest_exception ex
    join connex.erequest_exception_reason r on ex.exception_reason_id = r.erequest_exception_reason_id
    where ex.created_dt >= dateadd('day', -90, current_date())
)
select
    coalesce(exc.exception_reason_desc, 'No exception') as reason,
    count(*) as cnt,
    round(median(ft.fulfill_sec), 1) as median_fulfill_sec,
    round(percentile_cont(0.75) within group (order by ft.fulfill_sec), 1) as p75_sec,
    round(percentile_cont(0.95) within group (order by ft.fulfill_sec), 1) as p95_sec
from fulfill_times ft
join connex.erequest_dynamic e on ft.erequest_id = e.erequest_id
left join exceptions exc on ft.erequest_id = exc.erequest_id and exc.rn = 1
where e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
group by 1
having count(*) >= 100
order by cnt desc
limit 20;
