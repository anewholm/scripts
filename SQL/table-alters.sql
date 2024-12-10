do $$
begin
execute (
	select string_agg(concat('alter table if exists ', table_schema, '.', table_name, ' ', '
	    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id)
	    REFERENCES public.acorn_calendar_event (id) MATCH SIMPLE
	    ON UPDATE NO ACTION
	    ON DELETE NO ACTION
	    NOT VALID;
	CREATE INDEX IF NOT EXISTS fki_created_at_event_id
	    ON ', table_schema, '.', table_name, '(created_at_event_id)'),
	';
	
	') 
	from information_schema.tables 
	where table_name like('acorn_lojistiks_%')
);
end$$;