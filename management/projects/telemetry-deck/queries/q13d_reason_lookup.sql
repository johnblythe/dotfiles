-- Q13d: Exception reason lookup + category
select
    r.erequest_exception_reason_id,
    r.exception_reason_code,
    r.exception_reason_desc,
    r.exception_reason_parent_id,
    c.exception_category_desc
from connex.erequest_exception_reason r
left join connex.erequest_exception_category c
    on r.exception_reason_parent_id = c.erequest_exception_category_id
order by r.erequest_exception_reason_id;
