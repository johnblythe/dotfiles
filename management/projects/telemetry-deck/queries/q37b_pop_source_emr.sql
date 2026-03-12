-- Q37b: Population source type + EMR breakdown for comparison
select
    source_type,
    is_emr,
    count(*) as cnt,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from connex.erequest_dynamic
where source_type in ('UPLOAD', 'CENTRAL INTAKE')
  and created_dt >= dateadd('day', -90, current_date())
group by 1, 2
order by cnt desc;
