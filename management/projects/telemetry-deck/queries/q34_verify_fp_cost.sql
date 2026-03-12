-- Q34: QC Verify false positive review cost
-- How many conflicts are reviewed, how many ignored, estimated review time per conflict
with conflict_stats as (
    select
        c.erequest_id,
        count(*) as conflicts_per_request,
        sum(case when a.ignored = 'Y' then 1 else 0 end) as ignored_cnt,
        sum(case when a.deleted = 'Y' then 1 else 0 end) as deleted_cnt
    from connex.erequest_qc_conflicts c
    left join connex.erequest_qc_action a on c.erequest_qc_conflicts_id = a.erequest_qc_conflicts_id
    where c.erequest_id in (
        select erequest_id from connex.erequest_dynamic
        where created_dt >= dateadd('day', -90, current_date())
    )
    group by c.erequest_id
)
select
    count(distinct erequest_id) as requests_with_conflicts_90d,
    sum(conflicts_per_request) as total_conflicts_90d,
    sum(ignored_cnt) as total_ignored_90d,
    sum(deleted_cnt) as total_deleted_90d,
    round(sum(ignored_cnt) * 100.0 / nullif(sum(conflicts_per_request), 0), 1) as ignore_pct,
    -- Estimated review time: 15 sec per conflict (conservative)
    round(sum(conflicts_per_request) * 15 / 3600.0, 0) as est_review_hours_90d,
    round(sum(conflicts_per_request) * 15 / 3600.0 * 4, 0) as est_review_hours_annual,
    round(sum(conflicts_per_request) * 15 / 3600.0 * 4 / 2080, 1) as est_review_ftes,
    -- If we could filter 50% of FPs
    round(sum(ignored_cnt) * 0.5 * 15 / 3600.0 * 4, 0) as saved_hours_50pct_filter,
    round(sum(ignored_cnt) * 0.5 * 15 / 3600.0 * 4 / 2080, 1) as saved_ftes_50pct_filter,
    -- Stats
    round(avg(conflicts_per_request), 1) as avg_conflicts_per_request,
    round(median(conflicts_per_request), 1) as median_conflicts_per_request,
    max(conflicts_per_request) as max_conflicts_per_request
from conflict_stats;
