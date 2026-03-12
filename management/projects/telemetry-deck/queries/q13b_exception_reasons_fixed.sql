-- Q13b: Find exception reason lookup table and get top reasons
-- Step 1: Find the lookup table
select table_name, column_name
from information_schema.columns
where table_schema = 'CONNEX'
  and (column_name ilike '%exception%reason%' or column_name ilike '%exception%desc%')
  and table_name != 'EREQUEST_EXCEPTION'
order by table_name;
