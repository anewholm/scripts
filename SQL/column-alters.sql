do $$
begin
execute (
  select string_agg(concat(
	'ALTER TABLE ', table_schema, '.', table_name, ' ALTER COLUMN "', column_name, '" TYPE timestamp(0) without time zone'
	-- 'COMMENT ON COLUMN ', table_schema, '.', table_name, '.', column_name, ' IS '''' '
	-- 'ALTER TABLE ', table_schema, '.', table_name, ' ALTER COLUMN ', column_name, ' TYPE text COLLATE pg_catalog."default"'
  )::varchar, ';') 
  from information_schema.columns
  where data_type = 'timestamp with time zone'
  and table_name like('acorn_%')
  and is_updatable = 'YES'
);
end$$;

select *, table_schema, table_name, column_name, data_type,
  pg_catalog.col_description(concat(table_schema, '.', table_name)::regclass::oid, ordinal_position) as comment
from information_schema.columns
where data_type = 'timestamp with time zone'
and table_name like('acorn_%')
and is_updatable = 'YES'
