do $$
begin
execute (
	select string_agg(concat('alter table if exists ', table_schema, '.', table_name, ' owner to justice'), ';') 
	from information_schema.tables 
	where table_name like('acornassociated_university_%')
);
end$$;