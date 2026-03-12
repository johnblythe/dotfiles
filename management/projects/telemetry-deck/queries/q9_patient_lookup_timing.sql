-- Q9: Patient lookup durations and outcomes
-- How long does patient lookup take? How often does it fail (NotFound)?
with lookup_events as (
    select
        at.erequest_id,
        at.audit_type,
        at.event_dt,
        e.source_type,
        e.major_class
    from connex.erequest_audit_trail_dynamic at
    join connex.erequest_dynamic e on at.erequest_id = e.erequest_id
    where at.audit_type in ('PatientLookupStarted', 'PatientLookupFinished', 'PatientLookupNotFound')
      and at.event_dt >= dateadd('day', -90, current_date())
),
lookup_pairs as (
    select
        s.erequest_id,
        s.source_type,
        s.major_class,
        s.event_dt as started_at,
        f.event_dt as finished_at,
        f.audit_type as outcome,
        datediff('second', s.event_dt, f.event_dt) as lookup_sec
    from lookup_events s
    join lookup_events f
        on s.erequest_id = f.erequest_id
        and f.audit_type in ('PatientLookupFinished', 'PatientLookupNotFound')
        and f.event_dt > s.event_dt
        and datediff('second', s.event_dt, f.event_dt) < 300  -- cap at 5 min
    where s.audit_type = 'PatientLookupStarted'
    qualify row_number() over (partition by s.erequest_id, s.event_dt order by f.event_dt) = 1
)
select
    outcome,
    source_type,
    count(*) as lookup_count,
    round(avg(lookup_sec), 1) as avg_sec,
    round(median(lookup_sec), 1) as median_sec,
    round(percentile_cont(0.95) within group (order by lookup_sec), 1) as p95_sec
from lookup_pairs
group by outcome, source_type
order by source_type, outcome;
