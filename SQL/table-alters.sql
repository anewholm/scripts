select concat('alter table ', table_name, ' add column ...;') 
from information_schema.tables where table_name like('acorn%')