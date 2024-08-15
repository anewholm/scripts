CREATE OR REPLACE FUNCTION public.fn_acorn_lojistiks_transfers_created_at()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
declare
	event_id integer;
	description text;
	external_url varchar(2048);
begin
	-- We do not trigger on replicated rows
	-- that already have a value set
	if new.created_at is null then
		-- Use the Calendar system
		description  := 'Transfer created';
		external_url := concat('/backend/acorn/lojistiks/transfer/update/', new.id);
		insert into public.acorn_calendar_event(calendar_id, owner_user_id, owner_user_group_id, external_url) 
			values(1,1,1, external_url);
		event_id = currval('acorn_calendar_event_id_seq'::regclass);
		insert into public.acorn_calendar_event_part(event_id, "name", description, "start", "end", type_id) 
			values(event_id, description, description, now(), now(), 4);
		new.created_at = event_id;
	end if;

	return new;
end;
$BODY$;

CREATE OR REPLACE TRIGGER tr_acorn_lojistiks_transfers_created_at
    BEFORE INSERT
    ON public.acorn_lojistiks_transfers
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_acorn_lojistiks_transfers_created_at();