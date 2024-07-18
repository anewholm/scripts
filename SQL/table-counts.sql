SET @sqlString = concat('select * from ', (SELECT group_concat(concat('select "', table_name, ' as tbl", count(*) as cnt from ', table_name) separator ' union all ') FROM information_schema.tables where table_schema = DATABASE()), ' order by cnt desc');

PREPARE stmt FROM @sqlString;
EXECUTE stmt;
DEALLOCATE PREPARE stmt; 