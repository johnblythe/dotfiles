-- Q53: Conflicts per request distribution
-- How many requests have 1 conflict vs 20+?
with per_request as (
    select
        erequest_id,
        count(*) as conflict_cnt
    from connex.erequest_qc_conflicts
    group by erequest_id
)
select
    case
        when conflict_cnt = 1 then '1'
        when conflict_cnt <= 3 then '2-3'
        when conflict_cnt <= 5 then '4-5'
        when conflict_cnt <= 10 then '6-10'
        when conflict_cnt <= 20 then '11-20'
        when conflict_cnt <= 50 then '21-50'
        when conflict_cnt <= 100 then '51-100'
        else '100+'
    end as conflict_bucket,
    count(*) as request_cnt,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct,
    round(avg(conflict_cnt), 1) as avg_in_bucket,
    max(conflict_cnt) as max_in_bucket
from per_request
group by 1
order by min(conflict_cnt);
