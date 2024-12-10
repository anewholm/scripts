--
-- PostgreSQL database dump
--

-- Dumped from database version 16.6 (Ubuntu 16.6-1.pgdg22.04+1)
-- Dumped by pg_dump version 17.2 (Ubuntu 17.2-1.pgdg22.04+1)

-- Started on 2024-12-10 20:05:33 +03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 10 (class 2615 OID 394252)
-- Name: product; Type: SCHEMA; Schema: -; Owner: justice
--

CREATE SCHEMA product;


ALTER SCHEMA product OWNER TO justice;

--
-- TOC entry 9 (class 2615 OID 393754)
-- Name: public; Type: SCHEMA; Schema: -; Owner: justice
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO justice;

--
-- TOC entry 5047 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: justice
--

COMMENT ON SCHEMA public IS '';


--
-- TOC entry 4 (class 3079 OID 394253)
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- TOC entry 5049 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- TOC entry 5 (class 3079 OID 394342)
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- TOC entry 5050 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- TOC entry 3 (class 3079 OID 394088)
-- Name: hostname; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;


--
-- TOC entry 5051 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION hostname; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hostname IS 'Get the server host name';


--
-- TOC entry 2 (class 3079 OID 394050)
-- Name: http; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA public;


--
-- TOC entry 5052 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION http; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION http IS 'HTTP client for PostgreSQL, allows web page retrieval inside the database.';


--
-- TOC entry 398 (class 1255 OID 394085)
-- Name: fn_acornassociated_add_websockets_triggers(character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_add_websockets_triggers(schema character varying, table_prefix character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            
            begin
        -- SELECT * FROM information_schema.tables;
        -- This assumes that fn_acornassociated_new_replicated_row() exists
        -- Trigger on replpica also: ENABLE ALWAYS
        execute (
          SELECT string_agg(concat(
            'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ADD COLUMN IF NOT EXISTS response text;',
            'CREATE OR REPLACE TRIGGER tr_', table_name, '_new_replicated_row
                BEFORE INSERT
                ON ', table_schema, '.', table_name, '
                FOR EACH ROW
                EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();',
            'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ENABLE ALWAYS TRIGGER tr_', table_name, '_new_replicated_row;'
          ), ' ')
          FROM information_schema.tables
          where table_catalog = current_database()
          and table_schema like(schema)
          and table_name like(table_prefix)
          and table_type = 'BASE TABLE'
        );
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_add_websockets_triggers(schema character varying, table_prefix character varying) OWNER TO justice;

--
-- TOC entry 480 (class 1255 OID 395440)
-- Name: fn_acornassociated_calendar_create_event(character varying); Type: FUNCTION; Schema: public; Owner: sanchez
--

CREATE FUNCTION public.fn_acornassociated_calendar_create_event(type character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare 
	owner_user_id uuid;
	title character varying(1024);
	calendar_id uuid;
	event_type_id uuid;
	event_status_id uuid;
	event_id uuid;
begin
	title := initcap(replace(type, '_', ' '));
	-- We select the first user in the system
	-- Intentional EXCEPTION if there is not one
	select into owner_user_id fn_acornassociated_user_get_seed_user();
	select into event_status_id id from public.acornassociated_calendar_event_status limit 1;
	insert into public.acornassociated_calendar(name, owner_user_id) values(title, owner_user_id) returning id into calendar_id;
	insert into public.acornassociated_calendar_event_type(name, colour, style) values('Create', '#091386', 'color:#fff') returning id into event_type_id;

	insert into public.acornassociated_calendar_event(calendar_id, owner_user_id) values(calendar_id, owner_user_id) returning id into event_id;
	insert into public.acornassociated_calendar_event_part(event_id, type_id, status_id, name, start, "end") 
		values(event_id, event_type_id, event_status_id, concat(title, ' ', 'Create'), now(), now());

	return event_id;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_calendar_create_event(type character varying) OWNER TO sanchez;

--
-- TOC entry 468 (class 1255 OID 395553)
-- Name: fn_acornassociated_calendar_create_event(character varying, uuid); Type: FUNCTION; Schema: public; Owner: sanchez
--

CREATE FUNCTION public.fn_acornassociated_calendar_create_event(type character varying, user_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare 
	owner_user_id uuid;
	title character varying(1024);
	calendar_id uuid;
	event_type_id uuid;
	event_status_id uuid;
	event_id uuid;
begin
	title := initcap(replace(type, '_', ' '));
	-- We select the first user in the system
	-- Intentional EXCEPTION if there is not one
	if user_id is null then 
		owner_user_id := fn_acornassociated_user_get_seed_user();
	else
		owner_user_id := user_id;
	end if;
	select into event_status_id id from public.acornassociated_calendar_event_status limit 1;
	insert into public.acornassociated_calendar(name, owner_user_id) values(title, owner_user_id) returning id into calendar_id;
	insert into public.acornassociated_calendar_event_type(name, colour, style) values('Create', '#091386', 'color:#fff') returning id into event_type_id;

	insert into public.acornassociated_calendar_event(calendar_id, owner_user_id) values(calendar_id, owner_user_id) returning id into event_id;
	insert into public.acornassociated_calendar_event_part(event_id, type_id, status_id, name, start, "end") 
		values(event_id, event_type_id, event_status_id, concat(title, ' ', 'Create'), now(), now());

	return event_id;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_calendar_create_event(type character varying, user_id uuid) OWNER TO sanchez;

--
-- TOC entry 414 (class 1255 OID 394764)
-- Name: fn_acornassociated_calendar_event_trigger_insert_function(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_calendar_event_trigger_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
days_before interval;
days_after interval;
days_count int;
today date := now();
date_start date;
            begin
                -- This function creates the individual event instances on specific dates
                -- from event definitions, that can have preiodic repetition
                -- For example, an single event definition that repeats weekly for 2 months
                -- may have 9 individual event instances on specific dates
                -- Declares are configurable from WinterCMS settings

                -- Check if anything repeaty has changed (not locked_by_user_id)
                if     OLD is null
                    or NEW.start  is distinct from OLD.start
                    or NEW."end"  is distinct from OLD."end"
                    or NEW.until  is distinct from OLD.until
                    or NEW.mask   is distinct from OLD.mask
                    or NEW.repeat is distinct from OLD.repeat
                    or NEW.mask_type is distinct from OLD.mask_type
                    or NEW.repeat_frequency     is distinct from OLD.repeat_frequency
                    or NEW.parent_event_part_id is distinct from OLD.parent_event_part_id
                    or NEW.instances_deleted    is distinct from OLD.instances_deleted
                then
                    -- Settings
                    select coalesce((select substring("value" from '"days_before":"([^"]+)"')
                        from system_settings where item = 'acornassociated_calendar_settings'), '1 year')
                        into days_before;
                    select coalesce((select substring("value" from '"days_after":"([^"]+)"')
                        from system_settings where item = 'acornassociated_calendar_settings'), '2 years')
                        into days_after;
                    select extract('epoch' from days_before + days_after)/3600/24.0
                        into days_count;
                    select today - days_before
                        into date_start;

                    -- For updates (id cannot change)
                    delete from acornassociated_calendar_instance where event_part_id = NEW.id;

                    -- For inserts
                    insert into acornassociated_calendar_instance("date", event_part_id, instance_start, instance_end, instance_num)
                    select date_start + interval '1' day * gs as "date", ev.*
                    from generate_series(0, days_count) as gs
                    inner join (
                        -- single event
                        select NEW.id as event_part_id,
                            NEW."start" as "instance_start",
                            NEW."end"   as "instance_end",
                            0 as instance_num
                        where NEW.repeat is null
                    union all
                        -- repetition, no parent container
                        select NEW.id as event_part_id,
                            NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs as "instance_start",
                            NEW."end" + NEW.repeat_frequency * NEW."repeat" * gs.gs   as "instance_end",
                            gs.gs as instance_num
                        from generate_series(0, days_count) as gs
                        where not NEW.repeat is null and NEW.parent_event_part_id is null
                        and (NEW.instances_deleted is null or not gs.gs = any(NEW.instances_deleted))
                        and (NEW.until is null or NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs < NEW.until)
                        and (NEW.mask = 0 or NEW.mask & (2^date_part(NEW.mask_type, NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs))::int != 0)
                    union all
                        -- repetition with parent_event_part_id container calendar events
                        select NEW.id as event_part_id,
                            NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs as "instance_start",
                            NEW."end" + NEW.repeat_frequency * NEW."repeat" * gs.gs   as "instance_end",
                            gs.gs as instance_num
                        from generate_series(0, days_count) as gs
                        inner join acornassociated_calendar_instance pcc on NEW.parent_event_part_id = pcc.event_part_id
                            and (pcc.date, pcc.date + 1)
                            overlaps (NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs, NEW."end" + NEW.repeat_frequency * NEW."repeat" * gs.gs)
                        where not NEW.repeat is null
                        and (NEW.instances_deleted is null or not gs.gs = any(NEW.instances_deleted))
                        and (NEW.until is null or NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs < NEW.until)
                        and (NEW.mask = 0 or NEW.mask & (2^date_part(NEW.mask_type, NEW."start" + NEW.repeat_frequency * NEW."repeat" * gs.gs))::int != 0)
                    ) ev
                    on  (date_start + interval '1' day * gs, date_start + interval '1' day * (gs+1))
                    overlaps (ev.instance_start, ev.instance_end);

                    -- Recursively update child event parts
                    -- TODO: This could infinetly cycle
                    update acornassociated_calendar_event_part set id = id
                        where parent_event_part_id = NEW.id
                        and not id = NEW.id;
                end if;

                return NEW;
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_calendar_event_trigger_insert_function() OWNER TO justice;

--
-- TOC entry 485 (class 1255 OID 394750)
-- Name: fn_acornassociated_calendar_is_date(character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_calendar_is_date(s character varying, d timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
            
            begin

                if s is null then
                    return d;
                end if;
                perform s::timestamp with time zone;
                    return s;
                exception when others then
                    return d;
            
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_calendar_is_date(s character varying, d timestamp with time zone) OWNER TO justice;

--
-- TOC entry 467 (class 1255 OID 415345)
-- Name: fn_acornassociated_criminal_action_legalcase_defendants_cw(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	justice_legalcase_id uuid;
	warrant_type_id uuid;
begin
	select into justice_legalcase_id cl.legalcase_id 
		from public.acornassociated_criminal_legalcases cl
		inner join public.acornassociated_criminal_legalcase_defendants ld on cl.id = ld.legalcase_id
		where ld.id = p_id;
	select into warrant_type_id id from public.acornassociated_justice_warrant_types limit 1;
	
	insert into public.acornassociated_justice_warrants(user_id, created_at_event_id, created_by_user_id, warrant_type_id, legalcase_id)
		select user_id,
			public.fn_acornassociated_calendar_create_event('create_warrant', p_user_id),
			p_user_id,
			warrant_type_id,
			justice_legalcase_id
		from public.acornassociated_criminal_legalcase_defendants
		where id = p_id;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid) OWNER TO justice;

--
-- TOC entry 5053 (class 0 OID 0)
-- Dependencies: 467
-- Name: FUNCTION fn_acornassociated_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acornassociated_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid) IS 'labels:
  en: Create Warrant';


--
-- TOC entry 432 (class 1255 OID 394091)
-- Name: fn_acornassociated_first(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_first(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $1;
            $_$;


ALTER FUNCTION public.fn_acornassociated_first(anyelement, anyelement) OWNER TO justice;

--
-- TOC entry 394 (class 1255 OID 395547)
-- Name: fn_acornassociated_justice_action_legalcases_close_case(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_justice_action_legalcases_close_case(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acornassociated_justice_legalcases 
		set closed_at_event_id = public.fn_acornassociated_calendar_create_event('close_case', user_id)
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_justice_action_legalcases_close_case(model_id uuid, user_id uuid) OWNER TO justice;

--
-- TOC entry 5054 (class 0 OID 0)
-- Dependencies: 394
-- Name: FUNCTION fn_acornassociated_justice_action_legalcases_close_case(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acornassociated_justice_action_legalcases_close_case(model_id uuid, user_id uuid) IS 'labels:
  en: Close Case
  ku: Bigre Sicil
condition: closed_at_event_id is null';


--
-- TOC entry 426 (class 1255 OID 404514)
-- Name: fn_acornassociated_justice_action_legalcases_reopen_case(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acornassociated_justice_legalcases 
		set closed_at_event_id = NULL
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) OWNER TO justice;

--
-- TOC entry 5055 (class 0 OID 0)
-- Dependencies: 426
-- Name: FUNCTION fn_acornassociated_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acornassociated_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) IS 'labels:
  en: Re-open Case
  ku: Vekrî Sicil
condition: not closed_at_event_id is null';


--
-- TOC entry 417 (class 1255 OID 395515)
-- Name: fn_acornassociated_justice_action_legalcases_transfer_case(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_justice_action_legalcases_transfer_case(id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
end;
$$;


ALTER FUNCTION public.fn_acornassociated_justice_action_legalcases_transfer_case(id uuid, user_id uuid) OWNER TO justice;

--
-- TOC entry 5056 (class 0 OID 0)
-- Dependencies: 417
-- Name: FUNCTION fn_acornassociated_justice_action_legalcases_transfer_case(id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acornassociated_justice_action_legalcases_transfer_case(id uuid, user_id uuid) IS 'labels:
  en: Transfer Case';


--
-- TOC entry 457 (class 1255 OID 415350)
-- Name: fn_acornassociated_justice_action_warrants_revoke(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acornassociated_justice_warrants
		set revoked_at_event_id = public.fn_acornassociated_calendar_create_event('revoke_warrant', p_user_id)
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) OWNER TO justice;

--
-- TOC entry 5057 (class 0 OID 0)
-- Dependencies: 457
-- Name: FUNCTION fn_acornassociated_justice_action_warrants_revoke(model_id uuid, p_user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acornassociated_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) IS 'labels:
  en: Revoke
  ku: Bigre
condition: revoked_at_event_id is null';


--
-- TOC entry 460 (class 1255 OID 412832)
-- Name: fn_acornassociated_justice_seed(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_justice_seed() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
	parent_id uuid;
	usergroup_id uuid;
begin
		insert into public.acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî ya Rêveberiya Xweser Li Bakur û Rojhilatê Sûriyê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ايروس قزشو لامشل ةيتاذلا ةرادلإا يف ةيعامتجلاا ةلادعلا سلجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Jinê a Dadgeriya Civakî Ya Rêveberiya Xweser Li Bakur û Rojhilatê Sûriyê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ايرىس قزشو لامشن تيتاذنا ةرادلإا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Reqayê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"تقزنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Feratê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ثازفنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Dêra Zorê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"روشنا زيد يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Munbicê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"جبنم يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Efrînê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"هيزفع يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Tebqê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"تقبطنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}');

		insert into acornassociated_user_user_groups(name, parent_user_group_id)
		values('Encumena Dadgeriya Civakî Li Cizîrê, ji van beşan pêk tê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
		values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"هم فنأتي ،ةزيشجنا يف تيعامتجلاا تنادعنا سهجم"}');

				parent_id := usergroup_id;
				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Serokatiya Encumenê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"سهجمنا تسائر"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Komîteya Cêgratiyan', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ثابايننا تنجن"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Komîteya Çavnêrî Ya Dadwerî', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"يئاضقنا شيتفتنا تنجن"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Komîteya Aştbûnê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"حهصنا تنجن"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Komîteya Bi cihanînê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ذيفنتنا تنجن"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Nivîsgeha Darayî û Rêveberî', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"يرادلإاو ينامنا بتكمنا"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwan û Cêgratiyên girêdayî Encumena Dadageriya Civakî li Cizîrê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ةزيشجنا يف تيعامتجلاا تنادعنا سهجمن تعباتنا ثاباينناو هيواودنا"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Qamişlo', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ىهشماق يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Hesîça', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"تكسحنا يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Tirbespiyê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"هيبسبزت يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Derbasiyê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"هيسابرد يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Amûdê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ادىماع يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Til Temir', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"زمت مت يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Şedadê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"يدادشنا يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Girkê Legê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"يكن يكزك يف تيعامتجلاا تنادعنا ناىيد"}');

				insert into acornassociated_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Dêrikê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"كزيد يف تيعامتجلاا تنادعنا ناىيد"}');

						parent_id := usergroup_id;
						insert into acornassociated_user_user_groups(name, parent_user_group_id)
						values('Cêgratiya Giştî li Zerganê', parent_id) returning id into usergroup_id;
						insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
						values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"ناكرس يف تماعنا تبايننا"}');

						insert into acornassociated_user_user_groups(name, parent_user_group_id)
						values('Cêgratiya Giştî li Til Birakê', parent_id) returning id into usergroup_id;
						insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
						values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"كازب مت يف تماعنا تبايننا"}');

						insert into acornassociated_user_user_groups(name, parent_user_group_id)
						values('Cêgratiya Giştî li Holê', parent_id) returning id into usergroup_id;
						insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
						values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"لىهنا يف تماعنا تبايننا"}');

						insert into acornassociated_user_user_groups(name, parent_user_group_id)
						values('Cêgratiya Giştî li Til Hemîsê', parent_id) returning id into usergroup_id;
						insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
						values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"سيمح مت يف تماعنا تبايننا"}');

						insert into acornassociated_user_user_groups(name, parent_user_group_id)
						values('Cêgratiya Giştî li Çelaxa', parent_id) returning id into usergroup_id;
						insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
						values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"اغآ مج يف تماعنا تبايننا"}');

						insert into acornassociated_user_user_groups(name, parent_user_group_id)
						values('Cêgratiya Giştî li Til Koçerê', parent_id) returning id into usergroup_id;
						insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
						values('ar', usergroup_id, 'AcornAssociated\User\Models\UserGroup', '{"name":"زجىك مت يف تماعنا تبايننا"}');
end;
$$;


ALTER FUNCTION public.fn_acornassociated_justice_seed() OWNER TO justice;

--
-- TOC entry 452 (class 1255 OID 396053)
-- Name: fn_acornassociated_justice_update_name_identifier(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_justice_update_name_identifier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if old.name != new.name then
		insert into public.acornassociated_justice_legalcase_identifiers(legalcase_id, name, created_at_event_id, created_by_user_id)
			values(new.id, old.name, 
				public.fn_acornassociated_calendar_create_event('identifier'),
				public.fn_acornassociated_user_get_seed_user()
			);
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_justice_update_name_identifier() OWNER TO justice;

--
-- TOC entry 473 (class 1255 OID 394093)
-- Name: fn_acornassociated_last(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_last(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $2;
            $_$;


ALTER FUNCTION public.fn_acornassociated_last(anyelement, anyelement) OWNER TO justice;

--
-- TOC entry 423 (class 1255 OID 413922)
-- Name: fn_acornassociated_lojistiks_distance(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acornassociated_lojistiks_distance(source_location_id uuid, destination_location_id uuid) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
begin
	return (select point(sg.longitude, sg.latitude) <@> point(dg.longitude, dg.latitude)
		from public.acornassociated_lojistiks_locations sl
		inner join public.acornassociated_lojistiks_addresses sa on sl.address_id = sa.id
		inner join public.acornassociated_lojistiks_gps sg on sa.gps_id = sg.id,
		
		public.acornassociated_lojistiks_locations dl
		inner join public.acornassociated_lojistiks_addresses da on dl.address_id = da.id
		inner join public.acornassociated_lojistiks_gps dg on da.gps_id = dg.id
		
		where sl.id = source_location_id
		and dl.id = destination_location_id
	) * 1.609344; -- Miles to KM
end;
$$;


ALTER FUNCTION public.fn_acornassociated_lojistiks_distance(source_location_id uuid, destination_location_id uuid) OWNER TO postgres;

--
-- TOC entry 427 (class 1255 OID 413923)
-- Name: fn_acornassociated_lojistiks_is_date(character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acornassociated_lojistiks_is_date(s character varying, d timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
            begin
                
                if s is null then
                    return d;
                end if;
                perform s::timestamp with time zone;
                    return s;
                exception when others then
                    return d;
            
            end;
            $$;


ALTER FUNCTION public.fn_acornassociated_lojistiks_is_date(s character varying, d timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 391 (class 1255 OID 412944)
-- Name: fn_acornassociated_lojistiks_transfers_delete_calendar(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acornassociated_lojistiks_transfers_delete_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if not old.created_at is null then
		-- Use the Calendar system
		delete from acornassociated_calendar_event
			where id = old.created_at_event_id;
	end if;
	return old;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_lojistiks_transfers_delete_calendar() OWNER TO postgres;

--
-- TOC entry 472 (class 1255 OID 412945)
-- Name: fn_acornassociated_lojistiks_transfers_insert_calendar(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acornassociated_lojistiks_transfers_insert_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    pid uuid;
    event_name text;
begin
	-- Use the Calendar system
	select into event_name concat('Transfer (', coalesce(name, 'Unknown'), ')')
		from public.acornassociated_location_locations
		where id = new.location_id;
	insert into public.acornassociated_calendar_event(calendar_id, owner_user_id, owner_user_group_id, external_url) 
		select id,
        -- TODO: This should be passed through from the transfer BackendAuth::user()
        (select id from acornassociated_user_users limit 1),
        (select id from acornassociated_user_user_groups limit 1),
        concat('/backend/acornassociated/lojistiks/transfers/update/', new.id)
		from acornassociated_calendar
		where name = 'Default'
		returning id into pid;
	insert into public.acornassociated_calendar_event_part(event_id, "name", description, "start", "end", type_id, status_id)
		select pid, event_name, '', now(), now(), id,
        (select id from acornassociated_calendar_event_status where name = 'Normal')
		from acornassociated_calendar_event_type
		where name = 'Transfer started';
	new.created_at_event_id = pid;

	return new;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_lojistiks_transfers_insert_calendar() OWNER TO postgres;

--
-- TOC entry 411 (class 1255 OID 412946)
-- Name: fn_acornassociated_lojistiks_transfers_update_calendar(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acornassociated_lojistiks_transfers_update_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	event_name text;
begin
	if not new.created_at_event_id is null then
		-- Use the Calendar system
		select into event_name        concat('Transfer to ', coalesce(name, 'Unknown'))
			from public.acornassociated_location_locations
			where id = new.location_id;
		update acornassociated_calendar_event_part 
			set name = event_name
			where event_id = new.created_at_event_id;
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.fn_acornassociated_lojistiks_transfers_update_calendar() OWNER TO postgres;

--
-- TOC entry 489 (class 1255 OID 394084)
-- Name: fn_acornassociated_new_replicated_row(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_new_replicated_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
domain varchar(1024);
plugin_path varchar(1024);
action varchar(2048);
params varchar(2048);
url varchar(2048);
res public.http_response;
            begin
            -- https://www.postgresql.org/docs/current/plpgsql-trigger.html
            domain = 'acorn-lojistiks.laptop'; -- TODO: domain for api
            plugin_path = '/api';
            action = '/datachange';
            params = concat('TG_NAME=', TG_NAME, '&TG_OP=', TG_OP, '&TG_TABLE_SCHEMA=', TG_TABLE_SCHEMA, '&TG_TABLE_NAME=', TG_TABLE_NAME, '&ID=', new.id);
            url = concat('http://', domain, plugin_path, action, '?', params);

            res = public.http_get(url);
            new.response = concat(res.status, ' ', res.content);

            return new;
end;
            
$$;


ALTER FUNCTION public.fn_acornassociated_new_replicated_row() OWNER TO justice;

--
-- TOC entry 397 (class 1255 OID 394086)
-- Name: fn_acornassociated_reset_sequences(character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_reset_sequences(schema_like character varying, table_like character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            declare
reset_query varchar(32596);
            begin
        reset_query = (SELECT string_agg(
                concat('SELECT SETVAL(''',
              PGT.schemaname, '.', S.relname,
              ''', COALESCE(MAX(', C.attname, '), 1) ) FROM ',
              PGT.schemaname, '.', T.relname, ';'),
            '')
          FROM pg_class AS S,
            pg_depend AS D,
            pg_class AS T,
            pg_attribute AS C,
            pg_tables AS PGT
          WHERE S.relkind = 'S'
            AND S.oid = D.objid
            AND D.refobjid = T.oid
            AND D.refobjid = C.attrelid
            AND D.refobjsubid = C.attnum
            AND T.relname = PGT.tablename
            AND PGT.schemaname like(schema_like)
            AND T.relname like(table_like)
        );
        if not reset_query is null then
          execute reset_query;
        end if;
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_reset_sequences(schema_like character varying, table_like character varying) OWNER TO justice;

--
-- TOC entry 482 (class 1255 OID 394090)
-- Name: fn_acornassociated_server_id(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_server_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
pid uuid;
            begin
        if new.server_id is null then
          select "id" into pid from acornassociated_servers where hostname = hostname();
          if pid is null then
            insert into acornassociated_servers(hostname) values(hostname()) returning id into pid;
          end if;
          new.server_id = pid;
        end if;
        return new;
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_server_id() OWNER TO justice;

--
-- TOC entry 484 (class 1255 OID 394087)
-- Name: fn_acornassociated_table_counts(character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_table_counts(_schema character varying) RETURNS TABLE("table" text, count bigint)
    LANGUAGE plpgsql
    AS $$
            
            begin
          -- SELECT * FROM information_schema.tables;
          return query execute (select concat(
          'select "table", "count" from (',
            (
              SELECT string_agg(
              concat('select ''', table_name, ''' as "table", count(*) as "count" from ', table_name),
              ' union all '
            )
            FROM information_schema.tables
            where table_catalog = current_database()
            and table_schema = _schema
            and table_type = 'BASE TABLE'
          ),
          ') data order by "count" desc, "table" asc'
        ));
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_table_counts(_schema character varying) OWNER TO justice;

--
-- TOC entry 448 (class 1255 OID 394049)
-- Name: fn_acornassociated_truncate_database(character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acornassociated_truncate_database(schema_like character varying, table_like character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            declare
reset_query varchar(32596);
            begin
        reset_query = (SELECT 'TRUNCATE TABLE '
              || string_agg(format('%I.%I', schemaname, tablename), ', ')
              || ' CASCADE'
            FROM   pg_tables
            WHERE  schemaname like(schema_like)
            AND tablename like(table_like)
          );
        if not reset_query is null then
          execute reset_query;
        end if;
end;
            $$;


ALTER FUNCTION public.fn_acornassociated_truncate_database(schema_like character varying, table_like character varying) OWNER TO justice;

--
-- TOC entry 409 (class 1255 OID 395441)
-- Name: fn_acornassociated_user_get_seed_user(); Type: FUNCTION; Schema: public; Owner: sanchez
--

CREATE FUNCTION public.fn_acornassociated_user_get_seed_user() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
begin
	-- We select the first user in the system
	-- Intentional EXCEPTION if there is not one
	return (select uu.id 
		--from public.backend_users bu
		--inner join public.acornassociated_user_users uu on bu.acornassociated_user_user_id = uu.id
		--where bu.is_superuser
		from public.acornassociated_user_users uu
		limit 1);
end;
$$;


ALTER FUNCTION public.fn_acornassociated_user_get_seed_user() OWNER TO sanchez;

--
-- TOC entry 1533 (class 1255 OID 394092)
-- Name: agg_acornassociated_first(anyelement); Type: AGGREGATE; Schema: public; Owner: justice
--

CREATE AGGREGATE public.agg_acornassociated_first(anyelement) (
    SFUNC = public.fn_acornassociated_first,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acornassociated_first(anyelement) OWNER TO justice;

--
-- TOC entry 1534 (class 1255 OID 394094)
-- Name: agg_acornassociated_last(anyelement); Type: AGGREGATE; Schema: public; Owner: justice
--

CREATE AGGREGATE public.agg_acornassociated_last(anyelement) (
    SFUNC = public.fn_acornassociated_last,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acornassociated_last(anyelement) OWNER TO justice;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 360 (class 1259 OID 413924)
-- Name: acornassociated_lojistiks_computer_products; Type: TABLE; Schema: product; Owner: postgres
--

CREATE TABLE product.acornassociated_lojistiks_computer_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    electronic_product_id uuid NOT NULL,
    memory bigint,
    "HDD_size" bigint,
    processor_version double precision,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    processor_type integer,
    response text
);


ALTER TABLE product.acornassociated_lojistiks_computer_products OWNER TO postgres;

--
-- TOC entry 361 (class 1259 OID 413930)
-- Name: acornassociated_lojistiks_electronic_products; Type: TABLE; Schema: product; Owner: postgres
--

CREATE TABLE product.acornassociated_lojistiks_electronic_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    voltage double precision,
    created_by_user_id uuid,
    response text
);


ALTER TABLE product.acornassociated_lojistiks_electronic_products OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 394650)
-- Name: acornassociated_calendar; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    sync_file character varying(4096),
    sync_format integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.108968'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid NOT NULL,
    owner_user_group_id uuid,
    permissions integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.acornassociated_calendar OWNER TO justice;

--
-- TOC entry 5058 (class 0 OID 0)
-- Dependencies: 309
-- Name: TABLE acornassociated_calendar; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar IS 'package-type: plugin
table-type: content';


--
-- TOC entry 312 (class 1259 OID 394689)
-- Name: acornassociated_calendar_event; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_event (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    calendar_id uuid NOT NULL,
    external_url character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.128766'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid NOT NULL,
    owner_user_group_id uuid,
    permissions integer DEFAULT 79 NOT NULL
);


ALTER TABLE public.acornassociated_calendar_event OWNER TO justice;

--
-- TOC entry 5059 (class 0 OID 0)
-- Dependencies: 312
-- Name: TABLE acornassociated_calendar_event; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar_event IS 'table-type: content';


--
-- TOC entry 313 (class 1259 OID 394714)
-- Name: acornassociated_calendar_event_part; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_event_part (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    start timestamp(0) without time zone NOT NULL,
    "end" timestamp(0) without time zone NOT NULL,
    until timestamp(0) without time zone,
    mask integer DEFAULT 0 NOT NULL,
    mask_type character varying(256),
    type_id uuid NOT NULL,
    status_id uuid NOT NULL,
    repeat_frequency integer DEFAULT 1 NOT NULL,
    parent_event_part_id uuid,
    location_id uuid,
    locked_by_user_id integer,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.139605'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    repeat interval,
    alarm interval,
    instances_deleted integer[]
);


ALTER TABLE public.acornassociated_calendar_event_part OWNER TO justice;

--
-- TOC entry 5060 (class 0 OID 0)
-- Dependencies: 313
-- Name: TABLE acornassociated_calendar_event_part; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar_event_part IS 'table-type: content';


--
-- TOC entry 311 (class 1259 OID 394681)
-- Name: acornassociated_calendar_event_status; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_event_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    style character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    system boolean DEFAULT false NOT NULL
);


ALTER TABLE public.acornassociated_calendar_event_status OWNER TO justice;

--
-- TOC entry 5061 (class 0 OID 0)
-- Dependencies: 311
-- Name: TABLE acornassociated_calendar_event_status; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar_event_status IS 'table-type: content';


--
-- TOC entry 310 (class 1259 OID 394671)
-- Name: acornassociated_calendar_event_type; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_event_type (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    whole_day boolean DEFAULT false NOT NULL,
    colour character varying(16),
    style character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.11728'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    system boolean DEFAULT false NOT NULL
);


ALTER TABLE public.acornassociated_calendar_event_type OWNER TO justice;

--
-- TOC entry 5062 (class 0 OID 0)
-- Dependencies: 310
-- Name: TABLE acornassociated_calendar_event_type; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar_event_type IS 'table-type: content';


--
-- TOC entry 315 (class 1259 OID 394766)
-- Name: acornassociated_calendar_event_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_event_user (
    event_part_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.164696'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_calendar_event_user OWNER TO justice;

--
-- TOC entry 5063 (class 0 OID 0)
-- Dependencies: 315
-- Name: TABLE acornassociated_calendar_event_user; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar_event_user IS 'table-type: content';


--
-- TOC entry 316 (class 1259 OID 394787)
-- Name: acornassociated_calendar_event_user_group; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_event_user_group (
    event_part_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_calendar_event_user_group OWNER TO justice;

--
-- TOC entry 314 (class 1259 OID 394751)
-- Name: acornassociated_calendar_instance; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_calendar_instance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date NOT NULL,
    event_part_id uuid NOT NULL,
    instance_num integer NOT NULL,
    instance_start timestamp(0) without time zone NOT NULL,
    instance_end timestamp(0) without time zone NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.151591'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_calendar_instance OWNER TO justice;

--
-- TOC entry 5064 (class 0 OID 0)
-- Dependencies: 314
-- Name: TABLE acornassociated_calendar_instance; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_calendar_instance IS 'table-type: content';


--
-- TOC entry 322 (class 1259 OID 394899)
-- Name: acornassociated_civil_hearings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_civil_hearings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_civil_hearings OWNER TO justice;

--
-- TOC entry 5065 (class 0 OID 0)
-- Dependencies: 322
-- Name: TABLE acornassociated_civil_hearings; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_civil_hearings IS 'icon: handshake
labels:
  en: Hearing
  ar: جلسة إستماع مدنية
labels-plural:
  en: Hearings
  ar: جلسات إستماع مدنية';


--
-- TOC entry 323 (class 1259 OID 394903)
-- Name: acornassociated_civil_legalcases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_civil_legalcases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_civil_legalcases OWNER TO justice;

--
-- TOC entry 5066 (class 0 OID 0)
-- Dependencies: 323
-- Name: TABLE acornassociated_civil_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_civil_legalcases IS 'icon: angry
labels: 
  en: Case
  ar: القضية مدنية
labels-plural:
  en: Cases
  ar: القضايا مدنية
plugin-names:
  en: Civil
  ar: القضية مدنية
plugin-descriptions:
  en: Civil cases
order: 1
plugin-icon: handshake';


--
-- TOC entry 324 (class 1259 OID 394943)
-- Name: acornassociated_criminal_appeals; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_appeals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (event_id) STORED
);


ALTER TABLE public.acornassociated_criminal_appeals OWNER TO justice;

--
-- TOC entry 5067 (class 0 OID 0)
-- Dependencies: 324
-- Name: TABLE acornassociated_criminal_appeals; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_appeals IS 'icon: hand-paper
labels: 
  en: Appeal
  ar: الاستئناف الجنائي
labels-plural:
  en: Appeals
  ar: الاستئنافات الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();';


--
-- TOC entry 325 (class 1259 OID 394947)
-- Name: acornassociated_criminal_crime_evidence; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_crime_evidence (
    defendant_crime_id uuid NOT NULL,
    legalcase_evidence_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_crime_evidence OWNER TO justice;

--
-- TOC entry 5068 (class 0 OID 0)
-- Dependencies: 325
-- Name: TABLE acornassociated_criminal_crime_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_crime_evidence IS 'order: 43
labels:
  ar: دليل الجريمة الجنائية
labels-plural:
  ar: أدلة الجريمة الجنائية
';


--
-- TOC entry 326 (class 1259 OID 394950)
-- Name: acornassociated_criminal_crime_sentences; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_crime_sentences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    defendant_crime_id uuid NOT NULL,
    sentence_type_id uuid NOT NULL,
    amount double precision,
    suspended boolean DEFAULT false NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_crime_sentences OWNER TO justice;

--
-- TOC entry 5069 (class 0 OID 0)
-- Dependencies: 326
-- Name: TABLE acornassociated_criminal_crime_sentences; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_crime_sentences IS 'icon: id-card
order: 42
labels:
  ar: حكم الجريمة الجنائية
labels-plural:
  ar: أحكام الجرائم الجنائية
methods:
  name: return $this->sentence_type->name . '' ('' . $this->amount . '')'';';


--
-- TOC entry 327 (class 1259 OID 394955)
-- Name: acornassociated_criminal_crime_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_crime_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    parent_crime_type_id uuid,
    created_at_event_id uuid DEFAULT public.fn_acornassociated_calendar_create_event('crime_type'::character varying, NULL::uuid) NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acornassociated_user_get_seed_user() NOT NULL
);


ALTER TABLE public.acornassociated_criminal_crime_types OWNER TO justice;

--
-- TOC entry 5070 (class 0 OID 0)
-- Dependencies: 327
-- Name: TABLE acornassociated_criminal_crime_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_crime_types IS 'icon: keyboard
order: 41
seeding:
  - [DEFAULT, ''mysogyny'']
  - [DEFAULT, ''theft'']
labels:
  ar: نوع الجريمة الجنائية
labels-plural:
  ar: أنواع الجرائم الجنائية
';


--
-- TOC entry 328 (class 1259 OID 394961)
-- Name: acornassociated_criminal_crimes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_crimes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    crime_type_id uuid,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_crimes OWNER TO justice;

--
-- TOC entry 5071 (class 0 OID 0)
-- Dependencies: 328
-- Name: TABLE acornassociated_criminal_crimes; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_crimes IS 'icon: allergies
order: 40
menuSplitter: yes
labels:
  ar: الجريمة الجنائية
labels-plural:
  ar: الجرائم الجنائية
';


--
-- TOC entry 329 (class 1259 OID 394967)
-- Name: acornassociated_criminal_defendant_crimes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_defendant_crimes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_defendant_id uuid NOT NULL,
    crime_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_defendant_crimes OWNER TO justice;

--
-- TOC entry 5072 (class 0 OID 0)
-- Dependencies: 329
-- Name: TABLE acornassociated_criminal_defendant_crimes; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_defendant_crimes IS 'icon: id-card
labels:
  ar: جرائم المتهمين الجنائية
labels-plural:
  ar: جرايمة المتهم الجنائية
methods:
  name: return $this->crime->name;';


--
-- TOC entry 352 (class 1259 OID 412896)
-- Name: acornassociated_criminal_defendant_detentions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_defendant_detentions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    detention_reason_id uuid,
    detention_method_id uuid,
    actual_release_transfer_id uuid,
    legalcase_defendant_id uuid,
    name character varying(1024) GENERATED ALWAYS AS (id) STORED
);


ALTER TABLE public.acornassociated_criminal_defendant_detentions OWNER TO justice;

--
-- TOC entry 5073 (class 0 OID 0)
-- Dependencies: 352
-- Name: TABLE acornassociated_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_defendant_detentions IS 'methods:
  name: return $this->transfer->location->name . '' ('' . $this->detention_reason?->name . '')'';';


--
-- TOC entry 5074 (class 0 OID 0)
-- Dependencies: 352
-- Name: COLUMN acornassociated_criminal_defendant_detentions.detention_reason_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acornassociated_criminal_defendant_detentions.detention_reason_id IS 'labels:
  en: Reason
new-row: true';


--
-- TOC entry 5075 (class 0 OID 0)
-- Dependencies: 352
-- Name: COLUMN acornassociated_criminal_defendant_detentions.detention_method_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acornassociated_criminal_defendant_detentions.detention_method_id IS 'labels:
  en: Method';


--
-- TOC entry 5076 (class 0 OID 0)
-- Dependencies: 352
-- Name: COLUMN acornassociated_criminal_defendant_detentions.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acornassociated_criminal_defendant_detentions.name IS 'hidden: true';


--
-- TOC entry 354 (class 1259 OID 412916)
-- Name: acornassociated_criminal_detention_methods; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_detention_methods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description character varying(2048)
);


ALTER TABLE public.acornassociated_criminal_detention_methods OWNER TO justice;

--
-- TOC entry 353 (class 1259 OID 412908)
-- Name: acornassociated_criminal_detention_reasons; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_detention_reasons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description character varying(2048)
);


ALTER TABLE public.acornassociated_criminal_detention_reasons OWNER TO justice;

--
-- TOC entry 330 (class 1259 OID 394971)
-- Name: acornassociated_criminal_legalcase_defendants; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcase_defendants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_legalcase_defendants OWNER TO justice;

--
-- TOC entry 5077 (class 0 OID 0)
-- Dependencies: 330
-- Name: TABLE acornassociated_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcase_defendants IS 'icon: robot
order: 6
menu: false
labels:
  ar: المتهم في قضية جنائية
labels-plural:
  ar: المتهمين في قضية جنائية
';


--
-- TOC entry 331 (class 1259 OID 394975)
-- Name: acornassociated_criminal_legalcase_evidence; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcase_evidence (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_legalcase_evidence OWNER TO justice;

--
-- TOC entry 5078 (class 0 OID 0)
-- Dependencies: 331
-- Name: TABLE acornassociated_criminal_legalcase_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcase_evidence IS 'table-type: content
plural: legalcase_evidence
icon: object-group
order: 3
menu: false
labels:
  ar: دليل القضايا الجنائية
labels-plural:
  ar: أدلة القضايا الجنائية
';


--
-- TOC entry 334 (class 1259 OID 394989)
-- Name: acornassociated_criminal_legalcase_plaintiffs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcase_plaintiffs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_legalcase_plaintiffs OWNER TO justice;

--
-- TOC entry 5079 (class 0 OID 0)
-- Dependencies: 334
-- Name: TABLE acornassociated_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcase_plaintiffs IS 'icon: address-book
order: 2
menu: false
labels:
  ar: ضحية القضية الجنائية
labels-plural:
  ar: ضحايا القضية الجنائية
';


--
-- TOC entry 332 (class 1259 OID 394981)
-- Name: acornassociated_criminal_legalcase_prosecutor; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcase_prosecutor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    user_id uuid NOT NULL,
    user_group_id uuid,
    created_at_event_id uuid DEFAULT public.fn_acornassociated_calendar_create_event('legalcase_prosecutor'::character varying, NULL::uuid) NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acornassociated_user_get_seed_user() NOT NULL
);


ALTER TABLE public.acornassociated_criminal_legalcase_prosecutor OWNER TO justice;

--
-- TOC entry 5080 (class 0 OID 0)
-- Dependencies: 332
-- Name: TABLE acornassociated_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcase_prosecutor IS 'icon: id-card
order: 4
menu: false
labels:
  ar: المدعي العام للقضية الجنائية
labels-plural:
  ar: المدعون العامون للقضايا الجنائية
';


--
-- TOC entry 333 (class 1259 OID 394985)
-- Name: acornassociated_criminal_legalcase_related_events; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcase_related_events (
    event_id uuid NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    id uuid DEFAULT gen_random_uuid()
);


ALTER TABLE public.acornassociated_criminal_legalcase_related_events OWNER TO justice;

--
-- TOC entry 5081 (class 0 OID 0)
-- Dependencies: 333
-- Name: TABLE acornassociated_criminal_legalcase_related_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcase_related_events IS 'icon: address-book
order: 7
labels:
  en: Legalcase Events
  ar: الحدث المتعلقة بالقضاية الجنائية
labels-plural:
  ar: الأحداث المتعلقة بالقضايا الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();';


--
-- TOC entry 335 (class 1259 OID 394993)
-- Name: acornassociated_criminal_legalcase_witnesses; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcase_witnesses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_legalcase_witnesses OWNER TO justice;

--
-- TOC entry 5082 (class 0 OID 0)
-- Dependencies: 335
-- Name: TABLE acornassociated_criminal_legalcase_witnesses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcase_witnesses IS 'icon: search
order: 5
menu: false
labels:
  ar: شاهد القضية الجنائية
labels-plural:
  ar: شهود القضية الجنائية
';


--
-- TOC entry 336 (class 1259 OID 394997)
-- Name: acornassociated_criminal_legalcases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_legalcases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    server_id uuid
);


ALTER TABLE public.acornassociated_criminal_legalcases OWNER TO justice;

--
-- TOC entry 5083 (class 0 OID 0)
-- Dependencies: 336
-- Name: TABLE acornassociated_criminal_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_legalcases IS 'icon: dizzy
plugin-icon: address-book
order: 1
labels:
  ar: القضية الجنائية
labels-plural:
  ar: القضايا الجنائية
plugin-names:
  ar: القضية الجنائية
filters:
  owner_user_group: id in(select cl.id from acornassociated_criminal_legalcases cl inner join acornassociated_justice_legalcases  jl on jl.id = cl.legalcase_id where jl.owner_user_group_id in(:filtered))';


--
-- TOC entry 337 (class 1259 OID 395001)
-- Name: acornassociated_criminal_sentence_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_sentence_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_sentence_types OWNER TO justice;

--
-- TOC entry 5084 (class 0 OID 0)
-- Dependencies: 337
-- Name: TABLE acornassociated_criminal_sentence_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_sentence_types IS 'icon: hand-rock
order: 43
labels:
  ar: نوع الحكم الجنائي
labels-plural:
  ar: أنواع الأحكام الجنائية
';


--
-- TOC entry 338 (class 1259 OID 395007)
-- Name: acornassociated_criminal_session_recordings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_session_recordings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_session_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_session_recordings OWNER TO justice;

--
-- TOC entry 5085 (class 0 OID 0)
-- Dependencies: 338
-- Name: TABLE acornassociated_criminal_session_recordings; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_session_recordings IS 'icon: map
order: 25
menu: false
labels:
  ar: تسجيل الجلسة جنائية
labels-plural:
  ar: تسجيلات الجلسة جنائية
';


--
-- TOC entry 339 (class 1259 OID 395011)
-- Name: acornassociated_criminal_trial_judges; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_trial_judges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_id uuid NOT NULL,
    user_id uuid NOT NULL,
    user_group_id uuid,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_trial_judges OWNER TO justice;

--
-- TOC entry 5086 (class 0 OID 0)
-- Dependencies: 339
-- Name: TABLE acornassociated_criminal_trial_judges; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_trial_judges IS 'icon: thumbs-up
order: 22
menu: false
labels:
  ar: قاضي المحكمة الجنائية
labels-plural:
  ar: قضاة المحكمة الجنائية
methods:
  name: return $this->user->name;';


--
-- TOC entry 340 (class 1259 OID 395015)
-- Name: acornassociated_criminal_trial_sessions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_trial_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_trial_sessions OWNER TO justice;

--
-- TOC entry 5087 (class 0 OID 0)
-- Dependencies: 340
-- Name: TABLE acornassociated_criminal_trial_sessions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_trial_sessions IS 'icon: meh
order: 21
labels:
  ar: جلسة المحكمة الجنائية
labels-plural:
  ar: جلسات المحكمة الجنائية
methods:
  name: return $this->created_at_event->start;';


--
-- TOC entry 341 (class 1259 OID 395019)
-- Name: acornassociated_criminal_trials; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_criminal_trials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_criminal_trials OWNER TO justice;

--
-- TOC entry 5088 (class 0 OID 0)
-- Dependencies: 341
-- Name: TABLE acornassociated_criminal_trials; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_criminal_trials IS 'icon: ankh
order: 20
menuSplitter: yes
labels:
  ar: المحكمة الجنائية
labels-plural:
  ar: المحاكم الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();';


--
-- TOC entry 355 (class 1259 OID 413791)
-- Name: acornassociated_finance_currencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_finance_currencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    shortname character(3) NOT NULL,
    symbol character varying(16) NOT NULL
);


ALTER TABLE public.acornassociated_finance_currencies OWNER TO postgres;

--
-- TOC entry 5089 (class 0 OID 0)
-- Dependencies: 355
-- Name: TABLE acornassociated_finance_currencies; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_finance_currencies IS 'plugin-icon: money
icon: stripe
seeding:
  - [DEFAULT, ''Syrian Pound'', ''SYR'', ''£'']
  - [DEFAULT, ''American dollar'', ''USD'', ''$'']
methods:
  present($amount): return "$this->symbol$amount";
';


--
-- TOC entry 356 (class 1259 OID 413797)
-- Name: acornassociated_finance_invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_finance_invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    number integer NOT NULL,
    currency_id uuid NOT NULL,
    mark_paid boolean DEFAULT false NOT NULL,
    amount integer NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL,
    payer_user_id uuid,
    payer_user_group_id uuid,
    payee_user_id uuid,
    payee_user_group_id uuid,
    created_event_id uuid,
    CONSTRAINT payee_either_or CHECK (((NOT (payee_user_id IS NULL)) OR (NOT (payee_user_group_id IS NULL)))),
    CONSTRAINT payer_either_or CHECK (((NOT (payer_user_id IS NULL)) OR (NOT (payer_user_group_id IS NULL))))
);


ALTER TABLE public.acornassociated_finance_invoices OWNER TO postgres;

--
-- TOC entry 5090 (class 0 OID 0)
-- Dependencies: 356
-- Name: TABLE acornassociated_finance_invoices; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_finance_invoices IS 'methods:
  name:  return "#$this->number (" . $this->currency?->present($this->amount) . '') to '' . $this->payer_user_group?->name . '' '' . $this->payer_user?->name;
icon: swift';


--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN acornassociated_finance_invoices.payer_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_invoices.payer_user_id IS 'labels: 
  en: Payer
new-row: true';


--
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN acornassociated_finance_invoices.payer_user_group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_invoices.payer_user_group_id IS 'labels: 
  en: Payer Organisation';


--
-- TOC entry 5093 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN acornassociated_finance_invoices.payee_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_invoices.payee_user_id IS 'labels: 
  en: Payee
new-row: true';


--
-- TOC entry 5094 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN acornassociated_finance_invoices.payee_user_group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_invoices.payee_user_group_id IS 'labels: 
  en: Payee Organisation';


--
-- TOC entry 357 (class 1259 OID 413807)
-- Name: acornassociated_finance_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_finance_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    currency_id uuid NOT NULL,
    amount integer NOT NULL,
    number integer,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL
);


ALTER TABLE public.acornassociated_finance_payments OWNER TO postgres;

--
-- TOC entry 5095 (class 0 OID 0)
-- Dependencies: 357
-- Name: TABLE acornassociated_finance_payments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_finance_payments IS 'icon: vine';


--
-- TOC entry 5096 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN acornassociated_finance_payments.amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_payments.amount IS 'new-row: true';


--
-- TOC entry 358 (class 1259 OID 413814)
-- Name: acornassociated_finance_purchases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_finance_purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    number integer NOT NULL,
    mark_paid boolean DEFAULT false NOT NULL,
    currency_id uuid NOT NULL,
    amount integer NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL,
    payer_user_id uuid,
    payer_user_group_id uuid,
    payee_user_id uuid,
    payee_user_group_id uuid,
    CONSTRAINT payee_either_or CHECK (((NOT (payee_user_id IS NULL)) OR (NOT (payee_user_group_id IS NULL)))),
    CONSTRAINT payer_either_or CHECK (((NOT (payer_user_id IS NULL)) OR (NOT (payer_user_group_id IS NULL))))
);


ALTER TABLE public.acornassociated_finance_purchases OWNER TO postgres;

--
-- TOC entry 5097 (class 0 OID 0)
-- Dependencies: 358
-- Name: TABLE acornassociated_finance_purchases; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_finance_purchases IS 'icon: wpforms';


--
-- TOC entry 5098 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN acornassociated_finance_purchases.payer_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_purchases.payer_user_id IS 'labels: 
  en: Payer
new-row: true';


--
-- TOC entry 5099 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN acornassociated_finance_purchases.payer_user_group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_purchases.payer_user_group_id IS 'labels: 
  en: Payer Organisation';


--
-- TOC entry 5100 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN acornassociated_finance_purchases.payee_user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_purchases.payee_user_id IS 'labels: 
  en: Payee
new-row: true';


--
-- TOC entry 5101 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN acornassociated_finance_purchases.payee_user_group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_purchases.payee_user_group_id IS 'labels: 
  en: Payee Organisation';


--
-- TOC entry 359 (class 1259 OID 413824)
-- Name: acornassociated_finance_receipts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_finance_receipts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_id uuid NOT NULL,
    number integer NOT NULL,
    currency_id uuid NOT NULL,
    amount integer NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL
);


ALTER TABLE public.acornassociated_finance_receipts OWNER TO postgres;

--
-- TOC entry 5102 (class 0 OID 0)
-- Dependencies: 359
-- Name: TABLE acornassociated_finance_receipts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_finance_receipts IS 'icon: receipt';


--
-- TOC entry 5103 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN acornassociated_finance_receipts.currency_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_finance_receipts.currency_id IS 'new-row: true';


--
-- TOC entry 342 (class 1259 OID 395394)
-- Name: acornassociated_houseofpeace_events; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_houseofpeace_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    name character varying(1024)
);


ALTER TABLE public.acornassociated_houseofpeace_events OWNER TO justice;

--
-- TOC entry 5104 (class 0 OID 0)
-- Dependencies: 342
-- Name: TABLE acornassociated_houseofpeace_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_houseofpeace_events IS 'icon: route
labels:
  ar: حدث بيت الصلح
labels-plural:
  ar: أحداث بيت الصلح
';


--
-- TOC entry 343 (class 1259 OID 395400)
-- Name: acornassociated_houseofpeace_legalcases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_houseofpeace_legalcases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_houseofpeace_legalcases OWNER TO justice;

--
-- TOC entry 5105 (class 0 OID 0)
-- Dependencies: 343
-- Name: TABLE acornassociated_houseofpeace_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_houseofpeace_legalcases IS 'plugin-icon: heart
icon: hourglass
order: 1
labels:
  en: Community Issue
  ar: قضية بيت الصلح
labels-plural:
  en: Community Issues
  ar: قضايا بيت الصلح
plugin-names:
  en: House Of Peace
  ar: قضية بيت الصلح
';


--
-- TOC entry 318 (class 1259 OID 394818)
-- Name: acornassociated_justice_legalcase_categories; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_legalcase_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    parent_legalcase_category_id uuid
);


ALTER TABLE public.acornassociated_justice_legalcase_categories OWNER TO justice;

--
-- TOC entry 5106 (class 0 OID 0)
-- Dependencies: 318
-- Name: TABLE acornassociated_justice_legalcase_categories; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_justice_legalcase_categories IS 'icon: cat
labels:
  ar: فئة القضية العدلية
labels-plural:
  ar: فئات القضية العدلية
';


--
-- TOC entry 319 (class 1259 OID 394824)
-- Name: acornassociated_justice_legalcase_identifiers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_legalcase_identifiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_justice_legalcase_identifiers OWNER TO justice;

--
-- TOC entry 5107 (class 0 OID 0)
-- Dependencies: 319
-- Name: TABLE acornassociated_justice_legalcase_identifiers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_justice_legalcase_identifiers IS 'icon: unity
labels:
  ar: معرف قضايا العدالة
labels-plural:
  ar: معرفات قضايا العدالة
';


--
-- TOC entry 320 (class 1259 OID 394830)
-- Name: acornassociated_justice_legalcase_legalcase_category; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_legalcase_legalcase_category (
    legalcase_id uuid NOT NULL,
    legalcase_category_id uuid NOT NULL,
    created_at_event_id uuid DEFAULT public.fn_acornassociated_calendar_create_event('legalcase_category'::character varying, NULL::uuid) NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acornassociated_user_get_seed_user() NOT NULL
);


ALTER TABLE public.acornassociated_justice_legalcase_legalcase_category OWNER TO justice;

--
-- TOC entry 5108 (class 0 OID 0)
-- Dependencies: 320
-- Name: TABLE acornassociated_justice_legalcase_legalcase_category; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_justice_legalcase_legalcase_category IS 'labels:
  ar:قضية عدالة فئة القضية
labels-plural:
  ar: قضاية عدالة فئة القضية
';


--
-- TOC entry 321 (class 1259 OID 394833)
-- Name: acornassociated_justice_legalcases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_legalcases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    closed_at_event_id uuid,
    owner_user_group_id uuid
);


ALTER TABLE public.acornassociated_justice_legalcases OWNER TO justice;

--
-- TOC entry 5109 (class 0 OID 0)
-- Dependencies: 321
-- Name: TABLE acornassociated_justice_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_justice_legalcases IS '# Base table for all legal cases
table-type: central
icon: angry
labels:
  en: Case
  ar: قضية عدالة
labels-plural:
  ar: قضاية عدالة
plugin-names:
  ar: قضية عدالة
order: 1
plugin-icon: adjust
';


--
-- TOC entry 5110 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN acornassociated_justice_legalcases.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acornassociated_justice_legalcases.name IS 'labels: 
  en: Identifier
  ku: Nav';


--
-- TOC entry 5111 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN acornassociated_justice_legalcases.closed_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acornassociated_justice_legalcases.closed_at_event_id IS 'labels:
  en: Closed at';


--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 321
-- Name: COLUMN acornassociated_justice_legalcases.owner_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acornassociated_justice_legalcases.owner_user_group_id IS 'labels:
  en: Owner Organisation
';


--
-- TOC entry 344 (class 1259 OID 395459)
-- Name: acornassociated_justice_scanned_documents; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_scanned_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    document path,
    created_by_user_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    legalcase_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_justice_scanned_documents OWNER TO justice;

--
-- TOC entry 387 (class 1259 OID 415289)
-- Name: acornassociated_justice_warrant_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_warrant_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text
);


ALTER TABLE public.acornassociated_justice_warrant_types OWNER TO justice;

--
-- TOC entry 386 (class 1259 OID 415283)
-- Name: acornassociated_justice_warrants; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_justice_warrants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    user_id uuid NOT NULL,
    warrant_type_id uuid,
    legalcase_id uuid NOT NULL,
    revoked_at_event_id uuid
);


ALTER TABLE public.acornassociated_justice_warrants OWNER TO justice;

--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 386
-- Name: TABLE acornassociated_justice_warrants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_justice_warrants IS 'printable: true';


--
-- TOC entry 294 (class 1259 OID 394358)
-- Name: acornassociated_location_addresses; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    number character varying(1024),
    image character varying(2048),
    area_id uuid NOT NULL,
    gps_id uuid,
    server_id uuid NOT NULL,
    created_by_user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    response text,
    lookup_id uuid
);


ALTER TABLE public.acornassociated_location_addresses OWNER TO justice;

--
-- TOC entry 295 (class 1259 OID 394365)
-- Name: acornassociated_location_area_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_area_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_location_area_types OWNER TO justice;

--
-- TOC entry 296 (class 1259 OID 394372)
-- Name: acornassociated_location_areas; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    area_type_id uuid NOT NULL,
    parent_area_id uuid,
    gps_id uuid,
    server_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    is_current_version boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_location_areas OWNER TO justice;

--
-- TOC entry 297 (class 1259 OID 394381)
-- Name: acornassociated_location_gps; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_gps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    longitude double precision,
    latitude double precision,
    server_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_location_gps OWNER TO justice;

--
-- TOC entry 298 (class 1259 OID 394388)
-- Name: acornassociated_location_locations; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address_id uuid NOT NULL,
    name character varying(2048) NOT NULL,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    user_group_id uuid,
    type_id uuid
);


ALTER TABLE public.acornassociated_location_locations OWNER TO justice;

--
-- TOC entry 299 (class 1259 OID 394395)
-- Name: acornassociated_location_lookup; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_lookup (
    id uuid NOT NULL,
    address character varying(1024) NOT NULL,
    city character varying(1024) NOT NULL,
    zip character varying(1024) NOT NULL,
    country_code character varying(1024) NOT NULL,
    state_code character varying(1024) NOT NULL,
    latitude character varying(1024) NOT NULL,
    longitude character varying(1024) NOT NULL,
    vicinity character varying(1024) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.acornassociated_location_lookup OWNER TO justice;

--
-- TOC entry 300 (class 1259 OID 394401)
-- Name: acornassociated_location_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_location_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    parent_type_id uuid,
    server_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    colour character varying(1024),
    image character varying(1024)
);


ALTER TABLE public.acornassociated_location_types OWNER TO justice;

--
-- TOC entry 362 (class 1259 OID 413954)
-- Name: acornassociated_lojistiks_brands; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_brands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    image character varying(2048),
    response text,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid
);


ALTER TABLE public.acornassociated_lojistiks_brands OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 413960)
-- Name: acornassociated_lojistiks_containers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_containers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    name character varying(1024),
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_containers OWNER TO postgres;

--
-- TOC entry 364 (class 1259 OID 413966)
-- Name: acornassociated_lojistiks_drivers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_drivers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    vehicle_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_drivers OWNER TO postgres;

--
-- TOC entry 365 (class 1259 OID 413972)
-- Name: acornassociated_lojistiks_employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    user_role_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_employees OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 413990)
-- Name: acornassociated_lojistiks_measurement_units; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_measurement_units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    short_name character varying(1024),
    uses_quantity boolean DEFAULT true NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_measurement_units OWNER TO postgres;

--
-- TOC entry 370 (class 1259 OID 414024)
-- Name: acornassociated_lojistiks_offices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_offices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_offices OWNER TO postgres;

--
-- TOC entry 371 (class 1259 OID 414030)
-- Name: acornassociated_lojistiks_people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    last_transfer_location_id uuid,
    last_product_instance_location_id uuid
);


ALTER TABLE public.acornassociated_lojistiks_people OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 414036)
-- Name: acornassociated_lojistiks_product_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_product_attributes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    value character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_product_attributes OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 414042)
-- Name: acornassociated_lojistiks_product_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_product_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    product_category_type_id uuid NOT NULL,
    parent_product_category_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_product_categories OWNER TO postgres;

--
-- TOC entry 374 (class 1259 OID 414048)
-- Name: acornassociated_lojistiks_product_category_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_product_category_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_product_category_types OWNER TO postgres;

--
-- TOC entry 367 (class 1259 OID 413997)
-- Name: acornassociated_lojistiks_product_instance_transfer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_product_instance_transfer (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    product_instance_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_product_instance_transfer OWNER TO postgres;

--
-- TOC entry 368 (class 1259 OID 414003)
-- Name: acornassociated_lojistiks_product_instances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_product_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    external_identifier character varying(2048),
    asset_class "char" DEFAULT 'C'::"char" NOT NULL,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_product_instances OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 414054)
-- Name: acornassociated_lojistiks_product_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_product_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    sub_product_id uuid NOT NULL,
    quantity integer NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_product_products OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 414060)
-- Name: acornassociated_lojistiks_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    measurement_unit_id uuid NOT NULL,
    brand_id uuid NOT NULL,
    image character varying(2048),
    model_name character varying(2048),
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_products OWNER TO postgres;

--
-- TOC entry 377 (class 1259 OID 414066)
-- Name: acornassociated_lojistiks_products_product_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_products_product_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    product_category_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_products_product_categories OWNER TO postgres;

--
-- TOC entry 378 (class 1259 OID 414084)
-- Name: acornassociated_lojistiks_suppliers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_suppliers OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 414100)
-- Name: acornassociated_lojistiks_transfer_container_product_instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_transfer_container_product_instance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_container_id uuid NOT NULL,
    product_instance_transfer_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_transfer_container_product_instance OWNER TO postgres;

--
-- TOC entry 5114 (class 0 OID 0)
-- Dependencies: 380
-- Name: TABLE acornassociated_lojistiks_transfer_container_product_instance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_lojistiks_transfer_container_product_instance IS 'todo: true';


--
-- TOC entry 5115 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN acornassociated_lojistiks_transfer_container_product_instance.transfer_container_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_lojistiks_transfer_container_product_instance.transfer_container_id IS 'todo: true';


--
-- TOC entry 379 (class 1259 OID 414092)
-- Name: acornassociated_lojistiks_transfer_containers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_transfer_containers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    container_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_transfer_containers OWNER TO postgres;

--
-- TOC entry 5116 (class 0 OID 0)
-- Dependencies: 379
-- Name: TABLE acornassociated_lojistiks_transfer_containers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.acornassociated_lojistiks_transfer_containers IS 'todo: true';


--
-- TOC entry 381 (class 1259 OID 414108)
-- Name: acornassociated_lojistiks_transfer_invoice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_transfer_invoice (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    invoice_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_lojistiks_transfer_invoice OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 414112)
-- Name: acornassociated_lojistiks_transfer_purchase; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_transfer_purchase (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    purchase_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_lojistiks_transfer_purchase OWNER TO postgres;

--
-- TOC entry 369 (class 1259 OID 414011)
-- Name: acornassociated_lojistiks_transfers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_transfers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    driver_id uuid,
    server_id uuid NOT NULL,
    vehicle_id uuid,
    created_by_user_id uuid,
    created_at_event_id uuid,
    response text,
    pre_marked_arrived boolean DEFAULT false NOT NULL,
    sent_at_event_id uuid,
    arrived_at_event_id uuid
);


ALTER TABLE public.acornassociated_lojistiks_transfers OWNER TO postgres;

--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN acornassociated_lojistiks_transfers.response; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_lojistiks_transfers.response IS 'env: APP_DEBUG';


--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN acornassociated_lojistiks_transfers.sent_at_event_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.acornassociated_lojistiks_transfers.sent_at_event_id IS 'new-row: true';


--
-- TOC entry 383 (class 1259 OID 414121)
-- Name: acornassociated_lojistiks_vehicle_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_vehicle_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_vehicle_types OWNER TO postgres;

--
-- TOC entry 384 (class 1259 OID 414129)
-- Name: acornassociated_lojistiks_vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_vehicles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vehicle_type_id uuid NOT NULL,
    registration character varying(1024) NOT NULL,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_vehicles OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 414137)
-- Name: acornassociated_lojistiks_warehouses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acornassociated_lojistiks_warehouses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acornassociated_lojistiks_warehouses OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 394608)
-- Name: acornassociated_messaging_action; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_action (
    message_id uuid NOT NULL,
    action character varying(1024) NOT NULL,
    settings text NOT NULL,
    status uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_action OWNER TO justice;

--
-- TOC entry 306 (class 1259 OID 394613)
-- Name: acornassociated_messaging_label; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_label OWNER TO justice;

--
-- TOC entry 301 (class 1259 OID 394563)
-- Name: acornassociated_messaging_message; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_from_id uuid NOT NULL,
    subject character varying(2048) NOT NULL,
    body text NOT NULL,
    labels character varying(2048),
    "externalID" character varying(2048),
    source character varying(2048),
    mime_type character varying(64),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_message OWNER TO justice;

--
-- TOC entry 5119 (class 0 OID 0)
-- Dependencies: 301
-- Name: TABLE acornassociated_messaging_message; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_messaging_message IS 'table-type: content';


--
-- TOC entry 317 (class 1259 OID 394802)
-- Name: acornassociated_messaging_message_instance; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_message_instance (
    message_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.183819'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_message_instance OWNER TO justice;

--
-- TOC entry 304 (class 1259 OID 394603)
-- Name: acornassociated_messaging_message_message; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_message_message (
    message1_id uuid NOT NULL,
    message2_id uuid NOT NULL,
    relationship integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_message_message OWNER TO justice;

--
-- TOC entry 302 (class 1259 OID 394573)
-- Name: acornassociated_messaging_message_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_message_user (
    message_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_message_user OWNER TO justice;

--
-- TOC entry 303 (class 1259 OID 394588)
-- Name: acornassociated_messaging_message_user_group; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_message_user_group (
    message_id uuid NOT NULL,
    user_group_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_message_user_group OWNER TO justice;

--
-- TOC entry 307 (class 1259 OID 394621)
-- Name: acornassociated_messaging_status; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_status OWNER TO justice;

--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 307
-- Name: TABLE acornassociated_messaging_status; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_messaging_status IS 'table-type: content';


--
-- TOC entry 308 (class 1259 OID 394629)
-- Name: acornassociated_messaging_user_message_status; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_messaging_user_message_status (
    user_id uuid NOT NULL,
    message_id uuid NOT NULL,
    status_id uuid NOT NULL,
    value character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_messaging_user_message_status OWNER TO justice;

--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 308
-- Name: TABLE acornassociated_messaging_user_message_status; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acornassociated_messaging_user_message_status IS 'table-type: content';


--
-- TOC entry 275 (class 1259 OID 394095)
-- Name: acornassociated_servers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_servers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hostname character varying(1024) DEFAULT 'hostname()'::character varying NOT NULL,
    response text,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:18.175619'::timestamp without time zone NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (hostname) STORED,
    location_id uuid
);


ALTER TABLE public.acornassociated_servers OWNER TO justice;

--
-- TOC entry 346 (class 1259 OID 412558)
-- Name: acornassociated_university_course_teacher; Type: TABLE; Schema: public; Owner: sanchez
--

CREATE TABLE public.acornassociated_university_course_teacher (
    course_id uuid NOT NULL,
    teacher_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_university_course_teacher OWNER TO sanchez;

--
-- TOC entry 347 (class 1259 OID 412561)
-- Name: acornassociated_university_courses; Type: TABLE; Schema: public; Owner: sanchez
--

CREATE TABLE public.acornassociated_university_courses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acornassociated_university_courses OWNER TO sanchez;

--
-- TOC entry 348 (class 1259 OID 412567)
-- Name: acornassociated_university_students; Type: TABLE; Schema: public; Owner: sanchez
--

CREATE TABLE public.acornassociated_university_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_university_students OWNER TO sanchez;

--
-- TOC entry 349 (class 1259 OID 412571)
-- Name: acornassociated_university_teachers; Type: TABLE; Schema: public; Owner: sanchez
--

CREATE TABLE public.acornassociated_university_teachers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_university_teachers OWNER TO sanchez;

--
-- TOC entry 351 (class 1259 OID 412879)
-- Name: acornassociated_user_language_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_language_user (
    user_id uuid NOT NULL,
    language_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_user_language_user OWNER TO justice;

--
-- TOC entry 350 (class 1259 OID 412871)
-- Name: acornassociated_user_languages; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acornassociated_user_languages OWNER TO justice;

--
-- TOC entry 278 (class 1259 OID 394139)
-- Name: acornassociated_user_mail_blockers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_mail_blockers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    template character varying(255),
    user_id uuid,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_user_mail_blockers OWNER TO justice;

--
-- TOC entry 281 (class 1259 OID 394169)
-- Name: acornassociated_user_roles; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    permissions text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_user_roles OWNER TO justice;

--
-- TOC entry 277 (class 1259 OID 394128)
-- Name: acornassociated_user_throttle; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_throttle (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    ip_address character varying(255),
    attempts integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp(0) without time zone,
    is_suspended boolean DEFAULT false NOT NULL,
    suspended_at timestamp(0) without time zone,
    is_banned boolean DEFAULT false NOT NULL,
    banned_at timestamp(0) without time zone
);


ALTER TABLE public.acornassociated_user_throttle OWNER TO justice;

--
-- TOC entry 280 (class 1259 OID 394162)
-- Name: acornassociated_user_user_group; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_user_group (
    user_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acornassociated_user_user_group OWNER TO justice;

--
-- TOC entry 345 (class 1259 OID 404475)
-- Name: acornassociated_user_user_group_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_user_group_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    colour character varying(1024),
    image character varying(1024)
);


ALTER TABLE public.acornassociated_user_user_group_types OWNER TO justice;

--
-- TOC entry 279 (class 1259 OID 394153)
-- Name: acornassociated_user_user_groups; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_user_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    parent_user_group_id uuid,
    nest_left integer,
    nest_right integer,
    nest_depth integer,
    type_id uuid,
    colour character varying(1024),
    image character varying(1024)
);


ALTER TABLE public.acornassociated_user_user_groups OWNER TO justice;

--
-- TOC entry 276 (class 1259 OID 394115)
-- Name: acornassociated_user_users; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acornassociated_user_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    email character varying(255),
    password character varying(255),
    activation_code character varying(255),
    persist_code character varying(255),
    reset_password_code character varying(255),
    permissions text,
    is_activated boolean DEFAULT false NOT NULL,
    activated_at timestamp(0) without time zone,
    last_login timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    username character varying(255),
    surname character varying(255),
    deleted_at timestamp(0) without time zone,
    last_seen timestamp(0) without time zone,
    is_guest boolean DEFAULT false NOT NULL,
    is_superuser boolean DEFAULT false NOT NULL,
    created_ip_address character varying(255),
    last_ip_address character varying(255),
    acornassociated_imap_username character varying(255),
    acornassociated_imap_password character varying(255),
    acornassociated_imap_server character varying(255),
    acornassociated_imap_port integer,
    acornassociated_imap_protocol character varying(255),
    acornassociated_imap_encryption character varying(255),
    acornassociated_imap_authentication character varying(255),
    acornassociated_imap_validate_cert boolean,
    acornassociated_smtp_server character varying(255),
    acornassociated_smtp_port character varying(255),
    acornassociated_smtp_encryption character varying(255),
    acornassociated_smtp_authentication character varying(255),
    acornassociated_smtp_username character varying(255),
    acornassociated_smtp_password character varying(255),
    acornassociated_messaging_sounds boolean,
    acornassociated_messaging_email_notifications character(1),
    acornassociated_messaging_autocreated boolean,
    acornassociated_imap_last_fetch timestamp(0) without time zone,
    acornassociated_default_calendar uuid,
    acornassociated_start_of_week integer,
    acornassociated_default_event_time_from date,
    acornassociated_default_event_time_to date,
    is_system_user boolean DEFAULT false
);


ALTER TABLE public.acornassociated_user_users OWNER TO justice;

--
-- TOC entry 263 (class 1259 OID 393992)
-- Name: backend_access_log; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_access_log (
    id integer NOT NULL,
    user_id integer NOT NULL,
    ip_address character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.backend_access_log OWNER TO justice;

--
-- TOC entry 262 (class 1259 OID 393991)
-- Name: backend_access_log_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_access_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_access_log_id_seq OWNER TO justice;

--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 262
-- Name: backend_access_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_access_log_id_seq OWNED BY public.backend_access_log.id;


--
-- TOC entry 256 (class 1259 OID 393956)
-- Name: backend_user_groups; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    code character varying(255),
    description text,
    is_new_user_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public.backend_user_groups OWNER TO justice;

--
-- TOC entry 255 (class 1259 OID 393955)
-- Name: backend_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_groups_id_seq OWNER TO justice;

--
-- TOC entry 5123 (class 0 OID 0)
-- Dependencies: 255
-- Name: backend_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_groups_id_seq OWNED BY public.backend_user_groups.id;


--
-- TOC entry 261 (class 1259 OID 393982)
-- Name: backend_user_preferences; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.backend_user_preferences OWNER TO justice;

--
-- TOC entry 260 (class 1259 OID 393981)
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_preferences_id_seq OWNER TO justice;

--
-- TOC entry 5124 (class 0 OID 0)
-- Dependencies: 260
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_preferences_id_seq OWNED BY public.backend_user_preferences.id;


--
-- TOC entry 265 (class 1259 OID 394004)
-- Name: backend_user_roles; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_roles (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    permissions text,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.backend_user_roles OWNER TO justice;

--
-- TOC entry 264 (class 1259 OID 394003)
-- Name: backend_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_roles_id_seq OWNER TO justice;

--
-- TOC entry 5125 (class 0 OID 0)
-- Dependencies: 264
-- Name: backend_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_roles_id_seq OWNED BY public.backend_user_roles.id;


--
-- TOC entry 259 (class 1259 OID 393970)
-- Name: backend_user_throttle; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_throttle (
    id integer NOT NULL,
    user_id integer,
    ip_address character varying(255),
    attempts integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp(0) without time zone,
    is_suspended boolean DEFAULT false NOT NULL,
    suspended_at timestamp(0) without time zone,
    is_banned boolean DEFAULT false NOT NULL,
    banned_at timestamp(0) without time zone
);


ALTER TABLE public.backend_user_throttle OWNER TO justice;

--
-- TOC entry 258 (class 1259 OID 393969)
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_throttle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_throttle_id_seq OWNER TO justice;

--
-- TOC entry 5126 (class 0 OID 0)
-- Dependencies: 258
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_throttle_id_seq OWNED BY public.backend_user_throttle.id;


--
-- TOC entry 254 (class 1259 OID 393939)
-- Name: backend_users; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    login character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    activation_code character varying(255),
    persist_code character varying(255),
    reset_password_code character varying(255),
    permissions text,
    is_activated boolean DEFAULT false NOT NULL,
    role_id integer,
    activated_at timestamp(0) without time zone,
    last_login timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    deleted_at timestamp(0) without time zone,
    is_superuser boolean DEFAULT false NOT NULL,
    metadata text,
    acornassociated_url character varying(2048),
    acornassociated_user_user_id uuid
);


ALTER TABLE public.backend_users OWNER TO justice;

--
-- TOC entry 257 (class 1259 OID 393964)
-- Name: backend_users_groups; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_users_groups (
    user_id integer NOT NULL,
    user_group_id integer NOT NULL,
    deleted_at timestamp(0) without time zone
);


ALTER TABLE public.backend_users_groups OWNER TO justice;

--
-- TOC entry 253 (class 1259 OID 393938)
-- Name: backend_users_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_users_id_seq OWNER TO justice;

--
-- TOC entry 5127 (class 0 OID 0)
-- Dependencies: 253
-- Name: backend_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_users_id_seq OWNED BY public.backend_users.id;


--
-- TOC entry 245 (class 1259 OID 393887)
-- Name: cache; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO justice;

--
-- TOC entry 267 (class 1259 OID 394017)
-- Name: cms_theme_data; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cms_theme_data (
    id integer NOT NULL,
    theme character varying(255),
    data text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_data OWNER TO justice;

--
-- TOC entry 266 (class 1259 OID 394016)
-- Name: cms_theme_data_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.cms_theme_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_data_id_seq OWNER TO justice;

--
-- TOC entry 5128 (class 0 OID 0)
-- Dependencies: 266
-- Name: cms_theme_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.cms_theme_data_id_seq OWNED BY public.cms_theme_data.id;


--
-- TOC entry 269 (class 1259 OID 394027)
-- Name: cms_theme_logs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cms_theme_logs (
    id integer NOT NULL,
    type character varying(20) NOT NULL,
    theme character varying(255),
    template character varying(255),
    old_template character varying(255),
    content text,
    old_content text,
    user_id integer,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_logs OWNER TO justice;

--
-- TOC entry 268 (class 1259 OID 394026)
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.cms_theme_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_logs_id_seq OWNER TO justice;

--
-- TOC entry 5129 (class 0 OID 0)
-- Dependencies: 268
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.cms_theme_logs_id_seq OWNED BY public.cms_theme_logs.id;


--
-- TOC entry 271 (class 1259 OID 394039)
-- Name: cms_theme_templates; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cms_theme_templates (
    id integer NOT NULL,
    source character varying(255) NOT NULL,
    path character varying(255) NOT NULL,
    content text NOT NULL,
    file_size integer NOT NULL,
    updated_at timestamp(0) without time zone,
    deleted_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_templates OWNER TO justice;

--
-- TOC entry 270 (class 1259 OID 394038)
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.cms_theme_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_templates_id_seq OWNER TO justice;

--
-- TOC entry 5130 (class 0 OID 0)
-- Dependencies: 270
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.cms_theme_templates_id_seq OWNED BY public.cms_theme_templates.id;


--
-- TOC entry 223 (class 1259 OID 393763)
-- Name: deferred_bindings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.deferred_bindings (
    id integer NOT NULL,
    master_type character varying(255) NOT NULL,
    master_field character varying(255) NOT NULL,
    slave_type character varying(255) NOT NULL,
    slave_id character varying(255) NOT NULL,
    session_key character varying(255) NOT NULL,
    is_bind boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    pivot_data text
);


ALTER TABLE public.deferred_bindings OWNER TO justice;

--
-- TOC entry 222 (class 1259 OID 393762)
-- Name: deferred_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.deferred_bindings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deferred_bindings_id_seq OWNER TO justice;

--
-- TOC entry 5131 (class 0 OID 0)
-- Dependencies: 222
-- Name: deferred_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.deferred_bindings_id_seq OWNED BY public.deferred_bindings.id;


--
-- TOC entry 249 (class 1259 OID 393907)
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.failed_jobs (
    id integer NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    failed_at timestamp(0) without time zone,
    exception text,
    uuid character varying(255)
);


ALTER TABLE public.failed_jobs OWNER TO justice;

--
-- TOC entry 248 (class 1259 OID 393906)
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.failed_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO justice;

--
-- TOC entry 5132 (class 0 OID 0)
-- Dependencies: 248
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- TOC entry 252 (class 1259 OID 393931)
-- Name: job_batches; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO justice;

--
-- TOC entry 239 (class 1259 OID 393851)
-- Name: jobs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO justice;

--
-- TOC entry 238 (class 1259 OID 393850)
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO justice;

--
-- TOC entry 5133 (class 0 OID 0)
-- Dependencies: 238
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- TOC entry 221 (class 1259 OID 393756)
-- Name: migrations; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO justice;

--
-- TOC entry 220 (class 1259 OID 393755)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO justice;

--
-- TOC entry 5134 (class 0 OID 0)
-- Dependencies: 220
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 285 (class 1259 OID 394189)
-- Name: winter_location_countries; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_location_countries (
    id integer NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.winter_location_countries OWNER TO justice;

--
-- TOC entry 284 (class 1259 OID 394188)
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_location_countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNER TO justice;

--
-- TOC entry 5135 (class 0 OID 0)
-- Dependencies: 284
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNED BY public.winter_location_countries.id;


--
-- TOC entry 283 (class 1259 OID 394178)
-- Name: winter_location_states; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_location_states (
    id integer NOT NULL,
    country_id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.winter_location_states OWNER TO justice;

--
-- TOC entry 282 (class 1259 OID 394177)
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_location_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_states_id_seq OWNER TO justice;

--
-- TOC entry 5136 (class 0 OID 0)
-- Dependencies: 282
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_location_states_id_seq OWNED BY public.winter_location_states.id;


--
-- TOC entry 289 (class 1259 OID 394212)
-- Name: winter_translate_attributes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_attributes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    attribute_data text
);


ALTER TABLE public.winter_translate_attributes OWNER TO justice;

--
-- TOC entry 288 (class 1259 OID 394211)
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_attributes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNER TO justice;

--
-- TOC entry 5137 (class 0 OID 0)
-- Dependencies: 288
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNED BY public.winter_translate_attributes.id;


--
-- TOC entry 293 (class 1259 OID 394237)
-- Name: winter_translate_indexes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_indexes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    item character varying(255),
    value text
);


ALTER TABLE public.winter_translate_indexes OWNER TO justice;

--
-- TOC entry 292 (class 1259 OID 394236)
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_indexes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNER TO justice;

--
-- TOC entry 5138 (class 0 OID 0)
-- Dependencies: 292
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNED BY public.winter_translate_indexes.id;


--
-- TOC entry 291 (class 1259 OID 394224)
-- Name: winter_translate_locales; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_locales (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255),
    is_default boolean DEFAULT false NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.winter_translate_locales OWNER TO justice;

--
-- TOC entry 290 (class 1259 OID 394223)
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_locales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNER TO justice;

--
-- TOC entry 5139 (class 0 OID 0)
-- Dependencies: 290
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNED BY public.winter_translate_locales.id;


--
-- TOC entry 287 (class 1259 OID 394202)
-- Name: winter_translate_messages; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_messages (
    id integer NOT NULL,
    code character varying(255),
    message_data text,
    found boolean DEFAULT true NOT NULL,
    code_pre_2_1_0 character varying(255)
);


ALTER TABLE public.winter_translate_messages OWNER TO justice;

--
-- TOC entry 286 (class 1259 OID 394201)
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNER TO justice;

--
-- TOC entry 5140 (class 0 OID 0)
-- Dependencies: 286
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNED BY public.winter_translate_messages.id;


--
-- TOC entry 244 (class 1259 OID 393879)
-- Name: sessions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    payload text,
    last_activity integer,
    user_id integer,
    ip_address character varying(45),
    user_agent text
);


ALTER TABLE public.sessions OWNER TO justice;

--
-- TOC entry 241 (class 1259 OID 393860)
-- Name: system_event_logs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_event_logs (
    id integer NOT NULL,
    level character varying(255),
    message text,
    details text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_event_logs OWNER TO justice;

--
-- TOC entry 240 (class 1259 OID 393859)
-- Name: system_event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_event_logs_id_seq OWNER TO justice;

--
-- TOC entry 5141 (class 0 OID 0)
-- Dependencies: 240
-- Name: system_event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_event_logs_id_seq OWNED BY public.system_event_logs.id;


--
-- TOC entry 225 (class 1259 OID 393777)
-- Name: system_files; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_files (
    id integer NOT NULL,
    disk_name character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_size integer NOT NULL,
    content_type character varying(255) NOT NULL,
    title character varying(255),
    description text,
    field character varying(255),
    attachment_id character varying(255),
    attachment_type character varying(255),
    is_public boolean DEFAULT true NOT NULL,
    sort_order integer,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_files OWNER TO justice;

--
-- TOC entry 224 (class 1259 OID 393776)
-- Name: system_files_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_files_id_seq OWNER TO justice;

--
-- TOC entry 5142 (class 0 OID 0)
-- Dependencies: 224
-- Name: system_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_files_id_seq OWNED BY public.system_files.id;


--
-- TOC entry 237 (class 1259 OID 393841)
-- Name: system_mail_layouts; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_mail_layouts (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    content_html text,
    content_text text,
    content_css text,
    is_locked boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    options text
);


ALTER TABLE public.system_mail_layouts OWNER TO justice;

--
-- TOC entry 236 (class 1259 OID 393840)
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_mail_layouts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_layouts_id_seq OWNER TO justice;

--
-- TOC entry 5143 (class 0 OID 0)
-- Dependencies: 236
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_mail_layouts_id_seq OWNED BY public.system_mail_layouts.id;


--
-- TOC entry 251 (class 1259 OID 393918)
-- Name: system_mail_partials; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_mail_partials (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    content_html text,
    content_text text,
    is_custom boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_mail_partials OWNER TO justice;

--
-- TOC entry 250 (class 1259 OID 393917)
-- Name: system_mail_partials_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_mail_partials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_partials_id_seq OWNER TO justice;

--
-- TOC entry 5144 (class 0 OID 0)
-- Dependencies: 250
-- Name: system_mail_partials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_mail_partials_id_seq OWNED BY public.system_mail_partials.id;


--
-- TOC entry 235 (class 1259 OID 393830)
-- Name: system_mail_templates; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_mail_templates (
    id integer NOT NULL,
    code character varying(255),
    subject character varying(255),
    description text,
    content_html text,
    content_text text,
    layout_id integer,
    is_custom boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_mail_templates OWNER TO justice;

--
-- TOC entry 234 (class 1259 OID 393829)
-- Name: system_mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_mail_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_templates_id_seq OWNER TO justice;

--
-- TOC entry 5145 (class 0 OID 0)
-- Dependencies: 234
-- Name: system_mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_mail_templates_id_seq OWNED BY public.system_mail_templates.id;


--
-- TOC entry 233 (class 1259 OID 393819)
-- Name: system_parameters; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_parameters (
    id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.system_parameters OWNER TO justice;

--
-- TOC entry 232 (class 1259 OID 393818)
-- Name: system_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_parameters_id_seq OWNER TO justice;

--
-- TOC entry 5146 (class 0 OID 0)
-- Dependencies: 232
-- Name: system_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_parameters_id_seq OWNED BY public.system_parameters.id;


--
-- TOC entry 229 (class 1259 OID 393798)
-- Name: system_plugin_history; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_plugin_history (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    type character varying(20) NOT NULL,
    version character varying(50) NOT NULL,
    detail text,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.system_plugin_history OWNER TO justice;

--
-- TOC entry 228 (class 1259 OID 393797)
-- Name: system_plugin_history_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_plugin_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_history_id_seq OWNER TO justice;

--
-- TOC entry 5147 (class 0 OID 0)
-- Dependencies: 228
-- Name: system_plugin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_plugin_history_id_seq OWNED BY public.system_plugin_history.id;


--
-- TOC entry 227 (class 1259 OID 393790)
-- Name: system_plugin_versions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_plugin_versions (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    version character varying(50) NOT NULL,
    created_at timestamp(0) without time zone,
    is_disabled boolean DEFAULT false NOT NULL,
    is_frozen boolean DEFAULT false NOT NULL,
    acornassociated_infrastructure boolean DEFAULT false NOT NULL
);


ALTER TABLE public.system_plugin_versions OWNER TO justice;

--
-- TOC entry 226 (class 1259 OID 393789)
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_plugin_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_versions_id_seq OWNER TO justice;

--
-- TOC entry 5148 (class 0 OID 0)
-- Dependencies: 226
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_plugin_versions_id_seq OWNED BY public.system_plugin_versions.id;


--
-- TOC entry 243 (class 1259 OID 393870)
-- Name: system_request_logs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_request_logs (
    id integer NOT NULL,
    status_code integer,
    url character varying(255),
    referer text,
    count integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_request_logs OWNER TO justice;

--
-- TOC entry 242 (class 1259 OID 393869)
-- Name: system_request_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_request_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_request_logs_id_seq OWNER TO justice;

--
-- TOC entry 5149 (class 0 OID 0)
-- Dependencies: 242
-- Name: system_request_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_request_logs_id_seq OWNED BY public.system_request_logs.id;


--
-- TOC entry 247 (class 1259 OID 393895)
-- Name: system_revisions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_revisions (
    id integer NOT NULL,
    user_id integer,
    field character varying(255),
    "cast" character varying(255),
    old_value text,
    new_value text,
    revisionable_type character varying(255) NOT NULL,
    revisionable_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_revisions OWNER TO justice;

--
-- TOC entry 246 (class 1259 OID 393894)
-- Name: system_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_revisions_id_seq OWNER TO justice;

--
-- TOC entry 5150 (class 0 OID 0)
-- Dependencies: 246
-- Name: system_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_revisions_id_seq OWNED BY public.system_revisions.id;


--
-- TOC entry 231 (class 1259 OID 393809)
-- Name: system_settings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    item character varying(255),
    value text
);


ALTER TABLE public.system_settings OWNER TO justice;

--
-- TOC entry 230 (class 1259 OID 393808)
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_settings_id_seq OWNER TO justice;

--
-- TOC entry 5151 (class 0 OID 0)
-- Dependencies: 230
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- TOC entry 3963 (class 2604 OID 393995)
-- Name: backend_access_log id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_access_log ALTER COLUMN id SET DEFAULT nextval('public.backend_access_log_id_seq'::regclass);


--
-- TOC entry 3956 (class 2604 OID 393959)
-- Name: backend_user_groups id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_groups ALTER COLUMN id SET DEFAULT nextval('public.backend_user_groups_id_seq'::regclass);


--
-- TOC entry 3962 (class 2604 OID 393985)
-- Name: backend_user_preferences id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_preferences ALTER COLUMN id SET DEFAULT nextval('public.backend_user_preferences_id_seq'::regclass);


--
-- TOC entry 3964 (class 2604 OID 394007)
-- Name: backend_user_roles id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_roles ALTER COLUMN id SET DEFAULT nextval('public.backend_user_roles_id_seq'::regclass);


--
-- TOC entry 3958 (class 2604 OID 393973)
-- Name: backend_user_throttle id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_throttle ALTER COLUMN id SET DEFAULT nextval('public.backend_user_throttle_id_seq'::regclass);


--
-- TOC entry 3953 (class 2604 OID 393942)
-- Name: backend_users id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users ALTER COLUMN id SET DEFAULT nextval('public.backend_users_id_seq'::regclass);


--
-- TOC entry 3966 (class 2604 OID 394020)
-- Name: cms_theme_data id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_data ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_data_id_seq'::regclass);


--
-- TOC entry 3967 (class 2604 OID 394030)
-- Name: cms_theme_logs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_logs ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_logs_id_seq'::regclass);


--
-- TOC entry 3968 (class 2604 OID 394042)
-- Name: cms_theme_templates id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_templates ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_templates_id_seq'::regclass);


--
-- TOC entry 3930 (class 2604 OID 393766)
-- Name: deferred_bindings id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.deferred_bindings ALTER COLUMN id SET DEFAULT nextval('public.deferred_bindings_id_seq'::regclass);


--
-- TOC entry 3950 (class 2604 OID 393910)
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- TOC entry 3945 (class 2604 OID 393854)
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- TOC entry 3929 (class 2604 OID 393759)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 3946 (class 2604 OID 393863)
-- Name: system_event_logs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_event_logs ALTER COLUMN id SET DEFAULT nextval('public.system_event_logs_id_seq'::regclass);


--
-- TOC entry 3932 (class 2604 OID 393780)
-- Name: system_files id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_files ALTER COLUMN id SET DEFAULT nextval('public.system_files_id_seq'::regclass);


--
-- TOC entry 3943 (class 2604 OID 393844)
-- Name: system_mail_layouts id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_layouts ALTER COLUMN id SET DEFAULT nextval('public.system_mail_layouts_id_seq'::regclass);


--
-- TOC entry 3951 (class 2604 OID 393921)
-- Name: system_mail_partials id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_partials ALTER COLUMN id SET DEFAULT nextval('public.system_mail_partials_id_seq'::regclass);


--
-- TOC entry 3941 (class 2604 OID 393833)
-- Name: system_mail_templates id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_templates ALTER COLUMN id SET DEFAULT nextval('public.system_mail_templates_id_seq'::regclass);


--
-- TOC entry 3940 (class 2604 OID 393822)
-- Name: system_parameters id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_parameters ALTER COLUMN id SET DEFAULT nextval('public.system_parameters_id_seq'::regclass);


--
-- TOC entry 3938 (class 2604 OID 393801)
-- Name: system_plugin_history id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_history ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_history_id_seq'::regclass);


--
-- TOC entry 3934 (class 2604 OID 393793)
-- Name: system_plugin_versions id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_versions ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_versions_id_seq'::regclass);


--
-- TOC entry 3947 (class 2604 OID 393873)
-- Name: system_request_logs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_request_logs ALTER COLUMN id SET DEFAULT nextval('public.system_request_logs_id_seq'::regclass);


--
-- TOC entry 3949 (class 2604 OID 393898)
-- Name: system_revisions id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_revisions ALTER COLUMN id SET DEFAULT nextval('public.system_revisions_id_seq'::regclass);


--
-- TOC entry 3939 (class 2604 OID 393812)
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- TOC entry 3987 (class 2604 OID 394192)
-- Name: winter_location_countries id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_countries ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_countries_id_seq'::regclass);


--
-- TOC entry 3985 (class 2604 OID 394181)
-- Name: winter_location_states id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_states ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_states_id_seq'::regclass);


--
-- TOC entry 3992 (class 2604 OID 394215)
-- Name: winter_translate_attributes id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_attributes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_attributes_id_seq'::regclass);


--
-- TOC entry 3997 (class 2604 OID 394240)
-- Name: winter_translate_indexes id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_indexes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_indexes_id_seq'::regclass);


--
-- TOC entry 3993 (class 2604 OID 394227)
-- Name: winter_translate_locales id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_locales ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_locales_id_seq'::regclass);


--
-- TOC entry 3990 (class 2604 OID 394205)
-- Name: winter_translate_messages id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_messages ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_messages_id_seq'::regclass);


--
-- TOC entry 4445 (class 2606 OID 414146)
-- Name: acornassociated_lojistiks_computer_products computer_products_pkey; Type: CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_computer_products
    ADD CONSTRAINT computer_products_pkey PRIMARY KEY (id);


--
-- TOC entry 4451 (class 2606 OID 414148)
-- Name: acornassociated_lojistiks_electronic_products office_products_pkey; Type: CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_electronic_products
    ADD CONSTRAINT office_products_pkey PRIMARY KEY (id);


--
-- TOC entry 4343 (class 2606 OID 394840)
-- Name: acornassociated_justice_legalcases acornassocaited_justice_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcases
    ADD CONSTRAINT acornassocaited_justice_cases_pkey PRIMARY KEY (id);


--
-- TOC entry 4366 (class 2606 OID 395024)
-- Name: acornassociated_criminal_defendant_crimes acornassocaited_justice_defendant_crime_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_crimes
    ADD CONSTRAINT acornassocaited_justice_defendant_crime_pkey PRIMARY KEY (id);


--
-- TOC entry 4324 (class 2606 OID 394744)
-- Name: acornassociated_calendar_event_part acornassociated_calendar_event_part_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_part
    ADD CONSTRAINT acornassociated_calendar_event_part_pkey PRIMARY KEY (id);


--
-- TOC entry 4322 (class 2606 OID 394713)
-- Name: acornassociated_calendar_event acornassociated_calendar_event_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event
    ADD CONSTRAINT acornassociated_calendar_event_pkey PRIMARY KEY (id);


--
-- TOC entry 4320 (class 2606 OID 394688)
-- Name: acornassociated_calendar_event_status acornassociated_calendar_event_status_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_status
    ADD CONSTRAINT acornassociated_calendar_event_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4318 (class 2606 OID 394680)
-- Name: acornassociated_calendar_event_type acornassociated_calendar_event_type_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_type
    ADD CONSTRAINT acornassociated_calendar_event_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4331 (class 2606 OID 394791)
-- Name: acornassociated_calendar_event_user_group acornassociated_calendar_event_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user_group
    ADD CONSTRAINT acornassociated_calendar_event_user_group_pkey PRIMARY KEY (event_part_id, user_group_id);


--
-- TOC entry 4329 (class 2606 OID 404474)
-- Name: acornassociated_calendar_event_user acornassociated_calendar_event_user_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user
    ADD CONSTRAINT acornassociated_calendar_event_user_pkey PRIMARY KEY (event_part_id, user_id);


--
-- TOC entry 4327 (class 2606 OID 394763)
-- Name: acornassociated_calendar_instance acornassociated_calendar_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_instance
    ADD CONSTRAINT acornassociated_calendar_instance_pkey PRIMARY KEY (id);


--
-- TOC entry 4316 (class 2606 OID 394670)
-- Name: acornassociated_calendar acornassociated_calendar_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar
    ADD CONSTRAINT acornassociated_calendar_pkey PRIMARY KEY (id);


--
-- TOC entry 4338 (class 2606 OID 394842)
-- Name: acornassociated_justice_legalcase_identifiers acornassociated_case_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_identifiers
    ADD CONSTRAINT acornassociated_case_identifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 4347 (class 2606 OID 394908)
-- Name: acornassociated_civil_hearings acornassociated_civil_hearings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_hearings
    ADD CONSTRAINT acornassociated_civil_hearings_pkey PRIMARY KEY (id);


--
-- TOC entry 4350 (class 2606 OID 394910)
-- Name: acornassociated_civil_legalcases acornassociated_civil_legalcases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_legalcases
    ADD CONSTRAINT acornassociated_civil_legalcases_pkey PRIMARY KEY (id);


--
-- TOC entry 4353 (class 2606 OID 395026)
-- Name: acornassociated_criminal_appeals acornassociated_criminal_appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_appeals
    ADD CONSTRAINT acornassociated_criminal_appeals_pkey PRIMARY KEY (id);


--
-- TOC entry 4419 (class 2606 OID 412901)
-- Name: acornassociated_criminal_defendant_detentions acornassociated_criminal_defendant_detentions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_detentions
    ADD CONSTRAINT acornassociated_criminal_defendant_detentions_pkey PRIMARY KEY (id);


--
-- TOC entry 4427 (class 2606 OID 412923)
-- Name: acornassociated_criminal_detention_methods acornassociated_criminal_detention_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_detention_methods
    ADD CONSTRAINT acornassociated_criminal_detention_methods_pkey PRIMARY KEY (id);


--
-- TOC entry 4425 (class 2606 OID 412915)
-- Name: acornassociated_criminal_detention_reasons acornassociated_criminal_detention_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_detention_reasons
    ADD CONSTRAINT acornassociated_criminal_detention_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 4376 (class 2606 OID 395028)
-- Name: acornassociated_criminal_legalcase_related_events acornassociated_criminal_legalcase_events_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_related_events
    ADD CONSTRAINT acornassociated_criminal_legalcase_events_pkey PRIMARY KEY (event_id, legalcase_id);


--
-- TOC entry 4383 (class 2606 OID 395030)
-- Name: acornassociated_criminal_legalcases acornassociated_criminal_legalcases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcases
    ADD CONSTRAINT acornassociated_criminal_legalcases_pkey PRIMARY KEY (id);


--
-- TOC entry 4386 (class 2606 OID 395032)
-- Name: acornassociated_criminal_sentence_types acornassociated_criminal_sentence_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_sentence_types
    ADD CONSTRAINT acornassociated_criminal_sentence_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4388 (class 2606 OID 395034)
-- Name: acornassociated_criminal_session_recordings acornassociated_criminal_session_recordings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_session_recordings
    ADD CONSTRAINT acornassociated_criminal_session_recordings_pkey PRIMARY KEY (id);


--
-- TOC entry 4391 (class 2606 OID 395036)
-- Name: acornassociated_criminal_trial_judges acornassociated_criminal_trial_judge_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_judges
    ADD CONSTRAINT acornassociated_criminal_trial_judge_pkey PRIMARY KEY (id);


--
-- TOC entry 4394 (class 2606 OID 395038)
-- Name: acornassociated_criminal_trial_sessions acornassociated_criminal_trial_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_sessions
    ADD CONSTRAINT acornassociated_criminal_trial_sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 4396 (class 2606 OID 395040)
-- Name: acornassociated_criminal_trials acornassociated_criminal_trials_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trials
    ADD CONSTRAINT acornassociated_criminal_trials_pkey PRIMARY KEY (id);


--
-- TOC entry 4429 (class 2606 OID 413832)
-- Name: acornassociated_finance_currencies acornassociated_finance_currency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_currencies
    ADD CONSTRAINT acornassociated_finance_currency_pkey PRIMARY KEY (id);


--
-- TOC entry 4431 (class 2606 OID 413834)
-- Name: acornassociated_finance_invoices acornassociated_finance_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT acornassociated_finance_invoices_pkey PRIMARY KEY (id);


--
-- TOC entry 4437 (class 2606 OID 413836)
-- Name: acornassociated_finance_payments acornassociated_finance_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_payments
    ADD CONSTRAINT acornassociated_finance_payments_pkey PRIMARY KEY (id);


--
-- TOC entry 4439 (class 2606 OID 413838)
-- Name: acornassociated_finance_purchases acornassociated_finance_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_purchases
    ADD CONSTRAINT acornassociated_finance_purchases_pkey PRIMARY KEY (id);


--
-- TOC entry 4443 (class 2606 OID 413840)
-- Name: acornassociated_finance_receipts acornassociated_finance_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_receipts
    ADD CONSTRAINT acornassociated_finance_receipts_pkey PRIMARY KEY (id);


--
-- TOC entry 4398 (class 2606 OID 395405)
-- Name: acornassociated_houseofpeace_events acornassociated_houseofpeace_events_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_events
    ADD CONSTRAINT acornassociated_houseofpeace_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4400 (class 2606 OID 395407)
-- Name: acornassociated_houseofpeace_legalcases acornassociated_houseofpeace_legalcases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_legalcases
    ADD CONSTRAINT acornassociated_houseofpeace_legalcases_pkey PRIMARY KEY (id);


--
-- TOC entry 4335 (class 2606 OID 394844)
-- Name: acornassociated_justice_legalcase_categories acornassociated_justice_case_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_categories
    ADD CONSTRAINT acornassociated_justice_case_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4340 (class 2606 OID 394846)
-- Name: acornassociated_justice_legalcase_legalcase_category acornassociated_justice_case_category_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_legalcase_category
    ADD CONSTRAINT acornassociated_justice_case_category_pkey PRIMARY KEY (legalcase_id, legalcase_category_id);


--
-- TOC entry 4356 (class 2606 OID 395042)
-- Name: acornassociated_criminal_crime_evidence acornassociated_justice_crime_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_evidence
    ADD CONSTRAINT acornassociated_justice_crime_evidence_pkey PRIMARY KEY (defendant_crime_id, legalcase_evidence_id);


--
-- TOC entry 4359 (class 2606 OID 395044)
-- Name: acornassociated_criminal_crime_sentences acornassociated_justice_crime_sentences_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_sentences
    ADD CONSTRAINT acornassociated_justice_crime_sentences_pkey PRIMARY KEY (id);


--
-- TOC entry 4362 (class 2606 OID 395046)
-- Name: acornassociated_criminal_crime_types acornassociated_justice_crime_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_types
    ADD CONSTRAINT acornassociated_justice_crime_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4364 (class 2606 OID 395048)
-- Name: acornassociated_criminal_crimes acornassociated_justice_crimes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crimes
    ADD CONSTRAINT acornassociated_justice_crimes_pkey PRIMARY KEY (id);


--
-- TOC entry 4370 (class 2606 OID 395050)
-- Name: acornassociated_criminal_legalcase_defendants acornassociated_justice_defendant_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_defendants
    ADD CONSTRAINT acornassociated_justice_defendant_pkey PRIMARY KEY (id);


--
-- TOC entry 4372 (class 2606 OID 395052)
-- Name: acornassociated_criminal_legalcase_evidence acornassociated_justice_legalcase_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_evidence
    ADD CONSTRAINT acornassociated_justice_legalcase_evidence_pkey PRIMARY KEY (id);


--
-- TOC entry 4374 (class 2606 OID 395054)
-- Name: acornassociated_criminal_legalcase_prosecutor acornassociated_justice_legalcase_prosecution_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_prosecutor
    ADD CONSTRAINT acornassociated_justice_legalcase_prosecution_pkey PRIMARY KEY (id);


--
-- TOC entry 4379 (class 2606 OID 395056)
-- Name: acornassociated_criminal_legalcase_plaintiffs acornassociated_justice_legalcase_victims_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_plaintiffs
    ADD CONSTRAINT acornassociated_justice_legalcase_victims_pkey PRIMARY KEY (id);


--
-- TOC entry 4381 (class 2606 OID 395058)
-- Name: acornassociated_criminal_legalcase_witnesses acornassociated_justice_legalcase_witnesses_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_witnesses
    ADD CONSTRAINT acornassociated_justice_legalcase_witnesses_pkey PRIMARY KEY (id);


--
-- TOC entry 4402 (class 2606 OID 395496)
-- Name: acornassociated_justice_scanned_documents acornassociated_justice_scanned_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_scanned_documents
    ADD CONSTRAINT acornassociated_justice_scanned_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 4550 (class 2606 OID 415296)
-- Name: acornassociated_justice_warrant_types acornassociated_justice_warrant_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrant_types
    ADD CONSTRAINT acornassociated_justice_warrant_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4547 (class 2606 OID 415288)
-- Name: acornassociated_justice_warrants acornassociated_justice_warrants_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT acornassociated_justice_warrants_pkey PRIMARY KEY (id);


--
-- TOC entry 4295 (class 2606 OID 394409)
-- Name: acornassociated_location_lookup acornassociated_location_location_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_lookup
    ADD CONSTRAINT acornassociated_location_location_pkey PRIMARY KEY (id);


--
-- TOC entry 4464 (class 2606 OID 414150)
-- Name: acornassociated_lojistiks_employees acornassociated_lojistiks_employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_employees
    ADD CONSTRAINT acornassociated_lojistiks_employees_pkey PRIMARY KEY (id);


--
-- TOC entry 4509 (class 2606 OID 414152)
-- Name: acornassociated_lojistiks_product_products acornassociated_lojistiks_product_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products
    ADD CONSTRAINT acornassociated_lojistiks_product_products_pkey PRIMARY KEY (product_id, sub_product_id);


--
-- TOC entry 4543 (class 2606 OID 414154)
-- Name: acornassociated_lojistiks_warehouses acornassociated_lojistiks_warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_warehouses
    ADD CONSTRAINT acornassociated_lojistiks_warehouses_pkey PRIMARY KEY (id);


--
-- TOC entry 4310 (class 2606 OID 394620)
-- Name: acornassociated_messaging_label acornassociated_messaging_label_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_label
    ADD CONSTRAINT acornassociated_messaging_label_pkey PRIMARY KEY (id);


--
-- TOC entry 4300 (class 2606 OID 394572)
-- Name: acornassociated_messaging_message acornassociated_messaging_message_externalid_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message
    ADD CONSTRAINT acornassociated_messaging_message_externalid_unique UNIQUE ("externalID");


--
-- TOC entry 4333 (class 2606 OID 394807)
-- Name: acornassociated_messaging_message_instance acornassociated_messaging_message_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_instance
    ADD CONSTRAINT acornassociated_messaging_message_instance_pkey PRIMARY KEY (message_id, instance_id);


--
-- TOC entry 4308 (class 2606 OID 394607)
-- Name: acornassociated_messaging_message_message acornassociated_messaging_message_message_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_message
    ADD CONSTRAINT acornassociated_messaging_message_message_pkey PRIMARY KEY (message1_id, message2_id, relationship);


--
-- TOC entry 4302 (class 2606 OID 394570)
-- Name: acornassociated_messaging_message acornassociated_messaging_message_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message
    ADD CONSTRAINT acornassociated_messaging_message_pkey PRIMARY KEY (id);


--
-- TOC entry 4306 (class 2606 OID 394592)
-- Name: acornassociated_messaging_message_user_group acornassociated_messaging_message_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_user_group
    ADD CONSTRAINT acornassociated_messaging_message_user_group_pkey PRIMARY KEY (message_id, user_group_id);


--
-- TOC entry 4304 (class 2606 OID 394577)
-- Name: acornassociated_messaging_message_user acornassociated_messaging_message_user_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_user
    ADD CONSTRAINT acornassociated_messaging_message_user_pkey PRIMARY KEY (message_id, user_id);


--
-- TOC entry 4312 (class 2606 OID 394628)
-- Name: acornassociated_messaging_status acornassociated_messaging_status_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_status
    ADD CONSTRAINT acornassociated_messaging_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4314 (class 2606 OID 394633)
-- Name: acornassociated_messaging_user_message_status acornassociated_messaging_user_message_status_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_user_message_status
    ADD CONSTRAINT acornassociated_messaging_user_message_status_pkey PRIMARY KEY (message_id, status_id);


--
-- TOC entry 4228 (class 2606 OID 394105)
-- Name: acornassociated_servers acornassociated_servers_hostname_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_servers
    ADD CONSTRAINT acornassociated_servers_hostname_unique UNIQUE (hostname);


--
-- TOC entry 4230 (class 2606 OID 394103)
-- Name: acornassociated_servers acornassociated_servers_id_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_servers
    ADD CONSTRAINT acornassociated_servers_id_unique UNIQUE (id);


--
-- TOC entry 4411 (class 2606 OID 412576)
-- Name: acornassociated_university_students acornassociated_university_students_pkey; Type: CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_students
    ADD CONSTRAINT acornassociated_university_students_pkey PRIMARY KEY (id);


--
-- TOC entry 4413 (class 2606 OID 412578)
-- Name: acornassociated_university_teachers acornassociated_university_teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_teachers
    ADD CONSTRAINT acornassociated_university_teachers_pkey PRIMARY KEY (id);


--
-- TOC entry 4417 (class 2606 OID 412883)
-- Name: acornassociated_user_language_user acornassociated_user_language_user_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_language_user
    ADD CONSTRAINT acornassociated_user_language_user_pkey PRIMARY KEY (user_id, language_id);


--
-- TOC entry 4415 (class 2606 OID 412878)
-- Name: acornassociated_user_languages acornassociated_user_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_languages
    ADD CONSTRAINT acornassociated_user_languages_pkey PRIMARY KEY (id);


--
-- TOC entry 4251 (class 2606 OID 394176)
-- Name: acornassociated_user_roles acornassociated_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_roles
    ADD CONSTRAINT acornassociated_user_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4238 (class 2606 OID 394136)
-- Name: acornassociated_user_throttle acornassociated_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_throttle
    ADD CONSTRAINT acornassociated_user_throttle_pkey PRIMARY KEY (id);


--
-- TOC entry 4249 (class 2606 OID 394166)
-- Name: acornassociated_user_user_group acornassociated_user_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_user_group
    ADD CONSTRAINT acornassociated_user_user_group_pkey PRIMARY KEY (user_id, user_group_id);


--
-- TOC entry 4405 (class 2606 OID 404482)
-- Name: acornassociated_user_user_group_types acornassociated_user_user_group_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_user_group_types
    ADD CONSTRAINT acornassociated_user_user_group_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4247 (class 2606 OID 394160)
-- Name: acornassociated_user_user_groups acornassociated_user_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_user_groups
    ADD CONSTRAINT acornassociated_user_user_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 4234 (class 2606 OID 394123)
-- Name: acornassociated_user_users acornassociated_user_users_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_users
    ADD CONSTRAINT acornassociated_user_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4209 (class 2606 OID 393997)
-- Name: backend_access_log backend_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_access_log
    ADD CONSTRAINT backend_access_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4195 (class 2606 OID 393961)
-- Name: backend_user_groups backend_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT backend_user_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 4206 (class 2606 OID 393989)
-- Name: backend_user_preferences backend_user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_preferences
    ADD CONSTRAINT backend_user_preferences_pkey PRIMARY KEY (id);


--
-- TOC entry 4211 (class 2606 OID 394012)
-- Name: backend_user_roles backend_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT backend_user_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4203 (class 2606 OID 393978)
-- Name: backend_user_throttle backend_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_throttle
    ADD CONSTRAINT backend_user_throttle_pkey PRIMARY KEY (id);


--
-- TOC entry 4200 (class 2606 OID 393968)
-- Name: backend_users_groups backend_users_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users_groups
    ADD CONSTRAINT backend_users_groups_pkey PRIMARY KEY (user_id, user_group_id);


--
-- TOC entry 4188 (class 2606 OID 393947)
-- Name: backend_users backend_users_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT backend_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4453 (class 2606 OID 414162)
-- Name: acornassociated_lojistiks_brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- TOC entry 4171 (class 2606 OID 393893)
-- Name: cache cache_key_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_key_unique UNIQUE (key);


--
-- TOC entry 4216 (class 2606 OID 394024)
-- Name: cms_theme_data cms_theme_data_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_data
    ADD CONSTRAINT cms_theme_data_pkey PRIMARY KEY (id);


--
-- TOC entry 4219 (class 2606 OID 394034)
-- Name: cms_theme_logs cms_theme_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_logs
    ADD CONSTRAINT cms_theme_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4225 (class 2606 OID 394046)
-- Name: cms_theme_templates cms_theme_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_templates
    ADD CONSTRAINT cms_theme_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 4456 (class 2606 OID 414164)
-- Name: acornassociated_lojistiks_containers containers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_containers
    ADD CONSTRAINT containers_pkey PRIMARY KEY (id);


--
-- TOC entry 4409 (class 2606 OID 412580)
-- Name: acornassociated_university_courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- TOC entry 4131 (class 2606 OID 393771)
-- Name: deferred_bindings deferred_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.deferred_bindings
    ADD CONSTRAINT deferred_bindings_pkey PRIMARY KEY (id);


--
-- TOC entry 4461 (class 2606 OID 414166)
-- Name: acornassociated_lojistiks_drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- TOC entry 4190 (class 2606 OID 393951)
-- Name: backend_users email_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- TOC entry 4178 (class 2606 OID 393914)
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4180 (class 2606 OID 393928)
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4184 (class 2606 OID 393937)
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4159 (class 2606 OID 393858)
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4280 (class 2606 OID 394411)
-- Name: acornassociated_location_addresses location_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_addresses
    ADD CONSTRAINT location_addresses_pkey PRIMARY KEY (id);


--
-- TOC entry 4283 (class 2606 OID 394413)
-- Name: acornassociated_location_area_types location_area_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_area_types
    ADD CONSTRAINT location_area_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4286 (class 2606 OID 394415)
-- Name: acornassociated_location_areas location_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_areas
    ADD CONSTRAINT location_areas_pkey PRIMARY KEY (id);


--
-- TOC entry 4289 (class 2606 OID 394417)
-- Name: acornassociated_location_gps location_gps_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_gps
    ADD CONSTRAINT location_gps_pkey PRIMARY KEY (id);


--
-- TOC entry 4293 (class 2606 OID 394419)
-- Name: acornassociated_location_locations location_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_locations
    ADD CONSTRAINT location_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 4298 (class 2606 OID 394421)
-- Name: acornassociated_location_types location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_types
    ADD CONSTRAINT location_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4192 (class 2606 OID 393949)
-- Name: backend_users login_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT login_unique UNIQUE (login);


--
-- TOC entry 4468 (class 2606 OID 414172)
-- Name: acornassociated_lojistiks_measurement_units measurement_units_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_measurement_units
    ADD CONSTRAINT measurement_units_pkey PRIMARY KEY (id);


--
-- TOC entry 4127 (class 2606 OID 393761)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4198 (class 2606 OID 393963)
-- Name: backend_user_groups name_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT name_unique UNIQUE (name);


--
-- TOC entry 4486 (class 2606 OID 414174)
-- Name: acornassociated_lojistiks_offices office_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_offices
    ADD CONSTRAINT office_pkey PRIMARY KEY (id);


--
-- TOC entry 4494 (class 2606 OID 414176)
-- Name: acornassociated_lojistiks_people person_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- TOC entry 4498 (class 2606 OID 414178)
-- Name: acornassociated_lojistiks_product_attributes product_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_attributes
    ADD CONSTRAINT product_attributes_pkey PRIMARY KEY (id);


--
-- TOC entry 4503 (class 2606 OID 414180)
-- Name: acornassociated_lojistiks_product_categories product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4507 (class 2606 OID 414182)
-- Name: acornassociated_lojistiks_product_category_types product_category_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_category_types
    ADD CONSTRAINT product_category_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4476 (class 2606 OID 414184)
-- Name: acornassociated_lojistiks_product_instances product_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instances
    ADD CONSTRAINT product_instances_pkey PRIMARY KEY (id);


--
-- TOC entry 4515 (class 2606 OID 414186)
-- Name: acornassociated_lojistiks_products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- TOC entry 4519 (class 2606 OID 414188)
-- Name: acornassociated_lojistiks_products_product_categories products_product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories
    ADD CONSTRAINT products_product_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4258 (class 2606 OID 394197)
-- Name: winter_location_countries rainlab_location_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_countries
    ADD CONSTRAINT rainlab_location_countries_pkey PRIMARY KEY (id);


--
-- TOC entry 4255 (class 2606 OID 394185)
-- Name: winter_location_states rainlab_location_states_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_states
    ADD CONSTRAINT rainlab_location_states_pkey PRIMARY KEY (id);


--
-- TOC entry 4267 (class 2606 OID 394219)
-- Name: winter_translate_attributes rainlab_translate_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_attributes
    ADD CONSTRAINT rainlab_translate_attributes_pkey PRIMARY KEY (id);


--
-- TOC entry 4277 (class 2606 OID 394244)
-- Name: winter_translate_indexes rainlab_translate_indexes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_indexes
    ADD CONSTRAINT rainlab_translate_indexes_pkey PRIMARY KEY (id);


--
-- TOC entry 4271 (class 2606 OID 394233)
-- Name: winter_translate_locales rainlab_translate_locales_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_locales
    ADD CONSTRAINT rainlab_translate_locales_pkey PRIMARY KEY (id);


--
-- TOC entry 4261 (class 2606 OID 394209)
-- Name: winter_translate_messages rainlab_translate_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_messages
    ADD CONSTRAINT rainlab_translate_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 4244 (class 2606 OID 394146)
-- Name: acornassociated_user_mail_blockers rainlab_user_mail_blockers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_mail_blockers
    ADD CONSTRAINT rainlab_user_mail_blockers_pkey PRIMARY KEY (id);


--
-- TOC entry 4214 (class 2606 OID 394014)
-- Name: backend_user_roles role_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT role_unique UNIQUE (name);


--
-- TOC entry 4167 (class 2606 OID 393885)
-- Name: sessions sessions_id_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_id_unique UNIQUE (id);


--
-- TOC entry 4523 (class 2606 OID 414190)
-- Name: acornassociated_lojistiks_suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- TOC entry 4163 (class 2606 OID 393867)
-- Name: system_event_logs system_event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_event_logs
    ADD CONSTRAINT system_event_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4139 (class 2606 OID 393785)
-- Name: system_files system_files_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_files
    ADD CONSTRAINT system_files_pkey PRIMARY KEY (id);


--
-- TOC entry 4157 (class 2606 OID 393849)
-- Name: system_mail_layouts system_mail_layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_layouts
    ADD CONSTRAINT system_mail_layouts_pkey PRIMARY KEY (id);


--
-- TOC entry 4182 (class 2606 OID 393926)
-- Name: system_mail_partials system_mail_partials_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_partials
    ADD CONSTRAINT system_mail_partials_pkey PRIMARY KEY (id);


--
-- TOC entry 4155 (class 2606 OID 393838)
-- Name: system_mail_templates system_mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_templates
    ADD CONSTRAINT system_mail_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 4152 (class 2606 OID 393826)
-- Name: system_parameters system_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_parameters
    ADD CONSTRAINT system_parameters_pkey PRIMARY KEY (id);


--
-- TOC entry 4145 (class 2606 OID 393805)
-- Name: system_plugin_history system_plugin_history_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_history
    ADD CONSTRAINT system_plugin_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4142 (class 2606 OID 393795)
-- Name: system_plugin_versions system_plugin_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_versions
    ADD CONSTRAINT system_plugin_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 4165 (class 2606 OID 393878)
-- Name: system_request_logs system_request_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_request_logs
    ADD CONSTRAINT system_request_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4174 (class 2606 OID 393902)
-- Name: system_revisions system_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_revisions
    ADD CONSTRAINT system_revisions_pkey PRIMARY KEY (id);


--
-- TOC entry 4149 (class 2606 OID 393816)
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 4526 (class 2606 OID 414192)
-- Name: acornassociated_lojistiks_transfer_containers transfer_container_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers
    ADD CONSTRAINT transfer_container_pkey PRIMARY KEY (id);


--
-- TOC entry 4530 (class 2606 OID 414194)
-- Name: acornassociated_lojistiks_transfer_container_product_instance transfer_container_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT transfer_container_products_pkey PRIMARY KEY (id);


--
-- TOC entry 4472 (class 2606 OID 414196)
-- Name: acornassociated_lojistiks_product_instance_transfer transfer_product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer
    ADD CONSTRAINT transfer_product_pkey PRIMARY KEY (id);


--
-- TOC entry 4481 (class 2606 OID 414198)
-- Name: acornassociated_lojistiks_transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


--
-- TOC entry 4537 (class 2606 OID 414200)
-- Name: acornassociated_lojistiks_vehicle_types vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicle_types
    ADD CONSTRAINT vehicle_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4541 (class 2606 OID 414202)
-- Name: acornassociated_lojistiks_vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- TOC entry 4446 (class 1259 OID 414203)
-- Name: dr_acornassociated_lojistiks_computer_products_replica_identity; Type: INDEX; Schema: product; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_computer_products_replica_identity ON product.acornassociated_lojistiks_computer_products USING btree (server_id, id);

ALTER TABLE ONLY product.acornassociated_lojistiks_computer_products REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_computer_products_replica_identity;


--
-- TOC entry 4448 (class 1259 OID 414204)
-- Name: dr_acornassociated_lojistiks_electronic_products_replica_identi; Type: INDEX; Schema: product; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_electronic_products_replica_identi ON product.acornassociated_lojistiks_electronic_products USING btree (server_id, id);

ALTER TABLE ONLY product.acornassociated_lojistiks_electronic_products REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_electronic_products_replica_identi;


--
-- TOC entry 4449 (class 1259 OID 414943)
-- Name: fki_created_at_event_id; Type: INDEX; Schema: product; Owner: postgres
--

CREATE INDEX fki_created_at_event_id ON product.acornassociated_lojistiks_electronic_products USING btree (created_at_event_id);


--
-- TOC entry 4447 (class 1259 OID 414801)
-- Name: fki_server_id; Type: INDEX; Schema: product; Owner: postgres
--

CREATE INDEX fki_server_id ON product.acornassociated_lojistiks_computer_products USING btree (server_id);


--
-- TOC entry 4325 (class 1259 OID 394756)
-- Name: acornassociated_calendar_instance_date_event_part_id_instance_n; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_calendar_instance_date_event_part_id_instance_n ON public.acornassociated_calendar_instance USING btree (date, event_part_id, instance_num);


--
-- TOC entry 4240 (class 1259 OID 394147)
-- Name: acornassociated_user_mail_blockers_email_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_mail_blockers_email_index ON public.acornassociated_user_mail_blockers USING btree (email);


--
-- TOC entry 4241 (class 1259 OID 394148)
-- Name: acornassociated_user_mail_blockers_template_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_mail_blockers_template_index ON public.acornassociated_user_mail_blockers USING btree (template);


--
-- TOC entry 4242 (class 1259 OID 394149)
-- Name: acornassociated_user_mail_blockers_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_mail_blockers_user_id_index ON public.acornassociated_user_mail_blockers USING btree (user_id);


--
-- TOC entry 4236 (class 1259 OID 394138)
-- Name: acornassociated_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_throttle_ip_address_index ON public.acornassociated_user_throttle USING btree (ip_address);


--
-- TOC entry 4239 (class 1259 OID 394137)
-- Name: acornassociated_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_throttle_user_id_index ON public.acornassociated_user_throttle USING btree (user_id);


--
-- TOC entry 4245 (class 1259 OID 394161)
-- Name: acornassociated_user_user_groups_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_user_groups_code_index ON public.acornassociated_user_user_groups USING btree (code);


--
-- TOC entry 4231 (class 1259 OID 394126)
-- Name: acornassociated_user_users_activation_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_users_activation_code_index ON public.acornassociated_user_users USING btree (activation_code);


--
-- TOC entry 4232 (class 1259 OID 394150)
-- Name: acornassociated_user_users_login_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_users_login_index ON public.acornassociated_user_users USING btree (username);


--
-- TOC entry 4235 (class 1259 OID 394127)
-- Name: acornassociated_user_users_reset_password_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acornassociated_user_users_reset_password_code_index ON public.acornassociated_user_users USING btree (reset_password_code);


--
-- TOC entry 4185 (class 1259 OID 393952)
-- Name: act_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX act_code_index ON public.backend_users USING btree (activation_code);


--
-- TOC entry 4186 (class 1259 OID 393954)
-- Name: admin_role_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX admin_role_index ON public.backend_users USING btree (role_id);


--
-- TOC entry 4201 (class 1259 OID 393980)
-- Name: backend_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX backend_user_throttle_ip_address_index ON public.backend_user_throttle USING btree (ip_address);


--
-- TOC entry 4204 (class 1259 OID 393979)
-- Name: backend_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX backend_user_throttle_user_id_index ON public.backend_user_throttle USING btree (user_id);


--
-- TOC entry 4217 (class 1259 OID 394025)
-- Name: cms_theme_data_theme_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_data_theme_index ON public.cms_theme_data USING btree (theme);


--
-- TOC entry 4220 (class 1259 OID 394036)
-- Name: cms_theme_logs_theme_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_logs_theme_index ON public.cms_theme_logs USING btree (theme);


--
-- TOC entry 4221 (class 1259 OID 394035)
-- Name: cms_theme_logs_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_logs_type_index ON public.cms_theme_logs USING btree (type);


--
-- TOC entry 4222 (class 1259 OID 394037)
-- Name: cms_theme_logs_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_logs_user_id_index ON public.cms_theme_logs USING btree (user_id);


--
-- TOC entry 4223 (class 1259 OID 394048)
-- Name: cms_theme_templates_path_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_templates_path_index ON public.cms_theme_templates USING btree (path);


--
-- TOC entry 4226 (class 1259 OID 394047)
-- Name: cms_theme_templates_source_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_templates_source_index ON public.cms_theme_templates USING btree (source);


--
-- TOC entry 4196 (class 1259 OID 394001)
-- Name: code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX code_index ON public.backend_user_groups USING btree (code);


--
-- TOC entry 4128 (class 1259 OID 393773)
-- Name: deferred_bindings_master_field_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_master_field_index ON public.deferred_bindings USING btree (master_field);


--
-- TOC entry 4129 (class 1259 OID 393772)
-- Name: deferred_bindings_master_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_master_type_index ON public.deferred_bindings USING btree (master_type);


--
-- TOC entry 4132 (class 1259 OID 393915)
-- Name: deferred_bindings_session_key_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_session_key_index ON public.deferred_bindings USING btree (session_key);


--
-- TOC entry 4133 (class 1259 OID 393775)
-- Name: deferred_bindings_slave_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_slave_id_index ON public.deferred_bindings USING btree (slave_id);


--
-- TOC entry 4134 (class 1259 OID 393774)
-- Name: deferred_bindings_slave_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_slave_type_index ON public.deferred_bindings USING btree (slave_type);


--
-- TOC entry 4278 (class 1259 OID 394422)
-- Name: dr_acornassociated_location_addresses_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acornassociated_location_addresses_replica_identity ON public.acornassociated_location_addresses USING btree (server_id, id);


--
-- TOC entry 4281 (class 1259 OID 394423)
-- Name: dr_acornassociated_location_area_types_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acornassociated_location_area_types_replica_identity ON public.acornassociated_location_area_types USING btree (server_id, id);


--
-- TOC entry 4284 (class 1259 OID 394424)
-- Name: dr_acornassociated_location_areas_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acornassociated_location_areas_replica_identity ON public.acornassociated_location_areas USING btree (server_id, id);


--
-- TOC entry 4287 (class 1259 OID 394425)
-- Name: dr_acornassociated_location_gps_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acornassociated_location_gps_replica_identity ON public.acornassociated_location_gps USING btree (server_id, id);


--
-- TOC entry 4290 (class 1259 OID 394426)
-- Name: dr_acornassociated_location_location_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acornassociated_location_location_replica_identity ON public.acornassociated_location_locations USING btree (server_id, id);


--
-- TOC entry 4296 (class 1259 OID 394427)
-- Name: dr_acornassociated_location_types_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acornassociated_location_types_replica_identity ON public.acornassociated_location_types USING btree (server_id, id);


--
-- TOC entry 4454 (class 1259 OID 414208)
-- Name: dr_acornassociated_lojistiks_brands_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_brands_replica_identity ON public.acornassociated_lojistiks_brands USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_brands REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_brands_replica_identity;


--
-- TOC entry 4457 (class 1259 OID 414209)
-- Name: dr_acornassociated_lojistiks_containers_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_containers_replica_identity ON public.acornassociated_lojistiks_containers USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_containers REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_containers_replica_identity;


--
-- TOC entry 4459 (class 1259 OID 414210)
-- Name: dr_acornassociated_lojistiks_drivers_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_drivers_replica_identity ON public.acornassociated_lojistiks_drivers USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_drivers_replica_identity;


--
-- TOC entry 4465 (class 1259 OID 414211)
-- Name: dr_acornassociated_lojistiks_employees_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_employees_replica_identity ON public.acornassociated_lojistiks_employees USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_employees REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_employees_replica_identity;


--
-- TOC entry 4466 (class 1259 OID 414214)
-- Name: dr_acornassociated_lojistiks_measurement_units_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_measurement_units_replica_identity ON public.acornassociated_lojistiks_measurement_units USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_measurement_units REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_measurement_units_replica_identity;


--
-- TOC entry 4482 (class 1259 OID 414215)
-- Name: dr_acornassociated_lojistiks_office_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_office_replica_identity ON public.acornassociated_lojistiks_offices USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_offices REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_office_replica_identity;


--
-- TOC entry 4487 (class 1259 OID 414216)
-- Name: dr_acornassociated_lojistiks_people_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_people_replica_identity ON public.acornassociated_lojistiks_people USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_people REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_people_replica_identity;


--
-- TOC entry 4495 (class 1259 OID 414217)
-- Name: dr_acornassociated_lojistiks_product_attributes_replica_identit; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_product_attributes_replica_identit ON public.acornassociated_lojistiks_product_attributes USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_product_attributes REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_product_attributes_replica_identit;


--
-- TOC entry 4499 (class 1259 OID 414218)
-- Name: dr_acornassociated_lojistiks_product_categories_replica_identit; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_product_categories_replica_identit ON public.acornassociated_lojistiks_product_categories USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_product_categories_replica_identit;


--
-- TOC entry 4504 (class 1259 OID 414219)
-- Name: dr_acornassociated_lojistiks_product_category_types_replica_ide; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_product_category_types_replica_ide ON public.acornassociated_lojistiks_product_category_types USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_product_category_types REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_product_category_types_replica_ide;


--
-- TOC entry 4469 (class 1259 OID 414220)
-- Name: dr_acornassociated_lojistiks_product_instance_transfer_replica_; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_product_instance_transfer_replica_ ON public.acornassociated_lojistiks_product_instance_transfer USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_product_instance_transfer_replica_;


--
-- TOC entry 4473 (class 1259 OID 414221)
-- Name: dr_acornassociated_lojistiks_product_instances_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_product_instances_replica_identity ON public.acornassociated_lojistiks_product_instances USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instances REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_product_instances_replica_identity;


--
-- TOC entry 4510 (class 1259 OID 414222)
-- Name: dr_acornassociated_lojistiks_product_products_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_product_products_replica_identity ON public.acornassociated_lojistiks_product_products USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_product_products_replica_identity;


--
-- TOC entry 4516 (class 1259 OID 414223)
-- Name: dr_acornassociated_lojistiks_products_product_categories_replic; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_products_product_categories_replic ON public.acornassociated_lojistiks_products_product_categories USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_products_product_categories_replic;


--
-- TOC entry 4512 (class 1259 OID 414224)
-- Name: dr_acornassociated_lojistiks_products_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_products_replica_identity ON public.acornassociated_lojistiks_products USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_products REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_products_replica_identity;


--
-- TOC entry 4520 (class 1259 OID 414225)
-- Name: dr_acornassociated_lojistiks_suppliers_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_suppliers_replica_identity ON public.acornassociated_lojistiks_suppliers USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_suppliers REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_suppliers_replica_identity;


--
-- TOC entry 4527 (class 1259 OID 414226)
-- Name: dr_acornassociated_lojistiks_transfer_container_product_instanc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_transfer_container_product_instanc ON public.acornassociated_lojistiks_transfer_container_product_instance USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_transfer_container_product_instanc;


--
-- TOC entry 4524 (class 1259 OID 414227)
-- Name: dr_acornassociated_lojistiks_transfer_container_replica_identit; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_transfer_container_replica_identit ON public.acornassociated_lojistiks_transfer_containers USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_transfer_container_replica_identit;


--
-- TOC entry 4477 (class 1259 OID 414228)
-- Name: dr_acornassociated_lojistiks_transfers_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_transfers_replica_identity ON public.acornassociated_lojistiks_transfers USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_transfers_replica_identity;


--
-- TOC entry 4534 (class 1259 OID 414229)
-- Name: dr_acornassociated_lojistiks_vehicle_types_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_vehicle_types_replica_identity ON public.acornassociated_lojistiks_vehicle_types USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicle_types REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_vehicle_types_replica_identity;


--
-- TOC entry 4538 (class 1259 OID 414230)
-- Name: dr_acornassociated_lojistiks_vehicles_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_vehicles_replica_identity ON public.acornassociated_lojistiks_vehicles USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicles REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_vehicles_replica_identity;


--
-- TOC entry 4544 (class 1259 OID 414231)
-- Name: dr_acornassociated_lojistiks_warehouses_replica_identity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX dr_acornassociated_lojistiks_warehouses_replica_identity ON public.acornassociated_lojistiks_warehouses USING btree (server_id, id);

ALTER TABLE ONLY public.acornassociated_lojistiks_warehouses REPLICA IDENTITY USING INDEX dr_acornassociated_lojistiks_warehouses_replica_identity;


--
-- TOC entry 4458 (class 1259 OID 415156)
-- Name: fki_acornassociated_lojistiks_containers_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_containers_created_at_event_id ON public.acornassociated_lojistiks_containers USING btree (created_at_event_id);


--
-- TOC entry 4462 (class 1259 OID 415192)
-- Name: fki_acornassociated_lojistiks_drivers_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_drivers_created_at_event_id ON public.acornassociated_lojistiks_drivers USING btree (created_at_event_id);


--
-- TOC entry 4483 (class 1259 OID 415144)
-- Name: fki_acornassociated_lojistiks_offices_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_offices_created_at_event_id ON public.acornassociated_lojistiks_offices USING btree (created_at_event_id);


--
-- TOC entry 4488 (class 1259 OID 415150)
-- Name: fki_acornassociated_lojistiks_people_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_people_created_at_event_id ON public.acornassociated_lojistiks_people USING btree (created_at_event_id);


--
-- TOC entry 4496 (class 1259 OID 415162)
-- Name: fki_acornassociated_lojistiks_product_attributes_created_at_eve; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_product_attributes_created_at_eve ON public.acornassociated_lojistiks_product_attributes USING btree (created_at_event_id);


--
-- TOC entry 4500 (class 1259 OID 415168)
-- Name: fki_acornassociated_lojistiks_product_categories_created_at_eve; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_product_categories_created_at_eve ON public.acornassociated_lojistiks_product_categories USING btree (created_at_event_id);


--
-- TOC entry 4505 (class 1259 OID 415174)
-- Name: fki_acornassociated_lojistiks_product_category_types_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_product_category_types_created_at ON public.acornassociated_lojistiks_product_category_types USING btree (created_at_event_id);


--
-- TOC entry 4470 (class 1259 OID 415180)
-- Name: fki_acornassociated_lojistiks_product_instance_transfer_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_product_instance_transfer_created ON public.acornassociated_lojistiks_product_instance_transfer USING btree (created_at_event_id);


--
-- TOC entry 4474 (class 1259 OID 415186)
-- Name: fki_acornassociated_lojistiks_product_instances_created_at_even; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_product_instances_created_at_even ON public.acornassociated_lojistiks_product_instances USING btree (created_at_event_id);


--
-- TOC entry 4511 (class 1259 OID 415234)
-- Name: fki_acornassociated_lojistiks_product_products_created_at_event; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_product_products_created_at_event ON public.acornassociated_lojistiks_product_products USING btree (created_at_event_id);


--
-- TOC entry 4513 (class 1259 OID 415222)
-- Name: fki_acornassociated_lojistiks_products_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_products_created_at_event_id ON public.acornassociated_lojistiks_products USING btree (created_at_event_id);


--
-- TOC entry 4517 (class 1259 OID 415198)
-- Name: fki_acornassociated_lojistiks_products_product_categories_creat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_products_product_categories_creat ON public.acornassociated_lojistiks_products_product_categories USING btree (created_at_event_id);


--
-- TOC entry 4521 (class 1259 OID 415228)
-- Name: fki_acornassociated_lojistiks_suppliers_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_suppliers_created_at_event_id ON public.acornassociated_lojistiks_suppliers USING btree (created_at_event_id);


--
-- TOC entry 4535 (class 1259 OID 415204)
-- Name: fki_acornassociated_lojistiks_vehicle_types_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_vehicle_types_created_at_event_id ON public.acornassociated_lojistiks_vehicle_types USING btree (created_at_event_id);


--
-- TOC entry 4539 (class 1259 OID 415210)
-- Name: fki_acornassociated_lojistiks_vehicles_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_vehicles_created_at_event_id ON public.acornassociated_lojistiks_vehicles USING btree (created_at_event_id);


--
-- TOC entry 4545 (class 1259 OID 415216)
-- Name: fki_acornassociated_lojistiks_warehouses_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_acornassociated_lojistiks_warehouses_created_at_event_id ON public.acornassociated_lojistiks_warehouses USING btree (created_at_event_id);


--
-- TOC entry 4420 (class 1259 OID 414790)
-- Name: fki_actual_release_transfer_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_actual_release_transfer_id ON public.acornassociated_criminal_defendant_detentions USING btree (actual_release_transfer_id);


--
-- TOC entry 4478 (class 1259 OID 415275)
-- Name: fki_arrived_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_arrived_at_event_id ON public.acornassociated_lojistiks_transfers USING btree (arrived_at_event_id);


--
-- TOC entry 4377 (class 1259 OID 395059)
-- Name: fki_calendar_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_calendar_event_id ON public.acornassociated_criminal_legalcase_related_events USING btree (event_id);


--
-- TOC entry 4344 (class 1259 OID 395458)
-- Name: fki_closed_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_closed_at_event_id ON public.acornassociated_justice_legalcases USING btree (closed_at_event_id);


--
-- TOC entry 4406 (class 1259 OID 412581)
-- Name: fki_course_id; Type: INDEX; Schema: public; Owner: sanchez
--

CREATE INDEX fki_course_id ON public.acornassociated_university_course_teacher USING btree (course_id);


--
-- TOC entry 4432 (class 1259 OID 413841)
-- Name: fki_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_created_at ON public.acornassociated_finance_invoices USING btree (created_event_id);


--
-- TOC entry 4528 (class 1259 OID 414871)
-- Name: fki_created_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_created_at_event_id ON public.acornassociated_lojistiks_transfer_container_product_instance USING btree (created_at_event_id);


--
-- TOC entry 4367 (class 1259 OID 395060)
-- Name: fki_created_by_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_created_by_user_id ON public.acornassociated_criminal_defendant_crimes USING btree (created_by_user_id);


--
-- TOC entry 4368 (class 1259 OID 395061)
-- Name: fki_crime_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_crime_id ON public.acornassociated_criminal_defendant_crimes USING btree (crime_id);


--
-- TOC entry 4433 (class 1259 OID 413842)
-- Name: fki_currency_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_currency_id ON public.acornassociated_finance_invoices USING btree (currency_id);


--
-- TOC entry 4357 (class 1259 OID 395062)
-- Name: fki_defendant_crime_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_defendant_crime_id ON public.acornassociated_criminal_crime_evidence USING btree (defendant_crime_id);


--
-- TOC entry 4354 (class 1259 OID 395531)
-- Name: fki_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_event_id ON public.acornassociated_criminal_appeals USING btree (event_id);


--
-- TOC entry 4531 (class 1259 OID 414232)
-- Name: fki_invoice_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_invoice_id ON public.acornassociated_lojistiks_transfer_invoice USING btree (invoice_id);


--
-- TOC entry 4489 (class 1259 OID 414233)
-- Name: fki_last_product_instance_destination_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_last_product_instance_destination_location_id ON public.acornassociated_lojistiks_people USING btree (last_product_instance_location_id);


--
-- TOC entry 4490 (class 1259 OID 414932)
-- Name: fki_last_product_instance_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_last_product_instance_location_id ON public.acornassociated_lojistiks_people USING btree (last_product_instance_location_id);


--
-- TOC entry 4491 (class 1259 OID 414828)
-- Name: fki_last_transfer_destination_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_last_transfer_destination_location_id ON public.acornassociated_lojistiks_people USING btree (last_transfer_location_id);


--
-- TOC entry 4492 (class 1259 OID 414926)
-- Name: fki_last_transfer_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_last_transfer_location_id ON public.acornassociated_lojistiks_people USING btree (last_transfer_location_id);


--
-- TOC entry 4351 (class 1259 OID 394911)
-- Name: fki_legalcase1_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase1_id ON public.acornassociated_civil_legalcases USING btree (legalcase_id);


--
-- TOC entry 4348 (class 1259 OID 394912)
-- Name: fki_legalcase2_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase2_id ON public.acornassociated_civil_hearings USING btree (legalcase_id);


--
-- TOC entry 4341 (class 1259 OID 394847)
-- Name: fki_legalcase_category_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_category_id ON public.acornassociated_justice_legalcase_legalcase_category USING btree (legalcase_category_id);


--
-- TOC entry 4421 (class 1259 OID 412907)
-- Name: fki_legalcase_defendant_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_defendant_id ON public.acornassociated_criminal_defendant_detentions USING btree (legalcase_defendant_id);


--
-- TOC entry 4403 (class 1259 OID 395508)
-- Name: fki_legalcase_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_id ON public.acornassociated_justice_scanned_documents USING btree (legalcase_id);


--
-- TOC entry 4484 (class 1259 OID 414905)
-- Name: fki_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_location_id ON public.acornassociated_lojistiks_offices USING btree (location_id);


--
-- TOC entry 4422 (class 1259 OID 412929)
-- Name: fki_method_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_method_id ON public.acornassociated_criminal_defendant_detentions USING btree (detention_method_id);


--
-- TOC entry 4345 (class 1259 OID 412758)
-- Name: fki_owner_user_group_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_owner_user_group_id ON public.acornassociated_justice_legalcases USING btree (owner_user_group_id);


--
-- TOC entry 4336 (class 1259 OID 394848)
-- Name: fki_parent_legalcase_category_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_parent_legalcase_category_id ON public.acornassociated_justice_legalcase_categories USING btree (parent_legalcase_category_id);


--
-- TOC entry 4501 (class 1259 OID 414865)
-- Name: fki_parent_product_category_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_parent_product_category_id ON public.acornassociated_lojistiks_product_categories USING btree (parent_product_category_id);


--
-- TOC entry 4434 (class 1259 OID 413843)
-- Name: fki_payee_user_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_payee_user_group_id ON public.acornassociated_finance_invoices USING btree (payee_user_group_id);


--
-- TOC entry 4435 (class 1259 OID 413844)
-- Name: fki_payee_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_payee_user_id ON public.acornassociated_finance_invoices USING btree (payee_user_id);


--
-- TOC entry 4533 (class 1259 OID 414235)
-- Name: fki_purchase_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_purchase_id ON public.acornassociated_lojistiks_transfer_purchase USING btree (purchase_id);


--
-- TOC entry 4423 (class 1259 OID 412935)
-- Name: fki_reason_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_reason_id ON public.acornassociated_criminal_defendant_detentions USING btree (detention_reason_id);


--
-- TOC entry 4548 (class 1259 OID 415331)
-- Name: fki_revoked_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_revoked_at_event_id ON public.acornassociated_justice_warrants USING btree (revoked_at_event_id);


--
-- TOC entry 4479 (class 1259 OID 415269)
-- Name: fki_sent_at_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_sent_at_event_id ON public.acornassociated_lojistiks_transfers USING btree (sent_at_event_id);


--
-- TOC entry 4360 (class 1259 OID 395063)
-- Name: fki_sentence_type_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_sentence_type_id ON public.acornassociated_criminal_crime_sentences USING btree (sentence_type_id);


--
-- TOC entry 4384 (class 1259 OID 395064)
-- Name: fki_server_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_server_id ON public.acornassociated_criminal_legalcases USING btree (server_id);


--
-- TOC entry 4407 (class 1259 OID 412582)
-- Name: fki_teacher_id; Type: INDEX; Schema: public; Owner: sanchez
--

CREATE INDEX fki_teacher_id ON public.acornassociated_university_course_teacher USING btree (teacher_id);


--
-- TOC entry 4532 (class 1259 OID 414236)
-- Name: fki_transfer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_transfer_id ON public.acornassociated_lojistiks_transfer_invoice USING btree (transfer_id);


--
-- TOC entry 4392 (class 1259 OID 395065)
-- Name: fki_trial_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_trial_id ON public.acornassociated_criminal_trial_judges USING btree (trial_id);


--
-- TOC entry 4389 (class 1259 OID 395066)
-- Name: fki_trial_session_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_trial_session_id ON public.acornassociated_criminal_session_recordings USING btree (trial_session_id);


--
-- TOC entry 4291 (class 1259 OID 394428)
-- Name: fki_type_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_type_id ON public.acornassociated_location_locations USING btree (type_id);


--
-- TOC entry 4440 (class 1259 OID 413845)
-- Name: fki_user_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_user_group_id ON public.acornassociated_finance_purchases USING btree (payer_user_group_id);


--
-- TOC entry 4441 (class 1259 OID 413846)
-- Name: fki_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_user_id ON public.acornassociated_finance_purchases USING btree (payer_user_id);


--
-- TOC entry 4150 (class 1259 OID 393827)
-- Name: item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX item_index ON public.system_parameters USING btree (namespace, "group", item);


--
-- TOC entry 4160 (class 1259 OID 393916)
-- Name: jobs_queue_reserved_at_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX jobs_queue_reserved_at_index ON public.jobs USING btree (queue, reserved_at);


--
-- TOC entry 4256 (class 1259 OID 394198)
-- Name: rainlab_location_countries_name_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_location_countries_name_index ON public.winter_location_countries USING btree (name);


--
-- TOC entry 4252 (class 1259 OID 394186)
-- Name: rainlab_location_states_country_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_location_states_country_id_index ON public.winter_location_states USING btree (country_id);


--
-- TOC entry 4253 (class 1259 OID 394187)
-- Name: rainlab_location_states_name_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_location_states_name_index ON public.winter_location_states USING btree (name);


--
-- TOC entry 4263 (class 1259 OID 394220)
-- Name: rainlab_translate_attributes_locale_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_attributes_locale_index ON public.winter_translate_attributes USING btree (locale);


--
-- TOC entry 4264 (class 1259 OID 394221)
-- Name: rainlab_translate_attributes_model_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_attributes_model_id_index ON public.winter_translate_attributes USING btree (model_id);


--
-- TOC entry 4265 (class 1259 OID 394222)
-- Name: rainlab_translate_attributes_model_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_attributes_model_type_index ON public.winter_translate_attributes USING btree (model_type);


--
-- TOC entry 4272 (class 1259 OID 394248)
-- Name: rainlab_translate_indexes_item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_item_index ON public.winter_translate_indexes USING btree (item);


--
-- TOC entry 4273 (class 1259 OID 394245)
-- Name: rainlab_translate_indexes_locale_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_locale_index ON public.winter_translate_indexes USING btree (locale);


--
-- TOC entry 4274 (class 1259 OID 394246)
-- Name: rainlab_translate_indexes_model_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_model_id_index ON public.winter_translate_indexes USING btree (model_id);


--
-- TOC entry 4275 (class 1259 OID 394247)
-- Name: rainlab_translate_indexes_model_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_model_type_index ON public.winter_translate_indexes USING btree (model_type);


--
-- TOC entry 4268 (class 1259 OID 394234)
-- Name: rainlab_translate_locales_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_locales_code_index ON public.winter_translate_locales USING btree (code);


--
-- TOC entry 4269 (class 1259 OID 394235)
-- Name: rainlab_translate_locales_name_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_locales_name_index ON public.winter_translate_locales USING btree (name);


--
-- TOC entry 4259 (class 1259 OID 394210)
-- Name: rainlab_translate_messages_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_messages_code_index ON public.winter_translate_messages USING btree (code);


--
-- TOC entry 4193 (class 1259 OID 393953)
-- Name: reset_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX reset_code_index ON public.backend_users USING btree (reset_password_code);


--
-- TOC entry 4212 (class 1259 OID 394015)
-- Name: role_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX role_code_index ON public.backend_user_roles USING btree (code);


--
-- TOC entry 4168 (class 1259 OID 393929)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- TOC entry 4169 (class 1259 OID 393930)
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- TOC entry 4161 (class 1259 OID 393868)
-- Name: system_event_logs_level_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_event_logs_level_index ON public.system_event_logs USING btree (level);


--
-- TOC entry 4135 (class 1259 OID 393787)
-- Name: system_files_attachment_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_files_attachment_id_index ON public.system_files USING btree (attachment_id);


--
-- TOC entry 4136 (class 1259 OID 393788)
-- Name: system_files_attachment_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_files_attachment_type_index ON public.system_files USING btree (attachment_type);


--
-- TOC entry 4137 (class 1259 OID 393786)
-- Name: system_files_field_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_files_field_index ON public.system_files USING btree (field);


--
-- TOC entry 4153 (class 1259 OID 393839)
-- Name: system_mail_templates_layout_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_mail_templates_layout_id_index ON public.system_mail_templates USING btree (layout_id);


--
-- TOC entry 4143 (class 1259 OID 393806)
-- Name: system_plugin_history_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_plugin_history_code_index ON public.system_plugin_history USING btree (code);


--
-- TOC entry 4146 (class 1259 OID 393807)
-- Name: system_plugin_history_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_plugin_history_type_index ON public.system_plugin_history USING btree (type);


--
-- TOC entry 4140 (class 1259 OID 393796)
-- Name: system_plugin_versions_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_plugin_versions_code_index ON public.system_plugin_versions USING btree (code);


--
-- TOC entry 4172 (class 1259 OID 393905)
-- Name: system_revisions_field_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_revisions_field_index ON public.system_revisions USING btree (field);


--
-- TOC entry 4175 (class 1259 OID 393903)
-- Name: system_revisions_revisionable_id_revisionable_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_revisions_revisionable_id_revisionable_type_index ON public.system_revisions USING btree (revisionable_id, revisionable_type);


--
-- TOC entry 4176 (class 1259 OID 393904)
-- Name: system_revisions_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_revisions_user_id_index ON public.system_revisions USING btree (user_id);


--
-- TOC entry 4147 (class 1259 OID 393817)
-- Name: system_settings_item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_settings_item_index ON public.system_settings USING btree (item);


--
-- TOC entry 4207 (class 1259 OID 393990)
-- Name: user_item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX user_item_index ON public.backend_user_preferences USING btree (user_id, namespace, "group", item);


--
-- TOC entry 4262 (class 1259 OID 394251)
-- Name: winter_translate_messages_code_pre_2_1_0_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX winter_translate_messages_code_pre_2_1_0_index ON public.winter_translate_messages USING btree (code_pre_2_1_0);


--
-- TOC entry 4849 (class 2620 OID 414237)
-- Name: acornassociated_lojistiks_computer_products tr_acornassociated_lojistiks_computer_products_new_replicated_r; Type: TRIGGER; Schema: product; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_computer_products_new_replicated_r BEFORE INSERT ON product.acornassociated_lojistiks_computer_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE product.acornassociated_lojistiks_computer_products ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_computer_products_new_replicated_r;


--
-- TOC entry 4850 (class 2620 OID 414238)
-- Name: acornassociated_lojistiks_computer_products tr_acornassociated_lojistiks_computer_products_server_id; Type: TRIGGER; Schema: product; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_computer_products_server_id BEFORE INSERT ON product.acornassociated_lojistiks_computer_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4851 (class 2620 OID 414239)
-- Name: acornassociated_lojistiks_electronic_products tr_acornassociated_lojistiks_electronic_products_new_replicated; Type: TRIGGER; Schema: product; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_electronic_products_new_replicated BEFORE INSERT ON product.acornassociated_lojistiks_electronic_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE product.acornassociated_lojistiks_electronic_products ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_electronic_products_new_replicated;


--
-- TOC entry 4852 (class 2620 OID 414240)
-- Name: acornassociated_lojistiks_electronic_products tr_acornassociated_lojistiks_electronic_products_server_id; Type: TRIGGER; Schema: product; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_electronic_products_server_id BEFORE INSERT ON product.acornassociated_lojistiks_electronic_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4847 (class 2620 OID 394765)
-- Name: acornassociated_calendar_event_part tr_acornassociated_calendar_event_trigger_insert_function; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_calendar_event_trigger_insert_function AFTER INSERT OR UPDATE ON public.acornassociated_calendar_event_part FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_calendar_event_trigger_insert_function();


--
-- TOC entry 4848 (class 2620 OID 396054)
-- Name: acornassociated_justice_legalcases tr_acornassociated_justice_update_name_identifier; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_justice_update_name_identifier AFTER UPDATE ON public.acornassociated_justice_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_justice_update_name_identifier();

ALTER TABLE public.acornassociated_justice_legalcases DISABLE TRIGGER tr_acornassociated_justice_update_name_identifier;


--
-- TOC entry 4835 (class 2620 OID 394429)
-- Name: acornassociated_location_addresses tr_acornassociated_location_addresses_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_addresses_new_replicated_row BEFORE INSERT ON public.acornassociated_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_location_addresses ENABLE ALWAYS TRIGGER tr_acornassociated_location_addresses_new_replicated_row;


--
-- TOC entry 4836 (class 2620 OID 394430)
-- Name: acornassociated_location_addresses tr_acornassociated_location_addresses_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_addresses_server_id BEFORE INSERT ON public.acornassociated_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4837 (class 2620 OID 394431)
-- Name: acornassociated_location_area_types tr_acornassociated_location_area_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_area_types_new_replicated_row BEFORE INSERT ON public.acornassociated_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_location_area_types ENABLE ALWAYS TRIGGER tr_acornassociated_location_area_types_new_replicated_row;


--
-- TOC entry 4838 (class 2620 OID 394432)
-- Name: acornassociated_location_area_types tr_acornassociated_location_area_types_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_area_types_server_id BEFORE INSERT ON public.acornassociated_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4839 (class 2620 OID 394433)
-- Name: acornassociated_location_areas tr_acornassociated_location_areas_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_areas_new_replicated_row BEFORE INSERT ON public.acornassociated_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_location_areas ENABLE ALWAYS TRIGGER tr_acornassociated_location_areas_new_replicated_row;


--
-- TOC entry 4840 (class 2620 OID 394434)
-- Name: acornassociated_location_areas tr_acornassociated_location_areas_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_areas_server_id BEFORE INSERT ON public.acornassociated_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4841 (class 2620 OID 394435)
-- Name: acornassociated_location_gps tr_acornassociated_location_gps_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_gps_new_replicated_row BEFORE INSERT ON public.acornassociated_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_location_gps ENABLE ALWAYS TRIGGER tr_acornassociated_location_gps_new_replicated_row;


--
-- TOC entry 4842 (class 2620 OID 394436)
-- Name: acornassociated_location_gps tr_acornassociated_location_gps_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_gps_server_id BEFORE INSERT ON public.acornassociated_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4843 (class 2620 OID 394437)
-- Name: acornassociated_location_locations tr_acornassociated_location_locations_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_locations_new_replicated_row BEFORE INSERT ON public.acornassociated_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_location_locations ENABLE ALWAYS TRIGGER tr_acornassociated_location_locations_new_replicated_row;


--
-- TOC entry 4844 (class 2620 OID 394438)
-- Name: acornassociated_location_locations tr_acornassociated_location_locations_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_locations_server_id BEFORE INSERT ON public.acornassociated_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4845 (class 2620 OID 394439)
-- Name: acornassociated_location_types tr_acornassociated_location_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_types_new_replicated_row BEFORE INSERT ON public.acornassociated_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_location_types ENABLE ALWAYS TRIGGER tr_acornassociated_location_types_new_replicated_row;


--
-- TOC entry 4846 (class 2620 OID 394440)
-- Name: acornassociated_location_types tr_acornassociated_location_types_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acornassociated_location_types_server_id BEFORE INSERT ON public.acornassociated_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4853 (class 2620 OID 414247)
-- Name: acornassociated_lojistiks_brands tr_acornassociated_lojistiks_brands_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_brands_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_brands FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_brands ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_brands_new_replicated_row;


--
-- TOC entry 4854 (class 2620 OID 414248)
-- Name: acornassociated_lojistiks_brands tr_acornassociated_lojistiks_brands_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_brands_server_id BEFORE INSERT ON public.acornassociated_lojistiks_brands FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4855 (class 2620 OID 414249)
-- Name: acornassociated_lojistiks_containers tr_acornassociated_lojistiks_containers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_containers_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_containers ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_containers_new_replicated_row;


--
-- TOC entry 4856 (class 2620 OID 414250)
-- Name: acornassociated_lojistiks_containers tr_acornassociated_lojistiks_containers_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_containers_server_id BEFORE INSERT ON public.acornassociated_lojistiks_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4857 (class 2620 OID 414251)
-- Name: acornassociated_lojistiks_drivers tr_acornassociated_lojistiks_drivers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_drivers_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_drivers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_drivers ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_drivers_new_replicated_row;


--
-- TOC entry 4858 (class 2620 OID 414252)
-- Name: acornassociated_lojistiks_drivers tr_acornassociated_lojistiks_drivers_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_drivers_server_id BEFORE INSERT ON public.acornassociated_lojistiks_drivers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4859 (class 2620 OID 414253)
-- Name: acornassociated_lojistiks_employees tr_acornassociated_lojistiks_employees_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_employees_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_employees FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_employees ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_employees_new_replicated_row;


--
-- TOC entry 4860 (class 2620 OID 414254)
-- Name: acornassociated_lojistiks_employees tr_acornassociated_lojistiks_employees_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_employees_server_id BEFORE INSERT ON public.acornassociated_lojistiks_employees FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4861 (class 2620 OID 414259)
-- Name: acornassociated_lojistiks_measurement_units tr_acornassociated_lojistiks_measurement_units_new_replicated_r; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_measurement_units_new_replicated_r BEFORE INSERT ON public.acornassociated_lojistiks_measurement_units FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_measurement_units ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_measurement_units_new_replicated_r;


--
-- TOC entry 4862 (class 2620 OID 414260)
-- Name: acornassociated_lojistiks_measurement_units tr_acornassociated_lojistiks_measurement_units_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_measurement_units_server_id BEFORE INSERT ON public.acornassociated_lojistiks_measurement_units FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4872 (class 2620 OID 414261)
-- Name: acornassociated_lojistiks_offices tr_acornassociated_lojistiks_offices_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_offices_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_offices FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_offices ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_offices_new_replicated_row;


--
-- TOC entry 4873 (class 2620 OID 414262)
-- Name: acornassociated_lojistiks_offices tr_acornassociated_lojistiks_offices_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_offices_server_id BEFORE INSERT ON public.acornassociated_lojistiks_offices FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4874 (class 2620 OID 414263)
-- Name: acornassociated_lojistiks_people tr_acornassociated_lojistiks_people_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_people_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_people FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_people ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_people_new_replicated_row;


--
-- TOC entry 4875 (class 2620 OID 414264)
-- Name: acornassociated_lojistiks_people tr_acornassociated_lojistiks_people_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_people_server_id BEFORE INSERT ON public.acornassociated_lojistiks_people FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4876 (class 2620 OID 414265)
-- Name: acornassociated_lojistiks_product_attributes tr_acornassociated_lojistiks_product_attributes_new_replicated_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_attributes_new_replicated_ BEFORE INSERT ON public.acornassociated_lojistiks_product_attributes FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_product_attributes ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_product_attributes_new_replicated_;


--
-- TOC entry 4877 (class 2620 OID 414266)
-- Name: acornassociated_lojistiks_product_attributes tr_acornassociated_lojistiks_product_attributes_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_attributes_server_id BEFORE INSERT ON public.acornassociated_lojistiks_product_attributes FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4878 (class 2620 OID 414267)
-- Name: acornassociated_lojistiks_product_categories tr_acornassociated_lojistiks_product_categories_new_replicated_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_categories_new_replicated_ BEFORE INSERT ON public.acornassociated_lojistiks_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_product_categories ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_product_categories_new_replicated_;


--
-- TOC entry 4879 (class 2620 OID 414268)
-- Name: acornassociated_lojistiks_product_categories tr_acornassociated_lojistiks_product_categories_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_categories_server_id BEFORE INSERT ON public.acornassociated_lojistiks_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4880 (class 2620 OID 414269)
-- Name: acornassociated_lojistiks_product_category_types tr_acornassociated_lojistiks_product_category_types_new_replica; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_category_types_new_replica BEFORE INSERT ON public.acornassociated_lojistiks_product_category_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_product_category_types ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_product_category_types_new_replica;


--
-- TOC entry 4881 (class 2620 OID 414270)
-- Name: acornassociated_lojistiks_product_category_types tr_acornassociated_lojistiks_product_category_types_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_category_types_server_id BEFORE INSERT ON public.acornassociated_lojistiks_product_category_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4863 (class 2620 OID 414271)
-- Name: acornassociated_lojistiks_product_instance_transfer tr_acornassociated_lojistiks_product_instance_transfer_new_repl; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_instance_transfer_new_repl BEFORE INSERT ON public.acornassociated_lojistiks_product_instance_transfer FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_product_instance_transfer ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_product_instance_transfer_new_repl;


--
-- TOC entry 4864 (class 2620 OID 414272)
-- Name: acornassociated_lojistiks_product_instance_transfer tr_acornassociated_lojistiks_product_instance_transfer_server_i; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_instance_transfer_server_i BEFORE INSERT ON public.acornassociated_lojistiks_product_instance_transfer FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4865 (class 2620 OID 414273)
-- Name: acornassociated_lojistiks_product_instances tr_acornassociated_lojistiks_product_instances_new_replicated_r; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_instances_new_replicated_r BEFORE INSERT ON public.acornassociated_lojistiks_product_instances FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_product_instances ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_product_instances_new_replicated_r;


--
-- TOC entry 4866 (class 2620 OID 414274)
-- Name: acornassociated_lojistiks_product_instances tr_acornassociated_lojistiks_product_instances_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_instances_server_id BEFORE INSERT ON public.acornassociated_lojistiks_product_instances FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4882 (class 2620 OID 414275)
-- Name: acornassociated_lojistiks_product_products tr_acornassociated_lojistiks_product_products_new_replicated_ro; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_products_new_replicated_ro BEFORE INSERT ON public.acornassociated_lojistiks_product_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_product_products ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_product_products_new_replicated_ro;


--
-- TOC entry 4883 (class 2620 OID 414276)
-- Name: acornassociated_lojistiks_product_products tr_acornassociated_lojistiks_product_products_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_product_products_server_id BEFORE INSERT ON public.acornassociated_lojistiks_product_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4884 (class 2620 OID 414277)
-- Name: acornassociated_lojistiks_products tr_acornassociated_lojistiks_products_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_products_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_products ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_products_new_replicated_row;


--
-- TOC entry 4886 (class 2620 OID 414278)
-- Name: acornassociated_lojistiks_products_product_categories tr_acornassociated_lojistiks_products_product_categories_new_re; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_products_product_categories_new_re BEFORE INSERT ON public.acornassociated_lojistiks_products_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_products_product_categories ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_products_product_categories_new_re;


--
-- TOC entry 4887 (class 2620 OID 414279)
-- Name: acornassociated_lojistiks_products_product_categories tr_acornassociated_lojistiks_products_product_categories_server; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_products_product_categories_server BEFORE INSERT ON public.acornassociated_lojistiks_products_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4885 (class 2620 OID 414280)
-- Name: acornassociated_lojistiks_products tr_acornassociated_lojistiks_products_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_products_server_id BEFORE INSERT ON public.acornassociated_lojistiks_products FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4888 (class 2620 OID 414281)
-- Name: acornassociated_lojistiks_suppliers tr_acornassociated_lojistiks_suppliers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_suppliers_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_suppliers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_suppliers ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_suppliers_new_replicated_row;


--
-- TOC entry 4889 (class 2620 OID 414282)
-- Name: acornassociated_lojistiks_suppliers tr_acornassociated_lojistiks_suppliers_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_suppliers_server_id BEFORE INSERT ON public.acornassociated_lojistiks_suppliers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4890 (class 2620 OID 414283)
-- Name: acornassociated_lojistiks_transfer_containers tr_acornassociated_lojistiks_transfer_container_new_replicated_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfer_container_new_replicated_ BEFORE INSERT ON public.acornassociated_lojistiks_transfer_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_transfer_containers ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_transfer_container_new_replicated_;


--
-- TOC entry 4892 (class 2620 OID 414284)
-- Name: acornassociated_lojistiks_transfer_container_product_instance tr_acornassociated_lojistiks_transfer_container_product_instanc; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfer_container_product_instanc BEFORE INSERT ON public.acornassociated_lojistiks_transfer_container_product_instance FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_transfer_container_product_instance ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_transfer_container_product_instanc;


--
-- TOC entry 4891 (class 2620 OID 414285)
-- Name: acornassociated_lojistiks_transfer_containers tr_acornassociated_lojistiks_transfer_container_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfer_container_server_id BEFORE INSERT ON public.acornassociated_lojistiks_transfer_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4867 (class 2620 OID 414286)
-- Name: acornassociated_lojistiks_transfers tr_acornassociated_lojistiks_transfers_delete_calendar; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfers_delete_calendar AFTER DELETE ON public.acornassociated_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_lojistiks_transfers_delete_calendar();


--
-- TOC entry 4868 (class 2620 OID 414287)
-- Name: acornassociated_lojistiks_transfers tr_acornassociated_lojistiks_transfers_insert_calendar; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfers_insert_calendar BEFORE INSERT ON public.acornassociated_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_lojistiks_transfers_insert_calendar();


--
-- TOC entry 4869 (class 2620 OID 414288)
-- Name: acornassociated_lojistiks_transfers tr_acornassociated_lojistiks_transfers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfers_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_transfers ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_transfers_new_replicated_row;


--
-- TOC entry 4870 (class 2620 OID 414289)
-- Name: acornassociated_lojistiks_transfers tr_acornassociated_lojistiks_transfers_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfers_server_id BEFORE INSERT ON public.acornassociated_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4871 (class 2620 OID 414290)
-- Name: acornassociated_lojistiks_transfers tr_acornassociated_lojistiks_transfers_update_calendar; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_transfers_update_calendar BEFORE UPDATE ON public.acornassociated_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_lojistiks_transfers_update_calendar();


--
-- TOC entry 4893 (class 2620 OID 414291)
-- Name: acornassociated_lojistiks_vehicle_types tr_acornassociated_lojistiks_vehicle_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_vehicle_types_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_vehicle_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_vehicle_types ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_vehicle_types_new_replicated_row;


--
-- TOC entry 4894 (class 2620 OID 414292)
-- Name: acornassociated_lojistiks_vehicle_types tr_acornassociated_lojistiks_vehicle_types_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_vehicle_types_server_id BEFORE INSERT ON public.acornassociated_lojistiks_vehicle_types FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4895 (class 2620 OID 414293)
-- Name: acornassociated_lojistiks_vehicles tr_acornassociated_lojistiks_vehicles_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_vehicles_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_vehicles FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_vehicles ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_vehicles_new_replicated_row;


--
-- TOC entry 4896 (class 2620 OID 414294)
-- Name: acornassociated_lojistiks_vehicles tr_acornassociated_lojistiks_vehicles_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_vehicles_server_id BEFORE INSERT ON public.acornassociated_lojistiks_vehicles FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4897 (class 2620 OID 414295)
-- Name: acornassociated_lojistiks_warehouses tr_acornassociated_lojistiks_warehouses_new_replicated_row; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_warehouses_new_replicated_row BEFORE INSERT ON public.acornassociated_lojistiks_warehouses FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_new_replicated_row();

ALTER TABLE public.acornassociated_lojistiks_warehouses ENABLE ALWAYS TRIGGER tr_acornassociated_lojistiks_warehouses_new_replicated_row;


--
-- TOC entry 4898 (class 2620 OID 414296)
-- Name: acornassociated_lojistiks_warehouses tr_acornassociated_lojistiks_warehouses_server_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_acornassociated_lojistiks_warehouses_server_id BEFORE INSERT ON public.acornassociated_lojistiks_warehouses FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_server_id();


--
-- TOC entry 4719 (class 2606 OID 414297)
-- Name: acornassociated_lojistiks_computer_products computer_products_created_by_user; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_computer_products
    ADD CONSTRAINT computer_products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4723 (class 2606 OID 414938)
-- Name: acornassociated_lojistiks_electronic_products created_at_event_id; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_electronic_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4720 (class 2606 OID 415099)
-- Name: acornassociated_lojistiks_computer_products created_at_event_id; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_computer_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4721 (class 2606 OID 414302)
-- Name: acornassociated_lojistiks_computer_products electronic_product_id; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_computer_products
    ADD CONSTRAINT electronic_product_id FOREIGN KEY (electronic_product_id) REFERENCES product.acornassociated_lojistiks_electronic_products(id) NOT VALID;


--
-- TOC entry 4724 (class 2606 OID 414307)
-- Name: acornassociated_lojistiks_electronic_products electronic_products_created_by_user; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_electronic_products
    ADD CONSTRAINT electronic_products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4725 (class 2606 OID 414312)
-- Name: acornassociated_lojistiks_electronic_products product_id; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_electronic_products
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acornassociated_lojistiks_products(id);


--
-- TOC entry 4722 (class 2606 OID 414796)
-- Name: acornassociated_lojistiks_computer_products server_id; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_computer_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4726 (class 2606 OID 414802)
-- Name: acornassociated_lojistiks_electronic_products server_id; Type: FK CONSTRAINT; Schema: product; Owner: postgres
--

ALTER TABLE ONLY product.acornassociated_lojistiks_electronic_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4583 (class 2606 OID 394697)
-- Name: acornassociated_calendar_event acornassociated_calendar_event_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event
    ADD CONSTRAINT acornassociated_calendar_event_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acornassociated_calendar(id) ON DELETE CASCADE;


--
-- TOC entry 4584 (class 2606 OID 394707)
-- Name: acornassociated_calendar_event acornassociated_calendar_event_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event
    ADD CONSTRAINT acornassociated_calendar_event_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) ON DELETE CASCADE;


--
-- TOC entry 4585 (class 2606 OID 394702)
-- Name: acornassociated_calendar_event acornassociated_calendar_event_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event
    ADD CONSTRAINT acornassociated_calendar_event_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acornassociated_user_users(id) ON DELETE CASCADE;


--
-- TOC entry 4586 (class 2606 OID 394723)
-- Name: acornassociated_calendar_event_part acornassociated_calendar_event_part_event_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_part
    ADD CONSTRAINT acornassociated_calendar_event_part_event_id_foreign FOREIGN KEY (event_id) REFERENCES public.acornassociated_calendar_event(id) ON DELETE CASCADE;


--
-- TOC entry 4587 (class 2606 OID 394738)
-- Name: acornassociated_calendar_event_part acornassociated_calendar_event_part_locked_by_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_part
    ADD CONSTRAINT acornassociated_calendar_event_part_locked_by_user_id_foreign FOREIGN KEY (locked_by_user_id) REFERENCES public.backend_users(id) ON DELETE SET NULL;


--
-- TOC entry 4588 (class 2606 OID 394745)
-- Name: acornassociated_calendar_event_part acornassociated_calendar_event_part_parent_event_part_id_foreig; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_part
    ADD CONSTRAINT acornassociated_calendar_event_part_parent_event_part_id_foreig FOREIGN KEY (parent_event_part_id) REFERENCES public.acornassociated_calendar_event_part(id) ON DELETE CASCADE;


--
-- TOC entry 4589 (class 2606 OID 394733)
-- Name: acornassociated_calendar_event_part acornassociated_calendar_event_part_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_part
    ADD CONSTRAINT acornassociated_calendar_event_part_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acornassociated_calendar_event_status(id) ON DELETE CASCADE;


--
-- TOC entry 4590 (class 2606 OID 394728)
-- Name: acornassociated_calendar_event_part acornassociated_calendar_event_part_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_part
    ADD CONSTRAINT acornassociated_calendar_event_part_type_id_foreign FOREIGN KEY (type_id) REFERENCES public.acornassociated_calendar_event_type(id) ON DELETE CASCADE;


--
-- TOC entry 4592 (class 2606 OID 394772)
-- Name: acornassociated_calendar_event_user acornassociated_calendar_event_user_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user
    ADD CONSTRAINT acornassociated_calendar_event_user_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acornassociated_calendar_event_part(id) ON DELETE CASCADE;


--
-- TOC entry 4595 (class 2606 OID 394792)
-- Name: acornassociated_calendar_event_user_group acornassociated_calendar_event_user_group_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user_group
    ADD CONSTRAINT acornassociated_calendar_event_user_group_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acornassociated_calendar_event_part(id) ON DELETE CASCADE;


--
-- TOC entry 4596 (class 2606 OID 394797)
-- Name: acornassociated_calendar_event_user_group acornassociated_calendar_event_user_group_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user_group
    ADD CONSTRAINT acornassociated_calendar_event_user_group_user_group_id_foreign FOREIGN KEY (user_group_id) REFERENCES public.acornassociated_user_user_groups(id) ON DELETE CASCADE;


--
-- TOC entry 4593 (class 2606 OID 394782)
-- Name: acornassociated_calendar_event_user acornassociated_calendar_event_user_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user
    ADD CONSTRAINT acornassociated_calendar_event_user_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.acornassociated_user_roles(id) ON DELETE CASCADE;


--
-- TOC entry 4594 (class 2606 OID 394777)
-- Name: acornassociated_calendar_event_user acornassociated_calendar_event_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_event_user
    ADD CONSTRAINT acornassociated_calendar_event_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) ON DELETE CASCADE;


--
-- TOC entry 4591 (class 2606 OID 394757)
-- Name: acornassociated_calendar_instance acornassociated_calendar_instance_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar_instance
    ADD CONSTRAINT acornassociated_calendar_instance_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acornassociated_calendar_event_part(id) ON DELETE CASCADE;


--
-- TOC entry 4581 (class 2606 OID 394664)
-- Name: acornassociated_calendar acornassociated_calendar_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar
    ADD CONSTRAINT acornassociated_calendar_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) ON DELETE CASCADE;


--
-- TOC entry 4582 (class 2606 OID 394659)
-- Name: acornassociated_calendar acornassociated_calendar_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_calendar
    ADD CONSTRAINT acornassociated_calendar_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acornassociated_user_users(id) ON DELETE CASCADE;


--
-- TOC entry 4597 (class 2606 OID 394813)
-- Name: acornassociated_messaging_message_instance acornassociated_messaging_message_instance_instance_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_instance
    ADD CONSTRAINT acornassociated_messaging_message_instance_instance_id_foreign FOREIGN KEY (instance_id) REFERENCES public.acornassociated_calendar_instance(id) ON DELETE CASCADE;


--
-- TOC entry 4598 (class 2606 OID 394808)
-- Name: acornassociated_messaging_message_instance acornassociated_messaging_message_instance_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_instance
    ADD CONSTRAINT acornassociated_messaging_message_instance_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acornassociated_messaging_message(id) ON DELETE CASCADE;


--
-- TOC entry 4576 (class 2606 OID 394593)
-- Name: acornassociated_messaging_message_user_group acornassociated_messaging_message_user_group_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_user_group
    ADD CONSTRAINT acornassociated_messaging_message_user_group_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acornassociated_messaging_message(id) ON DELETE CASCADE;


--
-- TOC entry 4577 (class 2606 OID 394598)
-- Name: acornassociated_messaging_message_user_group acornassociated_messaging_message_user_group_user_group_id_fore; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_user_group
    ADD CONSTRAINT acornassociated_messaging_message_user_group_user_group_id_fore FOREIGN KEY (user_group_id) REFERENCES public.acornassociated_user_user_groups(id) ON DELETE CASCADE;


--
-- TOC entry 4574 (class 2606 OID 394583)
-- Name: acornassociated_messaging_message_user acornassociated_messaging_message_user_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_user
    ADD CONSTRAINT acornassociated_messaging_message_user_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acornassociated_messaging_message(id) ON DELETE CASCADE;


--
-- TOC entry 4575 (class 2606 OID 394578)
-- Name: acornassociated_messaging_message_user acornassociated_messaging_message_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_message_user
    ADD CONSTRAINT acornassociated_messaging_message_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) ON DELETE CASCADE;


--
-- TOC entry 4578 (class 2606 OID 394639)
-- Name: acornassociated_messaging_user_message_status acornassociated_messaging_user_message_status_message_id_foreig; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_user_message_status
    ADD CONSTRAINT acornassociated_messaging_user_message_status_message_id_foreig FOREIGN KEY (message_id) REFERENCES public.acornassociated_messaging_message(id) ON DELETE CASCADE;


--
-- TOC entry 4579 (class 2606 OID 394644)
-- Name: acornassociated_messaging_user_message_status acornassociated_messaging_user_message_status_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_user_message_status
    ADD CONSTRAINT acornassociated_messaging_user_message_status_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acornassociated_messaging_status(id) ON DELETE CASCADE;


--
-- TOC entry 4580 (class 2606 OID 394634)
-- Name: acornassociated_messaging_user_message_status acornassociated_messaging_user_message_status_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_messaging_user_message_status
    ADD CONSTRAINT acornassociated_messaging_user_message_status_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) ON DELETE CASCADE;


--
-- TOC entry 4699 (class 2606 OID 414785)
-- Name: acornassociated_criminal_defendant_detentions actual_release_transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_detentions
    ADD CONSTRAINT actual_release_transfer_id FOREIGN KEY (actual_release_transfer_id) REFERENCES public.acornassociated_lojistiks_transfers(id) NOT VALID;


--
-- TOC entry 5152 (class 0 OID 0)
-- Dependencies: 4699
-- Name: CONSTRAINT actual_release_transfer_id ON acornassociated_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT actual_release_transfer_id ON public.acornassociated_criminal_defendant_detentions IS 'type: 1to1';


--
-- TOC entry 4566 (class 2606 OID 394441)
-- Name: acornassociated_location_locations address_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_locations
    ADD CONSTRAINT address_id FOREIGN KEY (address_id) REFERENCES public.acornassociated_location_addresses(id) NOT VALID;


--
-- TOC entry 4553 (class 2606 OID 394446)
-- Name: acornassociated_location_addresses addresses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_addresses
    ADD CONSTRAINT addresses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4554 (class 2606 OID 394451)
-- Name: acornassociated_location_addresses area_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_addresses
    ADD CONSTRAINT area_id FOREIGN KEY (area_id) REFERENCES public.acornassociated_location_areas(id) NOT VALID;


--
-- TOC entry 4559 (class 2606 OID 394456)
-- Name: acornassociated_location_areas area_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_areas
    ADD CONSTRAINT area_type_id FOREIGN KEY (area_type_id) REFERENCES public.acornassociated_location_area_types(id);


--
-- TOC entry 4557 (class 2606 OID 394461)
-- Name: acornassociated_location_area_types area_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_area_types
    ADD CONSTRAINT area_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4560 (class 2606 OID 394466)
-- Name: acornassociated_location_areas areas_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_areas
    ADD CONSTRAINT areas_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4755 (class 2606 OID 415270)
-- Name: acornassociated_lojistiks_transfers arrived_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT arrived_at_event_id FOREIGN KEY (arrived_at_event_id) REFERENCES public.acornassociated_calendar_event(id) ON DELETE SET NULL NOT VALID;


--
-- TOC entry 4790 (class 2606 OID 414347)
-- Name: acornassociated_lojistiks_products brand_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products
    ADD CONSTRAINT brand_id FOREIGN KEY (brand_id) REFERENCES public.acornassociated_lojistiks_brands(id) NOT VALID;


--
-- TOC entry 4727 (class 2606 OID 414352)
-- Name: acornassociated_lojistiks_brands brands_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_brands
    ADD CONSTRAINT brands_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4651 (class 2606 OID 395069)
-- Name: acornassociated_criminal_legalcase_related_events calendar_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_related_events
    ADD CONSTRAINT calendar_event_id FOREIGN KEY (event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4607 (class 2606 OID 395656)
-- Name: acornassociated_justice_legalcases closed_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcases
    ADD CONSTRAINT closed_at_event_id FOREIGN KEY (closed_at_event_id) REFERENCES public.acornassociated_calendar_event(id) ON DELETE SET NULL NOT VALID;


--
-- TOC entry 4804 (class 2606 OID 414357)
-- Name: acornassociated_lojistiks_transfer_containers container_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers
    ADD CONSTRAINT container_id FOREIGN KEY (container_id) REFERENCES public.acornassociated_lojistiks_containers(id);


--
-- TOC entry 4730 (class 2606 OID 414362)
-- Name: acornassociated_lojistiks_containers containers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_containers
    ADD CONSTRAINT containers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4693 (class 2606 OID 412584)
-- Name: acornassociated_university_course_teacher course_id; Type: FK CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_course_teacher
    ADD CONSTRAINT course_id FOREIGN KEY (course_id) REFERENCES public.acornassociated_university_courses(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4704 (class 2606 OID 413847)
-- Name: acornassociated_finance_invoices created_at; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT created_at FOREIGN KEY (created_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4608 (class 2606 OID 394849)
-- Name: acornassociated_justice_legalcases created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcases
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4600 (class 2606 OID 394854)
-- Name: acornassociated_justice_legalcase_identifiers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_identifiers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4603 (class 2606 OID 394859)
-- Name: acornassociated_justice_legalcase_legalcase_category created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_legalcase_category
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4614 (class 2606 OID 394913)
-- Name: acornassociated_civil_legalcases created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_legalcases
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4611 (class 2606 OID 394918)
-- Name: acornassociated_civil_hearings created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_hearings
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4663 (class 2606 OID 395074)
-- Name: acornassociated_criminal_legalcases created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcases
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4621 (class 2606 OID 395079)
-- Name: acornassociated_criminal_crime_evidence created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_evidence
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4625 (class 2606 OID 395084)
-- Name: acornassociated_criminal_crime_sentences created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_sentences
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4672 (class 2606 OID 395089)
-- Name: acornassociated_criminal_trial_judges created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_judges
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4667 (class 2606 OID 395094)
-- Name: acornassociated_criminal_sentence_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_sentence_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4655 (class 2606 OID 395099)
-- Name: acornassociated_criminal_legalcase_plaintiffs created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_plaintiffs
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4652 (class 2606 OID 395104)
-- Name: acornassociated_criminal_legalcase_related_events created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_related_events
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4643 (class 2606 OID 395109)
-- Name: acornassociated_criminal_legalcase_evidence created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_evidence
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4632 (class 2606 OID 395114)
-- Name: acornassociated_criminal_crimes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crimes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4629 (class 2606 OID 395119)
-- Name: acornassociated_criminal_crime_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4635 (class 2606 OID 395124)
-- Name: acornassociated_criminal_defendant_crimes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_crimes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4617 (class 2606 OID 395129)
-- Name: acornassociated_criminal_appeals created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_appeals
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4639 (class 2606 OID 395134)
-- Name: acornassociated_criminal_legalcase_defendants created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_defendants
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4646 (class 2606 OID 395139)
-- Name: acornassociated_criminal_legalcase_prosecutor created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_prosecutor
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4659 (class 2606 OID 395144)
-- Name: acornassociated_criminal_legalcase_witnesses created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_witnesses
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4677 (class 2606 OID 395149)
-- Name: acornassociated_criminal_trial_sessions created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_sessions
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4680 (class 2606 OID 395154)
-- Name: acornassociated_criminal_trials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4669 (class 2606 OID 395159)
-- Name: acornassociated_criminal_session_recordings created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_session_recordings
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4687 (class 2606 OID 395408)
-- Name: acornassociated_houseofpeace_legalcases created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_legalcases
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4684 (class 2606 OID 395413)
-- Name: acornassociated_houseofpeace_events created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_events
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4690 (class 2606 OID 395470)
-- Name: acornassociated_justice_scanned_documents created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_scanned_documents
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id);


--
-- TOC entry 4809 (class 2606 OID 414866)
-- Name: acornassociated_lojistiks_transfer_container_product_instance created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4805 (class 2606 OID 414872)
-- Name: acornassociated_lojistiks_transfer_containers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4728 (class 2606 OID 414933)
-- Name: acornassociated_lojistiks_brands created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_brands
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4738 (class 2606 OID 415104)
-- Name: acornassociated_lojistiks_employees created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_employees
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4756 (class 2606 OID 415109)
-- Name: acornassociated_lojistiks_transfers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4743 (class 2606 OID 415134)
-- Name: acornassociated_lojistiks_measurement_units created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_measurement_units
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4763 (class 2606 OID 415139)
-- Name: acornassociated_lojistiks_offices created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_offices
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4767 (class 2606 OID 415145)
-- Name: acornassociated_lojistiks_people created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4731 (class 2606 OID 415151)
-- Name: acornassociated_lojistiks_containers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_containers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4773 (class 2606 OID 415157)
-- Name: acornassociated_lojistiks_product_attributes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_attributes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4777 (class 2606 OID 415163)
-- Name: acornassociated_lojistiks_product_categories created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4782 (class 2606 OID 415169)
-- Name: acornassociated_lojistiks_product_category_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_category_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4746 (class 2606 OID 415175)
-- Name: acornassociated_lojistiks_product_instance_transfer created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4751 (class 2606 OID 415181)
-- Name: acornassociated_lojistiks_product_instances created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instances
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4733 (class 2606 OID 415187)
-- Name: acornassociated_lojistiks_drivers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4795 (class 2606 OID 415193)
-- Name: acornassociated_lojistiks_products_product_categories created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4818 (class 2606 OID 415199)
-- Name: acornassociated_lojistiks_vehicle_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicle_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4821 (class 2606 OID 415205)
-- Name: acornassociated_lojistiks_vehicles created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicles
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4825 (class 2606 OID 415211)
-- Name: acornassociated_lojistiks_warehouses created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_warehouses
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4791 (class 2606 OID 415217)
-- Name: acornassociated_lojistiks_products created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4800 (class 2606 OID 415223)
-- Name: acornassociated_lojistiks_suppliers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_suppliers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4785 (class 2606 OID 415229)
-- Name: acornassociated_lojistiks_product_products created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4829 (class 2606 OID 415303)
-- Name: acornassociated_justice_warrants created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4747 (class 2606 OID 414722)
-- Name: acornassociated_lojistiks_product_instance_transfer created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer
    ADD CONSTRAINT created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4609 (class 2606 OID 394864)
-- Name: acornassociated_justice_legalcases created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcases
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4604 (class 2606 OID 394869)
-- Name: acornassociated_justice_legalcase_legalcase_category created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_legalcase_category
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4601 (class 2606 OID 394874)
-- Name: acornassociated_justice_legalcase_identifiers created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_identifiers
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4615 (class 2606 OID 394923)
-- Name: acornassociated_civil_legalcases created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_legalcases
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4612 (class 2606 OID 394928)
-- Name: acornassociated_civil_hearings created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_hearings
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4664 (class 2606 OID 395164)
-- Name: acornassociated_criminal_legalcases created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcases
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4622 (class 2606 OID 395169)
-- Name: acornassociated_criminal_crime_evidence created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_evidence
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4626 (class 2606 OID 395174)
-- Name: acornassociated_criminal_crime_sentences created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_sentences
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4673 (class 2606 OID 395179)
-- Name: acornassociated_criminal_trial_judges created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_judges
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4668 (class 2606 OID 395184)
-- Name: acornassociated_criminal_sentence_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_sentence_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4656 (class 2606 OID 395189)
-- Name: acornassociated_criminal_legalcase_plaintiffs created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_plaintiffs
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4653 (class 2606 OID 395194)
-- Name: acornassociated_criminal_legalcase_related_events created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_related_events
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4644 (class 2606 OID 395199)
-- Name: acornassociated_criminal_legalcase_evidence created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_evidence
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4633 (class 2606 OID 395204)
-- Name: acornassociated_criminal_crimes created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crimes
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4630 (class 2606 OID 395209)
-- Name: acornassociated_criminal_crime_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4636 (class 2606 OID 395214)
-- Name: acornassociated_criminal_defendant_crimes created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_crimes
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4618 (class 2606 OID 395219)
-- Name: acornassociated_criminal_appeals created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_appeals
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4640 (class 2606 OID 395224)
-- Name: acornassociated_criminal_legalcase_defendants created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_defendants
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4647 (class 2606 OID 395229)
-- Name: acornassociated_criminal_legalcase_prosecutor created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_prosecutor
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4660 (class 2606 OID 395234)
-- Name: acornassociated_criminal_legalcase_witnesses created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_witnesses
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4678 (class 2606 OID 395239)
-- Name: acornassociated_criminal_trial_sessions created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_sessions
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4681 (class 2606 OID 395244)
-- Name: acornassociated_criminal_trials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4670 (class 2606 OID 395249)
-- Name: acornassociated_criminal_session_recordings created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_session_recordings
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4688 (class 2606 OID 395418)
-- Name: acornassociated_houseofpeace_legalcases created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_legalcases
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4685 (class 2606 OID 395423)
-- Name: acornassociated_houseofpeace_events created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_events
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4691 (class 2606 OID 395465)
-- Name: acornassociated_justice_scanned_documents created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_scanned_documents
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4830 (class 2606 OID 415308)
-- Name: acornassociated_justice_warrants created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4637 (class 2606 OID 395254)
-- Name: acornassociated_criminal_defendant_crimes crime_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_crimes
    ADD CONSTRAINT crime_id FOREIGN KEY (crime_id) REFERENCES public.acornassociated_criminal_crimes(id) NOT VALID;


--
-- TOC entry 4634 (class 2606 OID 395259)
-- Name: acornassociated_criminal_crimes crime_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crimes
    ADD CONSTRAINT crime_type_id FOREIGN KEY (crime_type_id) REFERENCES public.acornassociated_criminal_crime_types(id) NOT VALID;


--
-- TOC entry 4705 (class 2606 OID 413852)
-- Name: acornassociated_finance_invoices currency_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acornassociated_finance_currencies(id) NOT VALID;


--
-- TOC entry 4710 (class 2606 OID 413857)
-- Name: acornassociated_finance_payments currency_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_payments
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acornassociated_finance_currencies(id) NOT VALID;


--
-- TOC entry 4712 (class 2606 OID 413862)
-- Name: acornassociated_finance_purchases currency_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_purchases
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acornassociated_finance_currencies(id) NOT VALID;


--
-- TOC entry 4717 (class 2606 OID 413867)
-- Name: acornassociated_finance_receipts currency_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_receipts
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acornassociated_finance_currencies(id) NOT VALID;


--
-- TOC entry 4623 (class 2606 OID 395264)
-- Name: acornassociated_criminal_crime_evidence defendant_crime_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_evidence
    ADD CONSTRAINT defendant_crime_id FOREIGN KEY (defendant_crime_id) REFERENCES public.acornassociated_criminal_defendant_crimes(id) NOT VALID;


--
-- TOC entry 4627 (class 2606 OID 395269)
-- Name: acornassociated_criminal_crime_sentences defendant_crime_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_sentences
    ADD CONSTRAINT defendant_crime_id FOREIGN KEY (defendant_crime_id) REFERENCES public.acornassociated_criminal_defendant_crimes(id) NOT VALID;


--
-- TOC entry 4757 (class 2606 OID 414382)
-- Name: acornassociated_lojistiks_transfers driver_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT driver_id FOREIGN KEY (driver_id) REFERENCES public.acornassociated_lojistiks_drivers(id) NOT VALID;


--
-- TOC entry 4734 (class 2606 OID 414387)
-- Name: acornassociated_lojistiks_drivers drivers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers
    ADD CONSTRAINT drivers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4739 (class 2606 OID 414392)
-- Name: acornassociated_lojistiks_employees employees_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_employees
    ADD CONSTRAINT employees_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4619 (class 2606 OID 395526)
-- Name: acornassociated_criminal_appeals event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_appeals
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acornassociated_calendar_event(id) NOT VALID;


--
-- TOC entry 4682 (class 2606 OID 395683)
-- Name: acornassociated_criminal_trials event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trials
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acornassociated_calendar_event(id) ON DELETE SET NULL NOT VALID;


--
-- TOC entry 4564 (class 2606 OID 394471)
-- Name: acornassociated_location_gps gps_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_gps
    ADD CONSTRAINT gps_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4561 (class 2606 OID 394476)
-- Name: acornassociated_location_areas gps_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_areas
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acornassociated_location_gps(id);


--
-- TOC entry 4555 (class 2606 OID 394481)
-- Name: acornassociated_location_addresses gps_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_addresses
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acornassociated_location_gps(id) NOT VALID;


--
-- TOC entry 4711 (class 2606 OID 413872)
-- Name: acornassociated_finance_payments invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_payments
    ADD CONSTRAINT invoice_id FOREIGN KEY (invoice_id) REFERENCES public.acornassociated_finance_invoices(id) NOT VALID;


--
-- TOC entry 4814 (class 2606 OID 414417)
-- Name: acornassociated_lojistiks_transfer_invoice invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_invoice
    ADD CONSTRAINT invoice_id FOREIGN KEY (invoice_id) REFERENCES public.acornassociated_finance_invoices(id) NOT VALID;


--
-- TOC entry 4697 (class 2606 OID 412889)
-- Name: acornassociated_user_language_user language_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_language_user
    ADD CONSTRAINT language_id FOREIGN KEY (language_id) REFERENCES public.acornassociated_user_languages(id);


--
-- TOC entry 4768 (class 2606 OID 414927)
-- Name: acornassociated_lojistiks_people last_product_instance_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT last_product_instance_location_id FOREIGN KEY (last_product_instance_location_id) REFERENCES public.acornassociated_location_locations(id) NOT VALID;


--
-- TOC entry 4769 (class 2606 OID 414921)
-- Name: acornassociated_lojistiks_people last_transfer_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT last_transfer_location_id FOREIGN KEY (last_transfer_location_id) REFERENCES public.acornassociated_location_locations(id) NOT VALID;


--
-- TOC entry 4605 (class 2606 OID 394879)
-- Name: acornassociated_justice_legalcase_legalcase_category legalcase_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_legalcase_category
    ADD CONSTRAINT legalcase_category_id FOREIGN KEY (legalcase_category_id) REFERENCES public.acornassociated_justice_legalcase_categories(id) NOT VALID;


--
-- TOC entry 5153 (class 0 OID 0)
-- Dependencies: 4605
-- Name: CONSTRAINT legalcase_category_id ON acornassociated_justice_legalcase_legalcase_category; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_category_id ON public.acornassociated_justice_legalcase_legalcase_category IS 'type: XtoX';


--
-- TOC entry 4638 (class 2606 OID 395274)
-- Name: acornassociated_criminal_defendant_crimes legalcase_defendant_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_crimes
    ADD CONSTRAINT legalcase_defendant_id FOREIGN KEY (legalcase_defendant_id) REFERENCES public.acornassociated_criminal_legalcase_defendants(id) NOT VALID;


--
-- TOC entry 5154 (class 0 OID 0)
-- Dependencies: 4638
-- Name: CONSTRAINT legalcase_defendant_id ON acornassociated_criminal_defendant_crimes; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_defendant_id ON public.acornassociated_criminal_defendant_crimes IS 'labels:
  en: Crimes';


--
-- TOC entry 4700 (class 2606 OID 412902)
-- Name: acornassociated_criminal_defendant_detentions legalcase_defendant_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_detentions
    ADD CONSTRAINT legalcase_defendant_id FOREIGN KEY (legalcase_defendant_id) REFERENCES public.acornassociated_criminal_legalcase_defendants(id) NOT VALID;


--
-- TOC entry 5155 (class 0 OID 0)
-- Dependencies: 4700
-- Name: CONSTRAINT legalcase_defendant_id ON acornassociated_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_defendant_id ON public.acornassociated_criminal_defendant_detentions IS 'labels:
  en: Detentions';


--
-- TOC entry 4624 (class 2606 OID 395279)
-- Name: acornassociated_criminal_crime_evidence legalcase_evidence_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_evidence
    ADD CONSTRAINT legalcase_evidence_id FOREIGN KEY (legalcase_evidence_id) REFERENCES public.acornassociated_criminal_legalcase_evidence(id) NOT VALID;


--
-- TOC entry 4602 (class 2606 OID 394884)
-- Name: acornassociated_justice_legalcase_identifiers legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_identifiers
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id);


--
-- TOC entry 5156 (class 0 OID 0)
-- Dependencies: 4602
-- Name: CONSTRAINT legalcase_id ON acornassociated_justice_legalcase_identifiers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_justice_legalcase_identifiers IS 'tab-location: 3
type: Xto1
bootstraps:
  xs: 12';


--
-- TOC entry 4606 (class 2606 OID 394889)
-- Name: acornassociated_justice_legalcase_legalcase_category legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_legalcase_category
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id) NOT VALID;


--
-- TOC entry 5157 (class 0 OID 0)
-- Dependencies: 4606
-- Name: CONSTRAINT legalcase_id ON acornassociated_justice_legalcase_legalcase_category; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_justice_legalcase_legalcase_category IS 'tab-location: 3
bootstraps:
  xs: 12
type: XtoX
';


--
-- TOC entry 4616 (class 2606 OID 394933)
-- Name: acornassociated_civil_legalcases legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_legalcases
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id) NOT VALID;


--
-- TOC entry 5158 (class 0 OID 0)
-- Dependencies: 4616
-- Name: CONSTRAINT legalcase_id ON acornassociated_civil_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_civil_legalcases IS 'type: 1to1
nameObject: true';


--
-- TOC entry 4613 (class 2606 OID 394938)
-- Name: acornassociated_civil_hearings legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_civil_hearings
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_civil_legalcases(id) NOT VALID;


--
-- TOC entry 4665 (class 2606 OID 395284)
-- Name: acornassociated_criminal_legalcases legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcases
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id) NOT VALID;


--
-- TOC entry 5159 (class 0 OID 0)
-- Dependencies: 4665
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcases IS 'type: 1to1
nameObject: true';


--
-- TOC entry 4620 (class 2606 OID 395289)
-- Name: acornassociated_criminal_appeals legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_appeals
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5160 (class 0 OID 0)
-- Dependencies: 4620
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_appeals; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_appeals IS 'tab-location: 2';


--
-- TOC entry 4641 (class 2606 OID 395294)
-- Name: acornassociated_criminal_legalcase_defendants legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_defendants
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5161 (class 0 OID 0)
-- Dependencies: 4641
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcase_defendants IS 'labels-plural:
  en: Defendants
  ku: XweBiparastinêni';


--
-- TOC entry 4654 (class 2606 OID 395299)
-- Name: acornassociated_criminal_legalcase_related_events legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_related_events
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5162 (class 0 OID 0)
-- Dependencies: 4654
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcase_related_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcase_related_events IS 'tab-location: 2
labels:
  en: Event
  ar: الحدث المتعلقة بالقضاية الجنائية
labels-plural:
  en: Events
  ar: الأحداث المتعلقة بالقضايا الجنائية
';


--
-- TOC entry 4645 (class 2606 OID 395304)
-- Name: acornassociated_criminal_legalcase_evidence legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_evidence
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5163 (class 0 OID 0)
-- Dependencies: 4645
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcase_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcase_evidence IS 'status: broken
labels:
  en: Evidence
  ar: دليل القضايا الجنائية
labels-plural:
  en: Evidence
  ar: أدلة القضايا الجنائية
tab-location: 2';


--
-- TOC entry 4648 (class 2606 OID 395309)
-- Name: acornassociated_criminal_legalcase_prosecutor legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_prosecutor
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5164 (class 0 OID 0)
-- Dependencies: 4648
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcase_prosecutor IS 'labels:
  en: Prosecutor
  ar: المدعي العام للقضية الجنائية
labels-plural:
  en: Prosecutors
  ar: المدعون العامون للقضايا الجنائية
';


--
-- TOC entry 4657 (class 2606 OID 395314)
-- Name: acornassociated_criminal_legalcase_plaintiffs legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_plaintiffs
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5165 (class 0 OID 0)
-- Dependencies: 4657
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcase_plaintiffs IS 'labels:
  en: Plaintiff
  ar: ضحية القضية الجنائية
labels-plural:
  en: Plaintiffs
  ar: ضحايا القضية الجنائية
';


--
-- TOC entry 4661 (class 2606 OID 395319)
-- Name: acornassociated_criminal_legalcase_witnesses legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_witnesses
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5166 (class 0 OID 0)
-- Dependencies: 4661
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_legalcase_witnesses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_legalcase_witnesses IS 'labels:
  en: Witness
  ar: شاهد القضية الجنائية
labels-plural:
  en: Witnesses
  ar: شهود القضية الجنائية
';


--
-- TOC entry 4683 (class 2606 OID 395324)
-- Name: acornassociated_criminal_trials legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trials
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_criminal_legalcases(id) NOT VALID;


--
-- TOC entry 5167 (class 0 OID 0)
-- Dependencies: 4683
-- Name: CONSTRAINT legalcase_id ON acornassociated_criminal_trials; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_criminal_trials IS 'tab-location: 2';


--
-- TOC entry 4689 (class 2606 OID 395428)
-- Name: acornassociated_houseofpeace_legalcases legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_legalcases
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id) NOT VALID;


--
-- TOC entry 5168 (class 0 OID 0)
-- Dependencies: 4689
-- Name: CONSTRAINT legalcase_id ON acornassociated_houseofpeace_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_houseofpeace_legalcases IS 'type: 1to1
nameObject: true';


--
-- TOC entry 4686 (class 2606 OID 395433)
-- Name: acornassociated_houseofpeace_events legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_houseofpeace_events
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_houseofpeace_legalcases(id) NOT VALID;


--
-- TOC entry 4692 (class 2606 OID 395503)
-- Name: acornassociated_justice_scanned_documents legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_scanned_documents
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id) NOT VALID;


--
-- TOC entry 5169 (class 0 OID 0)
-- Dependencies: 4692
-- Name: CONSTRAINT legalcase_id ON acornassociated_justice_scanned_documents; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_justice_scanned_documents IS 'tab-location: 3
type: Xto1
bootstraps:
  xs: 12';


--
-- TOC entry 4831 (class 2606 OID 415313)
-- Name: acornassociated_justice_warrants legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acornassociated_justice_legalcases(id) NOT VALID;


--
-- TOC entry 5170 (class 0 OID 0)
-- Dependencies: 4831
-- Name: CONSTRAINT legalcase_id ON acornassociated_justice_warrants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acornassociated_justice_warrants IS 'tab-location: 2
type: Xto1';


--
-- TOC entry 4551 (class 2606 OID 394546)
-- Name: acornassociated_servers location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_servers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acornassociated_location_locations(id) ON DELETE SET NULL;


--
-- TOC entry 4764 (class 2606 OID 414900)
-- Name: acornassociated_lojistiks_offices location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_offices
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acornassociated_location_locations(id) NOT VALID;


--
-- TOC entry 4801 (class 2606 OID 414906)
-- Name: acornassociated_lojistiks_suppliers location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_suppliers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acornassociated_location_locations(id) NOT VALID;


--
-- TOC entry 4758 (class 2606 OID 414911)
-- Name: acornassociated_lojistiks_transfers location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acornassociated_location_locations(id) NOT VALID;


--
-- TOC entry 4826 (class 2606 OID 414916)
-- Name: acornassociated_lojistiks_warehouses location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_warehouses
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acornassociated_location_locations(id) NOT VALID;


--
-- TOC entry 4567 (class 2606 OID 394486)
-- Name: acornassociated_location_locations locations_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_locations
    ADD CONSTRAINT locations_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4792 (class 2606 OID 414457)
-- Name: acornassociated_lojistiks_products measurement_unit_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products
    ADD CONSTRAINT measurement_unit_id FOREIGN KEY (measurement_unit_id) REFERENCES public.acornassociated_lojistiks_measurement_units(id);


--
-- TOC entry 4744 (class 2606 OID 414462)
-- Name: acornassociated_lojistiks_measurement_units measurement_units_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_measurement_units
    ADD CONSTRAINT measurement_units_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4701 (class 2606 OID 412924)
-- Name: acornassociated_criminal_defendant_detentions method_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_detentions
    ADD CONSTRAINT method_id FOREIGN KEY (detention_method_id) REFERENCES public.acornassociated_criminal_detention_methods(id) NOT VALID;


--
-- TOC entry 4765 (class 2606 OID 414467)
-- Name: acornassociated_lojistiks_offices offices_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_offices
    ADD CONSTRAINT offices_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4610 (class 2606 OID 412753)
-- Name: acornassociated_justice_legalcases owner_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcases
    ADD CONSTRAINT owner_user_group_id FOREIGN KEY (owner_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 4562 (class 2606 OID 394491)
-- Name: acornassociated_location_areas parent_area_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_areas
    ADD CONSTRAINT parent_area_id FOREIGN KEY (parent_area_id) REFERENCES public.acornassociated_location_areas(id) NOT VALID;


--
-- TOC entry 4631 (class 2606 OID 395329)
-- Name: acornassociated_criminal_crime_types parent_crime_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_types
    ADD CONSTRAINT parent_crime_type_id FOREIGN KEY (parent_crime_type_id) REFERENCES public.acornassociated_criminal_crime_types(id);


--
-- TOC entry 5171 (class 0 OID 0)
-- Dependencies: 4631
-- Name: CONSTRAINT parent_crime_type_id ON acornassociated_criminal_crime_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT parent_crime_type_id ON public.acornassociated_criminal_crime_types IS 'labels-plural:
  en: Child Types';


--
-- TOC entry 4599 (class 2606 OID 394894)
-- Name: acornassociated_justice_legalcase_categories parent_legalcase_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_legalcase_categories
    ADD CONSTRAINT parent_legalcase_category_id FOREIGN KEY (parent_legalcase_category_id) REFERENCES public.acornassociated_justice_legalcase_categories(id) NOT VALID;


--
-- TOC entry 4778 (class 2606 OID 414860)
-- Name: acornassociated_lojistiks_product_categories parent_product_category_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories
    ADD CONSTRAINT parent_product_category_id FOREIGN KEY (parent_product_category_id) REFERENCES public.acornassociated_lojistiks_product_categories(id) NOT VALID;


--
-- TOC entry 4571 (class 2606 OID 394496)
-- Name: acornassociated_location_types parent_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_types
    ADD CONSTRAINT parent_type_id FOREIGN KEY (parent_type_id) REFERENCES public.acornassociated_location_types(id);


--
-- TOC entry 4706 (class 2606 OID 413877)
-- Name: acornassociated_finance_invoices payee_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT payee_user_group_id FOREIGN KEY (payee_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 4713 (class 2606 OID 413882)
-- Name: acornassociated_finance_purchases payee_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_purchases
    ADD CONSTRAINT payee_user_group_id FOREIGN KEY (payee_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 4707 (class 2606 OID 413887)
-- Name: acornassociated_finance_invoices payee_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT payee_user_id FOREIGN KEY (payee_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4714 (class 2606 OID 413892)
-- Name: acornassociated_finance_purchases payee_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_purchases
    ADD CONSTRAINT payee_user_id FOREIGN KEY (payee_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4715 (class 2606 OID 413897)
-- Name: acornassociated_finance_purchases payer_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_purchases
    ADD CONSTRAINT payer_user_group_id FOREIGN KEY (payer_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 4708 (class 2606 OID 413902)
-- Name: acornassociated_finance_invoices payer_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT payer_user_group_id FOREIGN KEY (payer_user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 4716 (class 2606 OID 413907)
-- Name: acornassociated_finance_purchases payer_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_purchases
    ADD CONSTRAINT payer_user_id FOREIGN KEY (payer_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4709 (class 2606 OID 413912)
-- Name: acornassociated_finance_invoices payer_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_invoices
    ADD CONSTRAINT payer_user_id FOREIGN KEY (payer_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4770 (class 2606 OID 414482)
-- Name: acornassociated_lojistiks_people people_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT people_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4735 (class 2606 OID 414487)
-- Name: acornassociated_lojistiks_drivers person_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers
    ADD CONSTRAINT person_id FOREIGN KEY (person_id) REFERENCES public.acornassociated_lojistiks_people(id);


--
-- TOC entry 4740 (class 2606 OID 414492)
-- Name: acornassociated_lojistiks_employees person_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_employees
    ADD CONSTRAINT person_id FOREIGN KEY (person_id) REFERENCES public.acornassociated_lojistiks_people(id);


--
-- TOC entry 4774 (class 2606 OID 414497)
-- Name: acornassociated_lojistiks_product_attributes product_attributes_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_attributes
    ADD CONSTRAINT product_attributes_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4779 (class 2606 OID 414502)
-- Name: acornassociated_lojistiks_product_categories product_categories_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories
    ADD CONSTRAINT product_categories_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4796 (class 2606 OID 414507)
-- Name: acornassociated_lojistiks_products_product_categories product_category_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories
    ADD CONSTRAINT product_category_id FOREIGN KEY (product_category_id) REFERENCES public.acornassociated_lojistiks_product_categories(id);


--
-- TOC entry 4780 (class 2606 OID 414512)
-- Name: acornassociated_lojistiks_product_categories product_category_type_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories
    ADD CONSTRAINT product_category_type_id FOREIGN KEY (product_category_type_id) REFERENCES public.acornassociated_lojistiks_product_category_types(id);


--
-- TOC entry 4783 (class 2606 OID 414517)
-- Name: acornassociated_lojistiks_product_category_types product_category_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_category_types
    ADD CONSTRAINT product_category_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4797 (class 2606 OID 414522)
-- Name: acornassociated_lojistiks_products_product_categories product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acornassociated_lojistiks_products(id);


--
-- TOC entry 4752 (class 2606 OID 414527)
-- Name: acornassociated_lojistiks_product_instances product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instances
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acornassociated_lojistiks_products(id);


--
-- TOC entry 4786 (class 2606 OID 414532)
-- Name: acornassociated_lojistiks_product_products product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acornassociated_lojistiks_products(id);


--
-- TOC entry 4775 (class 2606 OID 414537)
-- Name: acornassociated_lojistiks_product_attributes product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_attributes
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acornassociated_lojistiks_products(id);


--
-- TOC entry 4748 (class 2606 OID 414542)
-- Name: acornassociated_lojistiks_product_instance_transfer product_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer
    ADD CONSTRAINT product_instance_id FOREIGN KEY (product_instance_id) REFERENCES public.acornassociated_lojistiks_product_instances(id) NOT VALID;


--
-- TOC entry 4810 (class 2606 OID 414717)
-- Name: acornassociated_lojistiks_transfer_container_product_instance product_instance_transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT product_instance_transfer_id FOREIGN KEY (product_instance_transfer_id) REFERENCES public.acornassociated_lojistiks_product_instance_transfer(id) NOT VALID;


--
-- TOC entry 4753 (class 2606 OID 414547)
-- Name: acornassociated_lojistiks_product_instances product_instances_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instances
    ADD CONSTRAINT product_instances_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4787 (class 2606 OID 414552)
-- Name: acornassociated_lojistiks_product_products product_products_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products
    ADD CONSTRAINT product_products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4793 (class 2606 OID 414557)
-- Name: acornassociated_lojistiks_products products_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products
    ADD CONSTRAINT products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4798 (class 2606 OID 414562)
-- Name: acornassociated_lojistiks_products_product_categories products_product_categories_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories
    ADD CONSTRAINT products_product_categories_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4718 (class 2606 OID 413917)
-- Name: acornassociated_finance_receipts purchase_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_finance_receipts
    ADD CONSTRAINT purchase_id FOREIGN KEY (purchase_id) REFERENCES public.acornassociated_finance_purchases(id) NOT VALID;


--
-- TOC entry 4816 (class 2606 OID 414567)
-- Name: acornassociated_lojistiks_transfer_purchase purchase_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_purchase
    ADD CONSTRAINT purchase_id FOREIGN KEY (purchase_id) REFERENCES public.acornassociated_finance_purchases(id) NOT VALID;


--
-- TOC entry 4702 (class 2606 OID 412930)
-- Name: acornassociated_criminal_defendant_detentions reason_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_detentions
    ADD CONSTRAINT reason_id FOREIGN KEY (detention_reason_id) REFERENCES public.acornassociated_criminal_detention_reasons(id) NOT VALID;


--
-- TOC entry 4832 (class 2606 OID 415326)
-- Name: acornassociated_justice_warrants revoked_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT revoked_at_event_id FOREIGN KEY (revoked_at_event_id) REFERENCES public.acornassociated_calendar_event(id) ON DELETE SET NULL NOT VALID;


--
-- TOC entry 4759 (class 2606 OID 415264)
-- Name: acornassociated_lojistiks_transfers sent_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT sent_at_event_id FOREIGN KEY (sent_at_event_id) REFERENCES public.acornassociated_calendar_event(id) ON DELETE SET NULL NOT VALID;


--
-- TOC entry 4628 (class 2606 OID 395334)
-- Name: acornassociated_criminal_crime_sentences sentence_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_crime_sentences
    ADD CONSTRAINT sentence_type_id FOREIGN KEY (sentence_type_id) REFERENCES public.acornassociated_criminal_sentence_types(id) NOT VALID;


--
-- TOC entry 4568 (class 2606 OID 394501)
-- Name: acornassociated_location_locations server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_locations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4565 (class 2606 OID 394506)
-- Name: acornassociated_location_gps server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_gps
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4556 (class 2606 OID 394511)
-- Name: acornassociated_location_addresses server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_addresses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4558 (class 2606 OID 394516)
-- Name: acornassociated_location_area_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_area_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4563 (class 2606 OID 394521)
-- Name: acornassociated_location_areas server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_areas
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4572 (class 2606 OID 394526)
-- Name: acornassociated_location_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4666 (class 2606 OID 395339)
-- Name: acornassociated_criminal_legalcases server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcases
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4745 (class 2606 OID 414592)
-- Name: acornassociated_lojistiks_measurement_units server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_measurement_units
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4794 (class 2606 OID 414597)
-- Name: acornassociated_lojistiks_products server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4749 (class 2606 OID 414602)
-- Name: acornassociated_lojistiks_product_instance_transfer server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4771 (class 2606 OID 414607)
-- Name: acornassociated_lojistiks_people server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4819 (class 2606 OID 414612)
-- Name: acornassociated_lojistiks_vehicle_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicle_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4732 (class 2606 OID 414617)
-- Name: acornassociated_lojistiks_containers server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_containers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4822 (class 2606 OID 414622)
-- Name: acornassociated_lojistiks_vehicles server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicles
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4736 (class 2606 OID 414627)
-- Name: acornassociated_lojistiks_drivers server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4806 (class 2606 OID 414632)
-- Name: acornassociated_lojistiks_transfer_containers server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4811 (class 2606 OID 414637)
-- Name: acornassociated_lojistiks_transfer_container_product_instance server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4784 (class 2606 OID 414642)
-- Name: acornassociated_lojistiks_product_category_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_category_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4781 (class 2606 OID 414647)
-- Name: acornassociated_lojistiks_product_categories server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_categories
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4799 (class 2606 OID 414652)
-- Name: acornassociated_lojistiks_products_product_categories server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_products_product_categories
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4760 (class 2606 OID 414662)
-- Name: acornassociated_lojistiks_transfers server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id);


--
-- TOC entry 4729 (class 2606 OID 414791)
-- Name: acornassociated_lojistiks_brands server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_brands
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4741 (class 2606 OID 414807)
-- Name: acornassociated_lojistiks_employees server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_employees
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4766 (class 2606 OID 414812)
-- Name: acornassociated_lojistiks_offices server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_offices
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4776 (class 2606 OID 414829)
-- Name: acornassociated_lojistiks_product_attributes server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_attributes
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4754 (class 2606 OID 414834)
-- Name: acornassociated_lojistiks_product_instances server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instances
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4827 (class 2606 OID 414845)
-- Name: acornassociated_lojistiks_warehouses server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_warehouses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4802 (class 2606 OID 414850)
-- Name: acornassociated_lojistiks_suppliers server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_suppliers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4788 (class 2606 OID 414855)
-- Name: acornassociated_lojistiks_product_products server_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acornassociated_servers(id) NOT VALID;


--
-- TOC entry 4789 (class 2606 OID 414672)
-- Name: acornassociated_lojistiks_product_products sub_product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_products
    ADD CONSTRAINT sub_product_id FOREIGN KEY (sub_product_id) REFERENCES public.acornassociated_lojistiks_products(id);


--
-- TOC entry 4803 (class 2606 OID 414677)
-- Name: acornassociated_lojistiks_suppliers suppliers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_suppliers
    ADD CONSTRAINT suppliers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4694 (class 2606 OID 412589)
-- Name: acornassociated_university_course_teacher teacher_id; Type: FK CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_course_teacher
    ADD CONSTRAINT teacher_id FOREIGN KEY (teacher_id) REFERENCES public.acornassociated_university_teachers(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4807 (class 2606 OID 414682)
-- Name: acornassociated_lojistiks_transfer_containers transfer_container_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers
    ADD CONSTRAINT transfer_container_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4812 (class 2606 OID 414687)
-- Name: acornassociated_lojistiks_transfer_container_product_instance transfer_container_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT transfer_container_id FOREIGN KEY (transfer_container_id) REFERENCES public.acornassociated_lojistiks_transfer_containers(id);


--
-- TOC entry 5172 (class 0 OID 0)
-- Dependencies: 4812
-- Name: CONSTRAINT transfer_container_id ON acornassociated_lojistiks_transfer_container_product_instance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT transfer_container_id ON public.acornassociated_lojistiks_transfer_container_product_instance IS 'type: Xto1';


--
-- TOC entry 4813 (class 2606 OID 414692)
-- Name: acornassociated_lojistiks_transfer_container_product_instance transfer_container_product_instances_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT transfer_container_product_instances_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4750 (class 2606 OID 414697)
-- Name: acornassociated_lojistiks_product_instance_transfer transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_product_instance_transfer
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acornassociated_lojistiks_transfers(id);


--
-- TOC entry 4808 (class 2606 OID 414702)
-- Name: acornassociated_lojistiks_transfer_containers transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_containers
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acornassociated_lojistiks_transfers(id);


--
-- TOC entry 4815 (class 2606 OID 414707)
-- Name: acornassociated_lojistiks_transfer_invoice transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_invoice
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acornassociated_lojistiks_transfers(id) NOT VALID;


--
-- TOC entry 4817 (class 2606 OID 414712)
-- Name: acornassociated_lojistiks_transfer_purchase transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfer_purchase
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acornassociated_lojistiks_transfers(id) NOT VALID;


--
-- TOC entry 4703 (class 2606 OID 414780)
-- Name: acornassociated_criminal_defendant_detentions transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_defendant_detentions
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acornassociated_lojistiks_transfers(id) NOT VALID;


--
-- TOC entry 5173 (class 0 OID 0)
-- Dependencies: 4703
-- Name: CONSTRAINT transfer_id ON acornassociated_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT transfer_id ON public.acornassociated_criminal_defendant_detentions IS 'type: 1to1';


--
-- TOC entry 4761 (class 2606 OID 414727)
-- Name: acornassociated_lojistiks_transfers transfers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT transfers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4674 (class 2606 OID 395344)
-- Name: acornassociated_criminal_trial_judges trial_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_judges
    ADD CONSTRAINT trial_id FOREIGN KEY (trial_id) REFERENCES public.acornassociated_criminal_trials(id) NOT VALID;


--
-- TOC entry 4679 (class 2606 OID 395349)
-- Name: acornassociated_criminal_trial_sessions trial_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_sessions
    ADD CONSTRAINT trial_id FOREIGN KEY (trial_id) REFERENCES public.acornassociated_criminal_trials(id) NOT VALID;


--
-- TOC entry 4671 (class 2606 OID 395354)
-- Name: acornassociated_criminal_session_recordings trial_session_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_session_recordings
    ADD CONSTRAINT trial_session_id FOREIGN KEY (trial_session_id) REFERENCES public.acornassociated_criminal_trial_sessions(id) NOT VALID;


--
-- TOC entry 4569 (class 2606 OID 394531)
-- Name: acornassociated_location_locations type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_locations
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acornassociated_location_types(id) NOT VALID;


--
-- TOC entry 4552 (class 2606 OID 404483)
-- Name: acornassociated_user_user_groups type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_user_groups
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acornassociated_user_user_group_types(id) NOT VALID;


--
-- TOC entry 4833 (class 2606 OID 415297)
-- Name: acornassociated_justice_warrants type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT type_id FOREIGN KEY (warrant_type_id) REFERENCES public.acornassociated_justice_warrant_types(id) NOT VALID;


--
-- TOC entry 4573 (class 2606 OID 394536)
-- Name: acornassociated_location_types types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_types
    ADD CONSTRAINT types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4570 (class 2606 OID 394541)
-- Name: acornassociated_location_locations user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_location_locations
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acornassociated_user_user_groups(id);


--
-- TOC entry 4649 (class 2606 OID 395359)
-- Name: acornassociated_criminal_legalcase_prosecutor user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_prosecutor
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 5174 (class 0 OID 0)
-- Dependencies: 4649
-- Name: CONSTRAINT user_group_id ON acornassociated_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_group_id ON public.acornassociated_criminal_legalcase_prosecutor IS 'nameObject: true';


--
-- TOC entry 4675 (class 2606 OID 395364)
-- Name: acornassociated_criminal_trial_judges user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_judges
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acornassociated_user_user_groups(id) NOT VALID;


--
-- TOC entry 4642 (class 2606 OID 395369)
-- Name: acornassociated_criminal_legalcase_defendants user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_defendants
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5175 (class 0 OID 0)
-- Dependencies: 4642
-- Name: CONSTRAINT user_id ON acornassociated_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acornassociated_criminal_legalcase_defendants IS 'nameObject: true';


--
-- TOC entry 4650 (class 2606 OID 395374)
-- Name: acornassociated_criminal_legalcase_prosecutor user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_prosecutor
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5176 (class 0 OID 0)
-- Dependencies: 4650
-- Name: CONSTRAINT user_id ON acornassociated_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acornassociated_criminal_legalcase_prosecutor IS 'nameObject: true';


--
-- TOC entry 4658 (class 2606 OID 395379)
-- Name: acornassociated_criminal_legalcase_plaintiffs user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_plaintiffs
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5177 (class 0 OID 0)
-- Dependencies: 4658
-- Name: CONSTRAINT user_id ON acornassociated_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acornassociated_criminal_legalcase_plaintiffs IS 'nameObject: true';


--
-- TOC entry 4662 (class 2606 OID 395384)
-- Name: acornassociated_criminal_legalcase_witnesses user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_legalcase_witnesses
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5178 (class 0 OID 0)
-- Dependencies: 4662
-- Name: CONSTRAINT user_id ON acornassociated_criminal_legalcase_witnesses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acornassociated_criminal_legalcase_witnesses IS 'nameObject: true';


--
-- TOC entry 4676 (class 2606 OID 395389)
-- Name: acornassociated_criminal_trial_judges user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_criminal_trial_judges
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4695 (class 2606 OID 412594)
-- Name: acornassociated_university_students user_id; Type: FK CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_students
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5179 (class 0 OID 0)
-- Dependencies: 4695
-- Name: CONSTRAINT user_id ON acornassociated_university_students; Type: COMMENT; Schema: public; Owner: sanchez
--

COMMENT ON CONSTRAINT user_id ON public.acornassociated_university_students IS 'type: 1to1';


--
-- TOC entry 4696 (class 2606 OID 412599)
-- Name: acornassociated_university_teachers user_id; Type: FK CONSTRAINT; Schema: public; Owner: sanchez
--

ALTER TABLE ONLY public.acornassociated_university_teachers
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5180 (class 0 OID 0)
-- Dependencies: 4696
-- Name: CONSTRAINT user_id ON acornassociated_university_teachers; Type: COMMENT; Schema: public; Owner: sanchez
--

COMMENT ON CONSTRAINT user_id ON public.acornassociated_university_teachers IS 'type: 1to1';


--
-- TOC entry 4698 (class 2606 OID 412884)
-- Name: acornassociated_user_language_user user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_user_language_user
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id);


--
-- TOC entry 4772 (class 2606 OID 414737)
-- Name: acornassociated_lojistiks_people user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_people
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4834 (class 2606 OID 415318)
-- Name: acornassociated_justice_warrants user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acornassociated_justice_warrants
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4742 (class 2606 OID 414742)
-- Name: acornassociated_lojistiks_employees user_role_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_employees
    ADD CONSTRAINT user_role_id FOREIGN KEY (user_role_id) REFERENCES public.acornassociated_user_roles(id) NOT VALID;


--
-- TOC entry 4762 (class 2606 OID 414747)
-- Name: acornassociated_lojistiks_transfers vehicle_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_transfers
    ADD CONSTRAINT vehicle_id FOREIGN KEY (vehicle_id) REFERENCES public.acornassociated_lojistiks_vehicles(id) NOT VALID;


--
-- TOC entry 4737 (class 2606 OID 414752)
-- Name: acornassociated_lojistiks_drivers vehicle_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_drivers
    ADD CONSTRAINT vehicle_id FOREIGN KEY (vehicle_id) REFERENCES public.acornassociated_lojistiks_vehicles(id) NOT VALID;


--
-- TOC entry 4823 (class 2606 OID 414757)
-- Name: acornassociated_lojistiks_vehicles vehicle_type_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicles
    ADD CONSTRAINT vehicle_type_id FOREIGN KEY (vehicle_type_id) REFERENCES public.acornassociated_lojistiks_vehicle_types(id);


--
-- TOC entry 4820 (class 2606 OID 414762)
-- Name: acornassociated_lojistiks_vehicle_types vehicle_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicle_types
    ADD CONSTRAINT vehicle_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4824 (class 2606 OID 414767)
-- Name: acornassociated_lojistiks_vehicles vehicles_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_vehicles
    ADD CONSTRAINT vehicles_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 4828 (class 2606 OID 414772)
-- Name: acornassociated_lojistiks_warehouses warehouses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acornassociated_lojistiks_warehouses
    ADD CONSTRAINT warehouses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acornassociated_user_users(id) NOT VALID;


--
-- TOC entry 5048 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: justice
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


-- Completed on 2024-12-10 20:05:33 +03

--
-- PostgreSQL database dump complete
--

