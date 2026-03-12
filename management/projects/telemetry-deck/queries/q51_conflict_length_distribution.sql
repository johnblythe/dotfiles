-- Q51: Conflict identifier_value length distribution
-- Hypothesis: short strings are more likely to be false positives
select
    case
        when len(c.identifier_value) <= 3 then '1-3 chars'
        when len(c.identifier_value) <= 6 then '4-6 chars'
        when len(c.identifier_value) <= 10 then '7-10 chars'
        when len(c.identifier_value) <= 15 then '11-15 chars'
        when len(c.identifier_value) <= 25 then '16-25 chars'
        else '26+ chars'
    end as length_bucket,
    c.identifier,
    count(*) as total_conflicts,
    sum(case when a.ignored = 'Y' then 1 else 0 end) as ignored_cnt,
    sum(case when a.deleted = 'Y' then 1 else 0 end) as deleted_cnt,
    round(sum(case when a.ignored = 'Y' then 1 else 0 end) * 100.0 / count(*), 1) as ignore_rate,
    round(sum(case when a.deleted = 'Y' then 1 else 0 end) * 100.0 / count(*), 1) as delete_rate
from connex.erequest_qc_conflicts c
left join connex.erequest_qc_action a on c.erequest_qc_conflicts_id = a.erequest_qc_conflicts_id
group by 1, 2
order by 2, 1;
