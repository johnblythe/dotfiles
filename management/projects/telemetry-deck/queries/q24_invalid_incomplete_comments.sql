-- Q24: Sample 'Invalid/Incomplete Request' comments - another high-volume reason
-- 70% of these mention 'missing' - what's missing?
select exception_comment, count(*) as cnt
from connex.erequest_exception ex
join connex.erequest_exception_reason r on ex.exception_reason_id = r.erequest_exception_reason_id
join connex.erequest_dynamic e on ex.erequest_id = e.erequest_id
where ex.created_dt >= dateadd('day', -90, current_date())
  and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
  and r.exception_reason_desc = 'Invalid/Incomplete Request'
  and ex.exception_comment is not null
  and trim(ex.exception_comment) != ''
group by exception_comment order by cnt desc limit 30;
