-- Q49b: Simpler Verify FP samples — just get identifier_value patterns
-- Medical terminology reason = ID 7
select
    c.identifier,
    c.identifier_value,
    a.ignored_reason_id,
    count(*) as freq
from connex.erequest_qc_action a
join connex.erequest_qc_conflicts c on a.erequest_qc_conflicts_id = c.erequest_qc_conflicts_id
where a.ignored = 'Y'
  and a.ignored_reason_id = 7
group by 1, 2, 3
order by freq desc
limit 50;
