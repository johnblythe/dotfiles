-- Q8: What % of requests have PatientLookup audit events?
-- Stratified by source_type to see if it's channel-dependent
with requests_90d as (
    select
        e.erequest_id,
        e.source_type,
        e.major_class
    from connex.erequest_dynamic e
    where e.date_received >= dateadd('day', -90, current_date())
      and e.source_type is not null
),
patient_lookups as (
    select distinct
        at.erequest_id,
        1 as has_lookup
    from connex.erequest_audit_trail_dynamic at
    where at.audit_type in ('PatientLookupStarted', 'PatientLookupFinished', 'PatientLookupNotFound')
      and at.event_dt >= dateadd('day', -90, current_date())
)
select
    r.source_type,
    count(*) as total_requests,
    count(pl.has_lookup) as with_patient_lookup,
    round(count(pl.has_lookup) * 100.0 / count(*), 1) as pct_with_lookup
from requests_90d r
left join patient_lookups pl on r.erequest_id = pl.erequest_id
group by r.source_type
order by total_requests desc;
