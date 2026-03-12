-- Q49: Verify false positive samples — "Medical terminology" ignores
-- What identifier values are flagged as conflicts but are actually medical terms?
select
    c.identifier,
    c.identifier_value,
    c.pages,
    a.comments
from connex.erequest_qc_conflicts c
join connex.erequest_qc_action a on c.erequest_qc_conflicts_id = a.erequest_qc_conflicts_id
join connex.ignore_conflict_reasons r on a.ignored_reason_id = r.ignore_conflict_reasons_id
where r.reason = 'Medical terminology/verbiage'
  and a.ignored = 'Y'
  and c.erequest_id in (
      select erequest_id from connex.erequest_dynamic
      where created_dt >= dateadd('day', -90, current_date())
  )
order by random()
limit 100;
