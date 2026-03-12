-- Q14: Exception category rollup (if categories exist)
-- Also check what columns are available
select column_name, data_type
from information_schema.columns
where table_schema = 'CONNEX'
  and table_name = 'EREQUEST_EXCEPTION'
order by ordinal_position;
