-- Q50: Verify FP samples — "Valid Patient Name/DOB/DOS" (reason ID 5)
select
    c.identifier,
    c.identifier_value,
    count(*) as freq
from connex.erequest_qc_action a
join connex.erequest_qc_conflicts c on a.erequest_qc_conflicts_id = c.erequest_qc_conflicts_id
where a.ignored = 'Y'
  and a.ignored_reason_id = 5
group by 1, 2
order by freq desc
limit 50;
