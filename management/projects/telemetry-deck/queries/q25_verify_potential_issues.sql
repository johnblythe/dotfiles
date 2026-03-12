-- Q25: Verify system - what events surround potential issues?
-- Track requests that had potential issues: what were they about?
-- Look at event_comments field for structured data
select
    audit_type,
    left(event_comments, 300) as comments_sample,
    count(*) as cnt
from HEALTHSOURCE.CONNEX.erequest_audit_trail_dynamic
where event_dt >= dateadd('day', -30, current_date())
  and audit_type in ('AuditFulfillmentSubmitPotentialIssue', 'AuditFulfillmentSubmitNoPotentialIssue', 'AuditFulfillmentQcSubmit', 'FulfillmentQCSubmitTaskCompleted', 'NewQCResults')
  and event_comments is not null
  and trim(event_comments) != ''
group by audit_type, comments_sample
order by cnt desc limit 30;
