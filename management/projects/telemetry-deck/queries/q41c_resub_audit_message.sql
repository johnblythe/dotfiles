-- Q41c: Check what's in audit_message for resubmissions
select
    audit_message,
    count(*) as freq
from connex.erequest_audit_trail_dynamic
where audit_type = 'RequestResubmittedToLogging'
  and event_dt >= dateadd('day', -90, current_date())
group by audit_message
order by freq desc
limit 30;
