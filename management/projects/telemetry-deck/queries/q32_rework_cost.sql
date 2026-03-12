-- Q32: Rework cost — volume and time estimates
-- Part A: How many rework requests in 90d (human-worked only)
with rework as (
    select
        es.erequest_id,
        count(*) as redo_transitions
    from connex.erequest_status_dynamic es
    join connex.request_status rs on es.status_id = rs.status_id
    join connex.erequest_dynamic e on es.erequest_id = e.erequest_id
    where rs.status_desc in ('Redo Logging', 'Back To Logging', 'Back To Fulfillment')
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and es.state_timestamp >= dateadd('day', -90, current_date())
      and e.created_dt >= dateadd('day', -90, current_date())
    group by es.erequest_id
)
select
    count(*) as rework_requests_90d,
    round(count(*) * 4, 0) as annualized,
    sum(redo_transitions) as total_redo_transitions_90d,
    round(avg(redo_transitions), 2) as avg_redos_per_request,
    max(redo_transitions) as max_redos_single_request
from rework;
