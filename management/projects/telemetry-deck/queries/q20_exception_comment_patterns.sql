-- Q20: Exception comment text analysis
-- Are comments structured (field-level feedback) or freetext?
-- Look for patterns that suggest automatable feedback
with exc_comments as (
    select
        ex.exception_comment,
        r.exception_reason_desc,
        length(ex.exception_comment) as comment_len
    from connex.erequest_exception ex
    join connex.erequest_exception_reason r
        on ex.exception_reason_id = r.erequest_exception_reason_id
    join connex.erequest_dynamic e on ex.erequest_id = e.erequest_id
    where ex.created_dt >= dateadd('day', -90, current_date())
      and e.source_type in ('UPLOAD', 'CENTRAL INTAKE')
      and ex.exception_comment is not null
      and trim(ex.exception_comment) != ''
)
select
    exception_reason_desc,
    count(*) as total_with_comments,
    round(avg(comment_len), 0) as avg_comment_len,
    round(median(comment_len), 0) as median_comment_len,
    -- Check for structured patterns
    count(case when exception_comment ilike '%DOB%' or exception_comment ilike '%date of birth%' then 1 end) as mentions_dob,
    count(case when exception_comment ilike '%SSN%' or exception_comment ilike '%social%' then 1 end) as mentions_ssn,
    count(case when exception_comment ilike '%auth%' then 1 end) as mentions_auth,
    count(case when exception_comment ilike '%name%' then 1 end) as mentions_name,
    count(case when exception_comment ilike '%date%' then 1 end) as mentions_date,
    count(case when exception_comment ilike '%missing%' then 1 end) as mentions_missing,
    count(case when exception_comment ilike '%incorrect%' or exception_comment ilike '%wrong%' then 1 end) as mentions_wrong,
    count(case when exception_comment ilike '%page%' then 1 end) as mentions_page,
    count(case when exception_comment ilike '%fee%' or exception_comment ilike '%payment%' then 1 end) as mentions_fee
from exc_comments
group by exception_reason_desc
order by total_with_comments desc
limit 20;
