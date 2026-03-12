-- Q41d: Full resubmission categorization from audit_message
with resub as (
    select
        audit_message,
        -- Extract the comment portion after "Comment : "
        case when audit_message like '%Comment : %'
            then trim(substr(audit_message, position('Comment : ' in audit_message) + 10))
            else ''
        end as comment_text
    from connex.erequest_audit_trail_dynamic
    where audit_type = 'RequestResubmittedToLogging'
      and event_dt >= dateadd('day', -90, current_date())
),
categorized as (
    select
        comment_text,
        case
            when comment_text = '' or comment_text = '.' then 'NO_REASON'
            when lower(comment_text) like '%second review%' or lower(comment_text) like '%2nd review%' then 'SECOND_REVIEW'
            when lower(comment_text) like '%coc%' or lower(comment_text) like '%boc%' then 'COC_BOC'
            when lower(comment_text) like '%split%' then 'SPLIT'
            when lower(comment_text) like '%site%' or lower(comment_text) like '%cbo%' or lower(comment_text) like '%landing%' then 'SITE_CHANGE'
            when lower(comment_text) like '%mrn%' then 'MRN_CORRECTION'
            when lower(comment_text) like '%dar%' or lower(comment_text) like '%relog%' then 'DAR_RELOG'
            when lower(comment_text) like '%pull list%' then 'PULL_LIST'
            when lower(comment_text) like '%billing%' then 'BILLING'
            when lower(comment_text) like '%dos%' or lower(comment_text) like '%date%' or lower(comment_text) like '%dob%' then 'DATE_CORRECTION'
            when lower(comment_text) like '%patient%' or lower(comment_text) like '%multiple%' then 'PATIENT_ISSUE'
            when lower(comment_text) like '%iex%' then 'IEX'
            when lower(comment_text) like '%edit%' or lower(comment_text) like '%update%' or lower(comment_text) like '%correct%' then 'EDIT_UPDATE'
            when lower(comment_text) like '%rtl%' then 'RTL'
            when lower(comment_text) like '%duplicate%' or lower(comment_text) like '%dupe%' then 'DUPLICATE'
            when lower(comment_text) like '%auth%' then 'AUTH'
            when lower(comment_text) like '%address%' or lower(comment_text) like '%requester%' then 'REQUESTER_INFO'
            else 'OTHER'
        end as category
    from resub
)
select category, count(*) as cnt,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from categorized
group by category
order by cnt desc;
