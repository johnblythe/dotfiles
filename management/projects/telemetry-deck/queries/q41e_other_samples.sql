-- Q41e: Sample the remaining OTHER category
with resub as (
    select
        case when audit_message like '%Comment : %'
            then trim(substr(audit_message, position('Comment : ' in audit_message) + 10))
            else ''
        end as comment_text
    from connex.erequest_audit_trail_dynamic
    where audit_type = 'RequestResubmittedToLogging'
      and event_dt >= dateadd('day', -90, current_date())
)
select comment_text, count(*) as freq
from resub
where comment_text not in ('', '.')
  and lower(comment_text) not like '%second review%' and lower(comment_text) not like '%2nd review%'
  and lower(comment_text) not like '%coc%' and lower(comment_text) not like '%boc%'
  and lower(comment_text) not like '%split%'
  and lower(comment_text) not like '%site%' and lower(comment_text) not like '%cbo%' and lower(comment_text) not like '%landing%'
  and lower(comment_text) not like '%mrn%'
  and lower(comment_text) not like '%dar%' and lower(comment_text) not like '%relog%'
  and lower(comment_text) not like '%pull list%'
  and lower(comment_text) not like '%billing%'
  and lower(comment_text) not like '%dos%' and lower(comment_text) not like '%date%' and lower(comment_text) not like '%dob%'
  and lower(comment_text) not like '%patient%' and lower(comment_text) not like '%multiple%'
  and lower(comment_text) not like '%iex%'
  and lower(comment_text) not like '%edit%' and lower(comment_text) not like '%update%' and lower(comment_text) not like '%correct%'
  and lower(comment_text) not like '%rtl%'
  and lower(comment_text) not like '%duplicate%' and lower(comment_text) not like '%dupe%'
  and lower(comment_text) not like '%auth%'
  and lower(comment_text) not like '%address%' and lower(comment_text) not like '%requester%'
group by comment_text
order by freq desc
limit 50;
