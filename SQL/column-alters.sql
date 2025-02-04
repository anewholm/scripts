do $$
begin
execute (
	select string_agg(concat(
	'COMMENT ON COLUMN ', table_schema, '.', table_name, '.', column_name, ' IS ''field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
tab-location: 1'''

	--'ALTER TABLE ', table_schema, '.', table_name, ' ALTER COLUMN ', column_name, ' TYPE text COLLATE pg_catalog."default"'
	
	)::varchar, ';') 
	from information_schema.columns
	where column_name like('description')
	and table_name like('acorn_criminal_%')
);
end$$;

--select table_schema, table_name, column_name from information_schema.columns where column_name like('description') and table_name like('acorn_criminal_%')
