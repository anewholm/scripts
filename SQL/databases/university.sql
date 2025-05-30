--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-1.pgdg24.04+1)
-- Dumped by pg_dump version 16.9 (Ubuntu 16.9-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: product; Type: SCHEMA; Schema: -; Owner: university
--

CREATE SCHEMA product;


ALTER SCHEMA product OWNER TO university;

--
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- Name: hostname; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;


--
-- Name: EXTENSION hostname; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hostname IS 'Get the server host name';


--
-- Name: http; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA public;


--
-- Name: EXTENSION http; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION http IS 'HTTP client for PostgreSQL, allows web page retrieval inside the database.';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- Name: acorn_exam_expression_detail; Type: TYPE; Schema: public; Owner: sz
--

CREATE TYPE public.acorn_exam_expression_detail AS (
	expression text,
	minimum double precision,
	maximum double precision,
	required boolean
);


ALTER TYPE public.acorn_exam_expression_detail OWNER TO sz;

--
-- Name: fn_acorn_add_websockets_triggers(character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            
            begin
        -- SELECT * FROM information_schema.tables;
        -- This assumes that fn_acorn_new_replicated_row() exists
        -- Trigger on replpica also: ENABLE ALWAYS
        execute (
          SELECT string_agg(concat(
            'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ADD COLUMN IF NOT EXISTS response text;',
            'CREATE OR REPLACE TRIGGER tr_', table_name, '_new_replicated_row
                BEFORE INSERT
                ON ', table_schema, '.', table_name, '
                FOR EACH ROW
                EXECUTE FUNCTION public.fn_acorn_new_replicated_row();',
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


ALTER FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) OWNER TO university;

--
-- Name: fn_acorn_avg(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_avg() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::int;
$$;


ALTER FUNCTION public.fn_acorn_avg() OWNER TO university;

--
-- Name: fn_acorn_avg(double precision[]); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select avg(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) OWNER TO sz;

--
-- Name: fn_acorn_calendar_create_activity_log_event(uuid, uuid, uuid, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare
calendar_id uuid;
            begin
            -- Calendar (system): acorn.justice::lang.plugin.activity_log
            -- Type: indicates the Model
            -- Status: indicates the action: create, update, delete, etc.
            calendar_id   := 'f3bc49bc-eac7-11ef-9e4a-1740a039dada';
            if not exists(select * from acorn_calendar_calendars where "id" = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid) then
                -- Just in case database seeding is happening before calendar seeding, or the system types have been deleted
                perform public.fn_acorn_calendar_seed();
            end if;
	
            return public.fn_acorn_calendar_create_event(calendar_id, owner_user_id, type_id, status_id, name);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            
            begin
            return public.fn_acorn_calendar_create_event(calendar_id, owner_user_id, type_id, status_id, name, now()::timestamp without time zone, now()::timestamp without time zone);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare

                new_event_id uuid;
            begin
            insert into public.acorn_calendar_events(calendar_id, owner_user_id) 
                values(calendar_id, owner_user_id) returning id into new_event_id;
            insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end") 
                values(new_event_id, event_type_id, event_status_id, name, date_from, date_to);
            return new_event_id;
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) OWNER TO university;

--
-- Name: fn_acorn_calendar_events_generate_event_instances(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_events_generate_event_instances() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            
            begin
            return public.fn_acorn_calendar_generate_event_instances(NEW, OLD);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_events_generate_event_instances() OWNER TO university;

--
-- Name: fn_acorn_calendar_generate_event_instances(record, record); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) RETURNS record
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
                if     old_event_part is null
                    or new_event_part.start  is distinct from old_event_part.start
                    or new_event_part."end"  is distinct from old_event_part."end"
                    or new_event_part.until  is distinct from old_event_part.until
                    or new_event_part.mask   is distinct from old_event_part.mask
                    or new_event_part.repeat is distinct from old_event_part.repeat
                    or new_event_part.mask_type is distinct from old_event_part.mask_type
                    or new_event_part.repeat_frequency     is distinct from old_event_part.repeat_frequency
                    or new_event_part.parent_event_part_id is distinct from old_event_part.parent_event_part_id
                    or new_event_part.instances_deleted    is distinct from old_event_part.instances_deleted
                then
                    -- Settings
                    select coalesce((select substring("value" from '"days_before":"([^"]+)"')
                        from system_settings where item = 'acorn_calendar_settings'), '1 year')
                        into days_before;
                    select coalesce((select substring("value" from '"days_after":"([^"]+)"')
                        from system_settings where item = 'acorn_calendar_settings'), '2 years')
                        into days_after;
                    select extract('epoch' from days_before + days_after)/3600/24.0
                        into days_count;
                    select today - days_before
                        into date_start;

                    -- For updates (id cannot change)
                    delete from acorn_calendar_instances where event_part_id = new_event_part.id;

                    -- For inserts
                    insert into acorn_calendar_instances("date", event_part_id, instance_start, instance_end, instance_num)
                    select date_start + interval '1' day * gs as "date", ev.*
                    from generate_series(0, days_count) as gs
                    inner join (
                        -- single event
                        select new_event_part.id as event_part_id,
                            new_event_part."start" as "instance_start",
                            new_event_part."end"   as "instance_end",
                            0 as instance_num
                        where new_event_part.repeat is null
                    union all
                        -- repetition, no parent container
                        select new_event_part.id as event_part_id,
                            new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs as "instance_start",
                            new_event_part."end" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs   as "instance_end",
                            gs.gs as instance_num
                        from generate_series(0, days_count) as gs
                        where not new_event_part.repeat is null and new_event_part.parent_event_part_id is null
                        and (new_event_part.instances_deleted is null or not gs.gs = any(new_event_part.instances_deleted))
                        and (new_event_part.until is null or new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs < new_event_part.until)
                        and (new_event_part.mask = 0 or new_event_part.mask & (2^date_part(new_event_part.mask_type, new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs))::int != 0)
                    union all
                        -- repetition with parent_event_part_id container calendar events
                        select new_event_part.id as event_part_id,
                            new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs as "instance_start",
                            new_event_part."end" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs   as "instance_end",
                            gs.gs as instance_num
                        from generate_series(0, days_count) as gs
                        inner join acorn_calendar_instances pcc on new_event_part.parent_event_part_id = pcc.event_part_id
                            and (pcc.date, pcc.date + 1)
                            overlaps (new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs, new_event_part."end" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs)
                        where not new_event_part.repeat is null
                        and (new_event_part.instances_deleted is null or not gs.gs = any(new_event_part.instances_deleted))
                        and (new_event_part.until is null or new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs < new_event_part.until)
                        and (new_event_part.mask = 0 or new_event_part.mask & (2^date_part(new_event_part.mask_type, new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs))::int != 0)
                    ) ev
                    on  (date_start + interval '1' day * gs, date_start + interval '1' day * (gs+1))
                    overlaps (ev.instance_start, ev.instance_end);

                    -- Recursively update child event parts
                    -- TODO: This could infinetly cycle
                    update acorn_calendar_event_parts set id = id
                        where parent_event_part_id = new_event_part.id
                        and not id = new_event_part.id;
                end if;

                return new_event_part;
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) OWNER TO university;

--
-- Name: fn_acorn_calendar_is_date(character varying, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
            
            begin

                if s is null then
                    return d;
                end if;
                perform s::timestamp without time zone;
                    return s;
                exception when others then
                    return d;
            
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) OWNER TO university;

--
-- Name: fn_acorn_calendar_lazy_create_event(character varying, uuid, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare
event_calendar_id uuid;
event_type_id uuid;
event_status_id  uuid;
            begin
            -- Lazy creates
            select into event_calendar_id id from acorn_calendar_calendars where name = calendar_name;
            if event_calendar_id is null then
                insert into acorn_calendar_calendars(name) values(calendar_name) returning id into event_calendar_id;
            end if;
        
            select into event_type_id id from acorn_calendar_event_types where name = type_name;
            if event_type_id is null then
                insert into acorn_calendar_event_types(name, calendar_id) values(type_name, event_calendar_id) returning id into event_type_id;
            end if;
        
            select into event_status_id id from acorn_calendar_event_statuses where name = status_name;
            if event_status_id is null then
                insert into acorn_calendar_event_statuses(name, calendar_id) values(status_name, event_calendar_id) returning id into event_status_id;
            end if;
        
            return public.fn_acorn_calendar_create_event(event_calendar_id, owner_user_id, event_type_id, event_status_id, event_name);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_seed(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_seed() RETURNS void
    LANGUAGE plpgsql
    AS $$
            
            begin
            -- Default calendars, with hardcoded ids
            if not exists(select * from acorn_calendar_calendars where "id" = 'ceea8856-e4c8-11ef-8719-5f58c97885a2'::uuid) then
                insert into acorn_calendar_calendars(id, "name", "system") 
                    values('ceea8856-e4c8-11ef-8719-5f58c97885a2'::uuid, 'Default', true);
            end if;
            if not exists(select * from acorn_calendar_calendars where "id" = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid) then
                insert into acorn_calendar_calendars(id, "name", "system") 
                    values('f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid, 'Activity Log', true);
            end if;

            -- System Statuses. Cannot be deleted
            if not exists(select * from acorn_calendar_event_statuses where "id" = '27446472-e4c9-11ef-bde0-9b663c96a619'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system") 
                    values('27446472-e4c9-11ef-bde0-9b663c96a619'::uuid, 'Normal', TRUE);
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "id" = 'fb2392de-e62e-11ef-b202-5fe79ff1071f') then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('fb2392de-e62e-11ef-b202-5fe79ff1071f', 'Cancelled', TRUE, 'text-decoration:line-through;border:1px dotted #fff;');
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "name" = 'Tentative') then
                insert into acorn_calendar_event_statuses("name", "system", "style") 
                    values('Tentative', TRUE, 'opacity:0.7;');
            end if;
            -- TODO: Does status "Conflict" make sense? Because maybe only 1 instance will conflict
            if not exists(select * from acorn_calendar_event_statuses where "name" = 'Conflict') then
                insert into acorn_calendar_event_statuses("name", "system", "style") 
                    values('Conflict', TRUE, 'border:1px solid red;background-color:#fff;color:#000;font-weight:bold;');
            end if;

            -- System Types. Cannot be deleted
            -- Types for each table in the activity log are lazy created
            if not exists(select * from acorn_calendar_event_types where "id" = '2f766546-e4c9-11ef-be8c-1f2daa98a10f'::uuid) then
                insert into acorn_calendar_event_types(id, "name", "system", "colour", "style") 
                    values('2f766546-e4c9-11ef-be8c-1f2daa98a10f'::uuid, 'Normal', TRUE, '#091386', 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_types where "name" = 'Meeting') then
                insert into acorn_calendar_event_types("name", "system", "colour", "style") 
                    values('Meeting', TRUE, '#C0392B', 'color:#fff');
            end if;

            -- Activity log statuses: TG_OP / Soft DELETE
            if not exists(select * from acorn_calendar_event_statuses where "id" = '7b432540-eac8-11ef-a9bc-434841a9f67b'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('7b432540-eac8-11ef-a9bc-434841a9f67b'::uuid, 'acorn.calendar::lang.models.general.insert', TRUE, 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "id" = '7c18bb7e-eac8-11ef-b4f2-ffae3296f461'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('7c18bb7e-eac8-11ef-b4f2-ffae3296f461'::uuid, 'acorn.calendar::lang.models.general.update', TRUE, 'color:#fff');
            end if;
            -- Soft DELETE (Actually an UPDATE TG_OP)
            if not exists(select * from acorn_calendar_event_statuses where "id" = '7ceca4c0-eac8-11ef-b685-f7f3f278f676'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('7ceca4c0-eac8-11ef-b685-f7f3f278f676'::uuid, 'acorn.calendar::lang.models.general.soft_delete', TRUE, 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "id" = 'f9690600-eac9-11ef-8002-5b2cbe0c12c0'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('f9690600-eac9-11ef-8002-5b2cbe0c12c0'::uuid, 'acorn.calendar::lang.models.general.soft_undelete', TRUE, 'color:#fff');
            end if;
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_seed() OWNER TO university;

--
-- Name: fn_acorn_calendar_trigger_activity_event(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_trigger_activity_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
name_optional character varying(2048);
soft_delete_optional boolean = false;
table_comment character varying(16384);
type_name character varying(1024);
title character varying(1024);
owner_user_id uuid;
event_type_id uuid;
event_status_id uuid;
activity_log_calendar_id uuid = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada';
            begin
            -- See also: fn_acorn_calendar_create_activity_log_event()
            -- Calendar (system): acorn.justice::lang.plugin.activity_log
            -- Type: indicates the Plugin & Model, e.g. "Criminal Trials"
            -- Status: indicates the action: INSERT, UPDATE, DELETE, or other custom

            -- This trigger function should only be used on final content tables
            -- This is a generic trigger. Some fields are required, others optional
            -- We use PG system catalogs because they are faster
            -- TODO: Process name-object linkage
            
            if not exists(select * from acorn_calendar_calendars where "id" = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid) then
                -- Just in case database seeding is happening before calendar seeding, or the system types have been deleted
                perform public.fn_acorn_calendar_seed();
            end if;
            
            -- Required fields
            -- created_at_event_id
            -- updated_at_event_id
            owner_user_id := NEW.created_by_user_id; -- NOT NULL
            type_name     := initcap(replace(replace(TG_TABLE_NAME, 'acorn_', ''), '_', ' '));
            title         := initcap(TG_OP) || ' ' || type_name;
			if owner_user_id is null then
				raise exception '% on %, created_by_user_id was NULL, and thus owner_user_id during fn_acorn_calendar_trigger_activity_event() auto-create', TG_OP, TG_TABLE_NAME;
			end if;

            -- Optional fields
            if exists(SELECT * FROM pg_attribute WHERE attrelid = TG_RELID AND attname = 'name') then name_optional := NEW.name; end if;
            if not name_optional is null then title = title || ':' || name_optional; end if;
            if exists(SELECT * FROM pg_attribute WHERE attrelid = TG_RELID AND attname = 'deleted_at') then soft_delete_optional := true; end if;

            -- TODO: Allow control from the table comment over event creation
            table_comment := obj_description(concat(TG_TABLE_SCHEMA, '.', TG_TABLE_NAME)::regclass, 'pg_class');

            -- Type: lang TG_TABLE_SCHEMA.TG_TABLE_NAME, acorn.justice::lang.models.related_events.label
            select into event_type_id id from acorn_calendar_event_types 
                where activity_log_related_oid = TG_RELID;
            if event_type_id is null then
                -- TODO: Colour?
                -- TODO: acorn.?::lang.models.?.label
                insert into public.acorn_calendar_event_types(name, activity_log_related_oid, calendar_id) 
                    values(type_name, TG_RELID, activity_log_calendar_id) returning id into event_type_id;
            end if;

            -- Scenarios
            case 
                when TG_OP = 'INSERT' then
                    -- Just in case the framework has specified it
                    if NEW.created_at_event_id is null then
                        -- Create event
                        event_status_id         := '7b432540-eac8-11ef-a9bc-434841a9f67b'; -- INSERT
                        NEW.created_at_event_id := public.fn_acorn_calendar_create_activity_log_event(owner_user_id, event_type_id, event_status_id, title);
                    end if;
                when TG_OP = 'UPDATE' then 
                    event_status_id := '7c18bb7e-eac8-11ef-b4f2-ffae3296f461'; -- UPDATE
                    if soft_delete_optional then
                        if not NEW.deleted_at = OLD.deleted_at then
                            case
                                when not NEW.deleted_at is null then event_status_id := '7ceca4c0-eac8-11ef-b685-f7f3f278f676'; -- Soft DELETE
                                else                                 event_status_id := 'f9690600-eac9-11ef-8002-5b2cbe0c12c0'; -- Soft un-DELETE
                            end case;
                        end if;
                    end if;
                    
                    -- Update event
                    if NEW.updated_at_event_id is null then
                        -- Create the initial Update event for this item
                        NEW.created_at_event_id := public.fn_acorn_calendar_create_activity_log_event(owner_user_id, event_type_id, event_status_id, title);
                    else
                        -- Add a new event part to the same updated event
                        insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end")
                            select event_id, type_id, status_id, name, now(), now() 
                            from public.acorn_calendar_event_parts 
                            where event_id = NEW.updated_at_event_id limit 1;
                    end if;
            end case;

            return NEW;
end;
            
$$;


ALTER FUNCTION public.fn_acorn_calendar_trigger_activity_event() OWNER TO university;

--
-- Name: fn_acorn_count(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_count() RETURNS integer
    LANGUAGE sql
    AS $$
	select 0;
$$;


ALTER FUNCTION public.fn_acorn_count() OWNER TO university;

--
-- Name: fn_acorn_count(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) RETURNS integer
    LANGUAGE sql
    AS $$
	select array_length(ints,1);
$$;


ALTER FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_exam_action_results_refresh(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_action_results_refresh() RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	refresh materialized view acorn_exam_result_internals;
end;
$$;


ALTER FUNCTION public.fn_acorn_exam_action_results_refresh() OWNER TO university;

--
-- Name: FUNCTION fn_acorn_exam_action_results_refresh(); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_exam_action_results_refresh() IS 'labels:
  en: Refresh
type: list';


--
-- Name: fn_acorn_exam_token_name(character varying[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) RETURNS character varying
    LANGUAGE sql
    AS $$
select fn_acorn_exam_token_name_internal(p_titles);
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) OWNER TO university;

--
-- Name: fn_acorn_exam_token_name(uuid, character varying[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) RETURNS character varying
    LANGUAGE sql
    AS $$
select fn_acorn_exam_token_name_internal(array_prepend(p_id::character varying, p_titles));
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) OWNER TO university;

--
-- Name: fn_acorn_exam_token_name_internal(character varying[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
	token character varying = '';
	record record;
begin
	for record in select unnest as title from unnest(p_titles) loop
		if not record.title is null and length(record.title) > 0 then
			if length(token) > 0 then token := token || '/'; end if;
			token := token || fn_acorn_exam_token_name_internal(record.title);
		end if;
	end loop;

	return token;
end;
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) OWNER TO university;

--
-- Name: fn_acorn_exam_token_name_internal(character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name_internal(p_title character varying) RETURNS character varying
    LANGUAGE sql
    AS $$
	select regexp_replace(lower(p_title), '[^a-z0-9.]+', '-', 'g');
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name_internal(p_title character varying) OWNER TO university;

--
-- Name: fn_acorn_exam_tokenize(character varying, integer); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer DEFAULT 0) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
declare
	p_regexp_matches character varying[];
	token_record record;
	expression_record acorn_exam_expression_detail;
	is_multiple bool;
	result1 double precision;
	passed int;
	results double precision[];
	results_string character varying;
	"result" double precision;
begin
	-- ########################################################## Special case of a score data point
	-- Implemented directly for performance reasons
	-- score requests
	-- so they do not have to be included in the token view
	/*
	for token_record in select 
			regexp_matches[1] as course, 
			regexp_matches[2] as material,
			regexp_matches[3] as academic_year,
			regexp_matches[4] as material_type,
			regexp_matches[5] as exam,
			regexp_matches[6] as exam_type,
			regexp_matches[7] as student_code,
		from regexp_matches(p_expr, '^score/([a-z0-9.-]+)/([a-z0-9.-]+)/([a-z0-9.-]+)/([a-z0-9.-]+)/([a-z0-9.-]+)/([a-z0-9.-]+)/([a-z0-9.-]+)/?(required)?', 'g')
	loop
		raise notice '%: Hard coded data point(%, %, %, %, %, %, %)', level, course, material, academic_year, material_type, exam, exam_type, student_code;
		select agg_array(score) into "result" 
		   FROM acorn_exam_scores sc
		      JOIN acorn_university_students s ON sc.student_id = s.id
		      JOIN acorn_exam_exam_materials em ON sc.exam_material_id = em.id
		      JOIN acorn_exam_exams e ON em.exam_id = e.id
		      JOIN acorn_exam_types et ON e.type_id = et.id
		      JOIN acorn_university_course_materials cm ON em.course_material_id = cm.id
		      JOIN acorn_university_academic_year_semesters ays ON cm.academic_year_semester_id = ays.id
		      JOIN acorn_university_academic_years ay ON ay.id = ays.academic_year_id
		      JOIN acorn_university_courses c ON cm.course_id = c.id
		      JOIN acorn_university_entities en ON c.entity_id = en.id
		      JOIN acorn_user_user_groups ug ON en.user_group_id = ug.id
		      JOIN acorn_university_materials m ON cm.material_id = m.id
		      JOIN acorn_university_material_types mt ON m.material_type_id = mt.id
			WHERE
				    fn_acorn_exam_token_name_internal(c.name)  = token_record.course
				and fn_acorn_exam_token_name_internal(m.name)  = token_record.material
				and fn_acorn_exam_token_name_internal(ay.name) = token_record.academic_year
				and fn_acorn_exam_token_name_internal(mt.name) = token_record.material_type
				and fn_acorn_exam_token_name_internal(e.name)  = token_record.exam
				and fn_acorn_exam_token_name_internal(et.name) = token_record.exam_type
				and fn_acorn_exam_token_name_internal(s.code)  = token_record.student_code;
	end loop;
	*/
	
	-- ########################################################## Use view
	-- Recursively replace all the tokens in the expr with the final value
	-- Only running the eval for the selected tokens, not the whole view
	raise notice '%: Expression(%)', level, p_expr;
	for token_record in select 
			array_agg(regexp_replace(id, '^[^:]*::', '')) as name, 
			array_agg(row("expression", minimum, maximum, required)) as expressions,
			regexp_matches[1] as match, 
			(regexp_matches[2] = '?') as passed,
			regexp_matches[3] as match_name
		from acorn_exam_tokens est
		inner join regexp_matches(p_expr, '(:(\??)([^ :=]+)=?([0-9.]*):)', 'g')
		on regexp_replace(id, '^[^:]*::', '') ~ concat('^', regexp_matches[3], '$')
		group by match, passed, match_name
	loop
		-- Now we have 1/multiple specific names for each single :token.*: match_name 
		-- some of which will lead to a recursive evaluation, some not
		-- For example:
		--   matched({
		--     course/literature/2023-2024/avg-of-materials/score/kob99/result,
		--     course/year-10/2023-2024/avg-of-materials/score/kob99/result,
		--     course/year-11/2023-2024/avg-of-materials/score/kob99/result
		--   }, course/.*/2023-2024/.*/score/kob99/result, f)
		-- No results for :regexp: that returned 0 specific names
		results := '{}';
		raise notice '  matched(%, %, %)', token_record.name, token_record.match_name, token_record.passed;
		
		for expression_record in select unnest(token_record.expressions)
		loop
			expression_record = expression_record.expression;
			raise notice '    Sub-Expression(%,%,%,%)', expression_record.expression, expression_record.minimum, expression_record.maximum, expression_record.required;
			result1 := fn_acorn_exam_tokenize(expression_record.expression, "level"+1);
			if token_record.passed then
				if expression_record.minimum is null then
					result1 := NULL;
					raise notice '      Minimum is NULL';
				elseif result1 is null then
					result1 := NULL;
					raise notice '      Result is NULL';
				else
					passed := 1;
					if result1 < expression_record.minimum then
						raise notice '      % < % => %', result1, expression_record.minimum, passed;
						passed := 0; 
					end if;
					if result1 > expression_record.maximum then 
						raise notice '      % > % => %', result1, expression_record.maximum, passed;
						passed := 0; 
					end if;
					result1 := passed;
				end if;
			end if;
			if result1 is null then
				raise notice '      => NULL (ignored)';
			else
				raise notice '      => %', result1;
				results := array_append(results, result1);
			end if;
		end loop;
		
		if array_length(results, 1) is null then
			raise notice '  No results / NULL returned. Not replacing, leave to default';
		else
			results_string := array_to_string(results, ',');
			raise notice '  Replacing % with %', token_record.match, results_string;
			p_expr := replace(p_expr, token_record.match, results_string);
		end if;
	end loop;

	-- Defaults
	for token_record in select regexp_matches[1] as match, regexp_matches[2] as match_default
		from regexp_matches(p_expr, '(:[^ :=]+=([0-9.]+):)', 'g')
		group by match, match_default
	loop
		raise notice '  Defaulting % to %', token_record.match, token_record.match_default;
		p_expr := replace(p_expr, token_record.match, token_record.match_default);
	end loop;

	-- Remove un-resolved tokens remain
	-- They did not match any rows. Missing scores for example
	if array_length(regexp_match(p_expr, '(:([^ :]+):)'), 1) != 0 then
		raise notice '  Removing un-resolved matches in %, ', p_expr;
		p_expr := regexp_replace(p_expr, '(:([^ :]+):)', '', 'g');
	end if;

	-- Namespace our spreadsheet functions to acorn
	p_regexp_matches := regexp_match(p_expr, '([a-zA-Z]+)\(');
	if array_length(p_regexp_matches, 1) != 0 then
		raise notice '  Morphing % functions() => fn_acorn_*() namespace', array_length(p_regexp_matches, 1);
		p_expr := regexp_replace(p_expr, '([a-zA-Z]+)\(', 'fn_acorn_\1(', 'g');
	end if;

	-- No replacements, no tokens
	-- Run the eval
	if trim(p_expr) = '' then
		"result" := NULL;
	elsif array_length(regexp_match(p_expr, '^[0-9.-]+$'), 1) != 0 then
		raise notice '  No more matches, number(%)', p_expr;
		"result" := p_expr::double precision;
	else
		raise notice '  No more matches, evaluating(%)', p_expr;
		execute concat('select ', p_expr) into "result";
	end if;

	return "result";
end;
$_$;


ALTER FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer) OWNER TO university;

--
-- Name: fn_acorn_first(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_first(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $1;
            $_$;


ALTER FUNCTION public.fn_acorn_first(anyelement, anyelement) OWNER TO university;

--
-- Name: fn_acorn_last(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_last(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $2;
            $_$;


ALTER FUNCTION public.fn_acorn_last(anyelement, anyelement) OWNER TO university;

--
-- Name: fn_acorn_max(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_max() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::int;
$$;


ALTER FUNCTION public.fn_acorn_max() OWNER TO university;

--
-- Name: fn_acorn_max(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select max(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_min(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_min() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::int;
$$;


ALTER FUNCTION public.fn_acorn_min() OWNER TO university;

--
-- Name: fn_acorn_min(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select min(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_new_replicated_row(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_new_replicated_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
server_domain varchar(1024);
plugin_path varchar(1024);
action varchar(2048);
params varchar(2048);
url varchar(2048);
res public.http_response;
            begin
            -- https://www.postgresql.org/docs/current/plpgsql-trigger.html
            select "domain" into server_domain from acorn_servers where hostname = hostname();
            if server_domain is null then
              new.response = 'No domain specified';
            else
                    plugin_path = '/api';
                    action = '/datachange';
                    params = concat('TG_NAME=', TG_NAME, '&TG_OP=', TG_OP, '&TG_TABLE_SCHEMA=', TG_TABLE_SCHEMA, '&TG_TABLE_NAME=', TG_TABLE_NAME, '&ID=', new.id);
                    url = concat('http://', server_domain, plugin_path, action, '?', params);
        
                    res = public.http_get(url);
                    new.response = concat(res.status, ' ', res.content);
            end if;

            return new;
end;
            $$;


ALTER FUNCTION public.fn_acorn_new_replicated_row() OWNER TO university;

--
-- Name: fn_acorn_reset_sequences(character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) RETURNS void
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


ALTER FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) OWNER TO university;

--
-- Name: fn_acorn_server_id(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_server_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
pid uuid;
            begin
        if new.server_id is null then
          select "id" into pid from acorn_servers where hostname = hostname();
          if pid is null then
            insert into acorn_servers(hostname) values(hostname()) returning id into pid;
          end if;
          new.server_id = pid;
        end if;
        return new;
end;
            $$;


ALTER FUNCTION public.fn_acorn_server_id() OWNER TO university;

--
-- Name: fn_acorn_sum(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sum() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::double precision;
$$;


ALTER FUNCTION public.fn_acorn_sum() OWNER TO university;

--
-- Name: fn_acorn_sum(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select sum(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_sum(character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sum(ints character varying) RETURNS integer
    LANGUAGE sql
    AS $$
	select sum(unnest) from (SELECT unnest(ints::integer[]))
$$;


ALTER FUNCTION public.fn_acorn_sum(ints character varying) OWNER TO university;

--
-- Name: fn_acorn_sumproduct(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sumproduct() RETURNS double precision
    LANGUAGE plpgsql
    AS $$
declare
begin
	return NULL::int;
end
$$;


ALTER FUNCTION public.fn_acorn_sumproduct() OWNER TO university;

--
-- Name: fn_acorn_sumproduct(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
declare
	len int;
	result double precision;
	values double precision[];
	weights double precision[];
begin
	len     := array_upper(ints,1) / 2;
	values  := ints[1:len];
	weights := ints[len+1:];

	result := 0;
	for i in 1..len loop
		result := result + (values[i] * weights[i]);
	end loop;

	return result;
end
$$;


ALTER FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_table_counts(character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_table_counts(_schema character varying) RETURNS TABLE("table" text, count bigint)
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


ALTER FUNCTION public.fn_acorn_table_counts(_schema character varying) OWNER TO university;

--
-- Name: fn_acorn_truncate_database(character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) RETURNS void
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


ALTER FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) OWNER TO university;

--
-- Name: fn_acorn_university_action_academic_years_clear(uuid, uuid, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_action_academic_years_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean DEFAULT false, p_for_enrollment_year boolean DEFAULT false, p_clear_exams_and_scores boolean DEFAULT false, p_confirm boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	if p_confirm then
		delete from acorn_university_hierarchies where academic_year_id = model_id;

		if p_clear_course_materials or p_clear_exams_and_scores then
			-- This will casscade to scores
			delete from acorn_exam_exam_materials
				where course_material_id in(
					select id from acorn_university_course_materials
						where enrollment_academic_year_id = model_id
				);
		end if;
		
		if p_clear_course_materials then
			-- This will cascade to calculation_course_materials
			if p_for_enrollment_year then
				delete from acorn_university_course_materials
					where enrollment_academic_year_id = model_id;
			else
				delete from acorn_university_course_materials
					where academic_year_semester_id in(
						select id from public.acorn_university_academic_year_semesters
						where academic_year_id = model_id
					);
			end if;
		end if;
	end if;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_action_academic_years_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean) OWNER TO university;

--
-- Name: FUNCTION fn_acorn_university_action_academic_years_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_university_action_academic_years_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean) IS 'labels:
  en: Clear year data
result-action: refresh
condition: exists(select * from acorn_university_hierarchies where academic_year_id = acorn_university_academic_years.id)
comment:
  en: >
    The data for the next following years can be deleted for courses starting on _this_ enrollment year.
    *or* for course materials falling in this year from any previous enrollment year course';


--
-- Name: fn_acorn_university_action_academic_years_copy_to(uuid, uuid, uuid, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean DEFAULT true, p_copy_materials boolean DEFAULT true, p_copy_seminars boolean DEFAULT true, p_copy_calculations boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	p_description text;
begin
	select 'Copied from ' || name into p_description 
		from acorn_university_academic_years 
		where id = model_id;

	-- Insert without parents
	insert into acorn_university_hierarchies(entity_id, academic_year_id, parent_id, created_by_user_id, description)
		select entity_id, p_academic_year_id, NULL, user_id, p_description
		from acorn_university_hierarchies
		where academic_year_id = model_id
		on conflict do nothing;

	-- Update parents
	update acorn_university_hierarchies h_update set parent_id = (
		-- new h.id
		select id from acorn_university_hierarchies h_new
		where h_new.academic_year_id = p_academic_year_id
		and   h_new.entity_id = (
			-- Which entity was the old parent?
			select h_old_parent.entity_id 
			from acorn_university_hierarchies h_old 
			inner join acorn_university_hierarchies h_old_parent on h_old.parent_id = h_old_parent.id
			where h_old.entity_id = h_update.entity_id
			and   h_old.academic_year_id = model_id
		)
	)
	where academic_year_id = p_academic_year_id and description = p_description;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) OWNER TO university;

--
-- Name: FUNCTION fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) IS 'labels:
  en: Copy year data to
result-action: refresh
condition: exists(select * from acorn_university_hierarchies where academic_year_id = acorn_university_academic_years.id)';


--
-- Name: fn_acorn_university_action_academic_years_import_2024(boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_action_academic_years_import_2024(import_students boolean DEFAULT true, import_bakeloria_2023_2024 boolean DEFAULT true, use_counties_as_schools boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	p_uuids uuid[];
	p_created_by_user_id uuid;
	p_imported character varying(1024) := 'Imported from 2024-v1';
	p_imported_like character varying(1024);
	-- Education Authorities (university_category) hierarchy entries
	p_top_node_entity_id   uuid := '5a722502-2cfc-11f0-8fc6-4f662cb2699a'::uuid;
	p_hi_EduAuth_2023_2024 uuid := 'bc4b7f20-3d1f-11f0-9fb4-4f2f6cb6e9bd'::uuid;
	p_hi_EduAuth_2024_2025 uuid := '25af8b3c-3d20-11f0-9b79-0f7a4e04beae'::uuid;
	-- Bakeloria school year for last years Mofadala
	-- Mofadala, end of last academic year
	-- enrolling for this year, 2024-2025
	p_2023_2024 uuid := '529bd45a-1b6c-11f0-99b6-b7f647885dbc'::uuid;
	-- University year
	-- This year, their 1st year, ending now in 2025
	p_2024_2025 uuid := '543d0928-1b6c-11f0-abc1-8bd8fff1240d'::uuid;
	-- Bakeloria course entities
  	p_science_entity    uuid := 'c555e604-2d8f-11f0-b535-bb3e95f882b4'::uuid;
  	p_literature_entity uuid := 'c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'::uuid;
  	p_year_10_entity    uuid := '4bf9dbe8-2e53-11f0-ad9d-eb001b270147'::uuid;
  	p_year_11_entity    uuid := '4bf9de9a-2e53-11f0-ad9e-1339796bedc7'::uuid;
begin
	p_created_by_user_id := fn_acorn_user_get_seed_user();
	p_imported_like      := p_imported || '%';

	-- This will cascade to entities, leafs and hierarchies
	delete from acorn_university_hierarchies where import_source like(p_imported_like);
	delete from acorn_user_user_groups       where import_source like(p_imported_like);
	delete from acorn_user_users             where import_source like(p_imported_like);
	raise notice 'Deleted previously imported data';
	-- delete from acorn_university_hierarchies where description like('Imported from%') or import_source like('Imported from%');
	-- delete from acorn_user_user_groups       where description like('Imported from%') or import_source like('Imported from%');
	-- delete from acorn_user_users             where import_source like('Imported from%');

	-- ######################################### Top Node EA for both years
	-- Education Authority hierarchies, no parent
	-- Top node Education Authority (seeded) assumed
	insert into acorn_university_hierarchies(id, entity_id, academic_year_id, parent_id, created_by_user_id, import_source)
		values(p_hi_EduAuth_2023_2024, p_top_node_entity_id, p_2023_2024, NULL, p_created_by_user_id, p_imported || ' ea:' || '2023-2024')
		on conflict(id) do nothing;
	raise notice '2023-2024 Education Authority (seeded) hierarchy checked/inserted';
	
	insert into acorn_university_hierarchies(id, entity_id, academic_year_id, parent_id, created_by_user_id, import_source)
		values(p_hi_EduAuth_2024_2025, p_top_node_entity_id, p_2024_2025, NULL, p_created_by_user_id, p_imported || ' ea:' || '2024-2025')
		on conflict(id) do nothing;
	raise notice '2024-2025 Education Authority (seeded) hierarchy checked/inserted';

	-- ######################################### Education Authorities
	-- university_mofadala_university_categories => Education Authorities
	-- Hemahengiya Zanîngehên, Desteya Perwerdehiyê, Desteya Tenduristî
	WITH inserted as (
		insert into acorn_user_user_groups(name, code, import_source) 
			select  initcap(name), 'EA' || fn_acorn_user_code_acronym(name), p_imported || ' university_mofadala_university_categories:' || uc.id
			from university_mofadala_university_categories uc
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Education Committees User Groups inserted', array_upper(p_uuids, 1);
		
	WITH inserted as (
		insert into acorn_university_entities(user_group_id, created_by_user_id, import_source)
			select ugs.id, p_created_by_user_id, ugs.import_source
			from acorn_user_user_groups ugs
			inner join unnest(p_uuids) on ugs.id = unnest
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Education Committees Entities inserted', array_upper(p_uuids, 1);

	-- Place those entities under the general Education Authority top node
	insert into acorn_university_hierarchies(entity_id, academic_year_id, parent_id, import_source, created_by_user_id)
		select unnest, p_2024_2025, p_hi_EduAuth_2024_2025, en.import_source, p_created_by_user_id 
		from acorn_university_entities en
		inner join unnest(p_uuids) on en.id = unnest;

	WITH inserted as (
		insert into acorn_university_education_authorities(entity_id)
			select unnest from unnest(p_uuids)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Education Committees inserted', array_upper(p_uuids, 1);

	-- ######################################### Universities
	-- Common manual data adjustments
	update acorn_user_user_groups set code = 'ROJ' where name = 'Rojava';
	update acorn_user_user_groups set code = 'KOB', name = 'Kobanî' where name in('Kobani', 'Kobanî');
	WITH inserted as (
		update acorn_university_hierarchies
			set parent_id = p_hi_EduAuth_2024_2025,
			import_source = p_imported || ' university_mofadala_universities:' || (
				select s.id 
				from acorn_university_universities un
				inner join acorn_university_entities en on un.entity_id = en.id
				inner join acorn_user_user_groups ug on en.user_group_id = ug.id
				inner join university_mofadala_universities s on ug.name = s.name and ug.code = s.code
				where en.id = acorn_university_hierarchies.entity_id
			)
			where academic_year_id = p_2024_2025
			and entity_id in(
				select en.id 
				from acorn_university_universities un
				inner join acorn_university_entities en on un.entity_id = en.id
				inner join acorn_user_user_groups ug on en.user_group_id = ug.id
				inner join university_mofadala_universities s on ug.name = s.name and ug.code = s.code
			)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Hierarchy universities updated', array_upper(p_uuids, 1);
	
	WITH inserted as (
		update acorn_university_entities
			set import_source = p_imported || ' university_mofadala_universities:' || (
				select s.id 
				from acorn_university_universities un
				inner join acorn_university_entities en on un.entity_id = en.id
				inner join acorn_user_user_groups ug on en.user_group_id = ug.id
				inner join university_mofadala_universities s on ug.name = s.name and ug.code = s.code
				where en.id = acorn_university_entities.id
			)
			where id in(
				select en.id 
				from acorn_university_universities un
				inner join acorn_university_entities en on un.entity_id = en.id
				inner join acorn_user_user_groups ug on en.user_group_id = ug.id
				inner join university_mofadala_universities s on ug.name = s.name and ug.code = s.code
			)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Entity universities updated', array_upper(p_uuids, 1);

	WITH inserted as (
		update acorn_user_user_groups
			set import_source = p_imported || ' university_mofadala_universities:' || (
				select s.id 
				from acorn_university_universities un
				inner join acorn_university_entities en on un.entity_id = en.id
				inner join acorn_user_user_groups ug on en.user_group_id = ug.id
				inner join university_mofadala_universities s on ug.name = s.name and ug.code = s.code
				where ug.id = acorn_user_user_groups.id
			)
			where id in(
				select ug.id 
				from acorn_university_universities un
				inner join acorn_university_entities en on un.entity_id = en.id
				inner join acorn_user_user_groups ug on en.user_group_id = ug.id
				inner join university_mofadala_universities s on ug.name = s.name and ug.code = s.code
			)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% User Group universities updated', array_upper(p_uuids, 1);

	-- Real university_mofadala_universities data
	WITH inserted as (
		insert into acorn_user_user_groups(name, code, import_source) 
			select initcap(name), code, p_imported || ' university_mofadala_universities:' || s.id
			from university_mofadala_universities s
			on conflict do nothing
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% University User Groups inserted', array_upper(p_uuids, 1);
		
	WITH inserted as (
		insert into acorn_university_entities(user_group_id, created_by_user_id, import_source)
			select ugs.id, p_created_by_user_id, ugs.import_source
			from acorn_user_user_groups ugs
			inner join unnest(p_uuids) on ugs.id = unnest
			on conflict do nothing
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% University Entities inserted', array_upper(p_uuids, 1);

	-- Place them under their associated university_category_id
	insert into acorn_university_hierarchies(academic_year_id, import_source, created_by_user_id, entity_id, parent_id)
		select p_2024_2025, p_imported || ' university_mofadala_universities:' || un.id, p_created_by_user_id,
			(select id from acorn_university_entities where import_source = p_imported || ' university_mofadala_universities:' || un.id), 
			(select id from acorn_university_hierarchies hi where import_source = p_imported || ' university_mofadala_university_categories:' || uc.id and hi.academic_year_id = p_2024_2025)
			from university_mofadala_universities un
			inner join university_mofadala_university_categories uc on uc.id = un.university_category_id
		on conflict do nothing;

	WITH inserted as (
		insert into acorn_university_universities(entity_id)
			select unnest from unnest(p_uuids)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Universities inserted', array_upper(p_uuids, 1);

    -- ######################################### Faculties
	WITH inserted as (
		insert into acorn_user_user_groups(name, code, import_source) 
			select  initcap(name), fn_acorn_user_code_acronym(name) || id, p_imported || ' university_mofadala_branches:' || s.id
			from university_mofadala_branches s
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Faculty User Groups inserted', array_upper(p_uuids, 1);

	WITH inserted as (
		insert into acorn_university_entities(user_group_id, created_by_user_id, import_source)
			select ugs.id, p_created_by_user_id, ugs.import_source
			from acorn_user_user_groups ugs
			inner join unnest(p_uuids) on ugs.id = unnest
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Faculty Entities inserted', array_upper(p_uuids, 1);

	-- Place them under their associated university_id
	insert into acorn_university_hierarchies(academic_year_id, import_source, created_by_user_id, entity_id, parent_id)
		select p_2024_2025, p_imported || ' university_mofadala_branches:' || br.id, p_created_by_user_id,
			(select id from acorn_university_entities where import_source = p_imported || ' university_mofadala_branches:' || br.id), 
			(select id from acorn_university_hierarchies hi where import_source = p_imported || ' university_mofadala_universities:' || un.id and hi.academic_year_id = p_2024_2025)
			from university_mofadala_branches br
			inner join university_mofadala_universities un on un.id = br.university_id
		on conflict do nothing;
	
	WITH inserted as (
		insert into acorn_university_faculties(entity_id)
			select unnest from unnest(p_uuids)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Faculties inserted', array_upper(p_uuids, 1);

	-- ######################################### Courses
	WITH inserted as (
		insert into acorn_user_user_groups(name, code, import_source)
			select case when name = '' then 'Course' else initcap(name) end case, 
				fn_acorn_user_code_acronym(name) || id, 
				p_imported || ' university_mofadala_departments:' || s.id
			from university_mofadala_departments s
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Course User Groups inserted', array_upper(p_uuids, 1);

	WITH inserted as (
		insert into acorn_university_entities(user_group_id, created_by_user_id, import_source)
			select ugs.id, p_created_by_user_id, ugs.import_source
			from acorn_user_user_groups ugs
			inner join unnest(p_uuids) on ugs.id = unnest
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Course Entities inserted', array_upper(p_uuids, 1);

	-- Place them under their associated university_id
	insert into acorn_university_hierarchies(academic_year_id, import_source, created_by_user_id, entity_id, parent_id)
		select p_2024_2025, p_imported || ' university_mofadala_departments:' || dp.id, p_created_by_user_id,
			(select id from acorn_university_entities where import_source = p_imported || ' university_mofadala_departments:' || dp.id), 
			(select id from acorn_university_hierarchies hi where import_source = p_imported || ' university_mofadala_branches:' || br.id and hi.academic_year_id = p_2024_2025)
			from university_mofadala_departments dp
			inner join university_mofadala_branches br on br.id = dp.branche_id
		on conflict do nothing;
	raise notice 'Course Entities placed under their Departments (branches)';

	WITH inserted as (
		insert into acorn_university_courses(entity_id)
			select unnest from unnest(p_uuids)
			returning id
		)
		select array_agg(inserted.id) into p_uuids from inserted;
	raise notice '% Courses inserted', array_upper(p_uuids, 1);

	if import_students then
		-- ######################################### Students
		-- university_mofadala_baccalaureate_marks: bakeloria code, father_name & mother_name, full_name, place_and_date_of_birth
		-- was copied in to university_mofadala_students during registration already
		WITH inserted as (
			-- acorn_university_students:
			-- id, username, email, password, 
			-- name, surname, birth_date,
			-- 
			-- activated_at, activation_code, created_ip_address, last_ip_address, persist_code, reset_password_code, 
			-- last_login, last_seen,
			-- created_at, updated_at, deleted_at, 
			-- permissions, is_guest, is_superuser, is_activated, is_system_user, 
			--
			-- acorn_imap_username, acorn_imap_password, acorn_imap_server, acorn_imap_port, acorn_imap_protocol, acorn_imap_encryption, acorn_imap_authentication, acorn_imap_validate_cert, 
			-- acorn_smtp_server, acorn_smtp_port, acorn_smtp_encryption, acorn_smtp_authentication, acorn_smtp_username, acorn_smtp_password, 
			-- acorn_messaging_sounds, acorn_messaging_email_notifications, acorn_messaging_autocreated, acorn_imap_last_fetch, 
			-- acorn_default_calendar, acorn_start_of_week, acorn_default_event_time_from, acorn_default_event_time_to
			insert into acorn_user_users(
				username, email, password,
				name, surname, birth_date, 
				-- Special, temporary during import:
				import_source
			)
				-- ## university_mofadala_students:
				-- code, email, national_id, 
				-- first_name, last_name, birth_date, 
				--
				-- HANDLED BELOW:
				-- need_housing, from_the_occupied_territories, families_of_martyrs, he_served_in_the_army, 
				-- department_id, baccalaureate_mark_id, type_certificate_id, 
				-- 
				-- TODO:
				-- father_name, mother_name, 
				-- self_image, image, 
				-- place_of_birth, 
				-- national_id, national_id_type, 
				-- gender, marital_status, 
				-- family_place, cumin, city_id, address, 
				-- cell_phone, tell_phone, emergency_number, 
				--
				-- center_id, mofadala_year_id, 
				-- hs_certificate_image, certificate_date, certificate_language_id, certificate_source, 
				-- attending_the_nomination_examination, there_is_a_candidacy_exam, candidate_exam_id, exam_center_id, candidacy_examination_score, 
				-- created_at, updated_at, 
				-- the_total, current_desire, enrollment_conflict, secondary_reallocation, enrollment_process_notes
				--
				-- NOT_REQUIRED|USED:
				-- user_id, constraint, id, information, 
				-- notes has 33 arabic values (IGNORED)
				select
					-- From university_mofadala_students
					st.code, 
					case 
						when email = 'a@b.com' then NULL
						else email
					end, 
					national_id, -- => password
					first_name, last_name, birth_date,
					
					p_imported || ' university_mofadala_students:' || st.id
				from university_mofadala_students st
				left join university_mofadala_baccalaureate_marks bm on st.baccalaureate_mark_id = bm.id
				on conflict do nothing
				returning id
			)
			select array_agg(inserted.id) into p_uuids from inserted;
		raise notice '% Student Users inserted', array_upper(p_uuids, 1);

		WITH inserted as (
			insert into acorn_university_students(
					user_id, code, import_source,
					-- Legacy & from university_mofadala_baccalaureate_marks
					legacy_import_the_total, legacy_import_result, legacy_import_avg, legacy_import_total_mark
				)
				select u.id, st.code, p_imported || ' university_mofadala_students:' || st.id,
					-- Legacy & from university_mofadala_baccalaureate_marks
					st.the_total, bm.result, bm.avg, bm.total_mark
				from acorn_user_users u,
					university_mofadala_students st
					left join university_mofadala_baccalaureate_marks bm on st.baccalaureate_mark_id = bm.id
					where u.import_source = p_imported || ' university_mofadala_students:' || st.id
				on conflict do nothing
				returning id
			)
			select array_agg(inserted.id) into p_uuids from inserted;
		raise notice '% Students + code inserted', array_upper(p_uuids, 1);

		-- ######################################### Special status
		-- families_of_martyrs:           021c0f46-3b96-11f0-add5-1fdf3952358b
		-- from_the_occupied_territories: 021c1022-3b96-11f0-add6-9b77f9e97678
		-- he_served_in_the_army:         021c104a-3b96-11f0-add7-bf3af6dabafb
		-- need_housing:                  021c1068-3b96-11f0-add8-a7fe27552a6d
		WITH inserted as (
			insert into acorn_university_student_status(student_id, student_status_id)
				select s.id, '021c0f46-3b96-11f0-add5-1fdf3952358b'::uuid 
					from acorn_user_users u
					inner join acorn_university_students s on s.user_id = u.id,
					university_mofadala_students st
					where u.import_source = p_imported || ' university_mofadala_students:' || st.id
					and st.families_of_martyrs
				on conflict do nothing
				returning student_id
			)
			select array_agg(inserted.student_id) into p_uuids from inserted;
		raise notice '% Students families_of_martyrs statuses inserted', array_upper(p_uuids, 1);
	
		WITH inserted as (
			insert into acorn_university_student_status(student_id, student_status_id)
				select s.id, '021c1022-3b96-11f0-add6-9b77f9e97678'::uuid 
					from acorn_user_users u
					inner join acorn_university_students s on s.user_id = u.id,
					university_mofadala_students st
					where u.import_source = p_imported || ' university_mofadala_students:' || st.id
					and st.from_the_occupied_territories
				on conflict do nothing
				returning student_id
			)
			select array_agg(inserted.student_id) into p_uuids from inserted;
		raise notice '% Students from_the_occupied_territories statuses inserted', array_upper(p_uuids, 1);

		WITH inserted as (
			insert into acorn_university_student_status(student_id, student_status_id)
				select s.id, '021c104a-3b96-11f0-add7-bf3af6dabafb'::uuid 
					from acorn_user_users u
					inner join acorn_university_students s on s.user_id = u.id,
					university_mofadala_students st
					where u.import_source = p_imported || ' university_mofadala_students:' || st.id
					and st.he_served_in_the_army
				on conflict do nothing
				returning student_id
			)
			select array_agg(inserted.student_id) into p_uuids from inserted;
		raise notice '% Students he_served_in_the_army statuses inserted', array_upper(p_uuids, 1);

		WITH inserted as (
			insert into acorn_university_student_status(student_id, student_status_id)
				select s.id, '021c1068-3b96-11f0-add8-a7fe27552a6d'::uuid 
					from acorn_user_users u
					inner join acorn_university_students s on s.user_id = u.id,
					university_mofadala_students st
					where u.import_source = p_imported || ' university_mofadala_students:' || st.id
					and st.need_housing
				on conflict do nothing
				returning student_id
			)
			select array_agg(inserted.student_id) into p_uuids from inserted;
		raise notice '% Students need_housing statuses inserted', array_upper(p_uuids, 1);

		-- ######################################### Enrolled Departments 
		-- Enroll 2023-2024 Students on to 2024-2025 courses
		WITH inserted as (
			insert into acorn_user_user_group_version(user_group_version_id, user_id)
				select hi.user_group_version_id, u.id
					from acorn_university_hierarchies hi,
					university_mofadala_students mst
					inner join acorn_user_users u on u.import_source = p_imported || ' university_mofadala_students:' || mst.id
					where hi.import_source = p_imported || ' university_mofadala_departments:' || mst.department_id
					and hi.academic_year_id = p_2024_2025
					and not mst.department_id is null
				on conflict do nothing
				returning user_id
			)
			select array_agg(inserted.user_id) into p_uuids from inserted;
		raise notice '% Students enrolled on to courses', array_upper(p_uuids, 1);

		if import_bakeloria_2023_2024 then
			-- ######################################### Bakeloria
			-- Record 2023-2024 Students school scores
			-- Requires seeding of Literature, Science, Year 10 & 11 entities

			-- ## university_mofadala_students:
			-- type_certificate_id:     1-Science, 2-Literature
			-- certificate_language_id: 1-Kurdish, 2-Arabic
			-- certificate_source:      Autonomous_Administration, Syrian
			-- certificate_date:
			-- baccalaureate_mark_id:   => university_mofadala_baccalaureate_marks.id
			
			-- ## university_mofadala_baccalaureate_marks:
			-- county:               Firat, Tepqa, Reqa, şehba, Cizîrê
			-- certificate:          Literature, Science
			-- certificate_language: Kurdish, Arabic
			-- result:               Binket, serket, Serket, Serkeftî
			-- code:                 Should be same as students table
			-- avg:                  ?
			-- total_mark:           ?
			-- TODO: Process certificate_language

			-- ######################################### Schools (counties)
			if use_counties_as_schools then
				with inserted as (
					insert into acorn_user_user_groups(name, code, import_source)
						select initcap(bm.name) || ' school', fn_acorn_user_code(name), p_imported || ' university_mofadala_baccalaureate_marks(county school):' || bm.name
						from (
							select distinct(county) as name
							from university_mofadala_baccalaureate_marks
						) bm
						on conflict do nothing
						returning id
				)
					select array_agg(inserted.id) into p_uuids from inserted;
				raise notice '% School (counties) User Groups inserted', array_upper(p_uuids, 1);
		
				with inserted as (
					insert into acorn_university_entities(user_group_id, created_by_user_id, import_source)
						select ugs.id, p_created_by_user_id, ugs.import_source
						from acorn_user_user_groups ugs
						inner join unnest(p_uuids) on ugs.id = unnest
						returning id
				)
					select array_agg(inserted.id) into p_uuids from inserted;
				raise notice '% School Entities inserted', array_upper(p_uuids, 1);
			else
				with inserted as (
					insert into acorn_user_user_groups(name, code, import_source)
						select 'School', 'SCH', p_imported || ' university_mofadala_baccalaureate_marks(county school):' || 'School'
						on conflict do nothing
						returning id
				)
					select array_agg(inserted.id) into p_uuids from inserted;
				raise notice '% School (counties) User Groups inserted', array_upper(p_uuids, 1);
		
				with inserted as (
					insert into acorn_university_entities(user_group_id, created_by_user_id, import_source)
						select ugs.id, p_created_by_user_id, ugs.import_source
						from acorn_user_user_groups ugs
						inner join unnest(p_uuids) on ugs.id = unnest
						returning id
				)
					select array_agg(inserted.id) into p_uuids from inserted;
				raise notice '% School Entities inserted', array_upper(p_uuids, 1);
			end if;
		
			-- Place them under the general Education Authority
			insert into acorn_university_hierarchies(entity_id, academic_year_id, parent_id, import_source, created_by_user_id)
				select en.id, p_2023_2024, p_hi_EduAuth_2023_2024, en.import_source, p_created_by_user_id 
				from acorn_university_entities en
				inner join unnest(p_uuids) on en.id = unnest;
	
			with inserted as (
				insert into acorn_university_schools(entity_id)
					select unnest from unnest(p_uuids)
					returning id
			)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Schools inserted', array_upper(p_uuids, 1);
	
			-- ######################################### Courses
			-- These should be seeded. We add them anyway just in case
			-- Year 10, 11, Science & Literature
			with inserted as (
				insert into acorn_user_user_groups(id, name, code, import_source)
					-- Copied from seeding in comment:
    				select 'a7237520-2d8f-11f0-a834-2b294fbfca54'::uuid, 'Science', 'SCI',    p_imported || ' standard bakeloria course seeding:1' union all
   					select 'a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b'::uuid, 'Literature', 'LIT', p_imported || ' standard bakeloria course seeding:2' union all
    				select '21397b0c-2e53-11f0-8a85-1759860470a0'::uuid, 'Year 10', 'Y10',    p_imported || ' standard bakeloria course seeding:3' union all
    				select '21397d32-2e53-11f0-8a86-abb690facbb0'::uuid, 'Year 11', 'Y11',    p_imported || ' standard bakeloria course seeding:4'
					on conflict do nothing
					returning id
			)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Bakeloria courses User Group inserted', array_upper(p_uuids, 1);
		
			with inserted as (
				insert into acorn_university_entities(id, user_group_id, created_by_user_id, import_source)
					select 'c555e604-2d8f-11f0-b535-bb3e95f882b4'::uuid, 'a7237520-2d8f-11f0-a834-2b294fbfca54'::uuid, p_created_by_user_id, p_imported || ' standard bakeloria course seeding:1' union all
				  	select 'c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'::uuid, 'a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b'::uuid, p_created_by_user_id, p_imported || ' standard bakeloria course seeding:2' union all
				  	select '4bf9dbe8-2e53-11f0-ad9d-eb001b270147'::uuid, '21397b0c-2e53-11f0-8a85-1759860470a0'::uuid, p_created_by_user_id, p_imported || ' standard bakeloria course seeding:3' union all
				  	select '4bf9de9a-2e53-11f0-ad9e-1339796bedc7'::uuid, '21397d32-2e53-11f0-8a86-abb690facbb0'::uuid, p_created_by_user_id, p_imported || ' standard bakeloria course seeding:4'
					on conflict do nothing
					returning id
			)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Bakeloria course Entities inserted', array_upper(p_uuids, 1);

			-- Place all courses under every imported school
			-- This always needs to happen
			with inserted as (
				insert into acorn_university_hierarchies(academic_year_id, import_source, created_by_user_id, entity_id, parent_id)
					select p_2023_2024, en.import_source, p_created_by_user_id,
						en.id, hi.id
					from acorn_university_entities en,
					acorn_university_hierarchies hi
					inner join acorn_university_schools sch on hi.entity_id = sch.entity_id and hi.academic_year_id = p_2023_2024
					where en.id in(
						-- Bakeloria course entities above
						'c555e604-2d8f-11f0-b535-bb3e95f882b4'::uuid, 
						'c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'::uuid, 
						'4bf9dbe8-2e53-11f0-ad9d-eb001b270147'::uuid, 
						'4bf9de9a-2e53-11f0-ad9e-1339796bedc7'::uuid
					)
					on conflict do nothing -- entity, parent, year unique
					returning id
			)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Bakeloria courses attatched to schools', array_upper(p_uuids, 1);

			with inserted as (
				insert into acorn_university_courses(id, entity_id)
					-- Bakeloria course entities above
					-- Science, Literature
					select 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'c555e604-2d8f-11f0-b535-bb3e95f882b4'::uuid union all
					select '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'::uuid union all
					-- Year 10,11
					select 'f6210e20-2e53-11f0-b41e-bbc1e97e17dc'::uuid, '4bf9dbe8-2e53-11f0-ad9d-eb001b270147'::uuid union all
					select 'f62111ea-2e53-11f0-b41f-ff3908814684'::uuid, '4bf9de9a-2e53-11f0-ad9e-1339796bedc7'::uuid
				on conflict do nothing
				returning id
			)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Bakeloria courses inserted', array_upper(p_uuids, 1);

			-- ######################################### Students => Bakeloria courses
			WITH inserted as (
				insert into acorn_user_user_group_version(user_group_version_id, user_id)
					select hi.user_group_version_id, u.id
						from acorn_university_hierarchies hi
						inner join acorn_university_hierarchies hiP on hi.parent_id = hiP.id,
						university_mofadala_students mst
						inner join university_mofadala_baccalaureate_marks bm on mst.baccalaureate_mark_id = bm.id
						inner join acorn_user_users u on u.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where hiP.import_source = p_imported || ' university_mofadala_baccalaureate_marks(county school):' || bm.county
						and hi.academic_year_id = p_2023_2024
						-- Bakeloria course entities above
						and (  
							   (hi.entity_id = 'c555e604-2d8f-11f0-b535-bb3e95f882b4'::uuid and bm.certificate = 'Science')
							or (hi.entity_id = 'c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'::uuid and bm.certificate = 'Literature')
							or hi.entity_id = '4bf9dbe8-2e53-11f0-ad9d-eb001b270147'::uuid -- Year 10
							or hi.entity_id = '4bf9de9a-2e53-11f0-ad9e-1339796bedc7'::uuid -- Year 11
						)
					on conflict do nothing -- PK: user_id, user_group_version_id
					returning user_id
				)
				select array_agg(inserted.user_id) into p_uuids from inserted;
			raise notice '% Students placed on to Bakeloria courses in schools', array_upper(p_uuids, 1);

			-- ######################################### Materials & Course materials
			-- These should be seeded, but we add just in case
			-- we assume the material type
			-- Literature (adabi) & Science (el) Bakeloria
			insert into acorn_university_materials(id, name, description, material_type_id, created_by_user_id)
				select 'cdc800ae-28be-11f0-a8a6-334555029afd'::uuid, 'Math',       NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'd675a530-28be-11f0-a2c9-9bb10fa15bd3'::uuid, 'Biology',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'dd494c0e-28be-11f0-94e1-a7b2083dd749'::uuid, 'Physics',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'e427a282-28be-11f0-8856-a7abd8a449c5'::uuid, 'Geography',  NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'ecf3dae8-28be-11f0-91f7-f31527b6ca23'::uuid, 'Chemistry',  NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'f3c853a8-28be-11f0-8938-73b157eb85a1'::uuid, 'Kurdish',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'::uuid, 'English',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select '005bba60-28bf-11f0-bf7f-cff663f8102b'::uuid, 'Arabic',     NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'd43af2a2-2bd9-11f0-b08b-5fd59b502470'::uuid, 'History',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'd8168f4e-2bd9-11f0-97a5-1b42cf640b5b'::uuid, 'Philosophy', NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'd84f8434-2bd9-11f0-bfa1-7b92380571bd'::uuid, 'Sociology',  NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select 'd88f0f6e-2bd9-11f0-8846-8bc9dcb96017'::uuid, 'Jineologi',  NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				-- Year 10,11 Bakeloria
				select '7f5c3dc8-2e53-11f0-8600-6ff513625846'::uuid, 'Year 10',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id union all
				select '7f5c4156-2e53-11f0-8601-43470f236a9e'::uuid, 'Year 11',    NULL, '6b4bae9a-149f-11f0-a4e5-779d31ace22e'::uuid, p_created_by_user_id
				on conflict do nothing;
			raise notice 'Bakeloria materials checked';

			insert into acorn_university_course_materials(id, course_id, material_id, required, minimum, maximum, weight, academic_year_semester_id, course_year_id, created_by_user_id)
				-- Bakeloria - Science: kurdish_language	english	math	biology	chemistry	phisic	arabic_language	geneology	Sociology
				select 'f36c46d6-2e3a-11f0-b6f1-17b78d5f0aec'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'f3c853a8-28be-11f0-8938-73b157eb85a1'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'f36c48de-2e3a-11f0-b6f2-3b9b22699d6a'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd7166b8c-2d91-11f0-8b19-e7d49c2e84f1'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'cdc800ae-28be-11f0-a8a6-334555029afd'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd7613d74-2d91-11f0-a545-27a082b4a92e'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'd675a530-28be-11f0-a2c9-9bb10fa15bd3'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select '90916acc-2e3b-11f0-8dcc-67434a77fd63'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'ecf3dae8-28be-11f0-91f7-f31527b6ca23'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd7f26d1c-2d91-11f0-a26f-f3e5473b3167'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'dd494c0e-28be-11f0-94e1-a7b2083dd749'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd60faf78-2d91-11f0-91b5-4ba74601f388'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, '005bba60-28bf-11f0-bf7f-cff663f8102b'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd7ceec66-2d91-11f0-b5d5-db13369d9435'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'd88f0f6e-2bd9-11f0-8846-8bc9dcb96017'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd7a990f6-2d91-11f0-95db-c330df9f103b'::uuid, 'ffc92184-2d8f-11f0-9f2f-af2e2a870b91'::uuid, 'd84f8434-2bd9-11f0-bfa1-7b92380571bd'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				-- Bakeloria - Literature: kurdish_language	english_language	arabic_language	history	geography	philosophy	sociology	science_of_woman
				select 'f36c4974-2e3a-11f0-b6f3-b33bd4aa8e09'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'f3c853a8-28be-11f0-8938-73b157eb85a1'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'f36c49f6-2e3a-11f0-b6f4-53ae331645fa'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd83b7214-2d91-11f0-81ee-973d6ea6519e'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, '005bba60-28bf-11f0-bf7f-cff663f8102b'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd882e05e-2d91-11f0-90fa-83869ea90163'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'd43af2a2-2bd9-11f0-b08b-5fd59b502470'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd95cc1d4-2d91-11f0-9084-33d5bf8f0fe0'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'e427a282-28be-11f0-8856-a7abd8a449c5'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd8c70de2-2d91-11f0-adfc-f320089c0508'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'd8168f4e-2bd9-11f0-97a5-1b42cf640b5b'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd8ed5b64-2d91-11f0-a8f4-d31ec556c6aa'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'd84f8434-2bd9-11f0-bfa1-7b92380571bd'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select 'd912a6bc-2d91-11f0-800e-6f442946f1de'::uuid, '001382ce-2d90-11f0-b3fe-bf0261495ded'::uuid, 'd88f0f6e-2bd9-11f0-8846-8bc9dcb96017'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				-- Year 10,11
				select '4e2005fe-2e54-11f0-982d-23d1bc2b7e01'::uuid, 'f6210e20-2e53-11f0-b41e-bbc1e97e17dc'::uuid, '7f5c3dc8-2e53-11f0-8600-6ff513625846'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id union all
				select '4e20093c-2e54-11f0-982e-63aa632c9cfa'::uuid, 'f62111ea-2e53-11f0-b41f-ff3908814684'::uuid, '7f5c4156-2e53-11f0-8601-43470f236a9e'::uuid, false, 0, 100, 50, '9c6e1d20-2bd1-11f0-8119-93a057070d34'::uuid, '5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'::uuid, p_created_by_user_id
				on conflict do nothing;
			raise notice 'Bakeloria course materials checked';
				
			-- ######################################### Exams
			-- We assume the exam
			insert into acorn_exam_exam_materials(id, exam_id, course_material_id, created_by_user_id)
				-- Bakeloria - Science: kurdish_language	english	math	biology	chemistry	phisic	arabic_language	geneology	Sociology
				select '457d9378-2e39-11f0-ba8b-6f3ecb4364d7'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd60faf78-2d91-11f0-91b5-4ba74601f388'::uuid, p_created_by_user_id union all
				select '457d945e-2e39-11f0-ba8c-c76bfb0d6f2b'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd7166b8c-2d91-11f0-8b19-e7d49c2e84f1'::uuid, p_created_by_user_id union all
				select '457d94b8-2e39-11f0-ba8e-b719896c4900'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd7613d74-2d91-11f0-a545-27a082b4a92e'::uuid, p_created_by_user_id union all
				select '457d9508-2e39-11f0-ba90-034ead284875'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd7a990f6-2d91-11f0-95db-c330df9f103b'::uuid, p_created_by_user_id union all
				select '457d953a-2e39-11f0-ba91-c3ac478afe9d'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd7ceec66-2d91-11f0-b5d5-db13369d9435'::uuid, p_created_by_user_id union all
				select '457d9562-2e39-11f0-ba92-a323dc5ecf81'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd7f26d1c-2d91-11f0-a26f-f3e5473b3167'::uuid, p_created_by_user_id union all
				select 'ffc94c10-2e3c-11f0-a5ae-af23be35f757'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'f36c46d6-2e3a-11f0-b6f1-17b78d5f0aec'::uuid, p_created_by_user_id union all
				select 'ffc94e0e-2e3c-11f0-a5af-9bfe9eafb920'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'f36c48de-2e3a-11f0-b6f2-3b9b22699d6a'::uuid, p_created_by_user_id union all
				select 'ffc94e86-2e3c-11f0-a5b0-ff3bca5d218c'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, '90916acc-2e3b-11f0-8dcc-67434a77fd63'::uuid, p_created_by_user_id union all
				-- Bakeloria - Literature: kurdish_language	english_language	arabic_language	history	geography	philosophy	sociology	science_of_woman
				select '457d95a8-2e39-11f0-ba94-7388a320a161'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd83b7214-2d91-11f0-81ee-973d6ea6519e'::uuid, p_created_by_user_id union all
				select '70d93d42-2e39-11f0-ac40-5ba568515e38'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd882e05e-2d91-11f0-90fa-83869ea90163'::uuid, p_created_by_user_id union all
				select '70d93e3c-2e39-11f0-ac42-af3e12ded276'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd8c70de2-2d91-11f0-adfc-f320089c0508'::uuid, p_created_by_user_id union all
				select '70d93eb4-2e39-11f0-ac43-972da636cb7c'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd8ed5b64-2d91-11f0-a8f4-d31ec556c6aa'::uuid, p_created_by_user_id union all
				select '70d93f18-2e39-11f0-ac44-73bb6ff561a0'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd912a6bc-2d91-11f0-800e-6f442946f1de'::uuid, p_created_by_user_id union all
				select '70d93fea-2e39-11f0-ac46-971488fba3f3'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'd95cc1d4-2d91-11f0-9084-33d5bf8f0fe0'::uuid, p_created_by_user_id union all
				select '3b38f444-2e3d-11f0-8ff5-f3c23880ba04'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'f36c4974-2e3a-11f0-b6f3-b33bd4aa8e09'::uuid, p_created_by_user_id union all
				select '3b38f7fa-2e3d-11f0-8ff6-63d00474903f'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, 'f36c49f6-2e3a-11f0-b6f4-53ae331645fa'::uuid, p_created_by_user_id union all
				-- Year 10,11
				select 'be8521f8-2e54-11f0-946a-670c67ddf3e8'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, '4e2005fe-2e54-11f0-982d-23d1bc2b7e01'::uuid, p_created_by_user_id union all
				select 'be8525b8-2e54-11f0-946b-87c080955d16'::uuid, '0816bbee-2bdd-11f0-8400-57e43cb8bcc9'::uuid, '4e20093c-2e54-11f0-982e-63aa632c9cfa'::uuid, p_created_by_user_id
				on conflict do nothing;
			raise notice 'Bakeloria exam materials checked';

			-- ######################################### Scores
			-- Bakeloria - Science: kurdish_language english_language math biology chemistry physics arabic_language science_of_woman sociology
			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d9378-2e39-11f0-ba8b-6f3ecb4364d7'::uuid, mbm.kurdish_language, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-kurdish_language Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d945e-2e39-11f0-ba8c-c76bfb0d6f2b'::uuid, mbm.english_language, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-english_language Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d94b8-2e39-11f0-ba8e-b719896c4900'::uuid, mbm.math, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-math Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d9508-2e39-11f0-ba90-034ead284875'::uuid, mbm.biology, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-biology Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d953a-2e39-11f0-ba91-c3ac478afe9d'::uuid, mbm.chemistry, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-chemistry Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d9562-2e39-11f0-ba92-a323dc5ecf81'::uuid, mbm.physics, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-physics Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, 'ffc94c10-2e3c-11f0-a5ae-af23be35f757'::uuid, mbm.arabic_language, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-arabic_language Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, 'ffc94e0e-2e3c-11f0-a5af-9bfe9eafb920'::uuid, mbm.science_of_woman, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-science_of_woman Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, 'ffc94e86-2e3c-11f0-a5b0-ff3bca5d218c'::uuid, mbm.sociology, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Science'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Science-sociology Marks inserted', array_upper(p_uuids, 1);

			-- Bakeloria - Literature: kurdish_language english_language arabic_language history geography philosophy sociology science_of_woman
			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '457d95a8-2e39-11f0-ba94-7388a320a161'::uuid, mbm.kurdish_language, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-kurdish_language Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '70d93d42-2e39-11f0-ac40-5ba568515e38'::uuid, mbm.english_language, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-english_language Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '70d93e3c-2e39-11f0-ac42-af3e12ded276'::uuid, mbm.arabic_language, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-arabic_language Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '70d93eb4-2e39-11f0-ac43-972da636cb7c'::uuid, mbm.history, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-history Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '70d93f18-2e39-11f0-ac44-73bb6ff561a0'::uuid, mbm.geography, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-geography Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '70d93fea-2e39-11f0-ac46-971488fba3f3'::uuid, mbm.philosophy, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-philosophy Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '3b38f444-2e3d-11f0-8ff5-f3c23880ba04'::uuid, mbm.sociology, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-sociology Marks inserted', array_upper(p_uuids, 1);

			WITH inserted as (
				insert into acorn_exam_scores(student_id, exam_material_id, score, created_by_user_id)
					select st.id, '3b38f7fa-2e3d-11f0-8ff6-63d00474903f'::uuid, mbm.science_of_woman, p_created_by_user_id
						from university_mofadala_baccalaureate_marks mbm
						inner join university_mofadala_students mst on mst.baccalaureate_mark_id = mbm.id
						inner join acorn_university_students st on st.import_source = p_imported || ' university_mofadala_students:' || mst.id
						where certificate = 'Literature'
					returning id
				)
				select array_agg(inserted.id) into p_uuids from inserted;
			raise notice '% Baccalaureate Literature-science_of_woman Marks inserted', array_upper(p_uuids, 1);
		end if;
	end if;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_action_academic_years_import_2024(import_students boolean, import_bakeloria_2023_2024 boolean, use_counties_as_schools boolean) OWNER TO university;

--
-- Name: FUNCTION fn_acorn_university_action_academic_years_import_2024(import_students boolean, import_bakeloria_2023_2024 boolean, use_counties_as_schools boolean); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_university_action_academic_years_import_2024(import_students boolean, import_bakeloria_2023_2024 boolean, use_counties_as_schools boolean) IS 'result-action: refresh
condition: (id = ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'')
labels:
  en: Import 2024-2025 Enrollment
comment:
  en: >
    Schools exams happened end-of 2023-2024, Universities enrollment happened begining-of 2024-2025.
    Cantons/Counties can be used for the "school" names, or just one "School" created for all School students';


--
-- Name: fn_acorn_university_action_hierarchies_clear(uuid, uuid, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean DEFAULT false, p_for_enrollment_year boolean DEFAULT false, p_clear_exams_and_scores boolean DEFAULT false, p_confirm boolean DEFAULT false) RETURNS void
    LANGUAGE sql
    AS $$
	select fn_acorn_university_action_academic_years_clear(
		academic_year_id, user_id, p_clear_course_materials, p_for_enrollment_year, p_clear_exams_and_scores, p_confirm
	) from acorn_university_hierarchies where id = model_id;
$$;


ALTER FUNCTION public.fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean) OWNER TO university;

--
-- Name: FUNCTION fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean) IS 'labels:
  en: Clear year data
result-action: refresh
condition: parent_id is null
comment:
  en: >
    The data for the next following years can be deleted for courses starting on _this_ enrollment year.
    *or* for course materials falling in this year from any previous enrollment year course';


--
-- Name: fn_acorn_university_action_hierarchies_copy_to(uuid, uuid, uuid, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean DEFAULT true, p_copy_materials boolean DEFAULT true, p_copy_seminars boolean DEFAULT true, p_copy_calculations boolean DEFAULT true) RETURNS void
    LANGUAGE sql
    AS $$
	select fn_acorn_university_action_academic_years_copy_to(
		academic_year_id, user_id, p_academic_year_id, p_promote_successful_students, p_copy_materials, p_copy_seminars, p_copy_calculations
	) from acorn_university_hierarchies where id = model_id;
$$;


ALTER FUNCTION public.fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) OWNER TO university;

--
-- Name: FUNCTION fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) IS 'labels:
  en: Copy year data to
result-action: refresh
condition: parent_id is null';


--
-- Name: fn_acorn_university_change_code(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_change_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if TG_OP = 'INSERT' or old.code != new.code then
		-- TODO: created_by_user_id is wrong here
		insert into acorn_university_student_codes(student_id, code, created_by_user_id)
			select new.id, new.code, new.user_id;
	end if;
	
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_change_code() OWNER TO university;

--
-- Name: fn_acorn_university_enrollment_year(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_enrollment_year() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	p_course_year_ordinal int;
	p_academic_year_ordinal int;
	p_academic_year_id uuid;
	p_enrollment_academic_year_id uuid;
begin
 	select academic_year_id into p_academic_year_id from acorn_university_academic_year_semesters 
		where id = new.academic_year_semester_id;
	select name into p_course_year_ordinal from acorn_university_course_years 
		where id = new.course_year_id;
	
	if p_course_year_ordinal = 1 then
		-- 1st year of course, year of enrollment = year of academic_year_semester
		p_enrollment_academic_year_id := p_academic_year_id;
	else
		-- > 1st year of course, year of enrollment is before
		select ordinal into p_academic_year_ordinal from acorn_university_academic_years 
			where id = p_academic_year_id;
		select id into p_enrollment_academic_year_id from (
			select id, ordinal from acorn_university_academic_years
				where ordinal < p_academic_year_ordinal
				order by ordinal desc
				limit p_course_year_ordinal-1
			) a 
			order by ordinal asc
			limit 1;
		if p_enrollment_academic_year_id is null then
			raise exception 'Enrollment Year not found for %th year', p_course_year_ordinal; 
		end if;
	end if;
	
	new.enrollment_academic_year_id = p_enrollment_academic_year_id;

	return new;
end;
            
$$;


ALTER FUNCTION public.fn_acorn_university_enrollment_year() OWNER TO university;

--
-- Name: fn_acorn_university_hierarchies_counts(uuid); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_hierarchies_counts(p_id uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
	p_users_count int;
	p_name character varying;
	p_descendant_users_count int := 0;
begin
	-- When a hierarchy is inserted, deleted or updated
	-- update the whole hierarchy for this academic year
	-- recursing down from the ancestors and then updating our way back up

	-- Get the descendant count for this group version
	select coalesce(sum(fn_acorn_university_hierarchies_counts(id)), 0) into p_descendant_users_count
		from acorn_university_hierarchies
		where parent_id = p_id;

	update acorn_university_hierarchies
		set descendant_users_count = p_descendant_users_count,
		    descendants_count      = array_upper(fn_acorn_university_hierarchies_descendants(id), 1)
		where id = p_id;

	-- Get the count for just this group version
	select coalesce(count(*), 0) into p_users_count
		from acorn_university_hierarchies hi
		inner join acorn_user_user_group_version uugv on hi.user_group_version_id = uugv.user_group_version_id
		where hi.id = p_id;

	select name into p_name 
		from acorn_university_hierarchies hi
		inner join acorn_user_user_group_versions ugv on hi.user_group_version_id = ugv.id
		inner join acorn_user_user_groups ugs on ugv.user_group_id = ugs.id
		where hi.id = p_id;
	raise notice '% users, % descendants for %', p_users_count, p_descendant_users_count, p_name;
	
	return p_users_count + p_descendant_users_count;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_hierarchies_counts(p_id uuid) OWNER TO university;

--
-- Name: fn_acorn_university_hierarchies_delete_version(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_hierarchies_delete_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from public.acorn_user_user_group_versions
		where id = old.user_group_version_id;
	return old;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_hierarchies_delete_version() OWNER TO university;

--
-- Name: fn_acorn_university_hierarchies_descendants(uuid); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_hierarchies_descendants(p_id uuid) RETURNS uuid[]
    LANGUAGE plpgsql
    AS $$
declare 
	record record;
	p_descendants uuid[] := ARRAY[]::uuid[];
begin
	for record in select 
			id, fn_acorn_university_hierarchies_descendants(id) as descendants
		from acorn_university_hierarchies
		where parent_id = p_id loop
		p_descendants := array_append(p_descendants, record.id);
		p_descendants := array_cat(p_descendants, record.descendants);
	end loop;
	
	return p_descendants;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_hierarchies_descendants(p_id uuid) OWNER TO university;

--
-- Name: fn_acorn_university_hierarchies_descendants_update(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_hierarchies_descendants_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	p_toplevel int;
begin
	-- When a hierarchy is inserted, deleted or updated
	-- update the whole hierarchy for this academic year
	-- recursing down from the ancestors and then updating our way back up
	select count(*) into p_toplevel 
		from acorn_university_hierarchies
		where parent_id is NULL;
	if p_toplevel != 0 then
		raise notice '--- Begin % Hierarchy updates', p_toplevel;
		perform fn_acorn_university_hierarchies_counts(id)
			from acorn_university_hierarchies
			where parent_id is NULL;
		raise notice '--- Finished Hierarchy updates';
	end if;

	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_hierarchies_descendants_update() OWNER TO university;

--
-- Name: fn_acorn_university_hierarchies_new_version(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_hierarchies_new_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	-- Add a new version for this entity/user_group
	insert into acorn_user_user_group_versions(user_group_id)
		select user_group_id 
			from acorn_university_entities
			where id = new.entity_id
		returning id into new.user_group_version_id;
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_hierarchies_new_version() OWNER TO university;

--
-- Name: fn_acorn_university_new_code(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_university_new_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	update acorn_university_student_codes
		set current = false
		where student_id = new.student_id and current;
	
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_university_new_code() OWNER TO university;

--
-- Name: fn_acorn_user_code(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_code(name character varying, word integer DEFAULT 0, length integer DEFAULT 3) RETURNS character varying
    LANGUAGE sql
    AS $$
	select substr(upper(
		case word
			when 0 then
				regexp_replace(name, '[^a-zA-Z0-9]', '')
			when 1 then
				regexp_replace(regexp_replace(name, '^[^ ]* ', ''), '[^a-zA-Z0-9]', '')
			else
				regexp_replace(regexp_replace(name, '^[^ ]* [^ ]* ', ''), '[^a-zA-Z0-9]', '')
		end), 1, length);
$$;


ALTER FUNCTION public.fn_acorn_user_code(name character varying, word integer, length integer) OWNER TO university;

--
-- Name: fn_acorn_user_code_acronym(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer DEFAULT 0, length integer DEFAULT 3) RETURNS character varying
    LANGUAGE sql
    AS $$
	select 
		substr(upper(
			regexp_replace(
				regexp_replace(name, '([^ ])[^ ]+', '\1', 'g'),
			' +', '', 'g')
		), word+1, length);
$$;


ALTER FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer, length integer) OWNER TO university;

--
-- Name: fn_acorn_user_get_seed_user(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_get_seed_user() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare
user_id uuid;
            begin
            -- Lazy create the seeder user
            select into user_id uu.id 
                from public.acorn_user_users uu
                where name = 'seeder' and is_system_user limit 1;
            if user_id is null then
                insert into public.acorn_user_users(name, is_system_user)
                    values('seeder', true) 
                    returning id into user_id;
            end if;
            
            
            return user_id;
end;
            $$;


ALTER FUNCTION public.fn_acorn_user_get_seed_user() OWNER TO university;

--
-- Name: fn_acorn_user_user_group_first_version(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_user_group_first_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into acorn_user_user_group_versions(user_group_id)
		values(new.id);
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_user_user_group_first_version() OWNER TO university;

--
-- Name: fn_acorn_user_user_group_version(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_user_group_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	select coalesce(max(version), 0) + 1 into new.version 
		from acorn_user_user_group_versions 
		where user_group_id = new.user_group_id;
	update acorn_user_user_group_versions 
		set current = false
		where user_group_id = new.user_group_id and current;
	
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_user_user_group_version() OWNER TO university;

--
-- Name: agg_acorn_first(anyelement); Type: AGGREGATE; Schema: public; Owner: university
--

CREATE AGGREGATE public.agg_acorn_first(anyelement) (
    SFUNC = public.fn_acorn_first,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acorn_first(anyelement) OWNER TO university;

--
-- Name: agg_acorn_last(anyelement); Type: AGGREGATE; Schema: public; Owner: university
--

CREATE AGGREGATE public.agg_acorn_last(anyelement) (
    SFUNC = public.fn_acorn_last,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acorn_last(anyelement) OWNER TO university;

--
-- Name: localserver_universityacceptance; Type: SERVER; Schema: -; Owner: university
--

CREATE SERVER localserver_universityacceptance FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'universityacceptance',
    host 'localhost',
    port '5432'
);


ALTER SERVER localserver_universityacceptance OWNER TO university;

--
-- Name: USER MAPPING sz SERVER localserver_universityacceptance; Type: USER MAPPING; Schema: -; Owner: university
--

CREATE USER MAPPING FOR sz SERVER localserver_universityacceptance OPTIONS (
    password 'SantaTickle2',
    "user" 'sz'
);


--
-- Name: USER MAPPING token_1 SERVER localserver_universityacceptance; Type: USER MAPPING; Schema: -; Owner: university
--

CREATE USER MAPPING FOR token_1 SERVER localserver_universityacceptance OPTIONS (
    password 'SantaTickle2',
    "user" 'sz'
);


--
-- Name: USER MAPPING university SERVER localserver_universityacceptance; Type: USER MAPPING; Schema: -; Owner: university
--

CREATE USER MAPPING FOR university SERVER localserver_universityacceptance OPTIONS (
    password 'SantaTickle2',
    "user" 'sz'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acorn_calendar_calendars; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_calendars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    system boolean DEFAULT false NOT NULL,
    sync_file character varying(4096),
    sync_format integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:14.674386'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid,
    owner_user_group_id uuid,
    permissions integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.acorn_calendar_calendars OWNER TO university;

--
-- Name: TABLE acorn_calendar_calendars; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_calendars IS 'package-type: plugin
table-type: content';


--
-- Name: acorn_calendar_event_part_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_part_user (
    event_part_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:15.233983'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_part_user OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_part_user; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_part_user IS 'table-type: content';


--
-- Name: acorn_calendar_event_part_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_part_user_group (
    event_part_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_calendar_event_part_user_group OWNER TO university;

--
-- Name: acorn_calendar_event_parts; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_parts (
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
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:15.006774'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    repeat interval,
    alarm interval,
    instances_deleted integer[]
);


ALTER TABLE public.acorn_calendar_event_parts OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_parts; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_parts IS 'table-type: content';


--
-- Name: acorn_calendar_event_statuses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    style character varying(255),
    system boolean DEFAULT false NOT NULL,
    calendar_id uuid,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_statuses OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_statuses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_statuses IS 'table-type: content';


--
-- Name: acorn_calendar_event_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    whole_day boolean DEFAULT false NOT NULL,
    colour character varying(16) DEFAULT '#333'::character varying,
    style character varying(2048),
    system boolean DEFAULT false NOT NULL,
    activity_log_related_oid integer,
    calendar_id uuid,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:14.760966'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_types OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_types IS 'table-type: content';


--
-- Name: acorn_calendar_events; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    calendar_id uuid NOT NULL,
    external_url character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:14.902277'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid NOT NULL,
    owner_user_group_id uuid,
    permissions integer DEFAULT 79 NOT NULL
);


ALTER TABLE public.acorn_calendar_events OWNER TO university;

--
-- Name: TABLE acorn_calendar_events; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_events IS 'table-type: content';


--
-- Name: acorn_calendar_instances; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date NOT NULL,
    event_part_id uuid NOT NULL,
    instance_num integer NOT NULL,
    instance_start timestamp(0) without time zone NOT NULL,
    instance_end timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.acorn_calendar_instances OWNER TO university;

--
-- Name: TABLE acorn_calendar_instances; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_instances IS 'table-type: content';


--
-- Name: acorn_exam_calculation_course_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_calculation_course_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_material_id uuid NOT NULL,
    calculation_id uuid NOT NULL,
    academic_year_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_calculation_course_materials OWNER TO university;

--
-- Name: TABLE acorn_exam_calculation_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_calculation_course_materials IS 'menu: false
labels:
  en: Course Material Calculation
labels-plural:
  en: Course Material Calculations';


--
-- Name: acorn_exam_calculation_courses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_calculation_courses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    calculation_id uuid NOT NULL,
    academic_year_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_calculation_courses OWNER TO university;

--
-- Name: TABLE acorn_exam_calculation_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_calculation_courses IS 'menu: false
labels:
  en: Course Calculation
labels-plural:
  en: Course Calculations';


--
-- Name: acorn_exam_calculation_material_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_calculation_material_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    material_type_id uuid NOT NULL,
    calculation_id uuid NOT NULL,
    academic_year_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_calculation_material_types OWNER TO university;

--
-- Name: TABLE acorn_exam_calculation_material_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_calculation_material_types IS 'menu: false
labels:
  en: Material Type Calculation
labels-plural:
  en: Material Type Calculations';


--
-- Name: acorn_exam_calculation_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_calculation_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_calculation_types OWNER TO university;

--
-- Name: TABLE acorn_exam_calculation_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_calculation_types IS 'seeding:
  - [''56013d6e-3247-11f0-8e96-2f232943abf8'', ''score'']
  - [''56013e90-3247-11f0-8e97-9b91890119b6'', ''count'']
  - [''56013ed6-3247-11f0-8e98-478677b2ee2a'', ''boolean'']
labels:
  en: Calculation Type
  ku: Cura Algoritum
labels-plural:
  en: Calculation Types
  ku: Curên Algoritum

';


--
-- Name: acorn_exam_calculations; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_calculations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'calculation'::character varying NOT NULL,
    description text,
    expression character varying(2048) NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    minimum double precision,
    maximum double precision,
    required boolean,
    calculation_type_id uuid
);


ALTER TABLE public.acorn_exam_calculations OWNER TO university;

--
-- Name: TABLE acorn_exam_calculations; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_calculations IS 'seeding:
  - [''15f02b5c-2bff-11f0-8074-4bf737ba6a74'', ''Avg of material exams'', ''<p>For course &lt;course&gt;/&lt;material&gt;</p>'', ''avg(:score/<course>/<material>/<year>/material/.*/.*/<student>:)'', NULL, NULL, false, ''56013d6e-3247-11f0-8e96-2f232943abf8'']
  - [''958b8af0-2e7f-11f0-b4b4-9f4a22fbe4eb'', ''Avg of materials'', ''<p>For course &lt;course&gt;</p>'', ''avg(:material/<course>/.*/<year>/material/<student>/(required)?/?result:)'', NULL, NULL, true, ''56013d6e-3247-11f0-8e96-2f232943abf8'']
  - [''958b952c-2e7f-11f0-b4b6-0f8c2c07f33e'', ''Bakeloria final mark'', NULL, ''avg(:course/.*/<year>/.*/score/<student>/result:)'', 60, NULL, true, ''56013d6e-3247-11f0-8e96-2f232943abf8'']
  - [''9ee46f13-b23e-4ab7-998a-b2585f1a41ad'', ''Count of required materials failed'', NULL, ''count(:material/<course>/.*/<year>/material/<student>/required/result=0:) - sum(:?material/<course>/.*/<year>/material/<student>/required/result=0:)'', 0, 0, true, ''56013e90-3247-11f0-8e97-9b91890119b6'']
  - [''9ee52bda-2631-48db-ac33-44630c76e83c'', ''Count of optional materials failed'', NULL, ''count(:material/<course>/.*/<year>/material/<student>/result=0:) - sum(:?material/<course>/.*/<year>/material/<student>/result=0:)'', 0, 1, true, ''56013e90-3247-11f0-8e97-9b91890119b6'']
  - [''9ee52f50-d22a-471e-bdeb-b13d81b1afb2'', ''Bakeloria pass'', NULL, ''sum(:?course/.*/<year>/count-of-required-materials-failed/count/<student>/required/result=0:, :?course/.*/<year>/count-of-optional-materials-failed/count/<student>/required/result=0:, :?calculation/<student>/<year>/bakeloria-final-mark=0:)'', 3, NULL, true, ''56013ed6-3247-11f0-8e98-478677b2ee2a'']
labels:
  en: Calculation
  ku: Algoritum
labels-plural:
  en: Calculations
  ku: Algoritumên
';


--
-- Name: COLUMN acorn_exam_calculations.expression; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_calculations.expression IS 'field-type: textarea
column-type: text';


--
-- Name: COLUMN acorn_exam_calculations.minimum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_calculations.minimum IS 'list-editable: true';


--
-- Name: COLUMN acorn_exam_calculations.maximum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_calculations.maximum IS 'list-editable: true';


--
-- Name: acorn_exam_exam_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_exam_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    exam_id uuid NOT NULL,
    course_material_id uuid NOT NULL,
    required boolean DEFAULT false NOT NULL,
    minimum integer DEFAULT 0 NOT NULL,
    maximum integer DEFAULT 100 NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    weight double precision,
    interview_id uuid,
    project_id uuid
);


ALTER TABLE public.acorn_exam_exam_materials OWNER TO university;

--
-- Name: TABLE acorn_exam_exam_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_exam_materials IS 'menu: false
attribute-functions:
  name: return $this->course_material->name . ''::'' . $this->exam->name;
labels:
  en: Material Exam
labels-plural:
  en: Material Exams
seeding:
  # Bakeloria - Science
  - [''457d9378-2e39-11f0-ba8b-6f3ecb4364d7'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d60faf78-2d91-11f0-91b5-4ba74601f388'']
  - [''457d945e-2e39-11f0-ba8c-c76bfb0d6f2b'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d7166b8c-2d91-11f0-8b19-e7d49c2e84f1'']
  - [''457d94b8-2e39-11f0-ba8e-b719896c4900'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d7613d74-2d91-11f0-a545-27a082b4a92e'']
  - [''457d9508-2e39-11f0-ba90-034ead284875'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d7a990f6-2d91-11f0-95db-c330df9f103b'']
  - [''457d953a-2e39-11f0-ba91-c3ac478afe9d'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d7ceec66-2d91-11f0-b5d5-db13369d9435'']
  - [''457d9562-2e39-11f0-ba92-a323dc5ecf81'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d7f26d1c-2d91-11f0-a26f-f3e5473b3167'']
  - [''ffc94c10-2e3c-11f0-a5ae-af23be35f757'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''f36c46d6-2e3a-11f0-b6f1-17b78d5f0aec'']
  - [''ffc94e0e-2e3c-11f0-a5af-9bfe9eafb920'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''f36c48de-2e3a-11f0-b6f2-3b9b22699d6a'']
  - [''ffc94e86-2e3c-11f0-a5b0-ff3bca5d218c'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''90916acc-2e3b-11f0-8dcc-67434a77fd63'']
  # Bakeloria - Literature
  - [''457d95a8-2e39-11f0-ba94-7388a320a161'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d83b7214-2d91-11f0-81ee-973d6ea6519e'']
  - [''70d93d42-2e39-11f0-ac40-5ba568515e38'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d882e05e-2d91-11f0-90fa-83869ea90163'']
  - [''70d93e3c-2e39-11f0-ac42-af3e12ded276'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d8c70de2-2d91-11f0-adfc-f320089c0508'']
  - [''70d93eb4-2e39-11f0-ac43-972da636cb7c'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d8ed5b64-2d91-11f0-a8f4-d31ec556c6aa'']
  - [''70d93f18-2e39-11f0-ac44-73bb6ff561a0'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d912a6bc-2d91-11f0-800e-6f442946f1de'']
  - [''70d93fea-2e39-11f0-ac46-971488fba3f3'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''d95cc1d4-2d91-11f0-9084-33d5bf8f0fe0'']
  - [''3b38f444-2e3d-11f0-8ff5-f3c23880ba04'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''f36c4974-2e3a-11f0-b6f3-b33bd4aa8e09'']
  - [''3b38f7fa-2e3d-11f0-8ff6-63d00474903f'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''f36c49f6-2e3a-11f0-b6f4-53ae331645fa'']
  # Year 10,11
  - [''be8521f8-2e54-11f0-946a-670c67ddf3e8'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''4e2005fe-2e54-11f0-982d-23d1bc2b7e01'']
  - [''be8525b8-2e54-11f0-946b-87c080955d16'', ''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''4e20093c-2e54-11f0-982e-63aa632c9cfa'']

';


--
-- Name: COLUMN acorn_exam_exam_materials.minimum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_exam_materials.minimum IS 'list-editable: true';


--
-- Name: COLUMN acorn_exam_exam_materials.maximum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_exam_materials.maximum IS 'list-editable: true';


--
-- Name: acorn_exam_exams; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_exams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'exam'::character varying NOT NULL,
    description text,
    type_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_exams OWNER TO university;

--
-- Name: TABLE acorn_exam_exams; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_exams IS 'order: 50
plugin-names:
  en: Exams
  ku: Ezmûnên
seeding:
  - [''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''Theory'', '''', ''cb58f452-28e3-11f0-bf77-eb3094eae79e'']
  - [''fb9806d4-2beb-11f0-9893-2ba7af07260a'', ''Laboratory'', '''', ''c2975b06-28e3-11f0-a996-1f7fab9642e9'']
labels:
  en: Exam
  ku: Ezmûn
labels-plural:
  en: Exams
  ku: Ezmûnên
';


--
-- Name: acorn_exam_tokens; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_exam_tokens AS
SELECT
    NULL::character varying AS id,
    NULL::character varying AS name,
    NULL::uuid AS student_id,
    NULL::uuid AS academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS material_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    NULL::character varying AS expression,
    NULL::double precision AS minimum,
    NULL::double precision AS maximum,
    NULL::boolean AS required,
    NULL::text AS expression_type,
    NULL::boolean AS needs_evaluate;


ALTER VIEW public.acorn_exam_tokens OWNER TO university;

--
-- Name: VIEW acorn_exam_tokens; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON VIEW public.acorn_exam_tokens IS 'menu: false
labels:
  en: Student Calculation
  ku: Dinirxinên Xwendekar
labels-plural:
  en: Student Calculations
  ku: Dinirxinên Xwendekarên';


--
-- Name: COLUMN acorn_exam_tokens.student_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.academic_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.academic_year_id IS 'extra-foreign-key: 
  table: acorn_university_academic_years
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.exam_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.course_material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.course_material_id IS 'extra-foreign-key: 
  table: acorn_university_course_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.course_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.course_id IS 'extra-foreign-key: 
  table: acorn_university_courses
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.material_id IS 'extra-foreign-key: 
  table: acorn_university_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.calculation_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.calculation_id IS 'extra-foreign-key: 
  table: acorn_exam_calculations
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.project_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.project_id IS 'extra-foreign-key: 
  table: acorn_university_projects
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.interview_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.interview_id IS 'extra-foreign-key: 
  table: acorn_exam_interviews
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: acorn_exam_result_internals; Type: MATERIALIZED VIEW; Schema: public; Owner: university
--

CREATE MATERIALIZED VIEW public.acorn_exam_result_internals AS
 SELECT et.id,
    et.name,
    et.student_id,
    et.academic_year_id,
    et.exam_id,
    et.course_material_id,
    et.course_id,
    et.material_id,
    et.calculation_id,
    ct.id AS calculation_type_id,
    ct.name AS calculation_type_name,
    et.project_id,
    et.interview_id,
    et.expression,
    et.minimum,
    et.maximum,
    et.required,
    et.expression_type,
    et.needs_evaluate,
    public.fn_acorn_exam_tokenize(et.expression) AS result
   FROM ((public.acorn_exam_tokens et
     LEFT JOIN public.acorn_exam_calculations c ON ((et.calculation_id = c.id)))
     LEFT JOIN public.acorn_exam_calculation_types ct ON ((c.calculation_type_id = ct.id)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.acorn_exam_result_internals OWNER TO university;

--
-- Name: MATERIALIZED VIEW acorn_exam_result_internals; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON MATERIALIZED VIEW public.acorn_exam_result_internals IS 'menu: false';


--
-- Name: COLUMN acorn_exam_result_internals.student_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.academic_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.academic_year_id IS 'extra-foreign-key: 
  table: acorn_university_academic_years
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.exam_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.course_material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.course_material_id IS 'extra-foreign-key: 
  table: acorn_university_course_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.course_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.course_id IS 'extra-foreign-key: 
  table: acorn_university_courses
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.material_id IS 'extra-foreign-key: 
  table: acorn_university_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.calculation_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.calculation_id IS 'extra-foreign-key: 
  table: acorn_exam_calculations
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.calculation_type_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.calculation_type_id IS 'extra-foreign-key: 
  table: acorn_exam_calculation_types
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.project_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.project_id IS 'extra-foreign-key: 
  table: acorn_university_projects
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_result_internals.interview_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_result_internals.interview_id IS 'extra-foreign-key: 
  table: acorn_exam_interviews
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: acorn_exam_results; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_exam_results AS
 SELECT id,
    name,
    student_id,
    academic_year_id,
    exam_id,
    course_material_id,
    course_id,
    material_id,
    calculation_id,
    calculation_type_id,
    project_id,
    interview_id,
    expression,
    minimum,
    maximum,
    required,
    expression_type,
    needs_evaluate,
    result,
    ((result >= COALESCE(minimum, (0)::double precision)) AND (result <= COALESCE(maximum, (100000)::double precision))) AS passed
   FROM public.acorn_exam_result_internals
  WHERE (NOT (result IS NULL));


ALTER VIEW public.acorn_exam_results OWNER TO university;

--
-- Name: VIEW acorn_exam_results; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON VIEW public.acorn_exam_results IS 'labels:
  en: Student Result
  ku: Encamên Xwendekar
labels-plural:
  en: Student Result
  ku: Encamên Xwendekarên';


--
-- Name: COLUMN acorn_exam_results.student_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.academic_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.academic_year_id IS 'extra-foreign-key: 
  table: acorn_university_academic_years
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.exam_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.course_material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.course_material_id IS 'extra-foreign-key: 
  table: acorn_university_course_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.course_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.course_id IS 'extra-foreign-key: 
  table: acorn_university_courses
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.material_id IS 'extra-foreign-key: 
  table: acorn_university_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.calculation_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.calculation_id IS 'extra-foreign-key: 
  table: acorn_exam_calculations
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.calculation_type_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.calculation_type_id IS 'extra-foreign-key: 
  table: acorn_exam_calculation_types
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.project_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.project_id IS 'extra-foreign-key: 
  table: acorn_university_projects
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.interview_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.interview_id IS 'extra-foreign-key: 
  table: acorn_exam_interviews
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.expression_type; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.expression_type IS 'filters:
  expression_type:
    label: acorn.exam::lang.models.result.expression_type
    conditions: expression_type in(:filtered)
    options:
      data: Data
      expression: Expression
      formulae: Formulae';


--
-- Name: COLUMN acorn_exam_results.passed; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_results.passed IS 'css-classes-column:
  - show-cross';


--
-- Name: acorn_exam_scores; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_scores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    exam_material_id uuid NOT NULL,
    score double precision NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    student_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_scores OWNER TO university;

--
-- Name: TABLE acorn_exam_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_scores IS 'order: 35
attribute-functions:
  name: return $this->exam_material->name;
# Handled by data_entry_view
menu: false
labels:
  en: Score
  ku: Sitand
labels-plural:
  en: Scores
  ku: Sitandên';


--
-- Name: COLUMN acorn_exam_scores.score; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_scores.score IS 'list-editable: delete-on-null';


--
-- Name: acorn_exam_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'exam'::character varying NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_types OWNER TO university;

--
-- Name: TABLE acorn_exam_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_types IS 'order: 40
menu-splitter: true
seeding:
  - [''c2975b06-28e3-11f0-a996-1f7fab9642e9'', ''laboratory'']
  - [''cb58f452-28e3-11f0-bf77-eb3094eae79e'', ''theory'']
labels:
  en: Exam Type
  ku: Cura Ezmûn
labels-plural:
  en: Exam Types
  ku: Curên Ezmûn
';


--
-- Name: acorn_university_academic_year_semesters; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_academic_year_semesters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    academic_year_id uuid NOT NULL,
    semester_id uuid NOT NULL,
    event_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_academic_year_semesters OWNER TO university;

--
-- Name: TABLE acorn_university_academic_year_semesters; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_academic_year_semesters IS 'order: 1015
seeding:
  # Year 2024
  - [''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', ''61c051fa-2b47-11f0-bc0f-ab4c8b696730'', EVENT(Default;Year 2024 Semester 1)]
  - [''9dd3c21e-2bd1-11f0-8ec0-530fd1227857'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', ''61eb583c-2b47-11f0-adc3-ef976031065b'', EVENT(Default;Year 2024 Semester 2)]
  - [''9e5bbd72-2bd1-11f0-9dcc-83b88755cb62'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', ''6212587e-2b47-11f0-b854-631a30042bb5'', EVENT(Default;Year 2024 Semester 3)]
  # Year 2025
  - [''9ea2909e-2bd1-11f0-9b80-f797a81e82a4'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', ''61c051fa-2b47-11f0-bc0f-ab4c8b696730'', EVENT(Default;Year 2025 Semester 1)]
  - [''9ee7d67c-2bd1-11f0-aba9-97727bc0b413'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', ''61eb583c-2b47-11f0-adc3-ef976031065b'', EVENT(Default;Year 2025 Semester 2)]
  - [''9f227dea-2bd1-11f0-bd27-c7d903e9ad4d'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', ''6212587e-2b47-11f0-b854-631a30042bb5'', EVENT(Default;Year 2025 Semester 3)]
labels:
  en: Year semester
  ku: Werzê Sal
labels-plural:
  en: Year semesters
  ku: Werzên Sal';


--
-- Name: acorn_university_year_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.acorn_university_year_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.acorn_university_year_seq OWNER TO university;

--
-- Name: acorn_university_academic_years; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_academic_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    start timestamp without time zone NOT NULL,
    "end" timestamp without time zone NOT NULL,
    current boolean DEFAULT true NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    name character varying(1024) DEFAULT ''::character varying NOT NULL,
    ordinal integer DEFAULT nextval('public.acorn_university_year_seq'::regclass)
);


ALTER TABLE public.acorn_university_academic_years OWNER TO university;

--
-- Name: TABLE acorn_university_academic_years; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_academic_years IS 'global-scope: true
order: 1000
seeding:
  - [''dee7d1e6-33ba-11f0-9757-0b77f37bff0c'', 01/09/2025, 30/05/2026, false, '''', ''2025-2026'', 107]
  - [''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', 01/09/2024, 30/05/2025, true, '''', ''2024-2025'', 106]
  - [''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', 01/09/2023, 30/05/2024, false, '''', ''2023-2024'', 105]
  - [''8fe62240-3546-11f0-bc4d-3f9721dbc106'', 01/09/2022, 30/05/2023, false, '''', ''2022-2023'', 104]
  - [''8fe62420-3546-11f0-bc4e-67afd1391b00'', 01/09/2021, 30/05/2022, false, '''', ''2021-2022'', 103]
  - [''8fe6248e-3546-11f0-bc4f-cf68964a0a8a'', 01/09/2020, 30/05/2021, false, '''', ''2020-2021'', 102]
  - [''8fe624fc-3546-11f0-bc50-57d4a0995e07'', 01/09/2019, 30/05/2020, false, '''', ''2019-2020'', 101]
  - [''8fe62560-3546-11f0-bc51-f7ceae4026bf'', 01/09/2018, 30/05/2019, false, '''', ''2018-2019'', 100]
labels:
  en: Academic Year
  ku: Sale Akademik
labels-plural:
  en: Academic Years
  ku: Salên Akademik
';


--
-- Name: COLUMN acorn_university_academic_years.name; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_academic_years.name IS 'column-type: partial
column-partial: current
css-classes-column:
  - tablet';


--
-- Name: COLUMN acorn_university_academic_years.ordinal; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_academic_years.ordinal IS 'invisible: true
hidden: true';


--
-- Name: acorn_university_course_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_course_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    material_id uuid NOT NULL,
    required boolean DEFAULT false NOT NULL,
    minimum integer DEFAULT 0 NOT NULL,
    maximum integer DEFAULT 100 NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    weight double precision,
    academic_year_semester_id uuid NOT NULL,
    course_year_id uuid NOT NULL,
    academic_year_semester_ordinal integer,
    enrollment_academic_year_id uuid NOT NULL,
    "order" integer
);


ALTER TABLE public.acorn_university_course_materials OWNER TO university;

--
-- Name: TABLE acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_course_materials IS 'attribute-functions:
  academic_year_semester_ordinal: "return (is_int($this->course_year) ? ($this->course_year-1) * 3 + $this->academic_year_semester?->semester->ordinal : NULL);"
seeding:
  # Jineologi
  - [''7250f0de-2be6-11f0-8437-3f38a27f0d25'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''005bba60-28bf-11f0-bf7f-cff663f8102b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''72f6f98e-2be6-11f0-95e8-5feec68b4c60'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''cdc800ae-28be-11f0-a8a6-334555029afd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''7336f566-2be6-11f0-b65c-377fa17f9a2c'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''737250c0-2be6-11f0-832f-9f9b2f075784'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''73ab76c0-2be6-11f0-bbac-dfa07554b168'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''73e00d9a-2be6-11f0-bf6f-5f78a750b209'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''7419875a-2be6-11f0-bf3e-13eea1a5d3c8'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''745124c6-2be6-11f0-801e-ff295edc2ab4'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''dd494c0e-28be-11f0-94e1-a7b2083dd749'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''9eae5f86-2be6-11f0-b57a-f7e9398cd276'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''e427a282-28be-11f0-8856-a7abd8a449c5'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  # Bakeloria - Science: kurdish_language	english	math	biology	chemistry	phisic	arabic_language	geneology	Sociology 
  - [''f36c46d6-2e3a-11f0-b6f1-17b78d5f0aec'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''f3c853a8-28be-11f0-8938-73b157eb85a1'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''f36c48de-2e3a-11f0-b6f2-3b9b22699d6a'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7166b8c-2d91-11f0-8b19-e7d49c2e84f1'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''cdc800ae-28be-11f0-a8a6-334555029afd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7613d74-2d91-11f0-a545-27a082b4a92e'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''90916acc-2e3b-11f0-8dcc-67434a77fd63'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''ecf3dae8-28be-11f0-91f7-f31527b6ca23'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7f26d1c-2d91-11f0-a26f-f3e5473b3167'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''dd494c0e-28be-11f0-94e1-a7b2083dd749'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d60faf78-2d91-11f0-91b5-4ba74601f388'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''005bba60-28bf-11f0-bf7f-cff663f8102b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7ceec66-2d91-11f0-b5d5-db13369d9435'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7a990f6-2d91-11f0-95db-c330df9f103b'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  # Bakeloria - Literature: kurdish_language	english_language	arabic_language	history	geography	philosophy	sociology	science_of_woman
  - [''f36c4974-2e3a-11f0-b6f3-b33bd4aa8e09'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''f3c853a8-28be-11f0-8938-73b157eb85a1'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''f36c49f6-2e3a-11f0-b6f4-53ae331645fa'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d83b7214-2d91-11f0-81ee-973d6ea6519e'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''005bba60-28bf-11f0-bf7f-cff663f8102b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d882e05e-2d91-11f0-90fa-83869ea90163'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d95cc1d4-2d91-11f0-9084-33d5bf8f0fe0'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''e427a282-28be-11f0-8856-a7abd8a449c5'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d8c70de2-2d91-11f0-adfc-f320089c0508'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d8ed5b64-2d91-11f0-a8f4-d31ec556c6aa'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d912a6bc-2d91-11f0-800e-6f442946f1de'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  # Year 10,11
  - [''4e2005fe-2e54-11f0-982d-23d1bc2b7e01'', ''f6210e20-2e53-11f0-b41e-bbc1e97e17dc'', ''7f5c3dc8-2e53-11f0-8600-6ff513625846'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''4e20093c-2e54-11f0-982e-63aa632c9cfa'', ''f62111ea-2e53-11f0-b41f-ff3908814684'', ''7f5c4156-2e53-11f0-8601-43470f236a9e'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
labels:
  en: Course material
  ku: Kors material
labels-plural:
  en: Course materials
  ku: Kors materialên
';


--
-- Name: COLUMN acorn_university_course_materials.required; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.required IS 'comment: primary';


--
-- Name: COLUMN acorn_university_course_materials.minimum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.minimum IS 'list-editable: true';


--
-- Name: COLUMN acorn_university_course_materials.maximum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.maximum IS 'list-editable: true';


--
-- Name: COLUMN acorn_university_course_materials.weight; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.weight IS 'list-editable: true';


--
-- Name: COLUMN acorn_university_course_materials.course_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.course_year_id IS 'column-type: partial
column-partial: ordinal
suffix: acorn.university::lang.models.courseyear.year
';


--
-- Name: COLUMN acorn_university_course_materials.academic_year_semester_ordinal; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.academic_year_semester_ordinal IS 'column-partial: ordinal
column-type: partial
suffix: acorn.university::lang.models.semester.label
read-only: true';


--
-- Name: COLUMN acorn_university_course_materials.enrollment_academic_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.enrollment_academic_year_id IS 'column-type: partial
column-partial: current
read-only: true';


--
-- Name: COLUMN acorn_university_course_materials."order"; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials."order" IS 'list-editable: true';


--
-- Name: acorn_university_courses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_courses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    weight double precision
);


ALTER TABLE public.acorn_university_courses OWNER TO university;

--
-- Name: TABLE acorn_university_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_courses IS 'order: 60
seeding:
  - [''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''204c8a80-1b5d-11f0-9a78-07337e2f1cca'']
  # Science, Literature
  - [''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''c555e604-2d8f-11f0-b535-bb3e95f882b4'']
  - [''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'']
  # Year 10,11
  - [''f6210e20-2e53-11f0-b41e-bbc1e97e17dc'', ''4bf9dbe8-2e53-11f0-ad9d-eb001b270147'']
  - [''f62111ea-2e53-11f0-b41f-ff3908814684'', ''4bf9de9a-2e53-11f0-ad9e-1339796bedc7'']
labels:
  en: Course
  ku: Kors
labels-plural:
  en: Courses
  ku: Korsên
';


--
-- Name: acorn_university_entities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_entities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_group_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    import_source character varying(1024)
);


ALTER TABLE public.acorn_university_entities OWNER TO university;

--
-- Name: TABLE acorn_university_entities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_entities IS 'menu: false
order: -100
seeding-other:
  acorn_user_user_groups:
    - [''2c4251c8-2cf9-11f0-bbd1-3370778ee65e'', ''Education Committee'', ''EDU'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''cae7ba7c-1b63-11f0-8a05-c36be60d3d46'', ''Rojava'', ''ROJ'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''f2c7a61a-1b63-11f0-9899-2b70d1861dd4'', ''Kobani'', ''KOB'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''f334763c-1b63-11f0-aab4-4f7e5f7e30cb'', ''Jineologi'', ''JIN'', NULL, NULL, NULL, ''cae7ba7c-1b63-11f0-8a05-c36be60d3d46'', 0, 0, 1]
    - [''505282d6-2cf9-11f0-8450-87f83af99ff9'', ''Til Maroof school'', ''MAR'', NULL, NULL, NULL, NULL, 0, 0, 0]
    # Bakeloria
    - [''a7237520-2d8f-11f0-a834-2b294fbfca54'', ''Science'', ''SCI'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b'', ''Literature'', ''LIT'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''21397b0c-2e53-11f0-8a85-1759860470a0'', ''Year 10'', ''Y10'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''21397d32-2e53-11f0-8a86-abb690facbb0'', ''Year 11'', ''Y11'', NULL, NULL, NULL, NULL, 0, 0, 0]
seeding:
  - [''5a722502-2cfc-11f0-8fc6-4f662cb2699a'', ''2c4251c8-2cf9-11f0-bbd1-3370778ee65e'']
  - [''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'', ''cae7ba7c-1b63-11f0-8a05-c36be60d3d46'']
  - [''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'', ''f2c7a61a-1b63-11f0-9899-2b70d1861dd4'']
  - [''204c8a80-1b5d-11f0-9a78-07337e2f1cca'', ''f334763c-1b63-11f0-aab4-4f7e5f7e30cb'']
  - [''4b38af66-2cfc-11f0-b608-2b766ae5cd8d'', ''505282d6-2cf9-11f0-8450-87f83af99ff9'']
    # Bakeloria
  - [''c555e604-2d8f-11f0-b535-bb3e95f882b4'', ''a7237520-2d8f-11f0-a834-2b294fbfca54'']
  - [''c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'', ''a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b'']
  - [''4bf9dbe8-2e53-11f0-ad9d-eb001b270147'', ''21397b0c-2e53-11f0-8a85-1759860470a0'']
  - [''4bf9de9a-2e53-11f0-ad9e-1339796bedc7'', ''21397d32-2e53-11f0-8a86-abb690facbb0'']
attribute-functions:
  name: "return $this->user_group->name;"
';


--
-- Name: acorn_university_hierarchies; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_hierarchies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    academic_year_id uuid NOT NULL,
    parent_id uuid,
    server_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    nest_left integer DEFAULT 0 NOT NULL,
    nest_right integer DEFAULT 0 NOT NULL,
    nest_depth integer DEFAULT 0 NOT NULL,
    description text,
    user_group_version_id uuid NOT NULL,
    descendant_users_count integer,
    descendants_count integer,
    import_source character varying(1024)
);


ALTER TABLE public.acorn_university_hierarchies OWNER TO university;

--
-- Name: TABLE acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_hierarchies IS 'order: 1010
menu-splitter: true
seeding:
  # 2023-2024
  - [''0ceec500-2be0-11f0-a1ba-abdbde63a860'', ''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'']
  - [''0d616290-2be0-11f0-8dc5-ab7f8b80419b'', ''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'']
  # 2024-2025
  - [''0da577c8-2be0-11f0-848f-577d1a1a8da3'', ''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'']
  - [''0ded31f8-2be0-11f0-b58f-63d2d9622b6b'', ''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'']
labels:
  en: Relationship
  ku: Teklî
labels-plural:
  en: Relationships
  ku: Teklîyên';


--
-- Name: COLUMN acorn_university_hierarchies.academic_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_hierarchies.academic_year_id IS 'column-type: partial
column-partial: current
# Supress create-system
sql-select: ""
value-from: ""
css-classes-column:
  - tablet';


--
-- Name: COLUMN acorn_university_hierarchies.descendant_users_count; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_hierarchies.descendant_users_count IS 'readOnly: true
columnPartial: count
columnType: partial
labels:
  en: Descendant members
labels-plural:
  en: Descendant members
';


--
-- Name: COLUMN acorn_university_hierarchies.descendants_count; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_hierarchies.descendants_count IS 'readOnly: true
columnPartial: count
columnType: partial
labels:
  en: Descendant Organisations
labels-plural:
  en: Descendant Organisations
';


--
-- Name: acorn_university_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    material_type_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_materials OWNER TO university;

--
-- Name: TABLE acorn_university_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_materials IS 'order: 30
seeding:
  # Literature (adabi) & Science (el) Bakeloria
  - [''cdc800ae-28be-11f0-a8a6-334555029afd'', ''Math'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', ''Biology'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''dd494c0e-28be-11f0-94e1-a7b2083dd749'', ''Physics'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''e427a282-28be-11f0-8856-a7abd8a449c5'', ''Geography'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''ecf3dae8-28be-11f0-91f7-f31527b6ca23'', ''Chemistry'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''f3c853a8-28be-11f0-8938-73b157eb85a1'', ''Kurdish'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'', ''English'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''005bba60-28bf-11f0-bf7f-cff663f8102b'', ''Arabic'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', ''History'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', ''Philosophy'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', ''Sociology'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', ''Jineologi'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  # Year 10,11 Bakeloria
  - [''7f5c3dc8-2e53-11f0-8600-6ff513625846'', ''Year 10'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''7f5c4156-2e53-11f0-8601-43470f236a9e'', ''Year 11'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
labels:
  en: Material
  ku: Material
labels-plural:
  en: Materials
  ku: Materials';


--
-- Name: acorn_university_students; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code character varying(1024) NOT NULL,
    import_source character varying(1024),
    legacy_import_result character varying(1024),
    legacy_import_the_total character varying(1024),
    legacy_import_avg character varying(1024),
    legacy_import_total_mark character varying(1024)
);


ALTER TABLE public.acorn_university_students OWNER TO university;

--
-- Name: TABLE acorn_university_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_students IS 'order: 500
menu-splitter: true
labels:
  en: Student
  ku: Xwendekar
labels-plural:
  en: Students
  ku: Xwendekarên';


--
-- Name: COLUMN acorn_university_students.legacy_import_result; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_students.legacy_import_result IS 'tab: Legacy 2024
tabLocation: 2
readOnly: true
comment: Binket, serket, Serket, Serkeftî';


--
-- Name: COLUMN acorn_university_students.legacy_import_the_total; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_students.legacy_import_the_total IS 'tab: Legacy 2024
tabLocation: 2
readOnly: true
comment: Final University enrollment score';


--
-- Name: COLUMN acorn_university_students.legacy_import_avg; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_students.legacy_import_avg IS 'tab: Legacy 2024
tabLocation: 2
readOnly: true';


--
-- Name: COLUMN acorn_university_students.legacy_import_total_mark; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_students.legacy_import_total_mark IS 'tab: Legacy 2024
tabLocation: 2
readOnly: true';


--
-- Name: acorn_user_user_group_version; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group_version (
    user_id uuid NOT NULL,
    user_group_version_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_user_group_version OWNER TO university;

--
-- Name: acorn_user_user_group_versions; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_group_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    current boolean DEFAULT true NOT NULL,
    import_source character varying(1024)
);


ALTER TABLE public.acorn_user_user_group_versions OWNER TO university;

--
-- Name: acorn_user_user_groups; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    parent_user_group_id uuid,
    nest_left integer DEFAULT 0 NOT NULL,
    nest_right integer DEFAULT 0 NOT NULL,
    nest_depth integer DEFAULT 0 NOT NULL,
    image character varying(1024),
    colour character varying(1024),
    type_id uuid,
    location_id uuid,
    import_source character varying(1024),
    CONSTRAINT name_valid CHECK (((name)::text <> ''::text))
);


ALTER TABLE public.acorn_user_user_groups OWNER TO university;

--
-- Name: acorn_user_users; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    email character varying(255),
    password character varying(255),
    activation_code character varying(255),
    persist_code character varying(255),
    reset_password_code character varying(255),
    permissions text,
    is_activated boolean DEFAULT false NOT NULL,
    is_system_user boolean DEFAULT false NOT NULL,
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
    acorn_imap_username character varying(255),
    acorn_imap_password character varying(255),
    acorn_imap_server character varying(255),
    acorn_imap_port integer,
    acorn_imap_protocol character varying(255),
    acorn_imap_encryption character varying(255),
    acorn_imap_authentication character varying(255),
    acorn_imap_validate_cert boolean,
    acorn_smtp_server character varying(255),
    acorn_smtp_port character varying(255),
    acorn_smtp_encryption character varying(255),
    acorn_smtp_authentication character varying(255),
    acorn_smtp_username character varying(255),
    acorn_smtp_password character varying(255),
    acorn_messaging_sounds boolean,
    acorn_messaging_email_notifications character(1),
    acorn_messaging_autocreated boolean,
    acorn_imap_last_fetch timestamp(0) without time zone,
    acorn_default_calendar uuid,
    acorn_start_of_week integer,
    acorn_default_event_time_from date,
    acorn_default_event_time_to date,
    birth_date timestamp without time zone,
    import_source character varying(1024)
);


ALTER TABLE public.acorn_user_users OWNER TO university;

--
-- Name: acorn_exam_data_entry_scores; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_exam_data_entry_scores AS
 SELECT concat(u.id, '::', en.user_group_id, '::', em.exam_id) AS id,
    u.id AS student_user_id,
    s.id AS student_id,
    s.code AS student_code,
    cm.academic_year_semester_id,
    ays.academic_year_id,
    s.code AS filename,
    en.user_group_id AS course_user_group_id,
    ugs.code AS course_code,
    em.exam_id,
    json_object_agg(public.fn_acorn_exam_token_name(VARIADIC ARRAY[m.name]), json_build_object('id', es.id, 'title', m.name, 'value', es.score, 'createValues', json_build_object('student_id', s.id, 'exam_material_id', em.id)) ORDER BY cm."order") AS scores,
    xr.result AS course_score
   FROM ((((((((((((((((public.acorn_university_courses c
     JOIN public.acorn_university_course_materials cm ON ((cm.course_id = c.id)))
     JOIN public.acorn_university_academic_year_semesters ays ON ((cm.academic_year_semester_id = ays.id)))
     JOIN public.acorn_university_academic_years ay ON ((ay.id = ays.academic_year_id)))
     JOIN public.acorn_exam_exam_materials em ON ((em.course_material_id = cm.id)))
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_university_hierarchies hi ON (((hi.entity_id = en.id) AND (hi.academic_year_id = ay.id))))
     JOIN public.acorn_user_user_group_versions ugv ON ((hi.user_group_version_id = ugv.id)))
     JOIN public.acorn_user_user_groups ugs ON ((ugv.user_group_id = ugs.id)))
     JOIN public.acorn_user_user_group_version ug ON ((ugv.id = ug.user_group_version_id)))
     JOIN public.acorn_user_users u ON ((u.id = ug.user_id)))
     JOIN public.acorn_university_students s ON ((s.user_id = u.id)))
     JOIN public.acorn_university_materials m ON ((cm.material_id = m.id)))
     JOIN public.acorn_exam_exams e ON ((em.exam_id = e.id)))
     JOIN public.acorn_exam_types et ON ((e.type_id = et.id)))
     LEFT JOIN public.acorn_exam_scores es ON (((es.exam_material_id = em.id) AND (es.student_id = s.id))))
     LEFT JOIN public.acorn_exam_results xr ON (((xr.course_id = c.id) AND (xr.course_material_id IS NULL) AND (xr.student_id = s.id) AND (xr.calculation_type_id = '56013d6e-3247-11f0-8e96-2f232943abf8'::uuid))))
  GROUP BY u.id, s.id, s.code, cm.academic_year_semester_id, ays.academic_year_id, en.user_group_id, ugs.code, em.exam_id, xr.result;


ALTER VIEW public.acorn_exam_data_entry_scores OWNER TO university;

--
-- Name: VIEW acorn_exam_data_entry_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON VIEW public.acorn_exam_data_entry_scores IS 'batch-print: true
labels:
  en: Data Entry Score
  ku: Sitand Diyar Kirin
labels-plural:
  en: Data Entry Scores
  ku: Sitandên Diyar Kirin
';


--
-- Name: COLUMN acorn_exam_data_entry_scores.student_user_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_user_id IS 'extra-foreign-key: 
  table: acorn_user_users
  comment:
    tab-location: 2
labels:
  en: Student User
labels-plural:
  en: Student Users
sql-select: acorn_user_users.name
sortable: true
searchable: true';


--
-- Name: COLUMN acorn_exam_data_entry_scores.student_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
    name-object: true
labels:
  en: Student
labels-plural:
  en: Students
invisible: true';


--
-- Name: COLUMN acorn_exam_data_entry_scores.student_code; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_code IS 'sortable: true
sql-select: acorn_exam_data_entry_scores.student_code';


--
-- Name: COLUMN acorn_exam_data_entry_scores.academic_year_semester_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.academic_year_semester_id IS 'extra-foreign-key: 
  table: acorn_university_academic_year_semesters
  comment:
    tab-location: 2
    name-object: true
labels:
  en: Academic Year Semester
labels-plural:
  en: Academic Year Semesters';


--
-- Name: COLUMN acorn_exam_data_entry_scores.academic_year_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.academic_year_id IS 'extra-foreign-key: 
  table: acorn_university_academic_years
  comment:
    tab-location: 2
    name-object: true
labels:
  en: Academic Year
labels-plural:
  en: Academic Years';


--
-- Name: COLUMN acorn_exam_data_entry_scores.course_user_group_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.course_user_group_id IS 'extra-foreign-key: 
  table: acorn_user_user_groups
  comment:
    tab-location: 2
    name-object: true
labels:
  en: Course
labels-plural:
  en: Courses';


--
-- Name: COLUMN acorn_exam_data_entry_scores.course_code; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.course_code IS 'sortable: true
sql-select: acorn_exam_data_entry_scores.course_code';


--
-- Name: COLUMN acorn_exam_data_entry_scores.exam_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2';


--
-- Name: COLUMN acorn_exam_data_entry_scores.scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.scores IS 'list-editable: delete-on-null
labels:
  en: Material Score
labels-plural:
  en: Materials Scores';


--
-- Name: acorn_exam_interview_students; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_interview_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    interview_id uuid NOT NULL,
    student_id uuid NOT NULL,
    teacher_id uuid,
    event_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    score double precision,
    course_material_id uuid
);


ALTER TABLE public.acorn_exam_interview_students OWNER TO university;

--
-- Name: TABLE acorn_exam_interview_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_interview_students IS 'menu: false
attribute-functions:
  name: return $this->interview->name;
labels:
  en: Student Interview
labels-plural:
  en: Student Interviews';


--
-- Name: COLUMN acorn_exam_interview_students.score; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_interview_students.score IS 'list-editable: true';


--
-- Name: acorn_exam_interviews; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_interviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying DEFAULT 'interview'::character varying NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    maximum double precision,
    minimum double precision,
    required boolean
);


ALTER TABLE public.acorn_exam_interviews OWNER TO university;

--
-- Name: TABLE acorn_exam_interviews; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_interviews IS 'seeding:
  - [''24dfbe1a-2bec-11f0-b616-ff9185a69d8b'', ''Example Interview'']
labels:
  en: Interview
  ku: Bihevditin
labels-plural:
  en: Interviews
  ku: Bihevditinên';


--
-- Name: acorn_location_addresses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    number character varying(1024),
    image character varying(2048),
    description text,
    area_id uuid NOT NULL,
    gps_id uuid,
    server_id uuid NOT NULL,
    created_by_user_id uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    response text,
    lookup_id uuid
);


ALTER TABLE public.acorn_location_addresses OWNER TO university;

--
-- Name: acorn_location_area_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_area_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_area_types OWNER TO university;

--
-- Name: acorn_location_areas; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    area_type_id uuid NOT NULL,
    parent_area_id uuid,
    gps_id uuid,
    server_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    is_current_version boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_areas OWNER TO university;

--
-- Name: acorn_location_gps; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_gps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    longitude double precision,
    latitude double precision,
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_gps OWNER TO university;

--
-- Name: acorn_location_locations; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address_id uuid NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    type_id uuid
);


ALTER TABLE public.acorn_location_locations OWNER TO university;

--
-- Name: acorn_location_lookup; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_lookup (
    id uuid NOT NULL,
    address character varying(1024) NOT NULL,
    city character varying(1024) NOT NULL,
    zip character varying(1024) NOT NULL,
    country_code character varying(1024) NOT NULL,
    state_code character varying(1024) NOT NULL,
    latitude character varying(1024) NOT NULL,
    longitude character varying(1024) NOT NULL,
    vicinity character varying(1024) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.acorn_location_lookup OWNER TO university;

--
-- Name: acorn_location_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    parent_type_id uuid,
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    colour character varying(1024),
    image character varying(1024)
);


ALTER TABLE public.acorn_location_types OWNER TO university;

--
-- Name: acorn_messaging_action; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_action (
    message_id uuid NOT NULL,
    action character varying(1024) NOT NULL,
    settings text NOT NULL,
    status uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_action OWNER TO university;

--
-- Name: acorn_messaging_label; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_label OWNER TO university;

--
-- Name: acorn_messaging_message; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message (
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


ALTER TABLE public.acorn_messaging_message OWNER TO university;

--
-- Name: TABLE acorn_messaging_message; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_messaging_message IS 'table-type: content';


--
-- Name: acorn_messaging_message_instance; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_instance (
    message_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:15.373287'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_instance OWNER TO university;

--
-- Name: acorn_messaging_message_message; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_message (
    message1_id uuid NOT NULL,
    message2_id uuid NOT NULL,
    relationship integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_message OWNER TO university;

--
-- Name: acorn_messaging_message_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_user (
    message_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_user OWNER TO university;

--
-- Name: acorn_messaging_message_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_user_group (
    message_id uuid NOT NULL,
    user_group_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_user_group OWNER TO university;

--
-- Name: acorn_messaging_status; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_status OWNER TO university;

--
-- Name: TABLE acorn_messaging_status; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_messaging_status IS 'table-type: content';


--
-- Name: acorn_messaging_user_message_status; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_user_message_status (
    user_id uuid NOT NULL,
    message_id uuid NOT NULL,
    status_id uuid NOT NULL,
    value character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_user_message_status OWNER TO university;

--
-- Name: TABLE acorn_messaging_user_message_status; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_messaging_user_message_status IS 'table-type: content';


--
-- Name: acorn_reporting_reports; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_reporting_reports (
    id integer NOT NULL,
    settings text NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_reporting_reports OWNER TO university;

--
-- Name: acorn_reporting_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.acorn_reporting_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.acorn_reporting_reports_id_seq OWNER TO university;

--
-- Name: acorn_reporting_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.acorn_reporting_reports_id_seq OWNED BY public.acorn_reporting_reports.id;


--
-- Name: acorn_servers; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_servers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hostname character varying(1024) DEFAULT 'hostname()'::character varying NOT NULL,
    domain character varying(1024),
    response text,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:42:56.917994'::timestamp without time zone NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (hostname) STORED,
    location_id uuid
);


ALTER TABLE public.acorn_servers OWNER TO university;

--
-- Name: acorn_university_course_language; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_course_language (
    course_id uuid NOT NULL,
    language_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_course_language OWNER TO university;

--
-- Name: TABLE acorn_university_course_language; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_course_language IS 'labels:
  en: Course language
  ku: Zimane Kors
labels-plural:
  en: Course languages
  ku: Zimanên kors';


--
-- Name: acorn_university_course_years; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_course_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    name integer NOT NULL
);


ALTER TABLE public.acorn_university_course_years OWNER TO university;

--
-- Name: TABLE acorn_university_course_years; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_course_years IS 'attribute-functions:
  name: $name = $this->attributes[''name'']; $ord = Model::ordinal($name); return "$name$ord year";
order: 1005
seeding:
  - [''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'', NULL, ''1'']
  - [''607dd68c-2b47-11f0-a57e-5f9aa740c8dc'', NULL, ''2'']
  - [''60dc4aaa-2b47-11f0-83f4-7f2b70ba9b18'', NULL, ''3'']
  - [''6118ff22-2b47-11f0-80a4-a7c3a85423e6'', NULL, ''4'']
  - [''99960a78-3864-11f0-a921-ff378d7cc773'', NULL, ''5'']
  - [''99960c8a-3864-11f0-a922-470968d3166b'', NULL, ''6'']
  - [''99960cee-3864-11f0-a923-2f0d564c9ec7'', NULL, ''7'']
  - [''99960d3e-3864-11f0-a924-53433cf99053'', NULL, ''8'']
  - [''99960d98-3864-11f0-a925-432355d22072'', NULL, ''9'']
  - [''61495bc2-2b47-11f0-b804-6317f8482a6b'', NULL, ''10'']
  - [''61733dca-2b47-11f0-b084-23828f21ea2c'', NULL, ''11'']
  - [''619bd3d4-2b47-11f0-9c1e-8b0e1b85bf28'', NULL, ''12'']
labels:
  en: Course Year
  ku: Salê Kors
labels-plural:
  en: Course Years
  ku: Salên Kors

';


--
-- Name: COLUMN acorn_university_course_years.name; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_years.name IS 'extra-translations:
  year: 
    en: Year
    ku: Sal';


--
-- Name: acorn_university_departments; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_departments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_departments OWNER TO university;

--
-- Name: TABLE acorn_university_departments; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_departments IS 'order: 50
labels:
  en: Department
  ku: Bêş
labels-plural:
  en: Departments
  ku: Bêşên';


--
-- Name: acorn_university_education_authorities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_education_authorities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_education_authorities OWNER TO university;

--
-- Name: TABLE acorn_university_education_authorities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_education_authorities IS 'order: 10
seeding:
  - [''783f2678-2cf9-11f0-a5b2-bbfb9ff0186a'', ''5a722502-2cfc-11f0-8fc6-4f662cb2699a'']
labels:
  en: Education Committee
  ku: Desteya Perwede
labels-plural:
  en: Education Committees
  ku: Desteyên Perwede';


--
-- Name: acorn_university_faculties; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_faculties (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_faculties OWNER TO university;

--
-- Name: TABLE acorn_university_faculties; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_faculties IS 'order: 40
labels:
  en: Faculty
  ku: Fakultî
labels-plural:
  en: Faculties
  ku: Fakultîyên';


--
-- Name: acorn_university_lectures; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_lectures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_material_id uuid NOT NULL,
    event_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_lectures OWNER TO university;

--
-- Name: COLUMN acorn_university_lectures.course_material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_lectures.course_material_id IS 'span: right';


--
-- Name: acorn_university_material_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_material_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'test'::character varying NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_material_types OWNER TO university;

--
-- Name: TABLE acorn_university_material_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_material_types IS 'order: 25
seeding:
  - [''6b4bae9a-149f-11f0-a4e5-779d31ace22e'', ''Material'']
labels:
  en: Material type
  ku: Cura material
labels-plural:
  en: Material types
  ku: Curên material';


--
-- Name: acorn_university_project_students; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_project_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    owner_student_id uuid,
    user_group_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    score double precision,
    course_material_id uuid,
    project_id uuid NOT NULL,
    description text
);


ALTER TABLE public.acorn_university_project_students OWNER TO university;

--
-- Name: TABLE acorn_university_project_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_project_students IS 'labels:
  en: Student Project
labels-plural:
  en: Student Projects';


--
-- Name: COLUMN acorn_university_project_students.score; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_project_students.score IS 'list-editable: true';


--
-- Name: acorn_university_projects; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    maximum double precision,
    minimum double precision,
    required boolean
);


ALTER TABLE public.acorn_university_projects OWNER TO university;

--
-- Name: TABLE acorn_university_projects; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_projects IS 'seeding:
  - [''5fcc2166-2bed-11f0-ae13-87be01ade284'', ''Example Project'']
labels:
  en: Project
  ku: Projê
labels-plural:
  en: Projects
  ku: Projên';


--
-- Name: acorn_university_schools; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_schools (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_schools OWNER TO university;

--
-- Name: TABLE acorn_university_schools; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_schools IS 'order: 30
seeding:
  - [''98870568-2cf9-11f0-8594-6b81dcd42328'', ''4b38af66-2cfc-11f0-b608-2b766ae5cd8d'']
labels:
  en: School
  ku: Dibistan
labels-plural:
  en: Schools
  ku: Dibistanên';


--
-- Name: acorn_university_semesters; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_semesters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    ordinal integer NOT NULL
);


ALTER TABLE public.acorn_university_semesters OWNER TO university;

--
-- Name: TABLE acorn_university_semesters; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_semesters IS 'attribute-functions:
  name: "return $this->attributes[''name''] . '' ('' . $this->ordinalText() . '')'';"
order: 1012
seeding:
  - [''61c051fa-2b47-11f0-bc0f-ab4c8b696730'', ''Semester 1'']
  - [''61eb583c-2b47-11f0-adc3-ef976031065b'', ''Semester 2'']
  - [''6212587e-2b47-11f0-b854-631a30042bb5'', ''Semester 3'']
labels:
  en: Semester
  ku: Werzê
labels-plural:
  en: Semesters
  ku: Werzên';


--
-- Name: acorn_university_student_codes; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_student_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    code character varying(1024) NOT NULL,
    entity_id uuid,
    name character varying(1024) GENERATED ALWAYS AS (code) STORED NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    current boolean DEFAULT true NOT NULL
);


ALTER TABLE public.acorn_university_student_codes OWNER TO university;

--
-- Name: acorn_university_student_status; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_student_status (
    student_id uuid NOT NULL,
    student_status_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_student_status OWNER TO university;

--
-- Name: acorn_university_student_statuses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_student_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    score double precision
);


ALTER TABLE public.acorn_university_student_statuses OWNER TO university;

--
-- Name: TABLE acorn_university_student_statuses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_student_statuses IS 'seeding:
  - [''021c0f46-3b96-11f0-add5-1fdf3952358b'', ''Families of Martyrs'']
  - [''021c1022-3b96-11f0-add6-9b77f9e97678'', ''From the occupied territories'']
  - [''021c104a-3b96-11f0-add7-bf3af6dabafb'', ''Served in the army'']
  - [''021c1068-3b96-11f0-add8-a7fe27552a6d'', ''Needs housing'']';


--
-- Name: acorn_university_teachers; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_teachers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_teachers OWNER TO university;

--
-- Name: TABLE acorn_university_teachers; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_teachers IS 'order: 510
labels:
  en: Teacher
  ku: Mamoste
labels-plural:
  en: Teachers
  ku: Mamostên';


--
-- Name: acorn_university_universities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_universities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_universities OWNER TO university;

--
-- Name: TABLE acorn_university_universities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_universities IS 'plugin-icon: book
plugin-names:
  en: Universities
  ku: Zaningehên
order: 20
seeding:
  - [''204c8a80-1b5d-11f0-9a78-07337e2f1cca'', ''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'']
  - [''11ad9e2e-1b6c-11f0-9008-4f702d5c7ef2'', ''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'']
labels:
  en: University
  ku: Zaningeh
labels-plural:
  en: Universities
  ku: Zaningehên';


--
-- Name: acorn_user_language_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_language_user (
    user_id uuid NOT NULL,
    language_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_language_user OWNER TO university;

--
-- Name: acorn_user_languages; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acorn_user_languages OWNER TO university;

--
-- Name: acorn_user_mail_blockers; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_mail_blockers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    template character varying(255),
    user_id uuid,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_mail_blockers OWNER TO university;

--
-- Name: acorn_user_role_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_role_user (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_role_user OWNER TO university;

--
-- Name: acorn_user_roles; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    permissions text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_roles OWNER TO university;

--
-- Name: acorn_user_throttle; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_throttle (
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


ALTER TABLE public.acorn_user_throttle OWNER TO university;

--
-- Name: acorn_user_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group (
    user_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_user_group OWNER TO university;

--
-- Name: acorn_user_user_group_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    description character varying(255),
    colour character varying(1024),
    image character varying(1024),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_user_group_types OWNER TO university;

--
-- Name: acorn_user_user_group_version_usages; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_user_user_group_version_usages AS
 SELECT NULL::uuid AS user_group_version_id,
    NULL::character varying(1024) AS "table",
    NULL::uuid AS id;


ALTER VIEW public.acorn_user_user_group_version_usages OWNER TO university;

--
-- Name: backend_access_log; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_access_log (
    id integer NOT NULL,
    user_id integer NOT NULL,
    ip_address character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.backend_access_log OWNER TO university;

--
-- Name: backend_access_log_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_access_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_access_log_id_seq OWNER TO university;

--
-- Name: backend_access_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_access_log_id_seq OWNED BY public.backend_access_log.id;


--
-- Name: backend_user_groups; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_user_groups OWNER TO university;

--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_groups_id_seq OWNER TO university;

--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_groups_id_seq OWNED BY public.backend_user_groups.id;


--
-- Name: backend_user_preferences; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_user_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.backend_user_preferences OWNER TO university;

--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_preferences_id_seq OWNER TO university;

--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_preferences_id_seq OWNED BY public.backend_user_preferences.id;


--
-- Name: backend_user_roles; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_user_roles OWNER TO university;

--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_roles_id_seq OWNER TO university;

--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_roles_id_seq OWNED BY public.backend_user_roles.id;


--
-- Name: backend_user_throttle; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_user_throttle OWNER TO university;

--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_throttle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_throttle_id_seq OWNER TO university;

--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_throttle_id_seq OWNED BY public.backend_user_throttle.id;


--
-- Name: backend_users; Type: TABLE; Schema: public; Owner: university
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
    acorn_url character varying(2048),
    acorn_user_user_id uuid
);


ALTER TABLE public.backend_users OWNER TO university;

--
-- Name: backend_users_groups; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_users_groups (
    user_id integer NOT NULL,
    user_group_id integer NOT NULL,
    deleted_at timestamp(0) without time zone
);


ALTER TABLE public.backend_users_groups OWNER TO university;

--
-- Name: backend_users_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_users_id_seq OWNER TO university;

--
-- Name: backend_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_users_id_seq OWNED BY public.backend_users.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO university;

--
-- Name: cms_theme_data; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.cms_theme_data (
    id integer NOT NULL,
    theme character varying(255),
    data text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_data OWNER TO university;

--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.cms_theme_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_data_id_seq OWNER TO university;

--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.cms_theme_data_id_seq OWNED BY public.cms_theme_data.id;


--
-- Name: cms_theme_logs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.cms_theme_logs OWNER TO university;

--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.cms_theme_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_logs_id_seq OWNER TO university;

--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.cms_theme_logs_id_seq OWNED BY public.cms_theme_logs.id;


--
-- Name: cms_theme_templates; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.cms_theme_templates OWNER TO university;

--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.cms_theme_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_templates_id_seq OWNER TO university;

--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.cms_theme_templates_id_seq OWNED BY public.cms_theme_templates.id;


--
-- Name: deferred_bindings; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.deferred_bindings OWNER TO university;

--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.deferred_bindings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deferred_bindings_id_seq OWNER TO university;

--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.deferred_bindings_id_seq OWNED BY public.deferred_bindings.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.failed_jobs OWNER TO university;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.failed_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO university;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.job_batches OWNER TO university;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.jobs OWNER TO university;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO university;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO university;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO university;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: p_users_count; Type: TABLE; Schema: public; Owner: sz
--

CREATE TABLE public.p_users_count (
    count bigint
);


ALTER TABLE public.p_users_count OWNER TO sz;

--
-- Name: winter_location_countries; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_location_countries (
    id integer NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.winter_location_countries OWNER TO university;

--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_location_countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNER TO university;

--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNED BY public.winter_location_countries.id;


--
-- Name: winter_location_states; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_location_states (
    id integer NOT NULL,
    country_id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.winter_location_states OWNER TO university;

--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_location_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_states_id_seq OWNER TO university;

--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_location_states_id_seq OWNED BY public.winter_location_states.id;


--
-- Name: winter_translate_attributes; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_attributes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    attribute_data text
);


ALTER TABLE public.winter_translate_attributes OWNER TO university;

--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_attributes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNER TO university;

--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNED BY public.winter_translate_attributes.id;


--
-- Name: winter_translate_indexes; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_indexes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    item character varying(255),
    value text
);


ALTER TABLE public.winter_translate_indexes OWNER TO university;

--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_indexes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNER TO university;

--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNED BY public.winter_translate_indexes.id;


--
-- Name: winter_translate_locales; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_locales (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255),
    is_default boolean DEFAULT false NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.winter_translate_locales OWNER TO university;

--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_locales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNER TO university;

--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNED BY public.winter_translate_locales.id;


--
-- Name: winter_translate_messages; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_messages (
    id integer NOT NULL,
    code character varying(255),
    message_data text,
    found boolean DEFAULT true NOT NULL,
    code_pre_2_1_0 character varying(255)
);


ALTER TABLE public.winter_translate_messages OWNER TO university;

--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNER TO university;

--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNED BY public.winter_translate_messages.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    payload text,
    last_activity integer,
    user_id integer,
    ip_address character varying(45),
    user_agent text
);


ALTER TABLE public.sessions OWNER TO university;

--
-- Name: system_event_logs; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_event_logs (
    id integer NOT NULL,
    level character varying(255),
    message text,
    details text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_event_logs OWNER TO university;

--
-- Name: system_event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_event_logs_id_seq OWNER TO university;

--
-- Name: system_event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_event_logs_id_seq OWNED BY public.system_event_logs.id;


--
-- Name: system_files; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_files OWNER TO university;

--
-- Name: system_files_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_files_id_seq OWNER TO university;

--
-- Name: system_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_files_id_seq OWNED BY public.system_files.id;


--
-- Name: system_mail_layouts; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_mail_layouts OWNER TO university;

--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_mail_layouts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_layouts_id_seq OWNER TO university;

--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_mail_layouts_id_seq OWNED BY public.system_mail_layouts.id;


--
-- Name: system_mail_partials; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_mail_partials OWNER TO university;

--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_mail_partials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_partials_id_seq OWNER TO university;

--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_mail_partials_id_seq OWNED BY public.system_mail_partials.id;


--
-- Name: system_mail_templates; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_mail_templates OWNER TO university;

--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_mail_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_templates_id_seq OWNER TO university;

--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_mail_templates_id_seq OWNED BY public.system_mail_templates.id;


--
-- Name: system_parameters; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_parameters (
    id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.system_parameters OWNER TO university;

--
-- Name: system_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_parameters_id_seq OWNER TO university;

--
-- Name: system_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_parameters_id_seq OWNED BY public.system_parameters.id;


--
-- Name: system_plugin_history; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_plugin_history (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    type character varying(20) NOT NULL,
    version character varying(50) NOT NULL,
    detail text,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.system_plugin_history OWNER TO university;

--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_plugin_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_history_id_seq OWNER TO university;

--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_plugin_history_id_seq OWNED BY public.system_plugin_history.id;


--
-- Name: system_plugin_versions; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_plugin_versions (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    version character varying(50) NOT NULL,
    created_at timestamp(0) without time zone,
    is_disabled boolean DEFAULT false NOT NULL,
    is_frozen boolean DEFAULT false NOT NULL,
    acorn_infrastructure boolean DEFAULT false NOT NULL
);


ALTER TABLE public.system_plugin_versions OWNER TO university;

--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_plugin_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_versions_id_seq OWNER TO university;

--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_plugin_versions_id_seq OWNED BY public.system_plugin_versions.id;


--
-- Name: system_request_logs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_request_logs OWNER TO university;

--
-- Name: system_request_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_request_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_request_logs_id_seq OWNER TO university;

--
-- Name: system_request_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_request_logs_id_seq OWNED BY public.system_request_logs.id;


--
-- Name: system_revisions; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_revisions OWNER TO university;

--
-- Name: system_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_revisions_id_seq OWNER TO university;

--
-- Name: system_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_revisions_id_seq OWNED BY public.system_revisions.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    item character varying(255),
    value text
);


ALTER TABLE public.system_settings OWNER TO university;

--
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_settings_id_seq OWNER TO university;

--
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- Name: university_mofadala_baccalaureate_marks; Type: FOREIGN TABLE; Schema: public; Owner: sz
--

CREATE FOREIGN TABLE public.university_mofadala_baccalaureate_marks (
    id integer NOT NULL,
    county character varying(255) NOT NULL,
    code text NOT NULL,
    certificate character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    father_name character varying(255) NOT NULL,
    mother_name character varying(255) NOT NULL,
    place_and_date_of_birth text NOT NULL,
    total_mark double precision NOT NULL,
    avg double precision NOT NULL,
    certificate_language character varying(255) NOT NULL,
    kurdish_language double precision,
    english_language double precision,
    arabic_language double precision,
    science_of_woman double precision,
    sociology double precision,
    history double precision,
    geography double precision,
    philosophy double precision,
    math double precision,
    biology double precision,
    chemistry double precision,
    physics double precision,
    result character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
)
SERVER localserver_universityacceptance
OPTIONS (
    schema_name 'public',
    table_name 'university_mofadala_baccalaureate_marks'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN county OPTIONS (
    column_name 'county'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN code OPTIONS (
    column_name 'code'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN certificate OPTIONS (
    column_name 'certificate'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN father_name OPTIONS (
    column_name 'father_name'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN mother_name OPTIONS (
    column_name 'mother_name'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN place_and_date_of_birth OPTIONS (
    column_name 'place_and_date_of_birth'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN total_mark OPTIONS (
    column_name 'total_mark'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN avg OPTIONS (
    column_name 'avg'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN certificate_language OPTIONS (
    column_name 'certificate_language'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN kurdish_language OPTIONS (
    column_name 'kurdish_language'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN english_language OPTIONS (
    column_name 'english_language'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN arabic_language OPTIONS (
    column_name 'arabic_language'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN science_of_woman OPTIONS (
    column_name 'science_of_woman'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN sociology OPTIONS (
    column_name 'sociology'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN history OPTIONS (
    column_name 'history'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN geography OPTIONS (
    column_name 'geography'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN philosophy OPTIONS (
    column_name 'philosophy'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN math OPTIONS (
    column_name 'math'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN biology OPTIONS (
    column_name 'biology'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN chemistry OPTIONS (
    column_name 'chemistry'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN physics OPTIONS (
    column_name 'physics'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN result OPTIONS (
    column_name 'result'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


ALTER FOREIGN TABLE public.university_mofadala_baccalaureate_marks OWNER TO sz;

--
-- Name: university_mofadala_branches; Type: FOREIGN TABLE; Schema: public; Owner: sz
--

CREATE FOREIGN TABLE public.university_mofadala_branches (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    phone character varying(255),
    email character varying(255),
    notes text,
    university_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
)
SERVER localserver_universityacceptance
OPTIONS (
    schema_name 'public',
    table_name 'university_mofadala_branches'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN type OPTIONS (
    column_name 'type'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN phone OPTIONS (
    column_name 'phone'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN email OPTIONS (
    column_name 'email'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN university_id OPTIONS (
    column_name 'university_id'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE public.university_mofadala_branches ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


ALTER FOREIGN TABLE public.university_mofadala_branches OWNER TO sz;

--
-- Name: university_mofadala_departments; Type: FOREIGN TABLE; Schema: public; Owner: sz
--

CREATE FOREIGN TABLE public.university_mofadala_departments (
    id integer NOT NULL,
    name character varying(255),
    women_only boolean NOT NULL,
    n_minimum integer NOT NULL,
    notes text,
    branche_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
)
SERVER localserver_universityacceptance
OPTIONS (
    schema_name 'public',
    table_name 'university_mofadala_departments'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN women_only OPTIONS (
    column_name 'women_only'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN n_minimum OPTIONS (
    column_name 'n_minimum'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN branche_id OPTIONS (
    column_name 'branche_id'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE public.university_mofadala_departments ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


ALTER FOREIGN TABLE public.university_mofadala_departments OWNER TO sz;

--
-- Name: university_mofadala_students; Type: FOREIGN TABLE; Schema: public; Owner: sz
--

CREATE FOREIGN TABLE public.university_mofadala_students (
    id integer NOT NULL,
    user_id integer NOT NULL,
    center_id integer NOT NULL,
    baccalaureate_mark_id integer,
    code character varying(255) NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    father_name character varying(255) NOT NULL,
    mother_name character varying(255) NOT NULL,
    self_image text,
    image text,
    place_of_birth character varying(255) NOT NULL,
    birth_date date NOT NULL,
    family_place text,
    national_id text,
    national_id_type integer NOT NULL,
    cumin text,
    city_id integer NOT NULL,
    address text,
    cell_phone character varying(255),
    tell_phone character varying(255),
    email character varying(255),
    emergency_number character varying(255),
    hs_certificate_image text,
    type_certificate_id integer NOT NULL,
    certificate_date date NOT NULL,
    certificate_language_id integer NOT NULL,
    certificate_source character varying(255) NOT NULL,
    attending_the_nomination_examination boolean NOT NULL,
    there_is_a_candidacy_exam boolean NOT NULL,
    candidate_exam_id integer,
    exam_center_id integer,
    candidacy_examination_score double precision,
    need_housing boolean NOT NULL,
    from_the_occupied_territories boolean NOT NULL,
    families_of_martyrs boolean NOT NULL,
    he_served_in_the_army boolean NOT NULL,
    gender character varying(255) NOT NULL,
    marital_status character varying(255) NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    mofadala_year_id integer NOT NULL,
    information text,
    the_total double precision,
    "constraint" character varying(255),
    department_id integer,
    current_desire integer,
    enrollment_conflict boolean,
    secondary_reallocation boolean,
    enrollment_process_notes text
)
SERVER localserver_universityacceptance
OPTIONS (
    schema_name 'public',
    table_name 'university_mofadala_students'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN user_id OPTIONS (
    column_name 'user_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN center_id OPTIONS (
    column_name 'center_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN baccalaureate_mark_id OPTIONS (
    column_name 'baccalaureate_mark_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN code OPTIONS (
    column_name 'code'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN first_name OPTIONS (
    column_name 'first_name'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN last_name OPTIONS (
    column_name 'last_name'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN father_name OPTIONS (
    column_name 'father_name'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN mother_name OPTIONS (
    column_name 'mother_name'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN self_image OPTIONS (
    column_name 'self_image'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN image OPTIONS (
    column_name 'image'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN place_of_birth OPTIONS (
    column_name 'place_of_birth'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN birth_date OPTIONS (
    column_name 'birth_date'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN family_place OPTIONS (
    column_name 'family_place'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN national_id OPTIONS (
    column_name 'national_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN national_id_type OPTIONS (
    column_name 'national_id_type'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN cumin OPTIONS (
    column_name 'cumin'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN city_id OPTIONS (
    column_name 'city_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN address OPTIONS (
    column_name 'address'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN cell_phone OPTIONS (
    column_name 'cell_phone'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN tell_phone OPTIONS (
    column_name 'tell_phone'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN email OPTIONS (
    column_name 'email'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN emergency_number OPTIONS (
    column_name 'emergency_number'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN hs_certificate_image OPTIONS (
    column_name 'hs_certificate_image'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN type_certificate_id OPTIONS (
    column_name 'type_certificate_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN certificate_date OPTIONS (
    column_name 'certificate_date'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN certificate_language_id OPTIONS (
    column_name 'certificate_language_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN certificate_source OPTIONS (
    column_name 'certificate_source'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN attending_the_nomination_examination OPTIONS (
    column_name 'attending_the_nomination_examination'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN there_is_a_candidacy_exam OPTIONS (
    column_name 'there_is_a_candidacy_exam'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN candidate_exam_id OPTIONS (
    column_name 'candidate_exam_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN exam_center_id OPTIONS (
    column_name 'exam_center_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN candidacy_examination_score OPTIONS (
    column_name 'candidacy_examination_score'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN need_housing OPTIONS (
    column_name 'need_housing'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN from_the_occupied_territories OPTIONS (
    column_name 'from_the_occupied_territories'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN families_of_martyrs OPTIONS (
    column_name 'families_of_martyrs'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN he_served_in_the_army OPTIONS (
    column_name 'he_served_in_the_army'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN gender OPTIONS (
    column_name 'gender'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN marital_status OPTIONS (
    column_name 'marital_status'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN mofadala_year_id OPTIONS (
    column_name 'mofadala_year_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN information OPTIONS (
    column_name 'information'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN the_total OPTIONS (
    column_name 'the_total'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN "constraint" OPTIONS (
    column_name 'constraint'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN department_id OPTIONS (
    column_name 'department_id'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN current_desire OPTIONS (
    column_name 'current_desire'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN enrollment_conflict OPTIONS (
    column_name 'enrollment_conflict'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN secondary_reallocation OPTIONS (
    column_name 'secondary_reallocation'
);
ALTER FOREIGN TABLE public.university_mofadala_students ALTER COLUMN enrollment_process_notes OPTIONS (
    column_name 'enrollment_process_notes'
);


ALTER FOREIGN TABLE public.university_mofadala_students OWNER TO sz;

--
-- Name: university_mofadala_universities; Type: FOREIGN TABLE; Schema: public; Owner: sz
--

CREATE FOREIGN TABLE public.university_mofadala_universities (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    city_id integer NOT NULL,
    university_category_id integer NOT NULL,
    phone character varying(255),
    email character varying(255),
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
)
SERVER localserver_universityacceptance
OPTIONS (
    schema_name 'public',
    table_name 'university_mofadala_universities'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN code OPTIONS (
    column_name 'code'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN city_id OPTIONS (
    column_name 'city_id'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN university_category_id OPTIONS (
    column_name 'university_category_id'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN phone OPTIONS (
    column_name 'phone'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN email OPTIONS (
    column_name 'email'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE public.university_mofadala_universities ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


ALTER FOREIGN TABLE public.university_mofadala_universities OWNER TO sz;

--
-- Name: university_mofadala_university_categories; Type: FOREIGN TABLE; Schema: public; Owner: sz
--

CREATE FOREIGN TABLE public.university_mofadala_university_categories (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
)
SERVER localserver_universityacceptance
OPTIONS (
    schema_name 'public',
    table_name 'university_mofadala_university_categories'
);
ALTER FOREIGN TABLE public.university_mofadala_university_categories ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE public.university_mofadala_university_categories ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE public.university_mofadala_university_categories ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE public.university_mofadala_university_categories ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE public.university_mofadala_university_categories ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


ALTER FOREIGN TABLE public.university_mofadala_university_categories OWNER TO sz;

--
-- Name: acorn_reporting_reports id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_reporting_reports ALTER COLUMN id SET DEFAULT nextval('public.acorn_reporting_reports_id_seq'::regclass);


--
-- Name: backend_access_log id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_access_log ALTER COLUMN id SET DEFAULT nextval('public.backend_access_log_id_seq'::regclass);


--
-- Name: backend_user_groups id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_groups ALTER COLUMN id SET DEFAULT nextval('public.backend_user_groups_id_seq'::regclass);


--
-- Name: backend_user_preferences id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_preferences ALTER COLUMN id SET DEFAULT nextval('public.backend_user_preferences_id_seq'::regclass);


--
-- Name: backend_user_roles id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_roles ALTER COLUMN id SET DEFAULT nextval('public.backend_user_roles_id_seq'::regclass);


--
-- Name: backend_user_throttle id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_throttle ALTER COLUMN id SET DEFAULT nextval('public.backend_user_throttle_id_seq'::regclass);


--
-- Name: backend_users id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users ALTER COLUMN id SET DEFAULT nextval('public.backend_users_id_seq'::regclass);


--
-- Name: cms_theme_data id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_data ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_data_id_seq'::regclass);


--
-- Name: cms_theme_logs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_logs ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_logs_id_seq'::regclass);


--
-- Name: cms_theme_templates id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_templates ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_templates_id_seq'::regclass);


--
-- Name: deferred_bindings id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.deferred_bindings ALTER COLUMN id SET DEFAULT nextval('public.deferred_bindings_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: system_event_logs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_event_logs ALTER COLUMN id SET DEFAULT nextval('public.system_event_logs_id_seq'::regclass);


--
-- Name: system_files id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_files ALTER COLUMN id SET DEFAULT nextval('public.system_files_id_seq'::regclass);


--
-- Name: system_mail_layouts id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_layouts ALTER COLUMN id SET DEFAULT nextval('public.system_mail_layouts_id_seq'::regclass);


--
-- Name: system_mail_partials id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_partials ALTER COLUMN id SET DEFAULT nextval('public.system_mail_partials_id_seq'::regclass);


--
-- Name: system_mail_templates id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_templates ALTER COLUMN id SET DEFAULT nextval('public.system_mail_templates_id_seq'::regclass);


--
-- Name: system_parameters id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_parameters ALTER COLUMN id SET DEFAULT nextval('public.system_parameters_id_seq'::regclass);


--
-- Name: system_plugin_history id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_history ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_history_id_seq'::regclass);


--
-- Name: system_plugin_versions id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_versions ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_versions_id_seq'::regclass);


--
-- Name: system_request_logs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_request_logs ALTER COLUMN id SET DEFAULT nextval('public.system_request_logs_id_seq'::regclass);


--
-- Name: system_revisions id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_revisions ALTER COLUMN id SET DEFAULT nextval('public.system_revisions_id_seq'::regclass);


--
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- Name: winter_location_countries id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_countries ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_countries_id_seq'::regclass);


--
-- Name: winter_location_states id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_states ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_states_id_seq'::regclass);


--
-- Name: winter_translate_attributes id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_attributes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_attributes_id_seq'::regclass);


--
-- Name: winter_translate_indexes id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_indexes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_indexes_id_seq'::regclass);


--
-- Name: winter_translate_locales id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_locales ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_locales_id_seq'::regclass);


--
-- Name: winter_translate_messages id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_messages ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_messages_id_seq'::regclass);


--
-- Data for Name: acorn_calendar_calendars; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_calendars (id, name, description, system, sync_file, sync_format, created_at, updated_at, owner_user_id, owner_user_group_id, permissions) FROM stdin;
ceea8856-e4c8-11ef-8719-5f58c97885a2	Default	\N	t	\N	0	2025-04-03 08:43:15	\N	\N	\N	1
f3bc49bc-eac7-11ef-9e4a-1740a039dada	Activity Log	\N	t	\N	0	2025-04-03 08:43:15	\N	\N	\N	1
\.


--
-- Data for Name: acorn_calendar_event_part_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_part_user (event_part_id, user_id, role_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_part_user_group; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_part_user_group (event_part_id, user_group_id) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_parts; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_parts (id, event_id, name, description, start, "end", until, mask, mask_type, type_id, status_id, repeat_frequency, parent_event_part_id, location_id, locked_by_user_id, created_at, updated_at, repeat, alarm, instances_deleted) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_statuses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_statuses (id, name, description, style, system, calendar_id, created_at, updated_at) FROM stdin;
27446472-e4c9-11ef-bde0-9b663c96a619	Normal	\N	\N	t	\N	\N	\N
fb2392de-e62e-11ef-b202-5fe79ff1071f	Cancelled	\N	text-decoration:line-through;border:1px dotted #fff;	t	\N	\N	\N
9c914367-bb6e-4b4c-b60d-d2de11ba0d67	Tentative	\N	opacity:0.7;	t	\N	\N	\N
0d846325-d836-4f5e-a723-5e4878e76fe9	Conflict	\N	border:1px solid red;background-color:#fff;color:#000;font-weight:bold;	t	\N	\N	\N
7b432540-eac8-11ef-a9bc-434841a9f67b	acorn.calendar::lang.models.general.insert	\N	color:#fff	t	\N	\N	\N
7c18bb7e-eac8-11ef-b4f2-ffae3296f461	acorn.calendar::lang.models.general.update	\N	color:#fff	t	\N	\N	\N
7ceca4c0-eac8-11ef-b685-f7f3f278f676	acorn.calendar::lang.models.general.soft_delete	\N	color:#fff	t	\N	\N	\N
f9690600-eac9-11ef-8002-5b2cbe0c12c0	acorn.calendar::lang.models.general.soft_undelete	\N	color:#fff	t	\N	\N	\N
\.


--
-- Data for Name: acorn_calendar_event_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_types (id, name, description, whole_day, colour, style, system, activity_log_related_oid, calendar_id, created_at, updated_at) FROM stdin;
2f766546-e4c9-11ef-be8c-1f2daa98a10f	Normal	\N	f	#091386	color:#fff	t	\N	\N	2025-04-03 08:43:15	\N
90675595-d8e9-45f0-b5b4-6e4dea848d50	Meeting	\N	f	#C0392B	color:#fff	t	\N	\N	2025-04-03 08:43:15	\N
6867d1bc-bcc0-40fa-a78f-e02762e33dd6	University Entities	\N	f	#333	\N	f	127565	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
f4511a42-177e-4b4f-815c-97bc62a7faec	University Years	\N	f	#333	\N	f	127498	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
736718a8-fd8e-4277-a7e5-d5f4c6d75f58	University Hierarchies	\N	f	#333	\N	f	127559	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
23b39dc4-c9ca-45a0-ac7d-5ceb9e5364e9	Exam Types	\N	f	#333	\N	f	130187	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
414d6fca-a3b9-4f16-81fb-16294ec0d8e0	Exam Material Types	\N	f	#333	\N	f	130231	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
dd927991-1b02-4659-96ec-00626e9afc5b	Exam Materials	\N	f	#333	\N	f	130202	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
e3d8874c-e1b5-4bea-a4eb-9c9f7bd378c1	Exam Exams	\N	f	#333	\N	f	130168	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
ae39a756-1988-4fc4-9f61-27c4e79f1c21	Exam Exam Materials	\N	f	#333	\N	f	130210	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
e90d2e25-a11e-46bc-8c0f-c2e441737d4b	Exam Results	\N	f	#333	\N	f	130360	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
c17e3dfd-f4b1-4e8e-a80b-5a499068e92e	University Years	\N	f	#333	\N	f	141180	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
7989413a-b4ca-4b11-9899-0366af60e6b6	Exam Material Types	\N	f	#333	\N	f	141034	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
9bb48e76-69fa-4108-808e-b281c24a37f0	Exam Materials	\N	f	#333	\N	f	141015	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
259112f5-5a87-45a8-9484-634fe93ba2fd	Exam Types	\N	f	#333	\N	f	141002	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
7f8556ac-88aa-44ab-a3d8-b92f826fd3a7	University Entities	\N	f	#333	\N	f	141157	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
e1cd4897-23bb-4492-b230-9d4e4820a8ea	Exam Exams	\N	f	#333	\N	f	140991	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
f3861664-97bb-469d-a47f-bd5082c8dcda	Exam Exam Materials	\N	f	#333	\N	f	140984	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
171d152d-cde2-4c11-92fe-9d371d1929ea	Exam Scores	\N	f	#333	\N	f	140998	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
9d9e45b6-2aed-4071-ba12-359359a36486	Exam Calculations	\N	f	#333	\N	f	140962	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
9f4415a1-7bf9-4af5-a154-1b999a029baf	Exam Scores	\N	f	#333	\N	f	143542	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
8c604e8e-b860-4bfd-898a-461703b57ff4	Exam Interviews	\N	f	#333	\N	f	148386	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
d4b30352-82e8-4c50-b0ef-dcb2dc2b9c9b	University Course Materials	\N	f	#333	\N	f	148335	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
f12691d2-5fbc-46ca-bb43-598a131893d1	University Hierarchies	\N	f	#333	\N	f	141168	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
0deccc54-7462-4f9e-801e-e00eda89cf56	University Semesters	\N	f	#333	\N	f	176467	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
6c8665e3-802f-4b18-9654-2da936d703b9	University Academic Years	\N	f	#333	\N	f	176460	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
4da3e8c4-5bd6-4219-a5c0-722c2e999a79	University Semester Years	\N	f	#333	\N	f	176482	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
b4f0f2a9-4858-49e8-99bf-9543e53cdee1	University Projects	\N	f	#333	\N	f	148424	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
1e34069e-7a17-40ef-9ae0-f983e7faf8db	Exam Interview Students	\N	f	#333	\N	f	148395	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
502ade43-df3d-4b31-9a29-43a92bc0f06c	University Projects	\N	f	#333	\N	f	177224	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
0110a0ca-5ac9-4abc-943f-3e5176bee820	Exam Calculation Types	\N	f	#333	\N	f	180876	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
86d8882e-8fb9-4fb3-aedc-d2859a7b7111	Exam Calculation Courses	\N	f	#333	\N	f	178528	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
ee663766-0e3a-440f-af3e-c88990ee2a18	Exam Calculation Material Types	\N	f	#333	\N	f	181403	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
781bf5bf-28c8-4427-aaa2-b01540504005	University Student Statuses	\N	f	#333	\N	f	182854	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
d9cabccc-3b2d-4dd2-b027-a6336bdaabbb	University Student Codes	\N	f	#333	\N	f	183142	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
\.


--
-- Data for Name: acorn_calendar_events; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_events (id, calendar_id, external_url, created_at, updated_at, owner_user_id, owner_user_group_id, permissions) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_instances; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_instances (id, date, event_part_id, instance_num, instance_start, instance_end) FROM stdin;
\.


--
-- Data for Name: acorn_exam_calculation_course_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_calculation_course_materials (id, course_material_id, calculation_id, academic_year_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_calculation_courses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_calculation_courses (id, course_id, calculation_id, academic_year_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_calculation_material_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_calculation_material_types (id, material_type_id, calculation_id, academic_year_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_calculation_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_calculation_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_calculations; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_calculations (id, name, description, expression, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, minimum, maximum, required, calculation_type_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_exam_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_exam_materials (id, exam_id, course_material_id, required, minimum, maximum, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, weight, interview_id, project_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_exams; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_exams (id, name, description, type_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_interview_students; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_interview_students (id, interview_id, student_id, teacher_id, event_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, score, course_material_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_interviews; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_interviews (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, maximum, minimum, required) FROM stdin;
\.


--
-- Data for Name: acorn_exam_scores; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_scores (id, exam_material_id, score, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, student_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_location_addresses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_addresses (id, name, number, image, description, area_id, gps_id, server_id, created_by_user_id, created_at, response, lookup_id) FROM stdin;
9e95fe34-42dd-4787-bf5d-11a20cb08d9b			\N	\N	11e62964-3046-4ea3-aa58-9a409322fe60	9e95fe34-362a-4077-8b7b-1156903f41f6	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	\N	2025-04-03 09:55:21.497978	No domain specified	\N
\.


--
-- Data for Name: acorn_location_area_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_area_types (id, name, description, server_id, created_at, created_by_user_id, response) FROM stdin;
9543b0ea-f4ed-4d01-867c-b8ae8c538f99	Country	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
705acf46-9875-428a-b5ee-557b3bbccf4b	Canton	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
77dab170-e9e8-43c1-a957-71fc0ce17d78	City	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
6df36782-529a-45a9-825a-6870f17b96b2	Village	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
ef15d7d0-eef2-4904-a596-c1b7270a50bf	Town	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
6d693694-ae57-451d-9ceb-0c71a968c1a8	Comune	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
\.


--
-- Data for Name: acorn_location_areas; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_areas (id, name, description, area_type_id, parent_area_id, gps_id, server_id, version, is_current_version, created_at, created_by_user_id, response) FROM stdin;
52e3448d-dc20-441d-a424-501df1853843	Syria	\N	9543b0ea-f4ed-4d01-867c-b8ae8c538f99	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
c290c871-bd35-4205-a839-da7ac29a080d	Cezîra	\N	705acf46-9875-428a-b5ee-557b3bbccf4b	52e3448d-dc20-441d-a424-501df1853843	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
11e62964-3046-4ea3-aa58-9a409322fe60	Qamişlo	\N	77dab170-e9e8-43c1-a957-71fc0ce17d78	c290c871-bd35-4205-a839-da7ac29a080d	ab7e8e74-65e2-46dd-b43e-d1260fb35f41	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
c2059e44-095a-470a-a1fd-05a53f26966b	Al Hêseke	\N	77dab170-e9e8-43c1-a957-71fc0ce17d78	c290c871-bd35-4205-a839-da7ac29a080d	b2e6dc49-acb5-4afe-9e10-484a7729e02d	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
\.


--
-- Data for Name: acorn_location_gps; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_gps (id, longitude, latitude, server_id, created_at, created_by_user_id, response) FROM stdin;
ab7e8e74-65e2-46dd-b43e-d1260fb35f41	37.0343936	41.2146239	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
b2e6dc49-acb5-4afe-9e10-484a7729e02d	36.5166478	40.7416334	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
9e95fe34-362a-4077-8b7b-1156903f41f6	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 09:55:21.497978	\N	No domain specified
\.


--
-- Data for Name: acorn_location_locations; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_locations (id, address_id, name, description, image, server_id, created_at, created_by_user_id, response, type_id) FROM stdin;
9e95fe34-4596-4431-865c-a5a8d2a638c4	9e95fe34-42dd-4787-bf5d-11a20cb08d9b	Court buildings	\N		cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 09:55:21.497978	\N	No domain specified	\N
\.


--
-- Data for Name: acorn_location_lookup; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_lookup (id, address, city, zip, country_code, state_code, latitude, longitude, vicinity, created_at) FROM stdin;
\.


--
-- Data for Name: acorn_location_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_types (id, name, description, parent_type_id, server_id, created_at, created_by_user_id, response, colour, image) FROM stdin;
669565d6-4a61-4ee4-b0c7-c515cda939fe	Office	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified	\N	\N
62bcfe95-0ce1-4410-8557-e69a79f9bff9	Warehouse	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified	\N	\N
4d0ef489-11b2-4631-a588-d499c86d5ac5	Supplier	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified	\N	\N
\.


--
-- Data for Name: acorn_messaging_action; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_action (message_id, action, settings, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_label; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_label (id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message (id, user_from_id, subject, body, labels, "externalID", source, mime_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_instance; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_instance (message_id, instance_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_message; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_message (message1_id, message2_id, relationship, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_user (message_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_user_group; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_user_group (message_id, user_group_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_status; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_status (id, name, description, created_at, updated_at) FROM stdin;
b22ad830-c533-45b3-a785-bcd560a61a26	Arrived	For external messages only, like email.	\N	\N
a92b4430-24dc-41ac-8483-aff392aab116	Seen	In a list	\N	\N
47b7bed3-8216-4e3b-83f9-d5e708e82979	Read	In full view, or if not truncated in a list	\N	\N
3c78554e-1551-439c-9555-0edfad45abfd	Important	User Action	\N	\N
ff3b282d-6941-4aee-8d8a-db1b8bcee14e	Hidden	User Action	\N	\N
\.


--
-- Data for Name: acorn_messaging_user_message_status; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_user_message_status (user_id, message_id, status_id, value, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_reporting_reports; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_reporting_reports (id, settings, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_servers; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_servers (id, hostname, domain, response, created_at, location_id) FROM stdin;
cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	laptop	\N	\N	2025-04-03 08:42:57	\N
\.


--
-- Data for Name: acorn_university_academic_year_semesters; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_academic_year_semesters (id, academic_year_id, semester_id, event_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_academic_years; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_academic_years (id, start, "end", current, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, name, ordinal) FROM stdin;
\.


--
-- Data for Name: acorn_university_course_language; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_course_language (course_id, language_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_course_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_course_materials (id, course_id, material_id, required, minimum, maximum, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, weight, academic_year_semester_id, course_year_id, academic_year_semester_ordinal, enrollment_academic_year_id, "order") FROM stdin;
\.


--
-- Data for Name: acorn_university_course_years; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_course_years (id, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, name) FROM stdin;
\.


--
-- Data for Name: acorn_university_courses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_courses (id, entity_id, weight) FROM stdin;
\.


--
-- Data for Name: acorn_university_departments; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_departments (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_education_authorities; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_education_authorities (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_entities; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_entities (id, user_group_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, import_source) FROM stdin;
\.


--
-- Data for Name: acorn_university_faculties; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_faculties (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_hierarchies; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_hierarchies (id, entity_id, academic_year_id, parent_id, server_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, nest_left, nest_right, nest_depth, description, user_group_version_id, descendant_users_count, descendants_count, import_source) FROM stdin;
\.


--
-- Data for Name: acorn_university_lectures; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_lectures (id, course_material_id, event_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_material_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_material_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_materials (id, name, description, material_type_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_project_students; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_project_students (id, name, owner_student_id, user_group_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, score, course_material_id, project_id, description) FROM stdin;
\.


--
-- Data for Name: acorn_university_projects; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_projects (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, maximum, minimum, required) FROM stdin;
\.


--
-- Data for Name: acorn_university_schools; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_schools (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_semesters; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_semesters (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, ordinal) FROM stdin;
\.


--
-- Data for Name: acorn_university_student_codes; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_student_codes (id, student_id, code, entity_id, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, current) FROM stdin;
\.


--
-- Data for Name: acorn_university_student_status; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_student_status (student_id, student_status_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_student_statuses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_student_statuses (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, score) FROM stdin;
\.


--
-- Data for Name: acorn_university_students; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_students (id, user_id, code, import_source, legacy_import_result, legacy_import_the_total, legacy_import_avg, legacy_import_total_mark) FROM stdin;
9ea61aa6-e7cf-4e71-b2d5-9375b103374f	9ea61aa6-e680-484d-9d30-aba185c5b329	KOB99	\N	\N	\N	\N	\N
c3b21639-182b-49eb-8fb1-91a7e8d80c44	3f64fd61-faec-4417-bf32-3e0a125f956d	KOB6	Imported from 2024-v1 university_mofadala_students:6	\N	84	\N	\N
9ee44e4d-521d-4edc-9919-aa7d8a8afa29	9ee44e4d-50ca-4a7e-b707-bdfad8ebd491	MNS	\N	\N	\N	\N	\N
10d0b3c6-67da-4daa-893a-830b46a88843	e4fb2c04-e9fa-4878-80e2-e724684a670b	KOB7	Imported from 2024-v1 university_mofadala_students:7	\N	84	\N	\N
9ea61ac5-d366-40f0-a172-4585931faa1f	9ea61ac5-d211-4e52-86f5-10c6d4dbe688	ROJ01	\N	\N	\N	\N	\N
9402da4e-8f49-4c5b-8c43-d8a261b96072	4e6a4629-f4db-4e6c-a4a3-f551ebc18933	KOB8	Imported from 2024-v1 university_mofadala_students:8	\N	81	\N	\N
8938864d-2824-42ce-809b-2f306f463466	f11cc724-0330-412a-a376-043d5bb604ea	KOB9	Imported from 2024-v1 university_mofadala_students:9	\N	77	\N	\N
3094e16d-1109-4fb6-8292-d39f2c68b522	3ef01289-8ade-4a5f-a0ad-fb78d3ad15ac	KOB10	Imported from 2024-v1 university_mofadala_students:10	\N	92	\N	\N
6852f8e4-9bc0-4aa3-8690-1c71815d0f1b	989ff7b1-bf93-45d3-923a-8826fde4f020	KOB11	Imported from 2024-v1 university_mofadala_students:11	\N	86	\N	\N
c2bc4572-9ee1-4cb3-b00c-0132cfad9590	f171e15a-20a6-4dd3-866c-30d8a675cfdd	KOB12	Imported from 2024-v1 university_mofadala_students:12	\N	94	\N	\N
ceae9399-e8cf-4b57-b7ce-dfc1d4dbfb70	aab5a941-06ae-4438-9edb-63705f62af74	KOB13	Imported from 2024-v1 university_mofadala_students:13	\N	90	\N	\N
2bde1394-7778-459c-97ad-d2c942dfe6ef	e24ae02b-c468-466f-a10d-f982f59c2c93	KOB14	Imported from 2024-v1 university_mofadala_students:14	\N	91	\N	\N
4b86c4ed-2b9c-4876-bf69-cc45e605a684	726257f9-c87c-49e4-a947-d2ffae8a413d	KOB15	Imported from 2024-v1 university_mofadala_students:15	\N	80	\N	\N
31e5b489-3e08-4851-9d84-b11facc5b0ef	4f7f0607-8ced-4663-be18-f4272d4cae2e	KOB16	Imported from 2024-v1 university_mofadala_students:16	\N	81	\N	\N
c8ef825c-3997-44bd-9e62-018860b2025a	090b0515-e919-4979-b5bd-f69f84d674a3	KOB17	Imported from 2024-v1 university_mofadala_students:17	\N	74	\N	\N
31f58b09-aa4d-49c9-9c95-343606d562e8	80288cda-4ad8-46e3-9c0a-0db9257db5b9	KOB18	Imported from 2024-v1 university_mofadala_students:18	\N	94	\N	\N
bccec837-8231-4339-a077-c96dcba17219	966b5795-6e8f-4975-b6ae-27c6c2feae24	KOB19	Imported from 2024-v1 university_mofadala_students:19	\N	79	\N	\N
4e7a7039-48ed-4394-8280-e11473e88534	0f98c4fd-b58f-4e4e-adc4-641f4ca05299	KOB20	Imported from 2024-v1 university_mofadala_students:20	\N	88	\N	\N
a6776929-1331-401d-9462-73b1101780c9	b0e8f0c1-4276-4d58-944b-00019244fa1c	KOB21	Imported from 2024-v1 university_mofadala_students:21	\N	90	\N	\N
dd20265c-1c14-4623-aed9-1625cff6803b	6e1d5573-9e0f-43b2-83ca-826916b1a7a1	KOB22	Imported from 2024-v1 university_mofadala_students:22	\N	87	\N	\N
abc6a7fd-489d-4e81-9519-954899ac705a	c5ec0a84-5bd1-4d26-a31e-54e524a6e9f5	KOB23	Imported from 2024-v1 university_mofadala_students:23	\N	78	\N	\N
0381110e-978b-42eb-9811-74991b12ac99	171949fd-ac4f-4c5e-ba22-85df6af3b97f	KOB24	Imported from 2024-v1 university_mofadala_students:24	\N	81	\N	\N
95811f34-f779-4a1b-b161-1d5111a69bbf	36e083b6-6baf-4a24-892f-c282fb41cc4d	KOB25	Imported from 2024-v1 university_mofadala_students:25	\N	85	\N	\N
dc853a45-8cfb-4dc8-b2e3-1e8a7b71fe25	9cd6cfcd-c97b-49b8-9122-37c91b4e1d71	KOB26	Imported from 2024-v1 university_mofadala_students:26	\N	93	\N	\N
e1387563-dbce-4679-b6a5-15cae3a3ebf8	d783f34c-6083-491c-a9ae-0af1fb117303	KOB27	Imported from 2024-v1 university_mofadala_students:27	\N	76	\N	\N
771b7dbd-1c8e-4c89-ba6f-8d692117c796	13504931-bdb7-4442-a817-bf86df4c04aa	KOB28	Imported from 2024-v1 university_mofadala_students:28	\N	82	\N	\N
cd438ea7-f2c3-4466-b713-a55ec1b8f3f4	7a2149f9-1779-4a09-bcc9-637f58cbd484	KOB29	Imported from 2024-v1 university_mofadala_students:29	\N	74	\N	\N
cb547411-806d-4538-9ea1-2d7d2fc2eebc	62674f06-8c4c-4020-b999-54a001027e99	KOB4	Imported from 2024-v1 university_mofadala_students:4	\N	74	\N	\N
0f879da8-3dbe-4c37-b44d-43dbe8892013	b880a3af-09cb-4394-a70d-4564ae2f7804	KOB1	Imported from 2024-v1 university_mofadala_students:1	Serkeftî	93	88.13	705
f36ff0d5-53d3-4961-9f73-ee053ea831e9	fe9d69ca-0980-402f-af33-ed3a093ea83f	KOB30	Imported from 2024-v1 university_mofadala_students:30	\N	89	\N	\N
a478191d-9bbe-42d7-9ed4-6f7af67c8637	2f57dcef-7fbf-486c-b186-67d9ac6bf434	KOB31	Imported from 2024-v1 university_mofadala_students:31	\N	86	\N	\N
56fadb0f-2553-4661-b099-fe5c1d3c083e	07a2844a-7a19-4cfa-865c-5b59dfcf317a	KOB32	Imported from 2024-v1 university_mofadala_students:32	\N	79	\N	\N
bcf20546-841a-4cc7-bf96-b27c694604b8	6ee2bf6a-8914-415c-9665-86e97a718253	KOB33	Imported from 2024-v1 university_mofadala_students:33	\N	88	\N	\N
31752ada-da0b-4539-ace9-2aa41d1bc93a	0c7e2d6c-dc3c-4d79-80ff-c499bb11927d	KOB34	Imported from 2024-v1 university_mofadala_students:34	\N	80	\N	\N
2c16fa21-f09b-4df5-a73a-3702fcbdcb91	3dcbfe97-d3e8-450e-b872-2dc4a728f4d2	KOB35	Imported from 2024-v1 university_mofadala_students:35	\N	92	\N	\N
c3cccb30-2724-439b-8965-8d5233e44312	0e1492a4-0fd3-4521-a28c-16701dda1896	KOB36	Imported from 2024-v1 university_mofadala_students:36	\N	92	\N	\N
f2804ef9-2d78-466c-a131-704cb20cb484	d21cd6b0-1301-43fe-87bd-a2c706986af9	KOB37	Imported from 2024-v1 university_mofadala_students:37	\N	85	\N	\N
e4f4bdfe-1079-4f58-8857-fc4a682da5ea	4e94d6dd-517a-4c54-ad5b-6f678d72cac3	KOB38	Imported from 2024-v1 university_mofadala_students:38	\N	93	\N	\N
c889a800-b587-4270-9264-55f3c6218a92	5753efcc-d8a3-4575-81e8-8e3e36779ee3	KOB39	Imported from 2024-v1 university_mofadala_students:39	\N	75	\N	\N
32b017ec-e2c1-4bc2-9685-6a438f981a8a	2854e734-ac2a-47ea-804e-afebf2977fe8	KOB40	Imported from 2024-v1 university_mofadala_students:40	\N	84	\N	\N
9862ba71-19d0-4bdf-8240-d3bc3e60a2d2	f6fa2d27-59eb-4b27-8646-dd50bd0b971b	KOB41	Imported from 2024-v1 university_mofadala_students:41	\N	94	\N	\N
d2cae070-5cf4-4b40-b67b-df5d7516d6f1	ae9cf707-9a2e-41c6-89fe-65d504ce2581	KOB42	Imported from 2024-v1 university_mofadala_students:42	\N	89	\N	\N
a6b98917-fd45-4d84-b834-169245e28302	8e56c70d-dc29-4e13-a593-e42ed4719d55	KOB43	Imported from 2024-v1 university_mofadala_students:43	\N	79	\N	\N
fa9764b4-9864-464c-a9ed-d9e9ccb113bc	856c63d5-9eb3-44c4-923c-237e4476e0fa	KOB44	Imported from 2024-v1 university_mofadala_students:44	\N	82	\N	\N
8a07afb1-75f5-43a0-8f6e-a8a6ab9ec4ff	dd72c8b5-a780-46d9-8fda-a46cabed8a9f	KOB45	Imported from 2024-v1 university_mofadala_students:45	\N	91	\N	\N
1385565d-c684-4da7-b2bb-1818a575deaf	2265bd45-67c5-4a5d-8016-a36bec3844dd	KOB46	Imported from 2024-v1 university_mofadala_students:46	\N	89	\N	\N
7212f396-6459-4c1a-9489-df1a4be9efce	90e5f167-800c-41c5-9352-7ba76184800f	KOB47	Imported from 2024-v1 university_mofadala_students:47	\N	91	\N	\N
82272432-9de7-441c-a919-ad3d5587f810	823cc6b7-c309-4327-a02b-d60ed3305b2e	KOB48	Imported from 2024-v1 university_mofadala_students:48	\N	83	\N	\N
bc09fdc6-1f4f-449e-96ef-905a7b89e9ae	c102cdff-32d7-41d1-9435-a17ec69879cb	KOB49	Imported from 2024-v1 university_mofadala_students:49	\N	85	\N	\N
db3b50a7-8888-4ecd-8ab4-ebb9f333043f	aaa6f127-5c7e-4278-b3b7-54dfeb40dfa2	KOB50	Imported from 2024-v1 university_mofadala_students:50	\N	83	\N	\N
6769f493-e0a0-4a6e-a066-7400b6fcf163	a4a64845-d7af-4b7a-87df-0ae0c59f560a	KOB51	Imported from 2024-v1 university_mofadala_students:51	\N	83	\N	\N
5e13dcf3-60ba-49d7-9ff6-14e421442e1f	93d05a2b-7992-4cf0-a3ad-c3d26390ffab	KOB52	Imported from 2024-v1 university_mofadala_students:52	\N	81	\N	\N
4753ff20-0aff-4996-b505-68d1b54af40b	1b78aea7-21c3-4523-b773-5c31d67e461d	KOB53	Imported from 2024-v1 university_mofadala_students:53	\N	81	\N	\N
3d9fbec1-dd1f-43e7-8637-da2f719fe0ab	4c9318ba-d04e-455d-b56f-f05fb3bcb0be	KOB54	Imported from 2024-v1 university_mofadala_students:54	\N	75	\N	\N
48a8a5a5-0666-4977-baa5-6d894455947e	1ade79ea-fd20-4a7f-be73-2579ccb2c31d	KOB55	Imported from 2024-v1 university_mofadala_students:55	\N	86	\N	\N
3b734148-78f4-45a8-961a-4268a1b78f11	0d6a8654-4d20-46b8-8884-a3001a0bcc41	KOB56	Imported from 2024-v1 university_mofadala_students:56	\N	83	\N	\N
ad453288-f589-4dc0-9c3b-7a8f9d6c38ef	dd95f51d-1a74-4fcf-991d-cb33a41da997	KOB57	Imported from 2024-v1 university_mofadala_students:57	\N	93	\N	\N
47390d2f-fbc4-4d92-8548-5e4021bfcf43	a36ab23c-e8e8-4c4d-9fcb-dbd0cb28d0b6	KOB58	Imported from 2024-v1 university_mofadala_students:58	\N	88	\N	\N
a36d4e70-59b5-4f43-9338-467e5c44401e	71da8bcd-7dfb-4fc5-a267-6139bcd09205	KOB59	Imported from 2024-v1 university_mofadala_students:59	\N	77	\N	\N
a1ea349b-14b6-495b-9cd5-818b113c4116	5884674d-9de1-4549-8355-f8221c62a826	KOB60	Imported from 2024-v1 university_mofadala_students:60	\N	87	\N	\N
a4afe289-db3f-4ffb-8ab0-9383d649c335	efc9e0fe-17f4-4b8f-bc07-26bc6a8da641	KOB61	Imported from 2024-v1 university_mofadala_students:61	\N	79	\N	\N
bdbae39c-0c5d-466b-a432-361978dc9c06	56eee99e-1152-4b6c-84d8-52d2e3a8e0f6	KOB62	Imported from 2024-v1 university_mofadala_students:62	\N	92	\N	\N
1e1149b1-a7c6-45bd-aa49-ed381c15ef81	da9a7888-ecdd-495a-be63-d51316977d3b	KOB63	Imported from 2024-v1 university_mofadala_students:63	\N	88	\N	\N
da0b8924-4ebb-4fe1-8aad-29ff05cd2eda	3d514f29-e08a-4939-9d08-570e67f0b3ec	KOB64	Imported from 2024-v1 university_mofadala_students:64	\N	77	\N	\N
9cb1942d-5b1d-437e-a1cc-0e3aa0e8ee20	e2b4bbab-dba6-4bc7-b883-c89e2da5f845	KOB65	Imported from 2024-v1 university_mofadala_students:65	\N	91	\N	\N
097815eb-a821-4bc0-b9b6-ee82c997bbe7	cdd57003-d205-4064-bdb4-c1aa24b7da7d	KOB66	Imported from 2024-v1 university_mofadala_students:66	\N	74	\N	\N
2ce28798-92ab-4939-a9ee-6aa1feb35827	818a7a2c-372f-42fa-a767-c67395ef6d08	KOB67	Imported from 2024-v1 university_mofadala_students:67	\N	80	\N	\N
f671ba48-6ba5-44dc-8576-c8d6f9bdd424	28ac41a4-ef42-4567-ad85-b08f92046447	KOB68	Imported from 2024-v1 university_mofadala_students:68	\N	80	\N	\N
1e75501e-da3f-4c9a-b9fe-c5e996870297	e78844ac-c83b-4877-8725-bc35e403f20a	KOB69	Imported from 2024-v1 university_mofadala_students:69	\N	80	\N	\N
f49532c6-d643-4faa-ba85-78ce8c05c744	45ccf283-6396-4ccb-8c1f-da1de92c2e4a	KOB70	Imported from 2024-v1 university_mofadala_students:70	\N	85	\N	\N
f5efa991-0051-4c77-a85c-16e306b32897	4d50712b-1a4d-425d-b7ed-61d512546f43	KOB71	Imported from 2024-v1 university_mofadala_students:71	\N	81	\N	\N
d339e2cc-b208-468f-8814-6dc779f68a1f	cb9e973a-d540-447e-bbad-0f0331885bd9	KOB72	Imported from 2024-v1 university_mofadala_students:72	\N	83	\N	\N
94da30a7-ccf4-48fe-8c1a-e0ea1e7ea5d3	b221bac3-9d62-4845-bd8f-947d0b3cca8e	KOB73	Imported from 2024-v1 university_mofadala_students:73	\N	89	\N	\N
aa2cb1fd-04de-4f34-a615-d97034310ec0	5308f937-7182-4684-9d98-cd6d0510b345	KOB74	Imported from 2024-v1 university_mofadala_students:74	\N	81	\N	\N
af7f6671-292d-4f60-900c-9492c2dc5414	1af621f0-69bf-4dc4-849d-14aef7e3a692	KOB75	Imported from 2024-v1 university_mofadala_students:75	\N	81	\N	\N
90a67e77-ea86-4ba8-abcb-ef2e125deaeb	7e6c1cd5-60be-4da4-ae23-cb41932da741	KOB76	Imported from 2024-v1 university_mofadala_students:76	\N	91	\N	\N
877bf44f-cb32-42c7-b9f7-1044b4401c54	68338af7-34d8-4edd-b7e8-0ad9364d79da	KOB77	Imported from 2024-v1 university_mofadala_students:77	\N	90	\N	\N
d614e7d5-c417-4e5b-b9f2-2fb529d19082	bffe3efb-d7b9-4c87-b7eb-7312c1ad1171	KOB78	Imported from 2024-v1 university_mofadala_students:78	\N	91	\N	\N
c2394250-8f2d-46c9-a671-c0357a1099d4	c51b90c4-9d8e-4fae-b3e3-67dec4e27918	KOB79	Imported from 2024-v1 university_mofadala_students:79	\N	80	\N	\N
423a464f-b977-49bc-b8d5-b4b133dddf33	63145aaf-8849-48c0-b90b-d8b23805a211	KOB80	Imported from 2024-v1 university_mofadala_students:80	\N	90	\N	\N
c7a47c61-f313-4efe-a43b-f2afb14e905d	3f5584d2-f5e3-47d4-b3b0-3a2076ec2dff	KOB5	Imported from 2024-v1 university_mofadala_students:5	\N	93	\N	\N
90cfe5b3-33a1-4f92-9aff-804d711c5b02	aa50a12a-3dac-46c0-9377-ce455d038e86	KOB2	Imported from 2024-v1 university_mofadala_students:2	Serkeftî	77	82.88	663
7ef7f69f-779e-4c91-8fa2-fe67c88c50e5	779b5391-b922-4ba9-87c3-8d49a3eeda03	KOB3	Imported from 2024-v1 university_mofadala_students:3	Serkeftî	79	84.13	673
\.


--
-- Data for Name: acorn_university_teachers; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_teachers (id, user_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_universities; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_universities (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_user_language_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_language_user (user_id, language_id) FROM stdin;
9ea61aa6-e680-484d-9d30-aba185c5b329	9eaa5c43-db07-4597-ac8c-156253e84376
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	9eaa5c43-db07-4597-ac8c-156253e84376
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	9eaa5c4d-9080-4799-afa7-3741349b5beb
9eda3ec9-0240-4f44-8f58-ff497c3845d3	9eaa5c43-db07-4597-ac8c-156253e84376
9ee44e4d-50ca-4a7e-b707-bdfad8ebd491	9eaa5c4d-9080-4799-afa7-3741349b5beb
\.


--
-- Data for Name: acorn_user_languages; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_languages (id, name) FROM stdin;
9eaa5c43-db07-4597-ac8c-156253e84376	Kurdish
9eaa5c4d-9080-4799-afa7-3741349b5beb	English
\.


--
-- Data for Name: acorn_user_mail_blockers; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_mail_blockers (id, email, template, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_user_role_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_role_user (user_id, role_id) FROM stdin;
\.


--
-- Data for Name: acorn_user_roles; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_roles (id, name, permissions, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_user_throttle; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_throttle (id, user_id, ip_address, attempts, last_attempt_at, is_suspended, suspended_at, is_banned, banned_at) FROM stdin;
9ea0e068-32b3-4f4e-b4ac-6f2c0101019a	9e95e47b-46dc-492d-8ffa-1954bc3f1611	\N	0	\N	f	\N	f	\N
9ea8645a-2223-40ae-a4e7-d220afbb5f70	9ea61ac5-d211-4e52-86f5-10c6d4dbe688	\N	0	\N	f	\N	f	\N
9ed51c00-b00d-49b2-b119-233b8823a538	9ea61aa6-e680-484d-9d30-aba185c5b329	\N	0	\N	f	\N	f	\N
9ed51c21-82b4-4eba-b2d9-84c4712987f0	9e95e47c-db72-48ec-8c0c-908592ebf59c	\N	0	\N	f	\N	f	\N
\.


--
-- Data for Name: acorn_user_user_group; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_group (user_id, user_group_id) FROM stdin;
\.


--
-- Data for Name: acorn_user_user_group_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_group_types (id, name, description, colour, image, created_at, updated_at) FROM stdin;
9ec2de06-399d-4bc4-8cb0-e641a39aef1d	Test	\N	\N		\N	\N
\.


--
-- Data for Name: acorn_user_user_group_version; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_group_version (user_id, user_group_version_id) FROM stdin;
62674f06-8c4c-4020-b999-54a001027e99	8f290af5-a843-41d5-aae9-4ead9b17adde
3f5584d2-f5e3-47d4-b3b0-3a2076ec2dff	52f8a3a6-a923-4a00-be40-3e008db908ad
aa50a12a-3dac-46c0-9377-ce455d038e86	04648969-39a7-44e0-9607-ffb709060c72
779b5391-b922-4ba9-87c3-8d49a3eeda03	6154fdcc-9f32-4ab0-a9f2-a6cf221fb80f
b880a3af-09cb-4394-a70d-4564ae2f7804	be148a2d-b0e5-4732-8bb0-609a2266d874
b880a3af-09cb-4394-a70d-4564ae2f7804	b735389e-bf8d-4b3e-bb59-1646f40a3bf1
b880a3af-09cb-4394-a70d-4564ae2f7804	ccfddbda-d0e8-465a-8247-e762c48def2f
aa50a12a-3dac-46c0-9377-ce455d038e86	be148a2d-b0e5-4732-8bb0-609a2266d874
aa50a12a-3dac-46c0-9377-ce455d038e86	b735389e-bf8d-4b3e-bb59-1646f40a3bf1
aa50a12a-3dac-46c0-9377-ce455d038e86	ccfddbda-d0e8-465a-8247-e762c48def2f
779b5391-b922-4ba9-87c3-8d49a3eeda03	be148a2d-b0e5-4732-8bb0-609a2266d874
779b5391-b922-4ba9-87c3-8d49a3eeda03	b735389e-bf8d-4b3e-bb59-1646f40a3bf1
779b5391-b922-4ba9-87c3-8d49a3eeda03	ccfddbda-d0e8-465a-8247-e762c48def2f
\.


--
-- Data for Name: acorn_user_user_group_versions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_group_versions (id, user_group_id, version, current, import_source) FROM stdin;
8449aed0-9382-4c0a-9363-73064ee68686	2c4251c8-2cf9-11f0-bbd1-3370778ee65e	4	f	\N
9f3779f0-cdf2-45ae-bc07-d12eee3ebd19	9e95e450-a158-42c4-a1ea-fddb46b67e7e	1	t	\N
422c3f7a-d120-43d0-9ceb-182a6b5930b9	9e95e450-97ee-40a8-a55e-4eb76beaf9ae	1	t	\N
5584c90a-c0ea-41b8-a223-a176254c014c	2c4251c8-2cf9-11f0-bbd1-3370778ee65e	5	t	\N
0ce262ab-2ca3-4989-a3ce-b5314672ad5b	b59330d1-04b8-4b61-8071-1a3cfdfa9d56	1	f	\N
70fc5dbd-13c3-4e3c-9aeb-ca4467aa9634	b59330d1-04b8-4b61-8071-1a3cfdfa9d56	2	t	\N
e62a657e-8907-4a05-9c7d-38fda067a417	af349d61-0cd4-4be2-98af-f729d946de7e	1	f	\N
17a7f25b-58e1-43a5-b765-ecfcf7d890d3	af349d61-0cd4-4be2-98af-f729d946de7e	2	t	\N
5969600f-5b48-4a61-a9f9-c692f03d1c9e	e22ec9eb-493c-42c5-93b7-4d8551e2097f	1	f	\N
44bdf382-0a22-4821-b22a-219b1bf8a433	e22ec9eb-493c-42c5-93b7-4d8551e2097f	2	t	\N
49a5eeaf-3e8c-4002-9926-d7bd80ee2d00	2997a720-c4aa-4775-b1fe-bce11eb47935	1	f	\N
9e182cda-f785-4fcf-9cfa-6018ec7c8043	2997a720-c4aa-4775-b1fe-bce11eb47935	2	t	\N
e5ca36f2-9270-43f5-a8e8-f8bd2a55726d	e7884a43-f541-4818-bb4e-0affac81a1a4	1	f	\N
8123e2c3-7302-49b9-8035-72b4ea78ab22	e7884a43-f541-4818-bb4e-0affac81a1a4	2	t	\N
7652c163-96fa-44b5-b0ac-9ab5d5613a13	1b6c5f61-5e61-499e-b901-53d31d032641	1	f	\N
3d8c04b6-3cc0-4016-8167-396deaa4ffa8	1b6c5f61-5e61-499e-b901-53d31d032641	2	t	\N
d0b4194c-c44c-4ae0-9584-445b33ea998b	41ace1f7-83b0-410f-aa1c-f70297986d6e	1	f	\N
fe5a5d59-f00d-42a9-834c-9ca2b206f6c4	41ace1f7-83b0-410f-aa1c-f70297986d6e	2	t	\N
14c09861-b46c-4f9b-bdc3-45494bd488d3	e92954ac-77b5-4ad3-b17d-16034c22b99a	1	f	\N
028aeef7-ed67-4edf-a74f-caad00d312f7	e92954ac-77b5-4ad3-b17d-16034c22b99a	2	t	\N
70ab3b49-8984-409a-a989-d744b4533823	e77683a2-7fd1-4494-9d4a-8971208f3b86	1	f	\N
c1c534f7-168c-493c-b805-a4747b11e423	e77683a2-7fd1-4494-9d4a-8971208f3b86	2	t	\N
aa775187-4ae5-4a34-9cdd-8c41b5d4d48a	97828e8a-3503-453b-959c-50ace786e4b0	1	f	\N
f80444da-fe6d-4f45-bf30-becf9b4b0eb8	97828e8a-3503-453b-959c-50ace786e4b0	2	t	\N
98c10734-339a-41cb-ae1d-c39c70df4939	a7237520-2d8f-11f0-a834-2b294fbfca54	34	f	\N
3db9b88a-0fb8-4823-a243-bf8891e7aaca	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	34	f	\N
0c16d1bd-143c-420b-93f1-96edd8fb1a8d	21397b0c-2e53-11f0-8a85-1759860470a0	34	f	\N
9f26c58e-d51d-4a1e-8a16-8929c172f725	21397d32-2e53-11f0-8a86-abb690facbb0	34	f	\N
ce6e28ac-c924-4b56-9db1-a0080f81bb05	cf38897d-2512-48b9-93d9-b96646f11ca0	1	f	\N
8dfcc2e0-1f82-4f0b-ae4c-9adddc17d738	cf38897d-2512-48b9-93d9-b96646f11ca0	2	t	\N
2a11f324-a93f-4e85-8ae8-a72f6ea04258	9d700354-a1dd-4be3-9d6a-2c01f16f220e	1	f	\N
4a2a0a65-1ce9-4f6f-9fb4-650f3030ea1f	9d700354-a1dd-4be3-9d6a-2c01f16f220e	2	t	\N
9484df23-4b75-444c-b2c2-1e3fd27b6c2c	ee267a6a-67b3-4cb1-9560-6e86820ccdc9	1	f	\N
4b36a0d6-68ca-4e19-b2fb-47215e054f65	ee267a6a-67b3-4cb1-9560-6e86820ccdc9	2	t	\N
c72be5f7-8367-4733-b516-4e51f9a453f4	0518d610-fc9d-4f0e-9546-fc7405e7c69e	1	f	\N
ea01deee-f12c-4ee8-a639-98091b30544f	0518d610-fc9d-4f0e-9546-fc7405e7c69e	2	t	\N
0fdc1143-8f3a-47fe-b406-e0c4e1bd7a93	4670c8a4-7d4c-4a55-a448-5d7afc7797de	1	f	\N
6c2f5bda-f364-47b1-a7b6-f7a485fa217b	4670c8a4-7d4c-4a55-a448-5d7afc7797de	2	t	\N
b8ab8ab2-9a9b-4c04-a7c9-6a626abec1e1	198246db-8799-4d3d-ab1e-640c3fb04cc8	1	f	\N
b889600d-a9a0-4fbc-96a5-6686495c64e4	198246db-8799-4d3d-ab1e-640c3fb04cc8	2	t	\N
e81709ca-c6fe-46f7-ad50-61b5354b04b7	26da196b-1ba4-4c0f-ad33-258ffa959736	1	f	\N
d40155f1-b3ee-4aa3-9eb4-94490128f45a	26da196b-1ba4-4c0f-ad33-258ffa959736	2	t	\N
e7e8e592-a600-48ed-b5e3-b7a711a40598	841d9354-fd36-47ef-bf5a-cf9a4576cf76	1	f	\N
306d425d-6191-4c40-8713-8b395df5a4f8	841d9354-fd36-47ef-bf5a-cf9a4576cf76	2	t	\N
f8d34432-8682-4be0-88f0-fac6dd998039	2c4251c8-2cf9-11f0-bbd1-3370778ee65e	2	f	\N
e4e7dc92-9a58-46d3-b9cd-eb4f8b98843e	49139628-343f-4e58-a2f6-ee37ece80ccb	1	f	\N
046ba2fd-8974-49a3-9f56-823b10fe1cd3	49139628-343f-4e58-a2f6-ee37ece80ccb	2	t	\N
ca73d954-12c2-456d-8aba-45f7ee2e0e66	7bf744be-6cf4-438c-a9ac-2c8ad9eec9c2	1	f	\N
ce71bda7-9c9d-4977-a6f8-4ab706b5da99	7bf744be-6cf4-438c-a9ac-2c8ad9eec9c2	2	t	\N
ae2ce41f-06eb-4d7a-98ff-47eeef21775f	38345a2b-c368-4f8b-854a-193fcf1db679	1	f	\N
b7bde34d-f256-4a92-88cd-c676d6cd19e2	38345a2b-c368-4f8b-854a-193fcf1db679	2	t	\N
c365dbba-2c9c-4c62-8801-eb2429ef45b5	ab66a3af-016d-4cd3-8c5b-0b29a3716f77	1	f	\N
6ecf753e-ef9f-4ab8-a080-fbfa7d9fdbe2	ab66a3af-016d-4cd3-8c5b-0b29a3716f77	2	t	\N
9e851179-716c-4a5c-88b2-3b337db59712	9e4fb89a-07a7-4458-8904-e413fc0a1e11	1	f	\N
669de373-d1c6-404c-814a-1cefbdbf3e79	9e4fb89a-07a7-4458-8904-e413fc0a1e11	2	t	\N
bfc140f0-fdc2-469a-899e-225bd1c389c2	b09dbce1-dcb0-441b-a33a-92d2f84d8513	1	f	\N
15cb7a08-f283-46e8-90d7-5a9fef039b70	b09dbce1-dcb0-441b-a33a-92d2f84d8513	2	t	\N
95e243e4-083b-47bc-9553-9dd0d1e15804	47123d4b-11f7-4b73-8c57-a52e4cf49a3b	1	f	\N
ea2947a0-95d9-43ec-8859-20bed21d01f6	47123d4b-11f7-4b73-8c57-a52e4cf49a3b	2	t	\N
e0f6e25f-acff-45eb-93c0-44f124dc8163	78f27ce7-5802-46e8-a559-ca7e12d16c21	1	f	\N
04c8d470-8af0-45a8-a7be-03696d24773a	78f27ce7-5802-46e8-a559-ca7e12d16c21	2	t	\N
2e1c7eed-c326-48d1-ac43-88dd37fdfa49	0ca98908-268c-4636-a83f-0f5806fa57ef	1	f	\N
1be6605a-f967-4d4b-a44e-1e50f38416d1	0ca98908-268c-4636-a83f-0f5806fa57ef	2	t	\N
6a8ff6a5-9632-4944-8a35-1e40d0c30a79	bdc5f878-2001-41b7-97d6-d331df13be97	1	f	\N
0fadfaa7-ad17-4dea-89c8-d49400c70c44	bdc5f878-2001-41b7-97d6-d331df13be97	2	t	\N
331eef73-8078-41c5-8875-3c7c31f3304f	6a4c2ca2-926a-4b40-bc67-f77541b9bc95	1	f	\N
f400d11a-ff2e-486c-8a8d-6101ca20a472	6a4c2ca2-926a-4b40-bc67-f77541b9bc95	2	t	\N
0974a405-b275-42f7-b23e-815cc1322a26	d3bd5348-6774-4c2f-83b9-657dde12139a	1	f	\N
97c76f3b-f9e7-4096-b31f-84ce05ac8c74	d3bd5348-6774-4c2f-83b9-657dde12139a	2	t	\N
ed007867-13dc-4de2-a913-fbb702028d07	79c490d7-92d0-4133-a5a7-a8cb41da7a7c	1	f	\N
b58707b0-f30a-4918-b7bb-884c56af4514	79c490d7-92d0-4133-a5a7-a8cb41da7a7c	2	t	\N
a072996e-af66-4248-b706-3311d03814fb	8202c9ae-f143-46e0-8a1a-3b9953bb008f	1	f	\N
9933b876-1121-457e-ad1a-bd75bde1e55f	8202c9ae-f143-46e0-8a1a-3b9953bb008f	2	t	\N
54ad7a48-729a-4d67-b8c9-db5ea202ec5a	e321faa9-67be-464a-b529-e75821cd4064	1	f	\N
dcbc18bb-0a7d-47b0-bbd2-7bd2f2440488	e321faa9-67be-464a-b529-e75821cd4064	2	t	\N
a8c74029-3f31-41a4-8216-f3c0d609a2d4	ec677ed0-ef23-4aa3-af9c-b0eaba9beaba	1	f	\N
903447e1-7600-48f8-921e-287b83970c5a	ec677ed0-ef23-4aa3-af9c-b0eaba9beaba	2	t	\N
2e0e364c-9892-48d4-b4f4-aae18883b036	cf0cd8e6-0810-4e8b-97d2-28389b7f7c35	1	f	\N
7701776e-1b6b-46ce-8847-66c74488e824	cf0cd8e6-0810-4e8b-97d2-28389b7f7c35	2	t	\N
7457473c-8846-4e41-b87c-9da2dbd91839	c8e069e2-4f61-439d-a38e-813945233603	1	f	\N
e68de4d5-8196-4c6f-9d2b-d4215fad2e0f	21397b0c-2e53-11f0-8a85-1759860470a0	2	f	\N
df993abd-b096-49f9-9b63-c7f39abe4c18	21397d32-2e53-11f0-8a86-abb690facbb0	2	f	\N
2be5788f-6d23-4bc2-a9b8-79f68543f99d	a7237520-2d8f-11f0-a834-2b294fbfca54	2	f	\N
ee75104d-ce80-44be-b53d-abb201af16a9	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	2	f	\N
2a0330d9-90b7-4835-a9ba-47a5746d9c0a	2c4251c8-2cf9-11f0-bbd1-3370778ee65e	3	f	\N
cd768d06-9f2a-4e83-9997-a971c0c32068	c8e069e2-4f61-439d-a38e-813945233603	2	t	\N
2d576953-e86c-4bd6-9e63-54d6b3ff9140	c4589015-e6f0-4585-9e03-07f59c2f42d7	1	f	\N
0ac609e7-d5da-4725-8da7-38ecec1efa8c	c4589015-e6f0-4585-9e03-07f59c2f42d7	2	t	\N
c8b14e47-57e5-43db-bf8a-36e4c2d979de	9cfd2aaa-a4a1-40ea-9c37-f7fe5e72649f	1	f	\N
272a2c4a-f96d-4a1a-9b4b-c5fb1ad86de3	9cfd2aaa-a4a1-40ea-9c37-f7fe5e72649f	2	t	\N
3e125f48-2507-4198-a05e-0acd49d21167	3a8db0cf-f309-42bb-9924-698d6049c6f6	1	f	\N
cd2405f1-5baf-45f5-a115-ee177e8b6fe7	3a8db0cf-f309-42bb-9924-698d6049c6f6	2	t	\N
275e3073-5fad-47b5-9bb4-78032b6c8b75	123a36d2-1f13-400b-b014-ef877293ca0c	1	f	\N
1c89a06c-bece-4912-bdce-d9ce2463a5c8	123a36d2-1f13-400b-b014-ef877293ca0c	2	t	\N
37712908-db9b-428f-86cd-c6a0d47545e8	84798d76-092d-4398-a94b-a77879c935dd	1	f	\N
561e1bf3-77d5-4b81-85c5-f62d9bd4e906	84798d76-092d-4398-a94b-a77879c935dd	2	t	\N
ca4686a7-5db0-4541-86bc-8d4a3868329d	6bbdd42f-deb5-454e-89c7-4c4bd69d0636	1	f	\N
91241912-6035-4d01-8ede-408d9406a726	6bbdd42f-deb5-454e-89c7-4c4bd69d0636	2	t	\N
b8c1cdfe-588c-473d-a377-876fd609b22a	a7235b06-d2df-46a3-a3bb-e222d816edf1	1	f	\N
bb14bbf6-0e2d-4958-9022-126267a58f46	a7235b06-d2df-46a3-a3bb-e222d816edf1	2	t	\N
87bfcc08-cab7-4ab4-87e4-f46c901208ce	50a25141-1a6a-49ce-8cb3-85923cbb64c0	1	f	\N
f7ac077d-9ede-44d5-ae18-00943a513e24	50a25141-1a6a-49ce-8cb3-85923cbb64c0	2	t	\N
343114c7-8d99-4280-b761-3c324291206f	a0e84c81-e253-48a1-a87c-d8ee9bad6fe0	1	f	\N
fb45768d-b9a7-4da6-86e4-adbabced88ee	a0e84c81-e253-48a1-a87c-d8ee9bad6fe0	2	t	\N
9788f48d-f143-4599-95a3-6d68740677fd	92f93bdf-5182-436b-be67-f9de0d97da2f	1	f	\N
2dc37e37-18c4-439d-a801-8ffb89f2c7a1	92f93bdf-5182-436b-be67-f9de0d97da2f	2	t	\N
15e7793b-490f-4ec0-989e-17d2820e513a	e34d30db-8c88-4d3f-9b4f-24d900cb157d	1	f	\N
a3d3c4e5-29db-48c8-beb8-ae92336d6f1c	e34d30db-8c88-4d3f-9b4f-24d900cb157d	2	t	\N
ea2e901c-a240-4018-aed7-3ef7d0f7d135	a40e4d7e-0e29-4c40-b46c-69afb7902ba7	1	f	\N
0bcf794d-7103-458a-bd70-74aefc0944b8	a40e4d7e-0e29-4c40-b46c-69afb7902ba7	2	t	\N
9a24318a-ec4b-4328-b8c6-f9bb9507f58a	dda1ab65-9866-4157-b947-7ee6a1fe05f0	1	f	\N
04648969-39a7-44e0-9607-ffb709060c72	dda1ab65-9866-4157-b947-7ee6a1fe05f0	2	t	\N
443c8530-5b6f-4a9f-9b9e-b57040b0fd96	c1656ff3-79ae-4a44-b4c6-1ee8aa6123f4	1	f	\N
6154fdcc-9f32-4ab0-a9f2-a6cf221fb80f	c1656ff3-79ae-4a44-b4c6-1ee8aa6123f4	2	t	\N
fd0bd14b-ac18-4e85-9481-1b8d905a27dd	45b746bd-eaea-4163-9bfa-4d8ba5a52304	1	f	\N
8f290af5-a843-41d5-aae9-4ead9b17adde	45b746bd-eaea-4163-9bfa-4d8ba5a52304	2	t	\N
841f8240-ae08-48c4-89ed-e55a0cfd8a6c	185eceda-a734-4908-a840-4cf13eeb56dc	1	f	\N
52f8a3a6-a923-4a00-be40-3e008db908ad	185eceda-a734-4908-a840-4cf13eeb56dc	2	t	\N
e228182a-8557-4c30-82ef-020d5526c2d1	ea0f53ff-d31d-49c5-8a66-d43acc764503	1	f	\N
889707c5-b468-4e96-bfb7-017b9329b443	ea0f53ff-d31d-49c5-8a66-d43acc764503	2	t	\N
9521e003-2414-453e-b68b-465679e57be3	504ec37d-29ff-46ee-aef4-979ffe033a5c	1	f	\N
73b3552b-4873-4514-947f-019040d9c856	504ec37d-29ff-46ee-aef4-979ffe033a5c	2	t	\N
e3507250-683d-43d7-b2e7-29e5acb71a8d	8b42eada-f55a-4b12-9450-ee2d310fdb1d	1	f	\N
b49ad74a-4388-4df7-9206-fd1792756602	8b42eada-f55a-4b12-9450-ee2d310fdb1d	2	t	\N
e9db9846-fd19-445e-b710-cd40cceca668	8838537a-43a0-4b71-9c07-ba06a8e4d384	1	f	\N
042cb782-4063-4e9a-8864-5505bb67842f	8838537a-43a0-4b71-9c07-ba06a8e4d384	2	t	\N
5aa77bf9-53d9-446a-8a76-c623b4b695f3	1f609235-ec89-480e-86e6-26484153816e	1	f	\N
d2af8dc5-0eb8-45af-9893-600c45facf64	1f609235-ec89-480e-86e6-26484153816e	2	t	\N
7b422f7f-a768-43a2-9175-10cff7e41117	df633993-6248-4b09-bfe1-514f18067db9	1	f	\N
f941a631-3317-4a71-a311-4e72d8b21b3d	df633993-6248-4b09-bfe1-514f18067db9	2	t	\N
659b7ac4-d189-41bd-9c66-edfff8d5d5c4	779de72f-8536-4c1e-941c-4d537d277618	1	f	\N
65011286-1979-437d-8869-987ceaf415bc	779de72f-8536-4c1e-941c-4d537d277618	2	t	\N
f63bfe0e-ca47-4055-831c-9c8c568a8898	306e59db-833e-4980-8765-e7921aacdd6c	1	f	\N
9a373d5f-9427-40c0-ada2-a82cb5ca3469	306e59db-833e-4980-8765-e7921aacdd6c	2	t	\N
3d834c0c-2595-490e-a224-b965ba61a451	f1d94cd5-b1c9-4522-9a92-cf756fcb3681	1	f	\N
18d71889-6316-4ce7-80ee-19f8bee2c6b6	f1d94cd5-b1c9-4522-9a92-cf756fcb3681	2	t	\N
3272e7ff-9c2e-49c1-b156-90db09b43ba2	13a76bf2-f008-48f2-900e-567fb3792c11	1	f	\N
03af91b4-83bf-4a74-a482-037d412a9d27	13a76bf2-f008-48f2-900e-567fb3792c11	2	t	\N
f428baaa-d84b-4387-83b8-fa229d531eb1	1b18604c-c0b7-4aeb-9341-90ca81a78f32	1	f	\N
05214e03-18ba-4398-9f6e-b1aa0d9f4ae3	1b18604c-c0b7-4aeb-9341-90ca81a78f32	2	t	\N
73c20087-dffb-4bd6-af07-647b11fb563d	4f7abc9d-a12e-443f-a1be-d2a5019b4430	1	f	\N
542cf7a0-6468-45dc-919b-4b5b0ff229d0	4f7abc9d-a12e-443f-a1be-d2a5019b4430	2	t	\N
8e1453a5-1a1e-4162-90ef-eca76d7980a4	c74598ed-80f7-468c-bbb9-40a2cd0c3e0e	1	f	\N
3d9a8be1-cdc3-45ad-b771-655ac046a1cb	c74598ed-80f7-468c-bbb9-40a2cd0c3e0e	2	t	\N
2f7b79a1-0d87-4bdf-9aab-24e25853d776	8039c04a-e21c-4602-93cd-a93633ab86c8	1	f	\N
4c6d12df-fa73-4df5-bf36-71c5d6ede7a2	8039c04a-e21c-4602-93cd-a93633ab86c8	2	t	\N
a94e4d77-07fc-4cc9-9af3-d43c23dd29e3	99ca858c-069a-4e23-b23c-428fafb06801	1	f	\N
2f89cab1-464e-43b4-b147-753801bd2772	99ca858c-069a-4e23-b23c-428fafb06801	2	t	\N
cdbb3979-c65c-449d-8f64-f09b7c56a306	cffc5dad-5bd9-4f33-9723-fe6312545853	1	f	\N
519084da-7c48-4b3e-9d91-29e301fc9ee0	cffc5dad-5bd9-4f33-9723-fe6312545853	2	t	\N
2e036c8d-b679-4ff5-8f64-02d8fbae960e	c0ea6ede-2dbe-409c-81e0-986188faf691	1	f	\N
3f610d06-aff8-4033-b8e6-3dd099e35b9c	c0ea6ede-2dbe-409c-81e0-986188faf691	2	t	\N
59b32975-6483-458b-912e-e0e47bf6c686	51edf32e-4fd4-46d3-af34-a093c32a2063	1	f	\N
7ee9ab1e-21b9-4808-b045-061d5c5b5d55	51edf32e-4fd4-46d3-af34-a093c32a2063	2	t	\N
685b1c77-5494-4ea0-b323-767aa5a35042	a4999c50-de8e-4f6b-af56-725f2a9bfdde	1	f	\N
0f45a08f-6ee8-45a1-a945-beff39be49f3	a4999c50-de8e-4f6b-af56-725f2a9bfdde	2	t	\N
02a21ac6-5bdc-4e75-bd22-3dd9db07f7ce	ebfc9349-2d03-4b21-818b-2c13713015ad	1	f	\N
8654ea54-2f12-4246-8983-03dc4d17251b	ebfc9349-2d03-4b21-818b-2c13713015ad	2	t	\N
2c847e94-dc21-4ebd-acf4-24a0caef612c	9f39681f-ee66-4613-950a-0f4f57091c8d	1	f	\N
1d3e6fba-77be-4363-86a5-bf348f12a248	9f39681f-ee66-4613-950a-0f4f57091c8d	2	t	\N
cf6e7e7f-3913-4d61-9558-dbbc18aee8ee	a3d0c510-ae66-40ea-a0f8-1d968f4a8019	1	f	\N
4cb47b10-5012-4ebb-a940-3a0146a2d58c	a3d0c510-ae66-40ea-a0f8-1d968f4a8019	2	t	\N
e5dafccf-c9b8-4672-870f-540e61b7d23b	e22ae1ee-956f-48d0-9208-b62e428b3e8a	1	f	\N
e1c34343-fcb9-4df7-8002-79fe6a69cc43	e22ae1ee-956f-48d0-9208-b62e428b3e8a	2	t	\N
349ac6c8-ea38-4b31-9eac-fcfaf5b2814f	0185e795-6d6a-4a04-a177-52d4487d9fdc	1	f	\N
6b2e0b48-c863-43ef-b73f-ca4c4fcccaf3	0185e795-6d6a-4a04-a177-52d4487d9fdc	2	t	\N
298de6de-490a-4bb5-822e-3521a44816d9	592a56e3-c44b-4f00-8f67-01be727ddf54	1	f	\N
cbdb8fb1-65f5-44fe-8ad1-a287e023748c	592a56e3-c44b-4f00-8f67-01be727ddf54	2	t	\N
1299e4c3-3461-43a9-bed1-0157a8399801	2aefe66c-c817-40b3-bca0-fc2e81d3d03f	1	f	\N
37778322-92d7-473a-bec6-e243d72f70dd	2aefe66c-c817-40b3-bca0-fc2e81d3d03f	2	t	\N
f612e252-90c5-4be0-8421-25a91af02c2a	333bb6c8-7062-4d8d-b3d6-669901aabb30	1	f	\N
08c80e7a-9687-4676-ac25-47ef8acc30be	333bb6c8-7062-4d8d-b3d6-669901aabb30	2	t	\N
ad57d7ea-bc27-4bb1-8364-72c296d26037	e05babb7-3a6c-465f-b45f-185202f2ded8	1	f	\N
e15c1f17-9aad-45fc-bd20-9278ad6240fb	e05babb7-3a6c-465f-b45f-185202f2ded8	2	t	\N
841687a9-5744-4570-a781-31be009a9511	2957a8ee-9578-4a0c-a3e0-96666b8524b3	1	f	\N
da7717f4-79f9-48f4-bfb2-1965f6c0c987	2957a8ee-9578-4a0c-a3e0-96666b8524b3	2	t	\N
332acd60-f891-4a14-a461-ee06afedeeeb	f2c27b26-c922-46b6-bbbe-444b8b0bb389	1	f	\N
fa411555-c037-4889-84f6-76e3d5703a1a	f2c27b26-c922-46b6-bbbe-444b8b0bb389	2	t	\N
4e26dfef-973a-40f1-8ef9-0580564074de	7cb90a7e-0b13-4ffc-affe-718083238e5f	1	f	\N
0fb787a0-6bc8-428a-a1a4-4f9c51058222	7cb90a7e-0b13-4ffc-affe-718083238e5f	2	t	\N
8669da40-af6e-401d-ada1-91ce2148c1f7	b146fd5a-b440-47ef-bf97-39d28d0c04f6	1	f	\N
d995b156-d493-4498-880c-f5ec308deb4c	b146fd5a-b440-47ef-bf97-39d28d0c04f6	2	t	\N
5857d27b-528b-4e2b-900d-f9252266b65d	bc2a1c67-4422-493f-841a-828e3801dde1	1	f	\N
c10e57c9-b2f5-4fb5-83ec-ba61da1c9d5a	bc2a1c67-4422-493f-841a-828e3801dde1	2	t	\N
ff508bd5-22fd-4c54-84e5-f4dcbd0c68b0	b52ea900-4ab8-4699-97da-86e02998dbda	1	f	\N
e0853b18-eacd-4a25-a28b-011a311883eb	b52ea900-4ab8-4699-97da-86e02998dbda	2	t	\N
9eeeac70-09fb-4ba1-8236-4bee78eeb664	0b30a008-e995-425d-aa87-5be6b7002f1c	1	f	\N
5d2956d5-6041-489b-8a5e-3ab4f25d2764	0b30a008-e995-425d-aa87-5be6b7002f1c	2	t	\N
e231d7f5-0a7b-4ae5-a116-c3c3a805e3ba	8669ee0b-fcd3-483e-9425-80c3038320a0	1	f	\N
06437d13-bf76-44aa-a094-def9e4820079	8669ee0b-fcd3-483e-9425-80c3038320a0	2	t	\N
a924ba98-2008-4713-8329-fdf7b943ac0a	a81cb79b-b276-4be1-8edd-dde79f26600e	1	f	\N
eb875d39-5032-45c7-a308-167d2f1dacd8	a81cb79b-b276-4be1-8edd-dde79f26600e	2	t	\N
68e9c9b7-005d-478d-ae8b-a3a1aa7ffc40	c4791f60-3b93-4d8d-8db6-64f458da1b80	1	f	\N
98ac708a-15c4-4e60-8214-cb506196f089	c4791f60-3b93-4d8d-8db6-64f458da1b80	2	t	\N
2d73060e-d2cb-40c8-9219-d0054c5f1165	73f92e6b-4ab1-46d0-b7c1-31fdeb1f77a0	1	f	\N
6443700d-d149-425b-9cf3-2d9baebd8b28	73f92e6b-4ab1-46d0-b7c1-31fdeb1f77a0	2	t	\N
166f0e8c-ad71-492f-b55c-d8d0d9a81027	32965364-27f2-44ed-a8e3-fd529ec46118	1	f	\N
98f3f48a-69a3-42a3-bb12-c3283310564e	32965364-27f2-44ed-a8e3-fd529ec46118	2	t	\N
01908b72-fcb8-4e56-8423-fa18176f24fd	37af4eca-d201-41d5-9ab0-4c5f6e91483c	1	f	\N
7e2d4209-9d2d-4eec-aa42-069c248bf70b	37af4eca-d201-41d5-9ab0-4c5f6e91483c	2	t	\N
ed7fd435-9874-44e5-9653-d82a06a280ef	91891c71-2d9e-4c83-a6b5-52c2703b17e4	1	f	\N
c2138d90-3319-4705-a088-a179ca35935e	91891c71-2d9e-4c83-a6b5-52c2703b17e4	2	t	\N
26f3ce62-9ea6-4010-8084-0b503c5057bd	c3f4b5a0-3c51-4807-883f-f35f90e93c60	1	f	\N
44f6f015-d476-4086-88cf-159b1a375d1e	c3f4b5a0-3c51-4807-883f-f35f90e93c60	2	t	\N
b9bc788d-d8e7-48ef-9be9-b23cb12e85f1	1fff7c76-b965-48e5-8b7f-3b20a42df19c	1	f	\N
b80ac22b-b9e7-4525-8869-e611dd6cde2d	1fff7c76-b965-48e5-8b7f-3b20a42df19c	2	t	\N
8bb5a4d2-88cd-478d-a6a7-537c59c3d300	33e83ab2-e87f-4482-8586-c08abd5b5fae	1	f	\N
7c72a5c1-4891-4a47-8579-22fc050db282	33e83ab2-e87f-4482-8586-c08abd5b5fae	2	t	\N
ab86f5f6-c92c-4b59-a666-613f5288b1b8	84234e63-0f91-4a8f-a519-2a35c9658b02	1	f	\N
1cc76eae-4728-4aa4-abc6-a5ef237e74de	84234e63-0f91-4a8f-a519-2a35c9658b02	2	t	\N
21ac5f00-c716-4d8e-afbc-3d0b8574e7fc	f0f8f813-f3ab-4bd0-a36f-cedd77551ff9	1	f	\N
68848b9e-606c-4db8-a298-8505402c6f68	f0f8f813-f3ab-4bd0-a36f-cedd77551ff9	2	t	\N
2ef07e1e-f394-406d-bbb9-eff94ad8100f	9417c193-3816-4de2-91d3-2ad8ab46c3e5	1	f	\N
785c8370-1f50-47f2-9f26-b0ecbed360ee	9417c193-3816-4de2-91d3-2ad8ab46c3e5	2	t	\N
ea2b1c7e-3ba0-4834-b3d8-fbda9b939ddb	dea7cc2f-af64-48cb-aa8b-3e6c747d42da	1	f	\N
79fdf154-bc1a-499e-bb27-e044f3bb3e46	dea7cc2f-af64-48cb-aa8b-3e6c747d42da	2	t	\N
791886bc-482f-4ed2-8bab-b78114f8f895	6d4c9bd1-73b9-4cfe-8622-0c59e8c8b8ea	1	f	\N
780dad5a-3ab5-471b-a62a-eb58f7c93ca9	6d4c9bd1-73b9-4cfe-8622-0c59e8c8b8ea	2	t	\N
fb36783b-6546-4686-8695-bac0e32551cb	b098cd0f-45d4-4ccb-9d43-8000ff40dcb6	1	f	\N
94cb737f-b597-4f4e-8dc4-4ee452e2cb35	b098cd0f-45d4-4ccb-9d43-8000ff40dcb6	2	t	\N
f9d52036-1511-4aa7-88e9-d85d06f3c383	19d661ec-31a9-4ef4-bf23-f18566957598	1	f	\N
e36831f1-5d30-4c90-be41-766f69ceb66d	19d661ec-31a9-4ef4-bf23-f18566957598	2	t	\N
2c2c4a23-bfd1-46c5-8f6c-8d0462d7e134	4f67be6d-b997-4e28-b6bc-336692c5c545	1	f	\N
803ee3a6-924b-4891-b1cb-f63e5be6b422	4f67be6d-b997-4e28-b6bc-336692c5c545	2	t	\N
c87f95b7-ee44-42c1-9f2d-645cf18880d8	aa270f59-9dbd-4e91-a907-595aa681ce19	1	f	\N
27fb4e02-ef59-4093-98ef-eda35e70eaa6	aa270f59-9dbd-4e91-a907-595aa681ce19	2	t	\N
f61dd1f2-8c2d-41cc-9128-2f94e9724891	56d0c97b-5827-4ca7-952f-45bef5aa1db5	1	f	\N
bf10c4a8-b57f-465a-9ff0-04d114eaf32b	56d0c97b-5827-4ca7-952f-45bef5aa1db5	2	t	\N
62280b6b-e0fc-451c-81bb-8c7213466725	cb62eee1-b293-4d24-bb1d-b2c53f792179	1	f	\N
d9c9a52d-e01f-4f56-b7c8-c8a5b9fdd072	a7237520-2d8f-11f0-a834-2b294fbfca54	4	f	\N
67ae92e1-4c05-489c-9127-c6f329a3e8f3	cb62eee1-b293-4d24-bb1d-b2c53f792179	2	t	\N
cb7bed26-52c0-41e3-b493-12ea06ca2e87	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	4	f	\N
5f2750da-7f4c-4e12-86f8-30eed10b2071	8335d9c7-65ef-48f6-8db1-10af36b0e9b0	1	f	\N
20a3f1aa-ad26-4868-81b0-8381b8473a79	21397b0c-2e53-11f0-8a85-1759860470a0	4	f	\N
f0a36749-863a-415c-b11f-dfa4729ababd	8335d9c7-65ef-48f6-8db1-10af36b0e9b0	2	t	\N
72574fa0-c727-478f-8b2c-5935f2925db8	21397d32-2e53-11f0-8a86-abb690facbb0	4	f	\N
b7f93f66-9732-43c4-9cf4-ac5dd5ee3a4d	69e1902f-c28b-41a6-80f7-6f7515ddbf90	1	f	\N
b8a68f26-4acf-43fc-bdc5-171afdf862cc	69e1902f-c28b-41a6-80f7-6f7515ddbf90	2	t	\N
6dc21ec1-acf7-4060-9cd5-05f76622b9b3	a7860243-6042-40b7-b091-5a7258132dea	1	f	\N
6be376ef-9871-428d-947a-e8012bd3ab38	a7860243-6042-40b7-b091-5a7258132dea	2	t	\N
363f33d4-d6ed-4aac-a84b-a7373e92f10f	90fa882a-8d83-4b8d-a68a-e6a6de208543	1	f	\N
76630ec0-24cd-43a4-9d8a-a1d427e4787c	90fa882a-8d83-4b8d-a68a-e6a6de208543	2	t	\N
aa52286e-5acb-4516-aa87-e788b49ebef9	3329f68e-e379-48ec-aaa3-49b638e7d451	1	f	\N
8d1214eb-f3ba-453e-951d-b40241569d01	3329f68e-e379-48ec-aaa3-49b638e7d451	2	t	\N
a3f177ce-bd02-4c6b-9f8b-15ea7282a7bd	c0f5c3cb-5b80-4222-b2ec-0940dc010569	1	f	\N
c06704ee-e0ff-4e7b-83ec-27a84e840e11	c0f5c3cb-5b80-4222-b2ec-0940dc010569	2	t	\N
c1e1c53c-8543-42da-836d-ecb6977be500	5b9dc231-6afb-480e-8731-966ae796399e	1	f	\N
693c52aa-18fd-4c8b-a344-a3430dbd5275	5b9dc231-6afb-480e-8731-966ae796399e	2	t	\N
bbcb8300-a4c2-439a-aae5-15dbb513607d	84107d9d-6ad8-4061-9f9a-ae5b8d57ae65	1	f	\N
c792cb44-54f0-4fe8-8612-35ced48d8cf4	84107d9d-6ad8-4061-9f9a-ae5b8d57ae65	2	t	\N
2b54ae3f-417d-4b85-900a-3f87d2d3cd31	25a1932f-d230-417e-aa28-834f0f678d63	1	f	\N
66bf4397-542d-4a24-bf6e-9ad7635a9f4b	25a1932f-d230-417e-aa28-834f0f678d63	2	t	\N
8c102976-ab80-4358-a202-7e16a0259fb1	dcf70233-a5a6-4300-9d61-fe9e6ca284ae	1	f	\N
70e70653-f314-4c24-97e2-b073257bf58b	dcf70233-a5a6-4300-9d61-fe9e6ca284ae	2	t	\N
68d6a5a9-97aa-4709-af2f-42f3b441b216	f3b179c6-cb86-4e1b-bf4a-21bc789967de	1	f	\N
a9b7a2cf-1ce1-418b-8a03-9cf689de7a51	f3b179c6-cb86-4e1b-bf4a-21bc789967de	2	t	\N
0cba509b-9f58-46be-a791-285fe722e234	f4ac476b-ff3a-4056-a92e-3e4b84929146	1	f	\N
aff3ae64-d024-495f-85fe-3406540bd086	f4ac476b-ff3a-4056-a92e-3e4b84929146	2	t	\N
15318432-2070-4644-a86c-18b63ac71751	0d03af65-e501-4bcc-8565-73bf8475751c	1	f	\N
adfb9f52-1e64-4963-9269-db21ecae50df	0d03af65-e501-4bcc-8565-73bf8475751c	2	t	\N
ab235db7-3973-4184-86ee-616421bce441	b451d758-985b-446c-a35b-b2fbbbc5e887	1	f	\N
834045b6-ff09-4250-aecb-444141965560	b451d758-985b-446c-a35b-b2fbbbc5e887	2	t	\N
98822d9b-3e79-4a7d-9c07-441d4124f608	a7237520-2d8f-11f0-a834-2b294fbfca54	16	f	\N
82c36a7e-03bf-4488-8231-17e43697ac67	78453dc8-54ac-4285-82d2-4b606a1b1937	1	f	\N
189c335d-77bd-4531-bbaa-f86c88ba45fd	78453dc8-54ac-4285-82d2-4b606a1b1937	2	t	\N
73424752-3e59-4fc7-8637-b16633cf2137	059a81b0-02f5-4809-98ea-7b4410baed09	1	f	\N
87135b7b-fab6-4698-806a-0651cf4371af	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	16	f	\N
545ca8d3-cc03-4574-8825-4240ccb3c7f3	059a81b0-02f5-4809-98ea-7b4410baed09	2	t	\N
ae89198c-4308-443f-804e-00c33c2bded8	d184d775-c1d8-4dec-8a03-6ec016b592fe	1	f	\N
12dc39c5-8a6f-4532-ab79-f18aa14587ac	21397b0c-2e53-11f0-8a85-1759860470a0	16	f	\N
a28d37e8-4402-433a-ba95-8f918e323860	d184d775-c1d8-4dec-8a03-6ec016b592fe	2	t	\N
5f7aa862-7307-467a-adf6-801e538ea7a3	21397d32-2e53-11f0-8a86-abb690facbb0	16	f	\N
d2d296c2-cab5-4824-ad3b-6cd5a4aa139b	4237c417-0e64-4d1f-a08c-20a8035653ba	1	f	\N
17eb365f-8f00-47c2-9be0-07d818070309	4237c417-0e64-4d1f-a08c-20a8035653ba	2	t	\N
f157994c-f0dd-443e-b9f6-da2e65ea1041	fd0668a8-180f-4394-b43c-6224ee9f246b	1	f	\N
9db9e241-e4b6-4a13-bb16-41a34906f7be	fd0668a8-180f-4394-b43c-6224ee9f246b	2	t	\N
59802032-d156-49eb-b83b-946b94fa00bc	6285a1a1-9372-45b1-89d5-07fa13565a79	1	f	\N
d8d14918-f0cc-446b-aa2e-f56d436c19be	6285a1a1-9372-45b1-89d5-07fa13565a79	2	t	\N
be7e443e-41ca-43fc-aeed-7a9f5eb23a4b	82798834-89c3-461b-a233-91dadb3fa01b	1	f	\N
86181924-d728-489e-b658-68e3cedd9eae	82798834-89c3-461b-a233-91dadb3fa01b	2	t	\N
5f42f60a-668f-4339-be6f-2302b9dbb0f0	1f48142c-f07f-49c7-befa-5c58ecf23024	1	f	\N
1884c9e7-8775-4821-bd8a-27b38924818c	1f48142c-f07f-49c7-befa-5c58ecf23024	2	t	\N
17e5a8ec-7824-4175-b6df-7dec6cf82f79	bacd26df-e8f6-4910-af14-27b383a5e598	1	f	\N
b6250a7f-de6a-498d-9ffc-cc7ddd1bb890	bacd26df-e8f6-4910-af14-27b383a5e598	2	t	\N
00443360-efc6-4254-81db-0703bc38b74e	0ba99d60-cb69-40b3-94c4-124dbe2d4fdf	1	f	\N
c4993aa6-c9d3-4fd5-96ab-b1741546ea03	0ba99d60-cb69-40b3-94c4-124dbe2d4fdf	2	t	\N
20c1fe7a-d3bd-4222-ab76-fb3b83ad7f0a	adb8739a-2d1d-4e07-9c3a-ae64a0770a45	1	f	\N
017c478a-d9ae-41c0-b973-1fe71edd0f09	adb8739a-2d1d-4e07-9c3a-ae64a0770a45	2	t	\N
06cf70ef-d265-4bc6-9d57-b3693202a53f	fd2ab01e-f0ee-465e-be90-0c9d189385bb	1	f	\N
663ea37e-d899-4ae0-965e-b9a031daea93	fd2ab01e-f0ee-465e-be90-0c9d189385bb	2	t	\N
a2df09d9-ea1e-4c1d-b50b-0d8a743702bd	5c5e47ab-d64d-4901-8dc4-82272bbd7491	1	f	\N
38fa38a3-e277-43d3-945f-36e77adff248	5c5e47ab-d64d-4901-8dc4-82272bbd7491	2	t	\N
b0f04465-5fb2-4ea0-867c-335b35a37a39	67c38f1c-5e96-450b-884b-b3cc66067c76	1	f	\N
b287db80-9f6c-4567-9924-d65ab7410465	67c38f1c-5e96-450b-884b-b3cc66067c76	2	t	\N
69ba6fda-ecc6-451a-86be-8b7b21e662fe	c92ed41c-64e9-4b1b-828d-d29f51c95300	1	f	\N
806df7b3-3d02-4cb9-a72f-c0ea01e86114	c92ed41c-64e9-4b1b-828d-d29f51c95300	2	t	\N
a539cf84-dbd4-4fac-b3ee-235fddf82a29	578ad01b-b165-408a-ab3f-36710f76e5e6	1	f	\N
52ada4ce-995d-4fd9-be4d-ed7451c606b4	578ad01b-b165-408a-ab3f-36710f76e5e6	2	t	\N
0e44bd5d-0a3a-4e61-80c6-ebbecb4aa9b1	dc188438-04e5-46ed-927a-43d6a2fc5ce1	1	f	\N
be20d3c6-7edc-4e98-9028-f59e15f48292	dc188438-04e5-46ed-927a-43d6a2fc5ce1	2	t	\N
fc2873f2-7386-4e04-9f34-cdfc45a6e633	b98b86f4-13f6-4462-9bd1-4b3c47c7a938	1	f	\N
0c2ec99f-c92c-426d-b18a-7e09ac16d008	b98b86f4-13f6-4462-9bd1-4b3c47c7a938	2	t	\N
39e33b73-69c5-42b7-987b-215ad85dd6e5	1d78dc09-d63a-435c-98c3-82e8ce87abbf	1	f	\N
93d368b9-f3b8-4175-9074-15c3a9ed89e3	1d78dc09-d63a-435c-98c3-82e8ce87abbf	2	t	\N
ef82f268-8f89-4777-9d0e-2e1f5b2e0db8	efd284d5-6422-43e1-9330-1ebf7ef5eac0	1	f	\N
ac9e5fef-0249-4ca7-9340-525965b8a114	efd284d5-6422-43e1-9330-1ebf7ef5eac0	2	t	\N
6b6766e6-fc24-41f0-918b-dbc2bb3ce128	f134a8b1-9f70-4ff1-834d-4bdf61b55daf	1	f	\N
67a3c358-5346-425b-880f-ff4904a15cb5	f134a8b1-9f70-4ff1-834d-4bdf61b55daf	2	t	\N
bad7de33-c6ad-423c-a143-1e0aaa2972fa	548f2472-8a96-4c96-9c4e-59bb594a4c3c	1	f	\N
a252af42-8247-4b4d-a0d0-12174a193f97	548f2472-8a96-4c96-9c4e-59bb594a4c3c	2	t	\N
413a5137-30ad-4f85-9da2-fd8e7090a87d	bada4d6e-a05a-4e63-9561-1b606fbd166f	1	f	\N
65ee348e-4bdd-4eef-8e55-7b457017a1a1	bada4d6e-a05a-4e63-9561-1b606fbd166f	2	t	\N
633af01f-fd90-461e-ada3-1de07f39b844	c9d74556-2186-4a27-b705-7d2d578de32d	1	f	\N
5944af59-af86-449e-9cea-942ac2efd144	c9d74556-2186-4a27-b705-7d2d578de32d	2	t	\N
a702ad48-c2de-4349-8798-07017a715285	07a91465-7e3e-4a24-87f9-217bd27b1c9c	1	f	\N
35bbb9ed-c80d-45de-9a52-81dfbb61668e	07a91465-7e3e-4a24-87f9-217bd27b1c9c	2	t	\N
d5e00927-3a5e-4e94-8f8f-efd916ff9de1	447b5ad2-4252-4d19-a8a5-530333e9a7e9	1	f	\N
71ce2d97-274d-4f38-abb2-cb25ae981a3c	447b5ad2-4252-4d19-a8a5-530333e9a7e9	2	t	\N
84eab4ed-d241-4b96-8b6f-af8404ed1f66	7f5a67ca-48d8-46bb-b498-4ad0ef777312	1	f	\N
15c5096f-c0f9-469d-b701-909e46f5523e	7f5a67ca-48d8-46bb-b498-4ad0ef777312	2	t	\N
da33bab6-8b99-4f32-93e4-327b2e132ae6	8fd9a5fd-74f3-4b21-9fd1-b0fc68d04519	1	f	\N
c27e3f02-8c6c-4837-9783-82b546b721d6	8fd9a5fd-74f3-4b21-9fd1-b0fc68d04519	2	t	\N
c137707e-a9aa-4528-a71f-a4e94ef185cb	1b268407-8ca3-4853-9ca8-993a7683034a	1	f	\N
05866f61-b37e-483c-b60f-c1d593272de2	1b268407-8ca3-4853-9ca8-993a7683034a	2	t	\N
5125bc70-610d-4d49-b86d-3491bb0c13e1	a7237520-2d8f-11f0-a834-2b294fbfca54	59	f	\N
ccfddbda-d0e8-465a-8247-e762c48def2f	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	59	f	\N
b735389e-bf8d-4b3e-bb59-1646f40a3bf1	21397b0c-2e53-11f0-8a85-1759860470a0	59	f	\N
8942c35d-f245-492c-a42d-bb33579c509d	a7237520-2d8f-11f0-a834-2b294fbfca54	40	f	\N
1a418d0b-7d7e-4f2b-89dc-a55d6c4fd150	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	40	f	\N
5e9e9eb2-be55-4b88-a7f4-10a60ff58b06	21397b0c-2e53-11f0-8a85-1759860470a0	40	f	\N
66983d50-d4d0-44c9-b781-b48baa63f32d	21397d32-2e53-11f0-8a86-abb690facbb0	40	f	\N
be148a2d-b0e5-4732-8bb0-609a2266d874	21397d32-2e53-11f0-8a86-abb690facbb0	59	f	\N
0431d7f0-7818-4c82-8af4-100ef32cc70b	a7237520-2d8f-11f0-a834-2b294fbfca54	60	f	\N
5ec21b39-b18f-4838-9a99-6b4485dc61d4	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	60	f	\N
a511503f-ac8d-4968-a44c-6ab0ac2e66e9	a7237520-2d8f-11f0-a834-2b294fbfca54	52	f	\N
75fc21d7-0d9d-45a5-ada9-6583fb0de73f	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	52	f	\N
c418a292-68ae-4e6c-8cc7-dace4fc89dd2	a7237520-2d8f-11f0-a834-2b294fbfca54	22	f	\N
82534d8e-ca9b-4b14-9121-40629df2a517	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	22	f	\N
33b32168-979e-40fc-b698-4d11776059dc	21397b0c-2e53-11f0-8a85-1759860470a0	22	f	\N
826e231f-faa5-478f-ba58-64bda47d3aea	a7237520-2d8f-11f0-a834-2b294fbfca54	10	f	\N
59b13fa8-5cc4-4181-8e7c-39ee88153307	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	10	f	\N
f02a7d3e-472c-454c-883f-6e542eab7ad7	21397b0c-2e53-11f0-8a85-1759860470a0	10	f	\N
64ea7085-c6ba-40af-af23-107f0948edc5	21397d32-2e53-11f0-8a86-abb690facbb0	10	f	\N
9dfdff6c-5b61-4a9c-99ce-587f1be3cc2e	21397d32-2e53-11f0-8a86-abb690facbb0	22	f	\N
12d8023d-edf8-41c6-a9f6-3c01f87c18f0	21397b0c-2e53-11f0-8a85-1759860470a0	60	f	\N
8324a4f4-c779-4303-8bc5-edf989e70387	21397d32-2e53-11f0-8a86-abb690facbb0	60	f	\N
e36d6072-02d2-4169-8c1d-b3ce9d3623ab	a7237520-2d8f-11f0-a834-2b294fbfca54	61	f	\N
9c1e020b-5e99-40a1-abb9-b815a8ae77ff	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	61	f	\N
fe253c06-2fc5-4081-83b1-cb788b3f2d90	21397b0c-2e53-11f0-8a85-1759860470a0	61	f	\N
dd907259-6ce2-4d6d-8947-3c3caadbc3e1	21397d32-2e53-11f0-8a86-abb690facbb0	61	f	\N
d5677ffe-f46b-4d99-88a0-563239250f29	a7237520-2d8f-11f0-a834-2b294fbfca54	62	f	\N
0f44e5d2-e3d1-4de5-b430-1670c2c65b27	a7237520-2d8f-11f0-a834-2b294fbfca54	63	t	\N
164f3913-9eaa-4282-a124-bfb3a1b311e6	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	62	f	\N
dc55ab01-d0cd-4d01-9ec0-e709a9aa5a93	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	63	t	\N
c5f025ae-e3f1-479e-8f34-b9dcb9f30d55	21397b0c-2e53-11f0-8a85-1759860470a0	62	f	\N
df16668c-b14f-46d3-9b4a-5606f8bfd41b	21397b0c-2e53-11f0-8a85-1759860470a0	63	t	\N
8978224d-0544-46fe-9e58-416770f7127e	21397d32-2e53-11f0-8a86-abb690facbb0	62	f	\N
a41cf7c5-4947-431b-8bed-a82ea50bf6b1	21397d32-2e53-11f0-8a86-abb690facbb0	63	t	\N
6f258498-8e3b-4b7f-abfc-d91a739af093	a7237520-2d8f-11f0-a834-2b294fbfca54	28	f	\N
e1ad09b6-8455-40b9-b1c9-9218afec8ecc	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	28	f	\N
fd931f91-79bd-4b7c-85e3-4375549a3962	21397b0c-2e53-11f0-8a85-1759860470a0	28	f	\N
4a0cee23-eb1c-47bf-b84b-3150f9126343	21397d32-2e53-11f0-8a86-abb690facbb0	28	f	\N
f987baf2-6fe2-43de-8b69-465a8fdcff31	21397b0c-2e53-11f0-8a85-1759860470a0	52	f	\N
fc00af73-5149-4020-ba85-68b8068f0622	a7237520-2d8f-11f0-a834-2b294fbfca54	58	f	\N
b5745033-1a01-4816-814c-b97cffda08db	a7237520-2d8f-11f0-a834-2b294fbfca54	46	f	\N
6092d1cc-471d-4834-a090-ee286fd7ecaa	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	46	f	\N
2003eb1a-3fdd-46b4-80a8-1b210330bed8	21397b0c-2e53-11f0-8a85-1759860470a0	46	f	\N
8887a911-35ee-45c1-a0b4-21219cfdba29	21397d32-2e53-11f0-8a86-abb690facbb0	46	f	\N
47044e53-ff10-44cc-aaca-db0a7b198970	21397d32-2e53-11f0-8a86-abb690facbb0	52	f	\N
06036470-7be4-4542-a6ca-eb127b6ac687	a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	58	f	\N
4d9a6fb5-69a6-4a18-9e30-b76c3026acbe	21397b0c-2e53-11f0-8a85-1759860470a0	58	f	\N
67587e95-4240-4c3e-a592-6bc37a7b0f65	21397d32-2e53-11f0-8a86-abb690facbb0	58	f	\N
\.


--
-- Data for Name: acorn_user_user_groups; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_groups (id, name, code, description, created_at, updated_at, parent_user_group_id, nest_left, nest_right, nest_depth, image, colour, type_id, location_id, import_source) FROM stdin;
b59330d1-04b8-4b61-8071-1a3cfdfa9d56	Hemahengiya Zanîngehên	EAHZ	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_university_categories:1
af349d61-0cd4-4be2-98af-f729d946de7e	Desteya Perwerdehiyê	EADP	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_university_categories:2
e22ec9eb-493c-42c5-93b7-4d8551e2097f	Desteya Tenduristî	EADT	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_university_categories:3
1b6c5f61-5e61-499e-b901-53d31d032641	Rojava	ROJ	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:1
2997a720-c4aa-4775-b1fe-bce11eb47935	Kobanî	KOB	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:2
e7884a43-f541-4818-bb4e-0affac81a1a4	Şerq	SRQ	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:3
97828e8a-3503-453b-959c-50ace786e4b0	Desteya Tenduristiy	DT	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:4
e92954ac-77b5-4ad3-b17d-16034c22b99a	Desteya Perwerdeyê  Ya Herêma Cizîrê	DPC	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:5
e77683a2-7fd1-4494-9d4a-8971208f3b86	Desteya Perwerdeyê  Ya Herêma  Efrîn Û Şehbayê	DPE	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:6
9e95e450-a158-42c4-a1ea-fddb46b67e7e	Registered	registered	Default group for registered users.	2025-04-03 07:42:58	2025-05-07 08:56:03	\N	2	10	0	\N	\N	\N	\N	\N
41ace1f7-83b0-410f-aa1c-f70297986d6e	Desteta Perwerdeyê Ya Herêma Firatê	DPF	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_universities:7
cf38897d-2512-48b9-93d9-b96646f11ca0	Faculty Of Language And Literature	FOL1	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:1
9d700354-a1dd-4be3-9d6a-2c01f16f220e	Faculty Of Social Sciences	FOS2	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:2
ee267a6a-67b3-4cb1-9560-6e86820ccdc9	Faculty Of Fine Art	FOF3	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:3
0518d610-fc9d-4f0e-9546-fc7405e7c69e	Faculty Of Political Science	FOP4	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:4
4670c8a4-7d4c-4a55-a448-5d7afc7797de	Medical Faculty	MF5	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:5
198246db-8799-4d3d-ab1e-640c3fb04cc8	Faculty Of Petroleum Studies	FOP6	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:6
26da196b-1ba4-4c0f-ad33-258ffa959736	Architecture	A7	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:7
841d9354-fd36-47ef-bf5a-cf9a4576cf76	Endazyariya Çandiniyê	EÇ8	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:8
49139628-343f-4e58-a2f6-ee37ece80ccb	Fakulteya Zanistên Xwezayî Û Teknolojiyê	FZX9	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:9
7bf744be-6cf4-438c-a9ac-2c8ad9eec9c2	Fakulteya Zanistên Perwerdehiyê	FZP10	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:10
38345a2b-c368-4f8b-854a-193fcf1db679	Fakulteya Mafnasiy	FM11	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:11
9e95e450-97ee-40a8-a55e-4eb76beaf9ae	Guest	guest	Default group for guest users.	2025-04-03 07:42:58	2025-04-25 16:48:45	\N	0	1	0	\N	\N	\N	\N	\N
ab66a3af-016d-4cd3-8c5b-0b29a3716f77	Fakulteya Zainstên Olî	FZO12	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:12
9e4fb89a-07a7-4458-8904-e413fc0a1e11	Peymangeha Bilind A Ragihandinê	PBA13	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:13
b09dbce1-dcb0-441b-a33a-92d2f84d8513	Peymangeha Bilind A Rêveberî Û Darayiyê	PBA14	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:14
a7237520-2d8f-11f0-a834-2b294fbfca54	Science	SCI	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	\N
47123d4b-11f7-4b73-8c57-a52e4cf49a3b	Civil Engineering	CE15	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:15
78f27ce7-5802-46e8-a559-ca7e12d16c21	Faculty Of Education	FOE16	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:16
0ca98908-268c-4636-a83f-0f5806fa57ef	Faculty Of Science Education	FOS17	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:17
bdc5f878-2001-41b7-97d6-d331df13be97	Fakulteya Zanistên Xwezayî	FZX18	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:18
6a4c2ca2-926a-4b40-bc67-f77541b9bc95	Fakulteya Wêje	FW19	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:19
d3bd5348-6774-4c2f-83b9-657dde12139a	Peymangeha Bijîşkî	PB20	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:20
79c490d7-92d0-4133-a5a7-a8cb41da7a7c	Peymangeha Teknînkî	PT21	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:21
8202c9ae-f143-46e0-8a1a-3b9953bb008f	Peymangeha Zagon Û Rêveberiyê	PZÛ22	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:22
e321faa9-67be-464a-b529-e75821cd4064	Peymangeha Jimaryariyê	PJ23	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:23
ec677ed0-ef23-4aa3-af9c-b0eaba9beaba	Fakulteya Mafnasiyê	FM24	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:24
cf0cd8e6-0810-4e8b-97d2-28389b7f7c35	Fakulteya Çandiniyê	FÇ25	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:25
c8e069e2-4f61-439d-a38e-813945233603	Faklteya Aboriyê	FA26	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:26
c4589015-e6f0-4585-9e03-07f59c2f42d7	Fakulteya Zanistên Bijîşkî	FZB27	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:27
9cfd2aaa-a4a1-40ea-9c37-f7fe5e72649f	Fakulteya Zanistî	FZ28	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:28
21397d32-2e53-11f0-8a86-abb690facbb0	Year 11	11Y		\N	2025-05-12 06:19:41	\N	0	0	0		\N	\N	\N	\N
3a8db0cf-f309-42bb-9924-698d6049c6f6	Fakulteya Wêje Û Zanistên Civakî	FWÛ29	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:29
21397b0c-2e53-11f0-8a85-1759860470a0	Year 10	10Y		\N	2025-05-12 06:19:53	\N	0	0	0		\N	\N	\N	\N
a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	Literature	LIT		\N	2025-05-12 06:20:03	\N	0	0	0		\N	\N	\N	\N
123a36d2-1f13-400b-b014-ef877293ca0c	Fakulteya Zanistên Perwerdehiyê	FZP30	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:30
84798d76-092d-4398-a94b-a77879c935dd	Peymangeha Teknîkî	PT31	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:31
6bbdd42f-deb5-454e-89c7-4c4bd69d0636	Peymangeha Zanistên Rêveberî Û Darayiyê	PZR32	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:32
a7235b06-d2df-46a3-a3bb-e222d816edf1	Peymangeha Tenduristî	PT33	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:33
50a25141-1a6a-49ce-8cb3-85923cbb64c0	Peymangeha Amadekirina Mamosteyan A Qamişlo	PAM34	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:34
2c4251c8-2cf9-11f0-bbd1-3370778ee65e	Education Committee	EDC	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	\N
a0e84c81-e253-48a1-a87c-d8ee9bad6fe0	Peymangeha Amadekirina Mamosteyan A Hesekê	PAM35	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:35
92f93bdf-5182-436b-be67-f9de0d97da2f	Peymangeha Karzanî- Pîşesazî	PKP36	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:36
e34d30db-8c88-4d3f-9b4f-24d900cb157d	Peymangeha Amadekirina Mamosteyan A Efrîn Û Şehbayê	PAM37	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:37
a40e4d7e-0e29-4c40-b46c-69afb7902ba7	Peymangeha Amadekirina Mamosteyan A Kobanê	PAM38	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_branches:38
dda1ab65-9866-4157-b947-7ee6a1fe05f0	Kurdish Literature	KL1	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:1
c1656ff3-79ae-4a44-b4c6-1ee8aa6123f4	Arabic Literature	AL2	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:2
45b746bd-eaea-4163-9bfa-4d8ba5a52304	Kurdish To English Translation	KTE3	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:3
185eceda-a734-4908-a840-4cf13eeb56dc	Arabic To English Translation	ATE4	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:4
ea0f53ff-d31d-49c5-8a66-d43acc764503	Sociology	S5	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:5
504ec37d-29ff-46ee-aef4-979ffe033a5c	Philosophy	P6	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:6
8b42eada-f55a-4b12-9450-ee2d310fdb1d	Science Of Woman	SOW7	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:7
8838537a-43a0-4b71-9c07-ba06a8e4d384	History	H8	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:8
1f609235-ec89-480e-86e6-26484153816e	Geography	G9	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:9
df633993-6248-4b09-bfe1-514f18067db9	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:10
779de72f-8536-4c1e-941c-4d537d277618	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:11
306e59db-833e-4980-8765-e7921aacdd6c	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:12
f1d94cd5-b1c9-4522-9a92-cf756fcb3681	Petrol Engineering	PE13	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:13
13a76bf2-f008-48f2-900e-567fb3792c11	Petrol Chemistry Engineering	PCE14	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:14
1b18604c-c0b7-4aeb-9341-90ca81a78f32	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:15
4f7abc9d-a12e-443f-a1be-d2a5019b4430	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:16
c74598ed-80f7-468c-bbb9-40a2cd0c3e0e	Computers	C17	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:17
8039c04a-e21c-4602-93cd-a93633ab86c8	Communication	C18	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:18
99ca858c-069a-4e23-b23c-428fafb06801	Mechatronics	M19	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:19
cffc5dad-5bd9-4f33-9723-fe6312545853	Biochemistry	B20	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:20
c0ea6ede-2dbe-409c-81e0-986188faf691	Bîrkarî	B21	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:21
51edf32e-4fd4-46d3-af34-a093c32a2063	Physics	P22	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:22
a4999c50-de8e-4f6b-af56-725f2a9bfdde	Chemistry	C23	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:23
ebfc9349-2d03-4b21-818b-2c13713015ad	Zindînasî	Z24	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:24
9f39681f-ee66-4613-950a-0f4f57091c8d	Mamostetiya Refê	MR25	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:25
a3d0c510-ae66-40ea-a0f8-1d968f4a8019	Rêbaz Û Teknîkên Fêrkirinê (Minhac)	RÛT26	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:26
e22ae1ee-956f-48d0-9208-b62e428b3e8a	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:27
0185e795-6d6a-4a04-a177-52d4487d9fdc	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:28
592a56e3-c44b-4f00-8f67-01be727ddf54	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:29
2aefe66c-c817-40b3-bca0-fc2e81d3d03f	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:30
333bb6c8-7062-4d8d-b3d6-669901aabb30	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:31
e05babb7-3a6c-465f-b45f-185202f2ded8	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:32
2957a8ee-9578-4a0c-a3e0-96666b8524b3	Geography	G33	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:33
f2c27b26-c922-46b6-bbbe-444b8b0bb389	English Language	EL34	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:34
7cb90a7e-0b13-4ffc-affe-718083238e5f	Chemistry	C35	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:35
b146fd5a-b440-47ef-bf97-39d28d0c04f6	Physics	P36	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:36
bc2a1c67-4422-493f-841a-828e3801dde1	Bîrkarî	B37	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:37
b52ea900-4ab8-4699-97da-86e02998dbda	Zindînasî	Z38	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:38
0b30a008-e995-425d-aa87-5be6b7002f1c	Kurdish Language And Literature	KLA39	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:39
8669ee0b-fcd3-483e-9425-80c3038320a0	Arabic Language And Literature	ALA40	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:40
a81cb79b-b276-4be1-8edd-dde79f26600e	Anesthesia	A41	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:41
c4791f60-3b93-4d8d-8db6-64f458da1b80	Nursing	N42	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:42
73f92e6b-4ab1-46d0-b7c1-31fdeb1f77a0	Laborator	L43	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:43
32965364-27f2-44ed-a8e3-fd529ec46118	Pharmacy Technician	PT44	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:44
37af4eca-d201-41d5-9ab0-4c5f6e91483c	Computer	C45	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:45
91891c71-2d9e-4c83-a6b5-52c2703b17e4	Electrical	E46	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:46
c3f4b5a0-3c51-4807-883f-f35f90e93c60	Mechnical	M47	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:47
1fff7c76-b965-48e5-8b7f-3b20a42df19c	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:48
33e83ab2-e87f-4482-8586-c08abd5b5fae	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:49
84234e63-0f91-4a8f-a519-2a35c9658b02	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:50
f0f8f813-f3ab-4bd0-a36f-cedd77551ff9	Dexlûdan	D51	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:51
9417c193-3816-4de2-91d3-2ad8ab46c3e5	Bergirî	B52	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:52
dea7cc2f-af64-48cb-aa8b-3e6c747d42da	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:53
6d4c9bd1-73b9-4cfe-8622-0c59e8c8b8ea	Çavdêriya Giran	ÇG54	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:54
b098cd0f-45d4-4ccb-9d43-8000ff40dcb6	Physics	P55	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:55
19d661ec-31a9-4ef4-bf23-f18566957598	Chemistry	C56	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:56
4f67be6d-b997-4e28-b6bc-336692c5c545	Biology	B57	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:57
aa270f59-9dbd-4e91-a907-595aa681ce19	Bîrkarî	B58	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:58
56d0c97b-5827-4ca7-952f-45bef5aa1db5	Arabic Literature	AL59	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:59
cb62eee1-b293-4d24-bb1d-b2c53f792179	History	H60	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:60
8335d9c7-65ef-48f6-8db1-10af36b0e9b0	English Language	EL61	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:61
69e1902f-c28b-41a6-80f7-6f7515ddbf90	Mamostetiya Refê	MR62	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:62
a7860243-6042-40b7-b091-5a7258132dea	Perwerdeya Taybet	PT63	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:63
90fa882a-8d83-4b8d-a68a-e6a6de208543	Bexçeyên Zarokan	BZ64	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:64
3329f68e-e379-48ec-aaa3-49b638e7d451	Bernamesazî	B65	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:65
c0f5c3cb-5b80-4222-b2ec-0940dc010569	Rêveberî	R66	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:66
5b9dc231-6afb-480e-8731-966ae796399e	Jimaryarî	J67	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:67
84107d9d-6ad8-4061-9f9a-ae5b8d57ae65	Course	\N	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:68
25a1932f-d230-417e-aa28-834f0f678d63	Kurdish Language	KL69	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:69
dcf70233-a5a6-4300-9d61-fe9e6ca284ae	Childrens Gardens	CG70	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:70
f3b179c6-cb86-4e1b-bf4a-21bc789967de	Bîrkarî	B71	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:71
f4ac476b-ff3a-4056-a92e-3e4b84929146	English Language	EL72	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:72
0d03af65-e501-4bcc-8565-73bf8475751c	Biology	B73	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:73
b451d758-985b-446c-a35b-b2fbbbc5e887	Werzîş	W74	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:74
78453dc8-54ac-4285-82d2-4b606a1b1937	Music	M75	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:75
059a81b0-02f5-4809-98ea-7b4410baed09	Nîgarsazî	N76	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:76
d184d775-c1d8-4dec-8a03-6ec016b592fe	Kurdish Language	KL77	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:77
4237c417-0e64-4d1f-a08c-20a8035653ba	Childrens Gardens	CG78	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:78
fd0668a8-180f-4394-b43c-6224ee9f246b	Bîrkarî	B79	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:79
6285a1a1-9372-45b1-89d5-07fa13565a79	English Language	EL80	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:80
82798834-89c3-461b-a233-91dadb3fa01b	Biology	B81	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:81
1f48142c-f07f-49c7-befa-5c58ecf23024	Werzîş	W82	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:82
bacd26df-e8f6-4910-af14-27b383a5e598	Music	M83	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:83
0ba99d60-cb69-40b3-94c4-124dbe2d4fdf	Nîgarsazî	N84	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:84
adb8739a-2d1d-4e07-9c3a-ae64a0770a45	Computer Technician	CT85	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:85
fd2ab01e-f0ee-465e-be90-0c9d189385bb	Mechanics	M86	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:86
5c5e47ab-d64d-4901-8dc4-82272bbd7491	Biology	B87	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:87
67c38f1c-5e96-450b-884b-b3cc66067c76	Bîrkarî	B88	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:88
c92ed41c-64e9-4b1b-828d-d29f51c95300	Chemistry And Physics	CAP89	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:89
578ad01b-b165-408a-ab3f-36710f76e5e6	English Language	EL90	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:90
dc188438-04e5-46ed-927a-43d6a2fc5ce1	Kurdish Language	KL91	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:91
b98b86f4-13f6-4462-9bd1-4b3c47c7a938	Mamostetiya Refê	MR92	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:92
1d78dc09-d63a-435c-98c3-82e8ce87abbf	Arabic Language	AL93	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:93
efd284d5-6422-43e1-9330-1ebf7ef5eac0	Music	M94	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:94
f134a8b1-9f70-4ff1-834d-4bdf61b55daf	Mamostetiya Refê	MR95	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:95
548f2472-8a96-4c96-9c4e-59bb594a4c3c	Kurdish Language	KL96	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:96
bada4d6e-a05a-4e63-9561-1b606fbd166f	English Language	EL97	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:97
c9d74556-2186-4a27-b705-7d2d578de32d	Computers	C98	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_departments:98
07a91465-7e3e-4a24-87f9-217bd27b1c9c	Cizîrê school	CIZ	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_baccalaureate_marks(county school):Cizîrê
447b5ad2-4252-4d19-a8a5-530333e9a7e9	Firat school	FIR	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_baccalaureate_marks(county school):Firat
7f5a67ca-48d8-46bb-b498-4ad0ef777312	Reqa school	REQ	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_baccalaureate_marks(county school):Reqa
8fd9a5fd-74f3-4b21-9fd1-b0fc68d04519	Şehba school	EHB	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_baccalaureate_marks(county school):şehba
1b268407-8ca3-4853-9ca8-993a7683034a	Tepqa school	TEP	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N	Imported from 2024-v1 university_mofadala_baccalaureate_marks(county school):Tepqa
\.


--
-- Data for Name: acorn_user_users; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_users (id, name, email, password, activation_code, persist_code, reset_password_code, permissions, is_activated, is_system_user, activated_at, last_login, created_at, updated_at, username, surname, deleted_at, last_seen, is_guest, is_superuser, created_ip_address, last_ip_address, acorn_imap_username, acorn_imap_password, acorn_imap_server, acorn_imap_port, acorn_imap_protocol, acorn_imap_encryption, acorn_imap_authentication, acorn_imap_validate_cert, acorn_smtp_server, acorn_smtp_port, acorn_smtp_encryption, acorn_smtp_authentication, acorn_smtp_username, acorn_smtp_password, acorn_messaging_sounds, acorn_messaging_email_notifications, acorn_messaging_autocreated, acorn_imap_last_fetch, acorn_default_calendar, acorn_start_of_week, acorn_default_event_time_from, acorn_default_event_time_to, birth_date, import_source) FROM stdin;
9e95e475-919e-472a-b1e3-65d83adee981	Artisan	artisan@nowhere.org	$2y$10$04rS6CabSidfoSyFEwaOGeuv0SvRfwEySaQuyPFH0Szw2UnO5FoIS	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:22	2025-04-03 07:43:22	artisan	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e477-1d74-4314-8ae8-4dbb605cb027	Createsystem	createsystem@nowhere.org	$2y$10$xELVx7Ue7aLR2ffoLahdz.8nQsrCJu3uVZq3b2DRd4OV/zWPGBcWC	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:23	2025-04-03 07:43:23	createsystem	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e478-70c6-49a6-a82c-47f3639fc748	Seeder	seeder@nowhere.org	$2y$10$jnVJoLvkr0UMQ59RN6oZc.bFWyB0oVcteNUQ80N0EcAjv2xbAprpG	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:24	2025-04-03 07:43:24	seeder	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e479-9690-4091-a730-aecdf51f9258	Admin	admin@nowhere.org	$2y$10$CYphtl51Fbdv2TZcNZdtrezTwWNw0qeGfSc6oiuYEpE/pOK4gupYy	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:24	2025-04-03 07:43:24	admin	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
a11d6172-6565-4195-a62e-038358aa9fa9	seeder	\N	\N	\N	\N	\N	\N	f	t	\N	\N	\N	\N	\N	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
b880a3af-09cb-4394-a70d-4564ae2f7804	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB1	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:1
9e95e47b-46dc-492d-8ffa-1954bc3f1611	sz	sz@nowhere.org	$2y$10$lta6VXUFah18WoaE0L6/2eNtXxV1pJ14tG4juSxDF5QOlGq6C86zu	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:26	2025-04-03 07:43:26	sz	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-08-11 00:00:00	\N
aa50a12a-3dac-46c0-9377-ce455d038e86	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB2	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:2
779b5391-b922-4ba9-87c3-8d49a3eeda03	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB3	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:3
3f5584d2-f5e3-47d4-b3b0-3a2076ec2dff	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB5	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:5
63145aaf-8849-48c0-b90b-d8b23805a211	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB80	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:80
c51b90c4-9d8e-4fae-b3e3-67dec4e27918	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB79	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:79
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	Weeeeeee	a@we22.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-04 12:39:25	2025-05-04 12:39:25	a@we22.com	w	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
bffe3efb-d7b9-4c87-b7eb-7312c1ad1171	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB78	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:78
68338af7-34d8-4edd-b7e8-0ad9364d79da	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB77	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:77
9e95e47c-db72-48ec-8c0c-908592ebf59c	Demo	demo@nowhere.org	$2y$10$fXtS/tknV8gTiWiKWD4NEuYaGRQ.aMaTKLjYUlko6bkH7V2JZq7Oa	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:27	2025-05-04 17:56:19	demo		\N	\N	f	f	\N	\N	demo@nowhere.org		imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal	demo@nowhere.org		f	N	\N	\N	ceea8856-e4c8-11ef-8719-5f58c97885a2	1	\N	\N	2001-10-10 00:00:00	\N
7e6c1cd5-60be-4da4-ae23-cb41932da741	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB76	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:76
1af621f0-69bf-4dc4-849d-14aef7e3a692	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB75	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:75
9eda3ec9-0240-4f44-8f58-ff497c3845d3	Yani	r@a.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-07 07:12:14	2025-05-07 07:12:14	r@a.com		\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9eda41e0-abe7-4899-8d7b-bcfa2fd7bd8c	a	a@b.com44	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-07 07:20:53	2025-05-07 07:20:53	a@b.com44	s	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5308f937-7182-4684-9d98-cd6d0510b345	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB74	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:74
9eda61e1-2736-4187-bb6f-8ed20e6cc171	Yippee 38745	y@hhh.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-07 08:50:22	2025-05-07 08:50:22	y@hhh.com		\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
b221bac3-9d62-4845-bd8f-947d0b3cca8e	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB73	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:73
cb9e973a-d540-447e-bbad-0f0331885bd9	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB72	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:72
9ee44e4d-50ca-4a7e-b707-bdfad8ebd491	My new student	a@tt.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-12 07:13:54	2025-05-12 07:13:54	a@tt.com	weee	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9ea61aa6-e680-484d-9d30-aba185c5b329	Example Student (row 2)		\N	\N	\N	\N	\N	f	f	\N	\N	2025-04-11 09:08:09	2025-05-04 17:55:58		1to1	\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	ceea8856-e4c8-11ef-8719-5f58c97885a2	1	\N	\N	1971-08-11 00:00:00	\N
9ea61ac5-d211-4e52-86f5-10c6d4dbe688	Example Student (row 1)	a	\N	\N	\N	\N	\N	f	f	\N	\N	2025-04-11 09:08:29	2025-05-04 17:52:21	a	1	\N	\N	f	f	\N	\N	a		imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal	a		f	N	\N	\N	ceea8856-e4c8-11ef-8719-5f58c97885a2	1	\N	\N	2001-10-10 00:00:00	\N
4d50712b-1a4d-425d-b7ed-61d512546f43	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB71	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:71
45ccf283-6396-4ccb-8c1f-da1de92c2e4a	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB70	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:70
e78844ac-c83b-4877-8725-bc35e403f20a	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB69	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:69
28ac41a4-ef42-4567-ad85-b08f92046447	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB68	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:68
818a7a2c-372f-42fa-a767-c67395ef6d08	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB67	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:67
cdd57003-d205-4064-bdb4-c1aa24b7da7d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB66	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:66
e2b4bbab-dba6-4bc7-b883-c89e2da5f845	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB65	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:65
3d514f29-e08a-4939-9d08-570e67f0b3ec	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB64	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:64
da9a7888-ecdd-495a-be63-d51316977d3b	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB63	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:63
56eee99e-1152-4b6c-84d8-52d2e3a8e0f6	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB62	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:62
efc9e0fe-17f4-4b8f-bc07-26bc6a8da641	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB61	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:61
5884674d-9de1-4549-8355-f8221c62a826	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB60	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:60
71da8bcd-7dfb-4fc5-a267-6139bcd09205	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB59	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:59
a36ab23c-e8e8-4c4d-9fcb-dbd0cb28d0b6	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB58	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:58
dd95f51d-1a74-4fcf-991d-cb33a41da997	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB57	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:57
0d6a8654-4d20-46b8-8884-a3001a0bcc41	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB56	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:56
1ade79ea-fd20-4a7f-be73-2579ccb2c31d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB55	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:55
4c9318ba-d04e-455d-b56f-f05fb3bcb0be	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB54	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:54
1b78aea7-21c3-4523-b773-5c31d67e461d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB53	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:53
93d05a2b-7992-4cf0-a3ad-c3d26390ffab	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB52	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:52
a4a64845-d7af-4b7a-87df-0ae0c59f560a	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB51	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:51
aaa6f127-5c7e-4278-b3b7-54dfeb40dfa2	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB50	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:50
c102cdff-32d7-41d1-9435-a17ec69879cb	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB49	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:49
823cc6b7-c309-4327-a02b-d60ed3305b2e	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB48	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:48
90e5f167-800c-41c5-9352-7ba76184800f	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB47	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:47
2265bd45-67c5-4a5d-8016-a36bec3844dd	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB46	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:46
dd72c8b5-a780-46d9-8fda-a46cabed8a9f	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB45	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:45
856c63d5-9eb3-44c4-923c-237e4476e0fa	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB44	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:44
8e56c70d-dc29-4e13-a593-e42ed4719d55	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB43	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:43
ae9cf707-9a2e-41c6-89fe-65d504ce2581	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB42	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:42
f6fa2d27-59eb-4b27-8646-dd50bd0b971b	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB41	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:41
2854e734-ac2a-47ea-804e-afebf2977fe8	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB40	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:40
5753efcc-d8a3-4575-81e8-8e3e36779ee3	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB39	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:39
4e94d6dd-517a-4c54-ad5b-6f678d72cac3	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB38	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:38
d21cd6b0-1301-43fe-87bd-a2c706986af9	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB37	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:37
0e1492a4-0fd3-4521-a28c-16701dda1896	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB36	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:36
3dcbfe97-d3e8-450e-b872-2dc4a728f4d2	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB35	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:35
0c7e2d6c-dc3c-4d79-80ff-c499bb11927d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB34	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:34
6ee2bf6a-8914-415c-9665-86e97a718253	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB33	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:33
07a2844a-7a19-4cfa-865c-5b59dfcf317a	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB32	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:32
2f57dcef-7fbf-486c-b186-67d9ac6bf434	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB31	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:31
fe9d69ca-0980-402f-af33-ed3a093ea83f	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB30	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:30
62674f06-8c4c-4020-b999-54a001027e99	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB4	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:4
7a2149f9-1779-4a09-bcc9-637f58cbd484	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB29	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:29
13504931-bdb7-4442-a817-bf86df4c04aa	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB28	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:28
d783f34c-6083-491c-a9ae-0af1fb117303	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB27	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:27
9cd6cfcd-c97b-49b8-9122-37c91b4e1d71	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB26	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:26
36e083b6-6baf-4a24-892f-c282fb41cc4d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB25	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:25
171949fd-ac4f-4c5e-ba22-85df6af3b97f	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB24	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:24
c5ec0a84-5bd1-4d26-a31e-54e524a6e9f5	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB23	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:23
6e1d5573-9e0f-43b2-83ca-826916b1a7a1	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB22	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:22
b0e8f0c1-4276-4d58-944b-00019244fa1c	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB21	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:21
0f98c4fd-b58f-4e4e-adc4-641f4ca05299	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB20	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:20
966b5795-6e8f-4975-b6ae-27c6c2feae24	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB19	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:19
80288cda-4ad8-46e3-9c0a-0db9257db5b9	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB18	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:18
090b0515-e919-4979-b5bd-f69f84d674a3	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB17	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:17
4f7f0607-8ced-4663-be18-f4272d4cae2e	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB16	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:16
726257f9-c87c-49e4-a947-d2ffae8a413d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB15	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:15
e24ae02b-c468-466f-a10d-f982f59c2c93	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB14	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:14
aab5a941-06ae-4438-9edb-63705f62af74	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB13	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:13
f171e15a-20a6-4dd3-866c-30d8a675cfdd	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB12	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:12
989ff7b1-bf93-45d3-923a-8826fde4f020	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB11	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:11
3ef01289-8ade-4a5f-a0ad-fb78d3ad15ac	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB10	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:10
f11cc724-0330-412a-a376-043d5bb604ea	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB9	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:9
4e6a4629-f4db-4e6c-a4a3-f551ebc18933	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB8	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:8
e4fb2c04-e9fa-4878-80e2-e724684a670b	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB7	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:7
3f64fd61-faec-4417-bf32-3e0a125f956d	Debug created for OLAP data	\N	12345678	\N	\N	\N	\N	f	f	\N	\N	\N	\N	KOB6	Debug	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-03-12 00:00:00	Imported from 2024-v1 university_mofadala_students:6
9f08a53c-db29-4d16-ae1f-c076411b216a	Test	dfsgdsfgdsf@weee.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-30 08:46:47	2025-05-30 08:46:47	dfsgdsfgdsf@weee.com	Test	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: backend_access_log; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_access_log (id, user_id, ip_address, created_at, updated_at) FROM stdin;
1	1	127.0.0.1	2025-04-03 07:44:19	2025-04-03 07:44:19
2	1	127.0.0.1	2025-04-08 11:22:57	2025-04-08 11:22:57
3	1	127.0.0.1	2025-04-08 13:35:30	2025-04-08 13:35:30
4	1	127.0.0.1	2025-04-08 13:36:45	2025-04-08 13:36:45
5	1	127.0.0.1	2025-04-17 09:10:43	2025-04-17 09:10:43
6	1	127.0.0.1	2025-04-22 07:33:37	2025-04-22 07:33:37
7	1	127.0.0.1	2025-04-23 13:32:41	2025-04-23 13:32:41
8	1	127.0.0.1	2025-05-17 08:43:54	2025-05-17 08:43:54
9	1	127.0.0.1	2025-05-19 06:57:52	2025-05-19 06:57:52
10	1	127.0.0.1	2025-05-19 07:32:05	2025-05-19 07:32:05
11	1	127.0.0.1	2025-05-22 06:15:52	2025-05-22 06:15:52
12	1	127.0.0.1	2025-05-22 06:28:33	2025-05-22 06:28:33
13	1	127.0.0.1	2025-05-22 06:33:24	2025-05-22 06:33:24
14	1	127.0.0.1	2025-05-25 05:54:09	2025-05-25 05:54:09
\.


--
-- Data for Name: backend_user_groups; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_groups (id, name, created_at, updated_at, code, description, is_new_user_default) FROM stdin;
1	Owners	2025-04-03 07:39:25	2025-04-03 07:39:25	owners	Default group for website owners.	f
\.


--
-- Data for Name: backend_user_preferences; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_preferences (id, user_id, namespace, "group", item, value) FROM stdin;
2	5	backend	backend	preferences	{"locale":"ku","fallback_locale":"en","timezone":"Europe\\/Istanbul","icon_location":"inline","menu_location":"top"}
3	6	backend	backend	preferences	{"locale":"ku","fallback_locale":"en","timezone":"Europe\\/Istanbul","icon_location":"inline","menu_location":"top"}
15	1	acorn_exam	calculations	lists	{"visible":["name","description","expression","minimum","required","calculation_type","exam_calculation_courses__calculation","exam_calculation_material_types__calculation","exam_calculation_course_materials__calculation"],"order":["id","name","description","expression","created_at_event","updated_at_event","created_by_user","updated_by_user","server","minimum","maximum","required","exam_tokens__calculation","exam_results__calculation","_qrcode","_actions","calculation_type","exam_calculation_courses__calculation","exam_calculation_material_types__calculation","exam_calculation_course_materials__calculation","exam_result_internals__calculation"],"per_page":"20"}
5	1	acorn_exam	exams	lists-relationexamresultsexamviewlist	{"visible":["id","student","calculation","entity","expression","expression_type","needs_evaluate","result","_actions"],"order":["id","student","exam","calculation","entity","expression","expression_type","needs_evaluate","result","_qrcode","_actions"],"per_page":"10"}
8	1	acorn_university	courses	lists	{"visible":["entity_university_hierarchies__entity","name","code","university_course_materials__course","_actions","weight","entity_user_group_children","entity_user_group_users","import_source"],"order":["id","entity_university_hierarchies__entity","name","code","colour","image","university_course_materials__course","_qrcode","_actions","created_at_event","updated_at_event","weight","exam_results__course","exam_tokens__course","university_course_language__courses","entity_user_group","entity_user_group_children","entity_user_group_users","entity_user_group_eventParts","entity_user_group_versions","entity_user_group_users_count","exam_calculation_courses__course","exam_result_internals__course","import_source","entity_university_student_codes__entity"],"per_page":"20"}
6	1	acorn_exam	tokens	lists	{"visible":["name","student","exam","calculation","entity","expression","expression_type","needs_evaluate","_actions"],"order":["id","name","student","exam","calculation","entity","expression","expression_type","needs_evaluate","_qrcode","_actions"],"per_page":"20"}
14	1	acorn_exam	results	lists	{"visible":["name","student","course","material","academic_year","exam","calculation","expression","minimum","maximum","required","expression_type","result","passed"],"order":["id","name","student","course_material","course","material","academic_year","exam","calculation","project","interview","expression","minimum","maximum","required","expression_type","needs_evaluate","result","passed","_qrcode","_actions","calculation_type"],"per_page":"20"}
1	1	backend	backend	preferences	{"locale":"ku","fallback_locale":"en","timezone":"Europe\\/Istanbul","icon_location":"inline","menu_location":"top","dark_mode":"light","editor_theme":"twilight","editor_word_wrap":"off","editor_font_size":"11","editor_tab_size":"2","editor_code_folding":"manual","editor_autocompletion":"manual","editor_show_gutter":"0","editor_highlight_active_line":"0","editor_use_hard_tabs":"0","editor_display_indent_guides":"0","editor_show_invisibles":"0","editor_show_print_margin":"0","editor_auto_closing":"0","editor_enable_snippets":"0","user_id":1}
13	1	acorn_exam	dataentryscores	lists	{"visible":["student_user","student_code","course_user_group","academic_year_semester","exam","scores","course_score"],"order":["student_user","student","student_code","course_user_group","academic_year_semester","course_code","exam","scores","_qrcode","id","course_score","filename","_actions","academic_year"],"per_page":"20"}
4	1	acorn_university	students	lists-relationexamresultsstudentviewlist	{"visible":["course","course_material","exam","calculation","expression","expression_type","result","name","minimum","maximum","required","passed"],"order":["id","student","course","course_material","exam","calculation","expression","expression_type","needs_evaluate","result","_qrcode","_actions","name","project","interview","minimum","maximum","required","passed"],"per_page":"10"}
16	1	acorn_university	hierarchies	lists	{"visible":["entity","user_group_version_users_count","descendant_users_count","descendants_count","academic_year","import_source"],"order":["id","entity","user_group_version_users_count","descendant_users_count","descendants_count","parent","server","created_at_event","updated_at_event","created_by_user","updated_by_user","user_group_version_users","university_hierarchies__parent","_qrcode","academic_year","description","version","current","import_source","_actions"],"per_page":20}
7	1	acorn_university	universities	lists	{"visible":["name","_actions","code","colour","image","entity_university_hierarchies__entity"],"order":["id","name","_qrcode","_actions","code","colour","image","created_at_event","updated_at_event","entity_university_hierarchies__entity","entity_user_group","entity_user_group_children","entity_user_group_users","entity_user_group_eventParts"],"per_page":"20"}
17	1	acorn_university	years	lists	{"visible":["name","start","end","current","description","university_hierarchies__year","university_semester_years__year","exam_calculation_course__years","_actions"],"order":["id","name","start","end","current","description","created_at_event","updated_at_event","created_by_user","updated_by_user","server","university_hierarchies__year","university_semester_years__year","exam_calculation_course__years","_qrcode","_actions"],"per_page":"20"}
11	1	acorn_university	students	lists-relationexamdataentryscoresstudentviewlist	{"visible":["course_user_group","exam","scores","course_score"],"order":["student","course_user_group","exam","scores","_qrcode","_actions","student_user","student_code","course_code","id","filename","course_score"],"per_page":"10"}
10	1	acorn_university	courses	lists-relationuniversitycoursematerialscourseviewlist	{"visible":["material","required","minimum","maximum","weight","exam_exam_materials__course_material","academic_year_semester","course_year","academic_year_semester_ordinal","enrollment_academic_year","university_lectures__course_material"],"order":["id","course","material","required","minimum","maximum","created_at_event","updated_at_event","created_by_user","updated_by_user","server","weight","exam_exam_materials__course_material","_qrcode","_actions","calculation","exam_interview_students__course_material","university_project_students__course_material","exam_tokens__course_material","exam_results__course_material","academic_year_semester","course_year","academic_year_semester_ordinal","enrollment_academic_year","university_lectures__course_material"],"per_page":"10"}
19	1	acorn_university	courses	lists-relationentityuniversityhierarchiesentityviewlist	{"visible":["academic_year","parent"],"order":["id","entity","academic_year","parent","server","created_at_event","updated_at_event","created_by_user","updated_by_user","university_hierarchies__parent","_qrcode","_actions"],"per_page":"10"}
18	1	acorn_university	coursematerials	lists	{"visible":["course","material","enrollment_academic_year","course_year","academic_year_semester","academic_year_semester_ordinal","exam_exam_materials__course_material","university_lectures__course_material","order"],"order":["id","course","material","required","minimum","maximum","created_at_event","updated_at_event","created_by_user","updated_by_user","server","weight","enrollment_academic_year","course_year","academic_year_semester","academic_year_semester_ordinal","exam_exam_materials__course_material","exam_interview_students__course_material","university_project_students__course_material","university_lectures__course_material","exam_tokens__course_material","exam_results__course_material","_qrcode","_actions","order","exam_calculation_course_materials__course_material","exam_result_internals__course_material"],"per_page":"20"}
21	1	acorn_university	materialtypes	lists-relationexamcalculationmaterialtypematerialtypesmanagelist	{"visible":["name","description","expression","calculation_type","exam_results__calculation","exam_calculation_course__calculations","exam_calculation_material_type__calculations","exam_calculation_course_material__calculations","_actions"],"order":["id","name","description","expression","created_at_event","updated_at_event","created_by_user","updated_by_user","server","minimum","maximum","required","calculation_type","exam_tokens__calculation","exam_results__calculation","exam_calculation_course__calculations","exam_calculation_material_type__calculations","exam_calculation_course_material__calculations","_qrcode","_actions"],"per_page":false}
9	1	acorn_university	students	lists	{"visible":["name","surname","email","username","created_ip_address","code","exam_scores__student","exam_interview_students__student","university_student_status__students","university_project_students__owner_student","_actions","university_student_codes__student"],"order":["id","name","surname","email","username","created_ip_address","last_ip_address","code","exam_scores__student","exam_interview_students__student","exam_results__student","_qrcode","university_student_status__students","university_project_students__owner_student","user_groups","user_languages","user_user_group_versions","user_roles","user_eventParts","exam_tokens__student","exam_data_entry_scores__student","exam_result_internals__student","_actions","current","university_student_codes__student"],"per_page":"20"}
22	1	acorn_university	educationauthorities	lists	{"visible":["id","name","code","import_source","entity_user_group_users","entity_user_group_eventParts","entity_university_hierarchies__entity","entity_university_student_codes__entity","entity_user_group","entity_user_group_children","entity_user_group_versions","entity_user_group_users_count","_actions"],"order":["id","name","code","colour","image","created_at_event","updated_at_event","import_source","entity_user_group_users","entity_user_group_eventParts","entity_university_hierarchies__entity","entity_university_student_codes__entity","entity_user_group","entity_user_group_children","entity_user_group_versions","entity_user_group_users_count","_qrcode","_actions"],"per_page":"20"}
20	1	acorn_university	academicyears	lists	{"visible":["name","university_hierarchies__academic_year","university_academic_year_semesters__academic_year","exam_calculation_courses__academic_year","exam_calculation_material_types__academic_year","exam_calculation_course_materials__academic_year","exam_data_entry_scores__academic_year","_actions"],"order":["id","start","end","current","description","created_at_event","updated_at_event","created_by_user","updated_by_user","server","name","ordinal","university_hierarchies__academic_year","university_academic_year_semesters__academic_year","university_course_materials__enrollment_academic_year","_qrcode","exam_calculation_courses__academic_year","exam_calculation_material_types__academic_year","exam_calculation_course_materials__academic_year","exam_results__academic_year","exam_tokens__academic_year","exam_data_entry_scores__academic_year","_actions","exam_result_internals__academic_year"],"per_page":"20"}
\.


--
-- Data for Name: backend_user_roles; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_roles (id, name, code, description, permissions, is_system, created_at, updated_at) FROM stdin;
1	Publisher	publisher	Site editor with access to publishing tools.		t	2025-04-03 07:39:25	2025-04-03 07:39:25
2	Developer	developer	Site administrator with access to developer tools.		t	2025-04-03 07:39:25	2025-04-03 07:39:25
\.


--
-- Data for Name: backend_user_throttle; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_throttle (id, user_id, ip_address, attempts, last_attempt_at, is_suspended, suspended_at, is_banned, banned_at) FROM stdin;
1	1	127.0.0.1	0	\N	f	\N	f	\N
2	5	\N	0	\N	f	\N	f	\N
3	4	\N	0	\N	f	\N	f	\N
\.


--
-- Data for Name: backend_users; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_users (id, first_name, last_name, login, email, password, activation_code, persist_code, reset_password_code, permissions, is_activated, role_id, activated_at, last_login, created_at, updated_at, deleted_at, is_superuser, metadata, acorn_url, acorn_user_user_id) FROM stdin;
2	\N	\N	artisan	artisan@nowhere.org	$2y$10$ChjYqkUapNB3KsaekjQJGu1zgrgW7O.ru9QdlngpWvtrHSMUFvGnC	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:21	2025-04-03 07:43:22	\N	f	\N	\N	9e95e475-919e-472a-b1e3-65d83adee981
3	\N	\N	createsystem	createsystem@nowhere.org	$2y$10$ZqIy57H.7gf1NW8KyJ0ykOKXnn/AtOJO3IZEZFVk6bcVX7fQFODi6	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:23	2025-04-03 07:43:23	\N	f	\N	\N	9e95e477-1d74-4314-8ae8-4dbb605cb027
4	\N	\N	seeder	seeder@nowhere.org	$2y$10$HJ1ZIEc4od1rqY9awLMeeulTb91fIOuQup1MnLtVkaqR2o6.etILu	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:23	2025-04-03 07:43:24	\N	f	\N	\N	9e95e478-70c6-49a6-a82c-47f3639fc748
5	\N	\N	sz	sz@nowhere.org	$2y$10$r5Zck2dEs35hFYhepIOFeOKrp3CfQ5u.vlTew04YgIaumzY8uq1Uu	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:25	2025-04-03 07:43:26	\N	f	\N	\N	9e95e47b-46dc-492d-8ffa-1954bc3f1611
6	\N	\N	demo	demo@nowhere.org	$2y$10$iDWeqZhd1b/q.naIRMthX.wNkPXpdqVCP3FwLOSIyxlnJmKevMney	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:26	2025-04-03 07:43:27	\N	f	\N	\N	9e95e47c-db72-48ec-8c0c-908592ebf59c
1	Admin	Person	admin	admin@example.com	$2y$10$bwEGGgAzJOGZ2yF00lAJ1.DbiBDvQzwJ/HJN9ue7oX08ZL2iySNai	\N	$2y$10$xrj6pu1WsmdpvMlwugjIUOzt4SiqUR46sSOnAWQsbn9fOvU79COCy	\N		t	2	\N	2025-05-25 05:54:09	2025-04-03 07:39:25	2025-05-25 05:54:09	\N	t	\N	\N	9e95e479-9690-4091-a730-aecdf51f9258
\.


--
-- Data for Name: backend_users_groups; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_users_groups (user_id, user_group_id, deleted_at) FROM stdin;
1	1	\N
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cms_theme_data; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cms_theme_data (id, theme, data, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cms_theme_logs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cms_theme_logs (id, type, theme, template, old_template, content, old_content, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cms_theme_templates; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cms_theme_templates (id, source, path, content, file_size, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: deferred_bindings; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.deferred_bindings (id, master_type, master_field, slave_type, slave_id, session_key, is_bind, created_at, updated_at, pivot_data) FROM stdin;
1	Acorn\\Exam\\Models\\Exam	exam_exam_material_exams	Acorn\\Exam\\Models\\Material	5d92a794-e582-41af-9c63-076c3c5ec7ad	czDZYDTSfY1jczSDQWtT1o8aSpfw6nPikpRvIONN	t	2025-04-08 17:44:10	2025-04-08 17:44:10	\N
2	Acorn\\Exam\\Models\\Exam	exam_exam_material_exams	Acorn\\Exam\\Models\\Material	4ceccaec-a157-4e28-8aa4-e8be31a461e1	czDZYDTSfY1jczSDQWtT1o8aSpfw6nPikpRvIONN	t	2025-04-08 17:44:10	2025-04-08 17:44:10	\N
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.failed_jobs (id, connection, queue, payload, failed_at, exception, uuid) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	2013_10_01_000001_Db_Deferred_Bindings	1
2	2013_10_01_000002_Db_System_Files	1
3	2013_10_01_000003_Db_System_Plugin_Versions	1
4	2013_10_01_000004_Db_System_Plugin_History	1
5	2013_10_01_000005_Db_System_Settings	1
6	2013_10_01_000006_Db_System_Parameters	1
7	2013_10_01_000007_Db_System_Add_Disabled_Flag	1
8	2013_10_01_000008_Db_System_Mail_Templates	1
9	2013_10_01_000009_Db_System_Mail_Layouts	1
10	2014_10_01_000010_Db_Jobs	1
11	2014_10_01_000011_Db_System_Event_Logs	1
12	2014_10_01_000012_Db_System_Request_Logs	1
13	2014_10_01_000013_Db_System_Sessions	1
14	2015_10_01_000014_Db_System_Mail_Layout_Rename	1
15	2015_10_01_000015_Db_System_Add_Frozen_Flag	1
16	2015_10_01_000016_Db_Cache	1
17	2015_10_01_000017_Db_System_Revisions	1
18	2015_10_01_000018_Db_FailedJobs	1
19	2016_10_01_000019_Db_System_Plugin_History_Detail_Text	1
20	2016_10_01_000020_Db_System_Timestamp_Fix	1
21	2017_08_04_121309_Db_Deferred_Bindings_Add_Index_Session	1
22	2017_10_01_000021_Db_System_Sessions_Update	1
23	2017_10_01_000022_Db_Jobs_FailedJobs_Update	1
24	2017_10_01_000023_Db_System_Mail_Partials	1
25	2017_10_23_000024_Db_System_Mail_Layouts_Add_Options_Field	1
26	2021_10_01_000025_Db_Add_Pivot_Data_To_Deferred_Bindings	1
27	2022_08_06_000026_Db_System_Add_App_Birthday_Date	1
28	2022_10_14_000027_Db_Jobs_FailedJobs_Update	1
29	2023_09_24_000028_Db_System_Sessions_Indexes	1
30	2023_10_20_000029_Db_Jobs_Batches	1
31	2013_10_01_000001_Db_Backend_Users	2
32	2013_10_01_000002_Db_Backend_User_Groups	2
33	2013_10_01_000003_Db_Backend_Users_Groups	2
34	2013_10_01_000004_Db_Backend_User_Throttle	2
35	2014_01_04_000005_Db_Backend_User_Preferences	2
36	2014_10_01_000006_Db_Backend_Access_Log	2
37	2014_10_01_000007_Db_Backend_Add_Description_Field	2
38	2015_10_01_000008_Db_Backend_Add_Superuser_Flag	2
39	2016_10_01_000009_Db_Backend_Timestamp_Fix	2
40	2017_10_01_000010_Db_Backend_User_Roles	2
41	2018_12_16_000011_Db_Backend_Add_Deleted_At	2
42	2023_02_16_000012_Db_Backend_Add_User_Metadata	2
43	2023_09_09_000013_Db_Backend_Add_Users_Groups_Delete_At	2
44	2014_10_01_000001_Db_Cms_Theme_Data	3
45	2016_10_01_000002_Db_Cms_Timestamp_Fix	3
46	2017_10_01_000003_Db_Cms_Theme_Logs	3
47	2018_11_01_000001_Db_Cms_Theme_Templates	3
48	2024_01_01_000001_Db_Backend_Users_Url	4
49	2024_01_01_000001_Db_Functions	4
50	2024_01_01_000001_Db_PluginMenuControl	4
51	2024_01_01_000001_Db_Servers	4
\.


--
-- Data for Name: p_users_count; Type: TABLE DATA; Schema: public; Owner: sz
--

COPY public.p_users_count (count) FROM stdin;
0
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.sessions (id, payload, last_activity, user_id, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: system_event_logs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_event_logs (id, level, message, details, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_files; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_files (id, disk_name, file_name, file_size, content_type, title, description, field, attachment_id, attachment_type, is_public, sort_order, created_at, updated_at) FROM stdin;
1	68174cfc92925152822883.png	Screenshot_20250317_231933.png	1174067	image/png	\N	\N	avatar	9ea61aa6-e680-484d-9d30-aba185c5b329	Acorn\\User\\Models\\User	t	1	2025-05-04 11:18:20	2025-05-04 11:18:25
2	682ad65970787255891356.jpeg	logo.jpeg	49652	image/jpeg	\N	\N	logo	1	Backend\\Models\\BrandSetting	t	2	2025-05-19 06:57:29	2025-05-19 06:57:36
3	682ad65d9ffea466429374.jpeg	logo.jpeg	49652	image/jpeg	\N	\N	favicon	1	Backend\\Models\\BrandSetting	t	3	2025-05-19 06:57:33	2025-05-19 06:57:36
\.


--
-- Data for Name: system_mail_layouts; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_mail_layouts (id, name, code, content_html, content_text, content_css, is_locked, created_at, updated_at, options) FROM stdin;
1	Default layout	default	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n    <style type="text/css" media="screen">\n        {{ brandCss|raw }}\n        {{ css|raw }}\n    </style>\n</head>\n<body>\n    <table class="wrapper layout-default" width="100%" cellpadding="0" cellspacing="0">\n\n        <!-- Header -->\n        {% partial 'header' body %}\n            {{ subject|raw }}\n        {% endpartial %}\n\n        <tr>\n            <td align="center">\n                <table class="content" width="100%" cellpadding="0" cellspacing="0">\n                    <!-- Email Body -->\n                    <tr>\n                        <td class="body" width="100%" cellpadding="0" cellspacing="0">\n                            <table class="inner-body" align="center" width="570" cellpadding="0" cellspacing="0">\n                                <!-- Body content -->\n                                <tr>\n                                    <td class="content-cell">\n                                        {{ content|raw }}\n                                    </td>\n                                </tr>\n                            </table>\n                        </td>\n                    </tr>\n                </table>\n            </td>\n        </tr>\n\n        <!-- Footer -->\n        {% partial 'footer' body %}\n            &copy; {{ "now"|date("Y") }} {{ appName }}. All rights reserved.\n        {% endpartial %}\n\n    </table>\n\n</body>\n</html>	{{ content|raw }}	@media only screen and (max-width: 600px) {\n    .inner-body {\n        width: 100% !important;\n    }\n\n    .footer {\n        width: 100% !important;\n    }\n}\n\n@media only screen and (max-width: 500px) {\n    .button {\n        width: 100% !important;\n    }\n}	t	2025-04-03 07:39:25	2025-04-03 07:39:25	\N
2	System layout	system	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n    <style type="text/css" media="screen">\n        {{ brandCss|raw }}\n        {{ css|raw }}\n    </style>\n</head>\n<body>\n    <table class="wrapper layout-system" width="100%" cellpadding="0" cellspacing="0">\n        <tr>\n            <td align="center">\n                <table class="content" width="100%" cellpadding="0" cellspacing="0">\n                    <!-- Email Body -->\n                    <tr>\n                        <td class="body" width="100%" cellpadding="0" cellspacing="0">\n                            <table class="inner-body" align="center" width="570" cellpadding="0" cellspacing="0">\n                                <!-- Body content -->\n                                <tr>\n                                    <td class="content-cell">\n                                        {{ content|raw }}\n\n                                        <!-- Subcopy -->\n                                        {% partial 'subcopy' body %}\n                                            **This is an automatic message. Please do not reply to it.**\n                                        {% endpartial %}\n                                    </td>\n                                </tr>\n                            </table>\n                        </td>\n                    </tr>\n                </table>\n            </td>\n        </tr>\n    </table>\n\n</body>\n</html>	{{ content|raw }}\n\n\n---\nThis is an automatic message. Please do not reply to it.	@media only screen and (max-width: 600px) {\n    .inner-body {\n        width: 100% !important;\n    }\n\n    .footer {\n        width: 100% !important;\n    }\n}\n\n@media only screen and (max-width: 500px) {\n    .button {\n        width: 100% !important;\n    }\n}	t	2025-04-03 07:39:25	2025-04-03 07:39:25	\N
\.


--
-- Data for Name: system_mail_partials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_mail_partials (id, name, code, content_html, content_text, is_custom, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_mail_templates; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_mail_templates (id, code, subject, description, content_html, content_text, layout_id, is_custom, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_parameters; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_parameters (id, namespace, "group", item, value) FROM stdin;
1	system	app	birthday	"2025-04-03T07:39:23.508552Z"
2	system	update	count	0
4	system	core	modified	true
3	system	core	build	"1.2.6"
6	system	theme	history	{"Kenshin.KenshinSchool":"kenshin-kenshinschool"}
7	cms	theme	active	"kenshin-kenshinschool"
5	system	update	retry	1748692760
\.


--
-- Data for Name: system_plugin_history; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_plugin_history (id, code, type, version, detail, created_at) FROM stdin;
1	Winter.Demo	comment	1.0.1	First version of Demo	2025-04-03 07:39:25
2	Acorn.User	script	1.0.1	v1.0.1/create_users_table.php	2025-04-03 07:42:57
3	Acorn.User	script	1.0.1	v1.0.1/create_throttle_table.php	2025-04-03 07:42:57
4	Acorn.User	comment	1.0.1	Initialize plugin.	2025-04-03 07:42:57
5	Acorn.User	comment	1.0.2	Seed tables.	2025-04-03 07:42:57
6	Acorn.User	comment	1.0.3	Translated hard-coded text to language strings.	2025-04-03 07:42:57
7	Acorn.User	comment	1.0.4	Improvements to user-interface for Location manager.	2025-04-03 07:42:57
8	Acorn.User	comment	1.0.5	Added contact details for users.	2025-04-03 07:42:57
9	Acorn.User	script	1.0.6	v1.0.6/create_mail_blockers_table.php	2025-04-03 07:42:57
10	Acorn.User	comment	1.0.6	Added Mail Blocker utility so users can block specific mail templates.	2025-04-03 07:42:57
11	Acorn.User	comment	1.0.7	Add back-end Settings page.	2025-04-03 07:42:57
12	Acorn.User	comment	1.0.8	Updated the Settings page.	2025-04-03 07:42:57
13	Acorn.User	comment	1.0.9	Adds new welcome mail message for users and administrators.	2025-04-03 07:42:57
14	Acorn.User	comment	1.0.10	Adds administrator-only activation mode.	2025-04-03 07:42:57
15	Acorn.User	script	1.0.11	v1.0.11/users_add_login_column.php	2025-04-03 07:42:57
16	Acorn.User	comment	1.0.11	Users now have an optional login field that defaults to the email field.	2025-04-03 07:42:57
17	Acorn.User	script	1.0.12	v1.0.12/users_rename_login_to_username.php	2025-04-03 07:42:57
18	Acorn.User	comment	1.0.12	Create a dedicated setting for choosing the login mode.	2025-04-03 07:42:57
19	Acorn.User	comment	1.0.13	Minor fix to the Account sign in logic.	2025-04-03 07:42:57
20	Acorn.User	comment	1.0.14	Minor improvements to the code.	2025-04-03 07:42:57
21	Acorn.User	script	1.0.15	v1.0.15/users_add_surname.php	2025-04-03 07:42:57
22	Acorn.User	comment	1.0.15	Adds last name column to users table (surname).	2025-04-03 07:42:57
23	Acorn.User	comment	1.0.16	Require permissions for settings page too.	2025-04-03 07:42:57
24	Acorn.User	comment	1.1.0	!!! Profile fields and Locations have been removed.	2025-04-03 07:42:57
25	Acorn.User	script	1.1.1	v1.1.1/create_user_groups_table.php	2025-04-03 07:42:57
26	Acorn.User	script	1.1.1	v1.1.1/seed_user_groups_table.php	2025-04-03 07:42:58
27	Acorn.User	comment	1.1.1	Users can now be added to groups.	2025-04-03 07:42:58
28	Acorn.User	comment	1.1.2	A raw URL can now be passed as the redirect property in the Account component.	2025-04-03 07:42:58
29	Acorn.User	comment	1.1.3	Adds a super user flag to the users table, reserved for future use.	2025-04-03 07:42:58
30	Acorn.User	comment	1.1.4	User list can be filtered by the group they belong to.	2025-04-03 07:42:58
31	Acorn.User	comment	1.1.5	Adds a new permission to hide the User settings menu item.	2025-04-03 07:42:58
32	Acorn.User	script	1.2.0	v1.2.0/users_add_deleted_at.php	2025-04-03 07:42:58
33	Acorn.User	comment	1.2.0	Users can now deactivate their own accounts.	2025-04-03 07:42:58
34	Acorn.User	comment	1.2.1	New feature for checking if a user is recently active/online.	2025-04-03 07:42:58
35	Acorn.User	comment	1.2.2	Add bulk action button to user list.	2025-04-03 07:42:58
36	Acorn.User	comment	1.2.3	Included some descriptive paragraphs in the Reset Password component markup.	2025-04-03 07:42:58
37	Acorn.User	comment	1.2.4	Added a checkbox for blocking all mail sent to the user.	2025-04-03 07:42:58
38	Acorn.User	script	1.2.5	v1.2.5/update_timestamp_nullable.php	2025-04-03 07:42:58
39	Acorn.User	comment	1.2.5	Database maintenance. Updated all timestamp columns to be nullable.	2025-04-03 07:42:58
40	Acorn.User	script	1.2.6	v1.2.6/users_add_last_seen.php	2025-04-03 07:42:58
41	Acorn.User	comment	1.2.6	Add a dedicated last seen column for users.	2025-04-03 07:42:58
42	Acorn.User	comment	1.2.7	Minor fix to user timestamp attributes.	2025-04-03 07:42:58
43	Acorn.User	comment	1.2.8	Add date range filter to users list. Introduced a logout event.	2025-04-03 07:42:58
44	Acorn.User	comment	1.2.9	Add invitation mail for new accounts created in the back-end.	2025-04-03 07:42:58
45	Acorn.User	script	1.3.0	v1.3.0/users_add_guest_flag.php	2025-04-03 07:42:58
46	Acorn.User	script	1.3.0	v1.3.0/users_add_superuser_flag.php	2025-04-03 07:42:58
47	Acorn.User	comment	1.3.0	Introduced guest user accounts.	2025-04-03 07:42:58
48	Acorn.User	comment	1.3.1	User notification variables can now be extended.	2025-04-03 07:42:58
49	Acorn.User	comment	1.3.2	Minor fix to the Auth::register method.	2025-04-03 07:42:58
50	Acorn.User	comment	1.3.3	Allow prevention of concurrent user sessions via the user settings.	2025-04-03 07:42:58
51	Acorn.User	comment	1.3.4	Added force secure protocol property to the account component.	2025-04-03 07:42:58
52	Acorn.User	comment	1.4.0	!!! The Notifications tab in User settings has been removed.	2025-04-03 07:42:58
53	Acorn.User	comment	1.4.1	Added support for user impersonation.	2025-04-03 07:42:58
54	Acorn.User	comment	1.4.2	Fixes security bug in Password Reset component.	2025-04-03 07:42:58
55	Acorn.User	comment	1.4.3	Fixes session handling for AJAX requests.	2025-04-03 07:42:58
56	Acorn.User	comment	1.4.4	Fixes bug where impersonation touches the last seen timestamp.	2025-04-03 07:42:58
57	Acorn.User	comment	1.4.5	Added token fallback process to Account / Reset Password components when parameter is missing.	2025-04-03 07:42:58
58	Acorn.User	comment	1.4.6	Fixes Auth::register method signature mismatch with core Winter CMS Auth library	2025-04-03 07:42:58
59	Acorn.User	comment	1.4.7	Fixes redirect bug in Account component / Update translations and separate user and group management.	2025-04-03 07:42:58
60	Acorn.User	comment	1.4.8	Fixes a bug where calling MailBlocker::removeBlock could remove all mail blocks for the user.	2025-04-03 07:42:58
61	Acorn.User	comment	1.5.0	!!! Required password length is now a minimum of 8 characters. Previous passwords will not be affected until the next password change.	2025-04-03 07:42:58
62	Acorn.User	script	1.5.1	v1.5.1/users_add_ip_address.php	2025-04-03 07:42:58
63	Acorn.User	comment	1.5.1	User IP addresses are now logged. Introduce registration throttle.	2025-04-03 07:42:58
64	Acorn.User	comment	1.5.2	Whitespace from usernames is now trimmed, allowed for username to be added to Reset Password mail templates.	2025-04-03 07:42:58
65	Acorn.User	comment	1.5.3	Fixes a bug in the user update functionality if password is not changed. Added highlighting for banned users in user list.	2025-04-03 07:42:58
66	Acorn.User	comment	1.5.4	Multiple translation improvements. Added view events to extend user preview and user listing toolbars.	2025-04-03 07:42:58
67	Acorn.User	script	2.0.0	v2.0.0/rename_tables.php	2025-04-03 07:42:58
68	Acorn.User	comment	2.0.0	Rebrand to Acorn.User	2025-04-03 07:42:58
69	Acorn.User	comment	2.0.0	Update Russian language	2025-04-03 07:42:58
70	Acorn.User	script	2.0.1	v2.0.1/rename_indexes.php	2025-04-03 07:42:59
71	Acorn.User	comment	2.0.1	Rebrand table indexes	2025-04-03 07:42:59
72	Acorn.User	comment	2.1.0	Enforce password length rules on sign in. Compatibility fixes.	2025-04-03 07:42:59
73	Acorn.User	comment	2.2.0	Add avatar removal. Password resets will activate users if User activation mode is enabled.	2025-04-03 07:42:59
74	Acorn.User	comment	2.2.1	Fixes a bug introduced by the adoption of symfony/mime required since Laravel 7.x where sending an email to a blocked email address would not be prevented.	2025-04-03 07:42:59
75	Acorn.User	comment	2.2.2	Improved French translation, updated plugin icons, fixed migrations for Laravel 9	2025-04-03 07:42:59
76	Acorn.User	script	3.0.0	v3.0.0/create_user_roles_table.php	2025-04-03 07:42:59
77	Acorn.User	script	3.0.0	v3.0.0/add_backend_user_column.php	2025-04-03 07:42:59
78	Acorn.User	script	3.0.0	v3.0.0/create_user_languages.php	2025-04-03 07:42:59
79	Acorn.User	script	3.0.0	v3.0.0/create_user_group_types_table.php	2025-04-03 07:42:59
80	Acorn.User	comment	3.0.0	User Roles	2025-04-03 07:42:59
81	Acorn.User	comment	3.0.0	Add Backend User column	2025-04-03 07:42:59
82	Acorn.User	comment	3.0.0	Create user languages XtoX	2025-04-03 07:42:59
83	Acorn.User	comment	3.0.0	Create User Group Types	2025-04-03 07:42:59
84	Acorn.User	script	3.0.2	v3.0.2/create_usage_view.php	2025-04-03 07:42:59
85	Acorn.User	script	3.0.2	v3.0.2/create_functions.php	2025-04-03 07:42:59
86	Acorn.User	comment	3.0.2	Create Usage view	2025-04-03 07:42:59
87	Acorn.User	comment	3.0.2	Create Functions	2025-04-03 07:42:59
88	Winter.Location	comment	1.0.1	Initialize plugin.	2025-04-03 07:42:59
89	Winter.Location	script	1.0.2	v1.0.2/create_states_table.php	2025-04-03 07:42:59
90	Winter.Location	script	1.0.2	v1.0.2/create_countries_table.php	2025-04-03 07:42:59
91	Winter.Location	comment	1.0.2	Create database tables.	2025-04-03 07:42:59
92	Winter.Location	script	1.0.3	v1.0.3/seed_all_tables.php	2025-04-03 07:43:06
93	Winter.Location	comment	1.0.3	Add seed data for countries and states.	2025-04-03 07:43:06
94	Winter.Location	comment	1.0.4	Satisfy the new Google API key requirement.	2025-04-03 07:43:06
95	Winter.Location	script	1.0.5	v1.0.5/add_country_pinned_flag.php	2025-04-03 07:43:06
96	Winter.Location	comment	1.0.5	Countries can now be pinned to make them appear at the top of the list.	2025-04-03 07:43:06
97	Winter.Location	comment	1.0.6	Added support for defining a default country and state.	2025-04-03 07:43:06
98	Winter.Location	comment	1.0.7	Added basic geocoding method to the Country model.	2025-04-03 07:43:06
99	Winter.Location	comment	1.0.8	Include Mexico states	2025-04-03 07:43:06
100	Winter.Location	comment	1.1.0	!!! Update requires Build 447. Fixed AddressFinder formwidget not working correctly in repeaters.	2025-04-03 07:43:06
101	Winter.Location	comment	1.1.1	Minor fix to AddressFinder formwidget for the change to the FormField API	2025-04-03 07:43:06
102	Winter.Location	comment	1.1.2	Yet another change to the AddressFinder for changes to the FormField API	2025-04-03 07:43:06
103	Winter.Location	script	1.1.3	v1.1.3/seed_ar_states.php	2025-04-03 07:43:06
104	Winter.Location	comment	1.1.3	Include Argentina states	2025-04-03 07:43:06
105	Winter.Location	comment	1.1.4	Added support for UK counties	2025-04-03 07:43:06
106	Winter.Location	script	1.1.5	v1.1.5/seed_it_states.php	2025-04-03 07:43:07
107	Winter.Location	comment	1.1.5	Include Italian states (province)	2025-04-03 07:43:07
108	Winter.Location	script	1.1.6	v1.1.6/add_enabled_states.php	2025-04-03 07:43:07
109	Winter.Location	comment	1.1.6	Added ability to disable specific states	2025-04-03 07:43:07
110	Winter.Location	script	2.0.0	v2.0.0/rename_tables.php	2025-04-03 07:43:07
111	Winter.Location	comment	2.0.0	Rebrand to Winter.location	2025-04-03 07:43:07
112	Winter.Location	script	2.0.1	v2.0.1/rename_indexes.php	2025-04-03 07:43:07
113	Winter.Location	script	2.0.1	v2.0.1/fix_translate_records.php	2025-04-03 07:43:07
114	Winter.Location	comment	2.0.1	Rebrand table indexes	2025-04-03 07:43:07
115	Winter.Location	comment	2.0.1	Add migrations for translate plugin attributes and indexes tables	2025-04-03 07:43:07
116	Winter.Location	script	2.0.2	v2.0.2/seed_ru_states.php	2025-04-03 07:43:09
117	Winter.Location	comment	2.0.2	Include Russian states (subjects)	2025-04-03 07:43:09
118	Winter.TailwindUI	comment	1.0.1	First version of TailwindUI	2025-04-03 07:43:09
119	Winter.Translate	script	1.0.1	v1.0.1/create_messages_table.php	2025-04-03 07:43:09
120	Winter.Translate	script	1.0.1	v1.0.1/create_attributes_table.php	2025-04-03 07:43:09
121	Winter.Translate	script	1.0.1	v1.0.1/create_locales_table.php	2025-04-03 07:43:09
122	Winter.Translate	comment	1.0.1	First version of Translate	2025-04-03 07:43:09
123	Winter.Translate	comment	1.0.2	Languages and Messages can now be deleted.	2025-04-03 07:43:09
124	Winter.Translate	comment	1.0.3	Minor updates for latest Winter CMS release.	2025-04-03 07:43:09
125	Winter.Translate	comment	1.0.4	Locale cache will clear when updating a language.	2025-04-03 07:43:09
126	Winter.Translate	comment	1.0.5	Add Spanish language and fix plugin config.	2025-04-03 07:43:09
127	Winter.Translate	comment	1.0.6	Minor improvements to the code.	2025-04-03 07:43:09
128	Winter.Translate	comment	1.0.7	Fixes major bug where translations are skipped entirely!	2025-04-03 07:43:09
129	Winter.Translate	comment	1.0.8	Minor bug fixes.	2025-04-03 07:43:09
130	Winter.Translate	comment	1.0.9	Fixes an issue where newly created models lose their translated values.	2025-04-03 07:43:09
131	Winter.Translate	comment	1.0.10	Minor fix for latest build.	2025-04-03 07:43:09
132	Winter.Translate	comment	1.0.11	Fix multilingual rich editor when used in stretch mode.	2025-04-03 07:43:09
133	Winter.Translate	comment	1.1.0	Introduce compatibility with Winter.Pages plugin.	2025-04-03 07:43:10
134	Winter.Translate	comment	1.1.1	Minor UI fix to the language picker.	2025-04-03 07:43:10
135	Winter.Translate	comment	1.1.2	Add support for translating Static Content files.	2025-04-03 07:43:10
136	Winter.Translate	comment	1.1.3	Improved support for the multilingual rich editor.	2025-04-03 07:43:10
137	Winter.Translate	comment	1.1.4	Adds new multilingual markdown editor.	2025-04-03 07:43:10
138	Winter.Translate	comment	1.1.5	Minor update to the multilingual control API.	2025-04-03 07:43:10
139	Winter.Translate	comment	1.1.6	Minor improvements in the message editor.	2025-04-03 07:43:10
140	Winter.Translate	comment	1.1.7	Fixes bug not showing content when first loading multilingual textarea controls.	2025-04-03 07:43:10
141	Winter.Translate	comment	1.2.0	CMS pages now support translating the URL.	2025-04-03 07:43:10
142	Winter.Translate	comment	1.2.1	Minor update in the rich editor and code editor language control position.	2025-04-03 07:43:10
143	Winter.Translate	comment	1.2.2	Static Pages now support translating the URL.	2025-04-03 07:43:10
144	Winter.Translate	comment	1.2.3	Fixes Rich Editor when inserting a page link.	2025-04-03 07:43:10
145	Winter.Translate	script	1.2.4	v1.2.4/create_indexes_table.php	2025-04-03 07:43:10
146	Winter.Translate	comment	1.2.4	Translatable attributes can now be declared as indexes.	2025-04-03 07:43:10
147	Winter.Translate	comment	1.2.5	Adds new multilingual repeater form widget.	2025-04-03 07:43:10
148	Winter.Translate	comment	1.2.6	Fixes repeater usage with static pages plugin.	2025-04-03 07:43:10
149	Winter.Translate	comment	1.2.7	Fixes placeholder usage with static pages plugin.	2025-04-03 07:43:10
150	Winter.Translate	comment	1.2.8	Improvements to code for latest Winter CMS build compatibility.	2025-04-03 07:43:10
151	Winter.Translate	comment	1.2.9	Fixes context for translated strings when used with Static Pages.	2025-04-03 07:43:10
152	Winter.Translate	comment	1.2.10	Minor UI fix to the multilingual repeater.	2025-04-03 07:43:10
153	Winter.Translate	comment	1.2.11	Fixes translation not working with partials loaded via AJAX.	2025-04-03 07:43:10
154	Winter.Translate	comment	1.2.12	Add support for translating the new grouped repeater feature.	2025-04-03 07:43:10
155	Winter.Translate	comment	1.3.0	Added search to the translate messages page.	2025-04-03 07:43:10
156	Winter.Translate	script	1.3.1	v1.3.1/add_sort_order.php	2025-04-03 07:43:10
157	Winter.Translate	script	1.3.1	v1.3.1/seed_all_tables.php	2025-04-03 07:43:10
158	Winter.Translate	comment	1.3.1	Added reordering to languages	2025-04-03 07:43:10
159	Winter.Translate	comment	1.3.2	Improved compatibility with Winter.Pages, added ability to scan Mail Messages for translatable variables.	2025-04-03 07:43:10
160	Winter.Translate	comment	1.3.3	Fix to the locale picker session handling in Build 420 onwards.	2025-04-03 07:43:10
161	Winter.Translate	comment	1.3.4	Add alternate hreflang elements and adds prefixDefaultLocale setting.	2025-04-03 07:43:10
162	Winter.Translate	comment	1.3.5	Fix MLRepeater bug when switching locales.	2025-04-03 07:43:10
163	Winter.Translate	comment	1.3.6	Fix Middleware to use the prefixDefaultLocale setting introduced in 1.3.4	2025-04-03 07:43:10
164	Winter.Translate	comment	1.3.7	Fix config reference in LocaleMiddleware	2025-04-03 07:43:10
165	Winter.Translate	comment	1.3.8	Keep query string when switching locales	2025-04-03 07:43:10
166	Winter.Translate	comment	1.4.0	Add importer and exporter for messages	2025-04-03 07:43:10
167	Winter.Translate	comment	1.4.1	Updated Hungarian translation. Added Arabic translation. Fixed issue where default texts are overwritten by import. Fixed issue where the language switcher for repeater fields would overlap with the first repeater row.	2025-04-03 07:43:10
168	Winter.Translate	comment	1.4.2	Add multilingual MediaFinder	2025-04-03 07:43:10
169	Winter.Translate	comment	1.4.3	!!! Please update Winter CMS to Build 444 before updating this plugin. Added ability to translate CMS Pages fields (e.g. title, description, meta-title, meta-description)	2025-04-03 07:43:11
170	Winter.Translate	comment	1.4.4	Minor improvements to compatibility with Laravel framework.	2025-04-03 07:43:11
171	Winter.Translate	comment	1.4.5	Fixed issue when using the language switcher	2025-04-03 07:43:11
172	Winter.Translate	comment	1.5.0	Compatibility fix with Build 451	2025-04-03 07:43:11
173	Winter.Translate	comment	1.6.0	Make File Upload widget properties translatable. Merge Repeater core changes into MLRepeater widget. Add getter method to retrieve original translate data.	2025-04-03 07:43:11
174	Winter.Translate	comment	1.6.1	Add ability for models to provide translated computed data, add option to disable locale prefix routing	2025-04-03 07:43:11
175	Winter.Translate	comment	1.6.2	Implement localeUrl filter, add per-locale theme configuration support	2025-04-03 07:43:11
176	Winter.Translate	comment	1.6.3	Add eager loading for translations, restore support for accessors & mutators	2025-04-03 07:43:11
177	Winter.Translate	comment	1.6.4	Fixes PHP 7.4 compatibility	2025-04-03 07:43:11
178	Winter.Translate	comment	1.6.5	Fixes compatibility issue when other plugins use a custom model morph map	2025-04-03 07:43:11
179	Winter.Translate	script	1.6.6	v1.6.6/migrate_morphed_attributes.php	2025-04-03 07:43:11
180	Winter.Translate	comment	1.6.6	Introduce migration to patch existing translations using morph map	2025-04-03 07:43:11
181	Winter.Translate	script	1.6.7	v1.6.7/migrate_morphed_indexes.php	2025-04-03 07:43:11
182	Winter.Translate	comment	1.6.7	Introduce migration to patch existing indexes using morph map	2025-04-03 07:43:11
183	Winter.Translate	comment	1.6.8	Add support for transOrderBy; Add translation support for ThemeData; Update russian localization.	2025-04-03 07:43:11
184	Winter.Translate	comment	1.6.9	Clear Static Page menu cache after saving the model; CSS fix for Text/Textarea input fields language selector.	2025-04-03 07:43:11
185	Winter.Translate	script	1.6.10	v1.6.10/update_messages_table.php	2025-04-03 07:43:11
186	Winter.Translate	comment	1.6.10	Add option to purge deleted messages when scanning messages	2025-04-03 07:43:11
187	Winter.Translate	comment	1.6.10	Add Scan error column on Messages page	2025-04-03 07:43:11
188	Winter.Translate	comment	1.6.10	Fix translations that were lost when clicking locale twice while holding ctrl key	2025-04-03 07:43:11
189	Winter.Translate	comment	1.6.10	Fix error with nested fields default locale value	2025-04-03 07:43:11
190	Winter.Translate	comment	1.6.10	Escape Message translate params value	2025-04-03 07:43:11
191	Winter.Translate	comment	1.7.0	!!! Breaking change for the Message::trans() method (params are now escaped)	2025-04-03 07:43:11
192	Winter.Translate	comment	1.7.0	fix message translation documentation	2025-04-03 07:43:11
193	Winter.Translate	comment	1.7.0	fix string translation key for scan errors column header	2025-04-03 07:43:11
194	Winter.Translate	comment	1.7.1	Fix YAML issue with previous tag/release.	2025-04-03 07:43:11
195	Winter.Translate	comment	1.7.2	Fix regex when "|_" filter is followed by another filter	2025-04-03 07:43:11
196	Winter.Translate	comment	1.7.2	Try locale without country before returning default translation	2025-04-03 07:43:11
197	Winter.Translate	comment	1.7.2	Allow exporting default locale	2025-04-03 07:43:11
198	Winter.Translate	comment	1.7.2	Fire 'winter.translate.themeScanner.afterScan' event in the theme scanner for extendability	2025-04-03 07:43:11
199	Winter.Translate	comment	1.7.3	Make plugin ready for Laravel 6 update	2025-04-03 07:43:11
200	Winter.Translate	comment	1.7.3	Add support for translating Winter.Pages MenuItem properties (requires Winter.Pages v1.3.6)	2025-04-03 07:43:11
201	Winter.Translate	comment	1.7.3	Restore multilingual button position for textarea	2025-04-03 07:43:11
202	Winter.Translate	comment	1.7.3	Fix translatableAttributes	2025-04-03 07:43:11
203	Winter.Translate	comment	1.7.4	Faster version of transWhere	2025-04-03 07:43:11
204	Winter.Translate	comment	1.7.4	Mail templates/views can now be localized	2025-04-03 07:43:11
205	Winter.Translate	comment	1.7.4	Fix messages table layout on mobile	2025-04-03 07:43:11
206	Winter.Translate	comment	1.7.4	Fix scopeTransOrderBy duplicates	2025-04-03 07:43:11
207	Winter.Translate	comment	1.7.4	Polish localization updates	2025-04-03 07:43:11
208	Winter.Translate	comment	1.7.4	Turkish localization updates	2025-04-03 07:43:11
209	Winter.Translate	comment	1.7.4	Add Greek language localization	2025-04-03 07:43:11
210	Winter.Translate	comment	1.8.0	Adds initial support for October v2.0	2025-04-03 07:43:11
211	Winter.Translate	comment	1.8.1	Minor bugfix	2025-04-03 07:43:11
212	Winter.Translate	comment	1.8.2	Fixes translated file models and theme data for v2.0. The parent model must implement translatable behavior for their related file models to be translated.	2025-04-03 07:43:11
213	Winter.Translate	script	2.0.0	v2.0.0/rename_tables.php	2025-04-03 07:43:11
214	Winter.Translate	comment	2.0.0	Rebrand to Winter.Translate	2025-04-03 07:43:11
215	Winter.Translate	comment	2.0.0	Fix location for dropdown-to in css file	2025-04-03 07:43:11
216	Winter.Translate	script	2.0.1	v2.0.1/rename_indexes.php	2025-04-03 07:43:12
217	Winter.Translate	comment	2.0.1	Rebrand table indexes	2025-04-03 07:43:12
218	Winter.Translate	comment	2.0.1	Remove deprecated methods (setTranslateAttribute/getTranslateAttribute)	2025-04-03 07:43:12
219	Winter.Translate	comment	2.0.2	Added Latvian translation. Fixed plugin replacement issues.	2025-04-03 07:43:12
220	Winter.Translate	script	2.1.0	v2.1.0/migrate_message_code.php	2025-04-03 07:43:13
221	Winter.Translate	comment	2.1.0	!!! Potential breaking change: Message codes are now MD5 hashed versions of the original string. See https://github.com/wintercms/wn-translate-plugin/pull/2	2025-04-03 07:43:13
222	Winter.Translate	comment	2.1.1	Added support for Winter CMS 1.2.	2025-04-03 07:43:13
223	Winter.Translate	comment	2.1.2	Add Vietnamese translations	2025-04-03 07:43:13
224	Winter.Translate	comment	2.1.2	Add composer replace config.	2025-04-03 07:43:13
225	Winter.Translate	comment	2.1.2	Add MultiLang capability to Winter.Sitemap.	2025-04-03 07:43:13
226	Winter.Translate	comment	2.1.2	Add addTranslatableAttributes() method to TranslatableBehavior.	2025-04-03 07:43:13
227	Winter.Translate	comment	2.1.2	Fix dynamically adding fields to non-existent tab.	2025-04-03 07:43:13
228	Winter.Translate	comment	2.1.2	Fix translations conflicting between nested fields and translatable root fields of the same name.	2025-04-03 07:43:13
229	Winter.Translate	comment	2.1.3	Fixed issue with translatable models	2025-04-03 07:43:13
230	Winter.Translate	comment	2.1.4	Fixed issue with broken imports in the backend Locales controller.	2025-04-03 07:43:13
231	Winter.Translate	comment	2.1.5	Add support for translatable nested forms	2025-04-03 07:43:13
232	Winter.Translate	comment	2.1.5	Add validation for translated string	2025-04-03 07:43:13
233	Winter.Translate	comment	2.1.5	Add setTranslatableUseFallback() / deprecate noFallbackLocale()	2025-04-03 07:43:13
234	Winter.Translate	comment	2.1.5	Only extend cms page if cms module is enabled	2025-04-03 07:43:13
235	Winter.Translate	comment	2.1.5	Prevent browser autofill for hidden locale inputs	2025-04-03 07:43:13
236	Winter.Translate	comment	2.1.5	System MailTemplate model is now translatable	2025-04-03 07:43:13
237	Winter.Translate	comment	2.1.5	Make fields using @context translatable	2025-04-03 07:43:13
238	Winter.Translate	comment	2.1.6	Improve ML button styling	2025-04-03 07:43:13
239	Winter.Translate	comment	2.1.6	Fix TranslatableBehavior::lang method signature	2025-04-03 07:43:13
240	Winter.Translate	comment	2.1.7	Only set alternateLinks if more than one locale is used	2025-04-03 07:43:13
241	Winter.Translate	comment	2.1.7	Cleanup after model is deleted	2025-04-03 07:43:13
242	Winter.Translate	comment	2.1.7	Add missing french translations	2025-04-03 07:43:13
243	Winter.Translate	comment	2.2.0	Fix translating pages on Winter v1.2.7+	2025-04-03 07:43:13
244	Acorn.BackendLocalization	script	1.0.0	v1.1/seed_locale_backend.php	2025-04-03 07:43:13
245	Acorn.BackendLocalization	comment	1.0.0	Create special languages ​​for the backend 	2025-04-03 07:43:13
246	Acorn.Location	script	4.0.0	create_from_sql.php	2025-04-03 07:43:13
247	Acorn.Location	comment	4.0.0	Create from DB & seeder.sql	2025-04-03 07:43:13
248	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message.php	2025-04-03 07:43:13
249	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_user.php	2025-04-03 07:43:13
250	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_user_group.php	2025-04-03 07:43:13
251	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_message.php	2025-04-03 07:43:13
252	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_action.php	2025-04-03 07:43:14
253	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_label.php	2025-04-03 07:43:14
254	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_status.php	2025-04-03 07:43:14
255	Acorn.Messaging	script	1.0.1	seed_status.php	2025-04-03 07:43:14
256	Acorn.Messaging	comment	1.0.1	Initialize plugin.	2025-04-03 07:43:14
257	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message	2025-04-03 07:43:14
258	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_user	2025-04-03 07:43:14
259	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_user_group	2025-04-03 07:43:14
260	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_message	2025-04-03 07:43:14
261	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_action	2025-04-03 07:43:14
262	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_label	2025-04-03 07:43:14
263	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_status	2025-04-03 07:43:14
264	Acorn.Messaging	comment	1.0.1	Seeding message status	2025-04-03 07:43:14
265	Acorn.Messaging	script	2.0.0	create_acorn_users_extra_fields.php	2025-04-03 07:43:14
266	Acorn.Messaging	comment	2.0.0	Create acorn users extra fields	2025-04-03 07:43:14
267	Acorn.Reporting	script	1.0.1	builder_table_create_acorn_reporting_reports.php	2025-04-03 07:43:14
268	Acorn.Reporting	comment	1.0.1	Initialize plugin.	2025-04-03 07:43:14
269	Acorn.Reporting	comment	1.0.1	Created table acorn_reporting_reports	2025-04-03 07:43:14
270	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_calendars.php	2025-04-03 07:43:14
271	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_types.php	2025-04-03 07:43:14
272	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_statuses.php	2025-04-03 07:43:14
273	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_events.php	2025-04-03 07:43:14
274	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_parts.php	2025-04-03 07:43:15
275	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_instances.php	2025-04-03 07:43:15
276	Acorn.Calendar	script	2.0.1	create_acorn_calendar_event_trigger.php	2025-04-03 07:43:15
277	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_part_user.php	2025-04-03 07:43:15
278	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_part_user_group.php	2025-04-03 07:43:15
279	Acorn.Calendar	script	2.0.1	table_create_acorn_messaging_instance.php	2025-04-03 07:43:15
280	Acorn.Calendar	script	2.0.1	create_acorn_users_extra_fields.php	2025-04-03 07:43:15
281	Acorn.Calendar	script	2.0.1	create_functions.php	2025-04-03 07:43:15
282	Acorn.Calendar	script	2.0.1	seed_calendar.php	2025-04-03 07:43:15
283	Acorn.Calendar	comment	2.0.1	Initialize plugin.	2025-04-03 07:43:15
284	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_calendars	2025-04-03 07:43:15
285	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_types	2025-04-03 07:43:15
286	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_statuses	2025-04-03 07:43:15
287	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_events	2025-04-03 07:43:15
288	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_parts	2025-04-03 07:43:15
289	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_instances	2025-04-03 07:43:15
290	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_trigger	2025-04-03 07:43:15
291	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_part_user	2025-04-03 07:43:15
292	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_part_user_group	2025-04-03 07:43:15
293	Acorn.Calendar	comment	2.0.1	Created table acorn_messaging_message_instance	2025-04-03 07:43:15
294	Acorn.Calendar	comment	2.0.1	Create acorn users extra fields	2025-04-03 07:43:15
295	Acorn.Calendar	comment	2.0.1	Create functions, including fn_acorn_calendar_seed()	2025-04-03 07:43:15
296	Acorn.Calendar	comment	2.0.1	Seeding default Calendar, Types and Statuses	2025-04-03 07:43:15
297	Winter.Debugbar	comment	1.0.1	First version of Debugbar	2025-04-23 11:38:27
298	Winter.Debugbar	comment	1.0.2	Debugbar facade aliased (Alxy)	2025-04-23 11:38:27
299	Winter.Debugbar	comment	1.0.3	Added ajax debugging	2025-04-23 11:38:27
300	Winter.Debugbar	comment	1.0.4	Only display to backend authenticated users	2025-04-23 11:38:27
301	Winter.Debugbar	comment	1.0.5	Use elevated privileges	2025-04-23 11:38:27
302	Winter.Debugbar	comment	1.0.6	Fix fatal error when cms.page.beforeDisplay is fired multiple times (mnishihan)	2025-04-23 11:38:27
303	Winter.Debugbar	comment	1.0.7	Allow plugin to be installed via Composer (tim0991)	2025-04-23 11:38:27
304	Winter.Debugbar	comment	1.0.8	Fix debugbar dependency	2025-04-23 11:38:27
305	Winter.Debugbar	comment	2.0.0	!!! Upgrade for compatibility with Laravel 5.5 (PHP 7+, October 420+)	2025-04-23 11:38:27
306	Winter.Debugbar	comment	2.0.1	Add config file to prevent exceptions from being thrown (credit alxy)	2025-04-23 11:38:27
307	Winter.Debugbar	comment	3.0.0	Switched vendor to RainLab from Bedard, upgraded for compatibility with Laravel 6.x	2025-04-23 11:38:27
308	Winter.Debugbar	comment	3.0.1	Fixed bug that caused 502 errors on AJAX requests	2025-04-23 11:38:27
309	Winter.Debugbar	comment	3.1.0	Important security update and improved styling.	2025-04-23 11:38:27
310	Winter.Debugbar	comment	3.1.1	Added new "store all requests" config option. Added Slovenian translations.	2025-04-23 11:38:27
311	Winter.Debugbar	comment	4.0.0	Switched vendor to Winter from RainLab	2025-04-23 11:38:27
312	Winter.Debugbar	comment	4.0.1	Added Russian translation, added support for Twig v3 / Winter v1.2 / Laravel 9	2025-04-23 11:38:27
313	Winter.Debugbar	comment	4.0.2	Adds new collectors for Twig, CMS and Backend. Updated styling to match Winter branding	2025-04-23 11:38:27
314	Winter.Debugbar	comment	4.0.3	Improved compatibility with latest version of dependencies	2025-04-23 11:38:27
315	Winter.Debugbar	comment	4.0.4	Align styling with barryvdh/laravel-debugbar v3.15.x dependency	2025-04-23 11:38:27
316	Winter.Debugbar	comment	4.0.5	Styling / branding improvements	2025-04-23 11:38:27
317	Winter.Pages	comment	1.0.1	Implemented the static pages management and the Static Page component.	2025-05-21 12:56:04
318	Winter.Pages	comment	1.0.2	Fixed the page preview URL.	2025-05-21 12:56:04
319	Winter.Pages	comment	1.0.3	Implemented menus.	2025-05-21 12:56:04
320	Winter.Pages	comment	1.0.4	Implemented the content block management and placeholder support.	2025-05-21 12:56:04
321	Winter.Pages	comment	1.0.5	Added support for the Sitemap plugin.	2025-05-21 12:56:04
322	Winter.Pages	comment	1.0.6	Minor updates to the internal API.	2025-05-21 12:56:04
323	Winter.Pages	comment	1.0.7	Added the Snippets feature.	2025-05-21 12:56:04
324	Winter.Pages	comment	1.0.8	Minor improvements to the code.	2025-05-21 12:56:04
325	Winter.Pages	comment	1.0.9	Fixes issue where Snippet tab is missing from the Partials form.	2025-05-21 12:56:04
326	Winter.Pages	comment	1.0.10	Add translations for various locales.	2025-05-21 12:56:04
327	Winter.Pages	comment	1.0.11	Fixes issue where placeholders tabs were missing from Page form.	2025-05-21 12:56:04
328	Winter.Pages	comment	1.0.12	Implement Media Manager support.	2025-05-21 12:56:04
329	Winter.Pages	script	1.1.0	v1.1.0/snippets_rename_viewbag_properties.php	2025-05-21 12:56:04
330	Winter.Pages	comment	1.1.0	Adds meta title and description to pages. Adds |staticPage filter.	2025-05-21 12:56:04
331	Winter.Pages	comment	1.1.1	Add support for Syntax Fields.	2025-05-21 12:56:04
332	Winter.Pages	comment	1.1.2	Static Breadcrumbs component now respects the hide from navigation setting.	2025-05-21 12:56:04
333	Winter.Pages	comment	1.1.3	Minor back-end styling fix.	2025-05-21 12:56:04
334	Winter.Pages	comment	1.1.4	Minor fix to the StaticPage component API.	2025-05-21 12:56:04
335	Winter.Pages	comment	1.1.5	Fixes bug when using syntax fields.	2025-05-21 12:56:04
336	Winter.Pages	comment	1.1.6	Minor styling fix to the back-end UI.	2025-05-21 12:56:04
337	Winter.Pages	comment	1.1.7	Improved menu item form to include CSS class, open in a new window and hidden flag.	2025-05-21 12:56:04
338	Winter.Pages	comment	1.1.8	Improved the output of snippet partials when saved.	2025-05-21 12:56:04
339	Winter.Pages	comment	1.1.9	Minor update to snippet inspector internal API.	2025-05-21 12:56:04
340	Winter.Pages	comment	1.1.10	Fixes a bug where selecting a layout causes permanent unsaved changes.	2025-05-21 12:56:04
341	Winter.Pages	comment	1.1.11	Add support for repeater syntax field.	2025-05-21 12:56:04
342	Winter.Pages	comment	1.2.0	Added support for translations, UI updates.	2025-05-21 12:56:04
343	Winter.Pages	comment	1.2.1	Use nice titles when listing the content files.	2025-05-21 12:56:04
344	Winter.Pages	comment	1.2.2	Minor styling update.	2025-05-21 12:56:04
345	Winter.Pages	comment	1.2.3	Snippets can now be moved by dragging them.	2025-05-21 12:56:04
346	Winter.Pages	comment	1.2.4	Fixes a bug where the cursor is misplaced when editing text files.	2025-05-21 12:56:04
347	Winter.Pages	comment	1.2.5	Fixes a bug where the parent page is lost upon changing a page layout.	2025-05-21 12:56:04
348	Winter.Pages	comment	1.2.6	Shared view variables are now passed to static pages.	2025-05-21 12:56:04
349	Winter.Pages	comment	1.2.7	Fixes issue with duplicating properties when adding multiple snippets on the same page.	2025-05-21 12:56:04
350	Winter.Pages	comment	1.2.8	Fixes a bug where creating a content block without extension doesn't save the contents to file.	2025-05-21 12:56:04
351	Winter.Pages	comment	1.2.9	Add conditional support for translating page URLs.	2025-05-21 12:56:04
352	Winter.Pages	comment	1.2.10	Streamline generation of URLs to use the new Cms::url helper.	2025-05-21 12:56:04
353	Winter.Pages	comment	1.2.11	Implements repeater usage with translate plugin.	2025-05-21 12:56:04
354	Winter.Pages	comment	1.2.12	Fixes minor issue when using snippets and switching the application locale.	2025-05-21 12:56:04
355	Winter.Pages	comment	1.2.13	Fixes bug when AJAX is used on a page that does not yet exist.	2025-05-21 12:56:04
356	Winter.Pages	comment	1.2.14	Add theme logging support for changes made to menus.	2025-05-21 12:56:05
357	Winter.Pages	comment	1.2.15	Back-end navigation sort order updated.	2025-05-21 12:56:05
358	Winter.Pages	comment	1.2.16	Fixes a bug when saving a template that has been modified outside of the CMS (mtime mismatch).	2025-05-21 12:56:05
359	Winter.Pages	comment	1.2.17	Changes locations of custom fields to secondary tabs instead of the primary Settings area. New menu search ability on adding menu items	2025-05-21 12:56:05
360	Winter.Pages	comment	1.2.18	Fixes cache-invalidation issues when Winter.Translate is not installed. Added Greek & Simplified Chinese translations. Removed deprecated calls. Allowed saving HTML in snippet properties. Added support for the MediaFinder in menu items.	2025-05-21 12:56:05
361	Winter.Pages	comment	1.2.19	Catch exception with corrupted menu file.	2025-05-21 12:56:05
362	Winter.Pages	comment	1.2.20	StaticMenu component now exposes menuName property; added pages.menu.referencesGenerated event.	2025-05-21 12:56:05
363	Winter.Pages	comment	1.2.21	Fixes a bug where last Static Menu item cannot be deleted. Improved Persian, Slovak and Turkish translations.	2025-05-21 12:56:05
364	Winter.Pages	comment	1.3.0	Added support for using Database-driven Themes when enabled in the CMS configuration.	2025-05-21 12:56:05
365	Winter.Pages	comment	1.3.1	Added ChildPages Component, prevent hidden pages from being returned via menu item resolver.	2025-05-21 12:56:05
366	Winter.Pages	comment	1.3.2	Fixes error when creating a subpage whose parent has no layout set.	2025-05-21 12:56:05
367	Winter.Pages	comment	1.3.3	Improves user experience for users with only partial access through permissions	2025-05-21 12:56:05
368	Winter.Pages	comment	1.3.4	Fix error where large menus were being truncated due to the PHP "max_input_vars" configuration value. Improved Slovenian translation.	2025-05-21 12:56:05
369	Winter.Pages	comment	1.3.5	Minor fix to bust the browser cache for JS assets. Prevent duplicate property fields in snippet inspector.	2025-05-21 12:56:05
370	Winter.Pages	comment	1.3.6	ChildPages component now displays localized page titles from Translate plugin.	2025-05-21 12:56:05
371	Winter.Pages	comment	1.3.7	Improved page loading performance, added MenuPicker formwidget, added pages.snippets.listSnippets	2025-05-21 12:56:05
372	Winter.Pages	comment	1.4.0	Fixes bug when adding menu items in October CMS v2.0.	2025-05-21 12:56:05
373	Winter.Pages	comment	1.4.1	Fixes support for configuration values.	2025-05-21 12:56:05
374	Winter.Pages	comment	1.4.3	Fixes page deletion in newer platform builds.	2025-05-21 12:56:05
375	Winter.Pages	comment	2.0.0	Rebrand to Winter.Pages	2025-05-21 12:56:05
376	Winter.Pages	comment	2.0.1	Fixes rich editor usage inside repeaters.	2025-05-21 12:56:05
377	Winter.Pages	comment	2.0.1	Fixes a lifecycle issue when switching the page layout.	2025-05-21 12:56:05
378	Winter.Pages	comment	2.0.1	Fixes maintenance mode when using static pages.	2025-05-21 12:56:05
379	Winter.Pages	comment	2.0.2	Add support for Winter 1.2	2025-05-21 12:56:05
380	Winter.Pages	comment	2.0.3	Fixed issue with Primary Tabs losing min-size class	2025-05-21 12:56:05
381	Winter.Pages	comment	2.0.3	Added Vietnamese translation	2025-05-21 12:56:05
382	Winter.Pages	comment	2.0.3	Fixed issue where subpages of home would get 2 slashes	2025-05-21 12:56:05
383	Winter.Pages	comment	2.0.3	Fixed issue where allowed IPs couldn't access pages in maintenance mode	2025-05-21 12:56:05
384	Winter.Pages	comment	2.0.3	Improved Swedish translation	2025-05-21 12:56:05
385	Winter.Pages	comment	2.1.0	Added support for live previews of the frontend-rendered pages	2025-05-21 12:56:05
386	Winter.Pages	comment	2.1.1	Improved French translation	2025-05-21 12:56:05
387	Winter.Pages	comment	2.1.2	Added support for multilingual sitemap URLs	2025-05-21 12:56:05
388	Winter.Pages	comment	2.1.2	Fixed support for Winter.Translate	2025-05-21 12:56:05
389	Winter.Pages	comment	2.1.2	Collapse all pages in the backend list of pages by default	2025-05-21 12:56:05
390	Winter.Pages	comment	2.1.3	Added Duplicate button	2025-05-21 12:56:05
391	Winter.Pages	comment	2.1.4	Fix support for snippets in the default backend skin	2025-05-21 12:56:05
392	Winter.Pages	comment	2.1.5	Fixes issue where translated page content was not duplicated when duplicating a page	2025-05-21 12:56:05
393	Winter.Pages	comment	2.1.5	Fixes issue where the modified page counter was not working when updating a duplicated page	2025-05-21 12:56:05
394	Winter.Pages	comment	2.1.5	Made the MenuItems FormWidget more flexible	2025-05-21 12:56:05
395	Winter.Pages	comment	2.1.5	Apply Winter Coding Standards	2025-05-21 12:56:05
396	Winter.Pages	comment	2.1.5	Fixed issue caused by saving content before closing open snippet inspectors	2025-05-21 12:56:05
397	Winter.Pages	comment	2.1.5	Improved support for snippets defined in partials	2025-05-21 12:56:05
\.


--
-- Data for Name: system_plugin_versions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_plugin_versions (id, code, version, created_at, is_disabled, is_frozen, acorn_infrastructure) FROM stdin;
11	Acorn.University	1.0.0	2025-04-03 12:27:46	f	f	f
12	Acorn.Exam	1.0.0	2025-04-08 18:24:18	f	f	f
6	Acorn.BackendLocalization	1.0.0	2025-04-03 07:43:13	f	f	f
10	Acorn.Calendar	2.0.1	2025-04-03 07:43:15	f	f	f
3	Winter.Location	2.0.2	2025-04-03 07:43:09	f	f	f
4	Winter.TailwindUI	1.0.1	2025-04-03 07:43:09	f	f	f
1	Winter.Demo	1.0.1	2025-04-03 07:39:25	t	f	f
5	Winter.Translate	2.1.6	2025-04-23 11:38:27	f	f	f
7	Acorn.Location	4.0.0	2025-04-03 07:43:13	f	f	t
8	Acorn.Messaging	2.0.0	2025-04-03 07:43:14	f	f	t
9	Acorn.Reporting	1.0.1	2025-04-03 07:43:14	f	f	t
2	Acorn.User	3.0.2	2025-04-03 07:42:59	f	f	t
13	Winter.Debugbar	4.0.5	2025-04-23 11:38:27	f	f	f
14	Winter.Pages	2.1.5	2025-05-21 12:56:05	f	f	f
\.


--
-- Data for Name: system_request_logs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_request_logs (id, status_code, url, referer, count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_revisions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_revisions (id, user_id, field, "cast", old_value, new_value, revisionable_type, revisionable_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_settings (id, item, value) FROM stdin;
1	backend_brand_settings	{"app_name":"University","app_tagline":"Building free life","primary_color":"#34495e","secondary_color":"#e67e22","accent_color":"#3498db","default_colors":[{"color":"#1abc9c"},{"color":"#16a085"},{"color":"#2ecc71"},{"color":"#27ae60"},{"color":"#3498db"},{"color":"#2980b9"},{"color":"#9b59b6"},{"color":"#8e44ad"},{"color":"#34495e"},{"color":"#2b3e50"},{"color":"#f1c40f"},{"color":"#f39c12"},{"color":"#e67e22"},{"color":"#d35400"},{"color":"#e74c3c"},{"color":"#c0392b"},{"color":"#ecf0f1"},{"color":"#bdc3c7"},{"color":"#95a5a6"},{"color":"#7f8c8d"}],"menu_mode":"inline","auth_layout":"split","menu_location":"top","icon_location":"inline","custom_css":".list-cell-type-partial > .multi span.delimeter:nth-child(2),\\n.list-cell-type-partial > .multi span.academic-year:nth-child(7),\\n.list-cell-type-partial > .multi span.delimeter:nth-child(6),\\n.list-cell-type-partial > .multi span.academic-year:nth-child(11),\\n.list-cell-type-partial > .multi span.delimeter:nth-child(10),\\n.list-cell-type-partial > .multi span.academic-year:nth-child(15),\\n.list-cell-type-partial > .multi span.delimeter:nth-child(14),\\n.list-cell-type-partial > .multi span.academic-year:nth-child(19),\\n.list-cell-type-partial > .multi span.delimeter:nth-child(18),\\n.list-cell-type-partial > .multi span.academic-year:nth-child(23),\\n.list-cell-type-partial > .multi span.delimeter:nth-child(22)\\n{\\n  display:none;\\n}\\n.list-cell-type-partial > .multi span.academic-year:nth-child(3):before\\n{\\n  content: ' (';\\n}\\n.list-cell-type-partial > .multi span.academic-year:nth-child(3):after\\n{\\n  content: ') ';\\n}\\n.list-cell-type-partial > .multi span.current {\\n  font-weight: bold;\\n  color: #444;\\n}\\n.list-cell-name-academic_year.list-cell-type-partial.tablet > span.current {\\n  background-color: #777;\\n}\\n.list-cell-type-partial > .multi.hierarchy .delimeter:after {\\n  content: ' >> ';\\n  font-weight: bold;\\n  font-size: 10px;\\n  vertical-align: top;\\n}\\n.list-cell-type-partial > .multi.hierarchy .delimeter {\\n  width: 0px;\\n  font-size: 0px;\\n}"}
\.


--
-- Data for Name: winter_location_countries; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_location_countries (id, is_enabled, name, code, is_pinned) FROM stdin;
5	f	Afghanistan	AF	f
6	f	Aland Islands 	AX	f
7	f	Albania	AL	f
8	f	Algeria	DZ	f
9	f	American Samoa	AS	f
10	f	Andorra	AD	f
11	f	Angola	AO	f
12	f	Anguilla	AI	f
13	f	Antarctica	AQ	f
14	f	Antigua and Barbuda	AG	f
15	f	Argentina	AR	f
16	f	Armenia	AM	f
17	f	Aruba	AW	f
18	f	Austria	AT	f
19	f	Azerbaijan	AZ	f
20	f	Bahamas	BS	f
21	f	Bahrain	BH	f
22	f	Bangladesh	BD	f
23	f	Barbados	BB	f
24	f	Belarus	BY	f
25	f	Belgium	BE	f
26	f	Belize	BZ	f
27	f	Benin	BJ	f
28	f	Bermuda	BM	f
29	f	Bhutan	BT	f
30	f	Bolivia, Plurinational State of	BO	f
31	f	Bonaire, Sint Eustatius and Saba	BQ	f
32	f	Bosnia and Herzegovina	BA	f
33	f	Botswana	BW	f
34	f	Bouvet Island	BV	f
35	f	Brazil	BR	f
36	f	British Indian Ocean Territory	IO	f
37	f	Brunei Darussalam	BN	f
38	f	Bulgaria	BG	f
39	f	Burkina Faso	BF	f
40	f	Burundi	BI	f
41	f	Cambodia	KH	f
42	f	Cameroon	CM	f
43	f	Cape Verde	CV	f
44	f	Cayman Islands	KY	f
45	f	Central African Republic	CF	f
46	f	Chad	TD	f
47	f	Chile	CL	f
48	f	China	CN	f
49	f	Christmas Island	CX	f
50	f	Cocos (Keeling) Islands	CC	f
51	f	Colombia	CO	f
52	f	Comoros	KM	f
53	f	Congo	CG	f
54	f	Congo, the Democratic Republic of the	CD	f
55	f	Cook Islands	CK	f
56	f	Costa Rica	CR	f
57	f	Cote d'Ivoire	CI	f
58	f	Croatia	HR	f
59	f	Cuba	CU	f
60	f	Curaçao	CW	f
61	f	Cyprus	CY	f
62	f	Czech Republic	CZ	f
63	f	Denmark	DK	f
64	f	Djibouti	DJ	f
65	f	Dominica	DM	f
66	f	Dominican Republic	DO	f
67	f	Ecuador	EC	f
68	f	Egypt	EG	f
69	f	El Salvador	SV	f
70	f	Equatorial Guinea	GQ	f
71	f	Eritrea	ER	f
72	f	Estonia	EE	f
73	f	Ethiopia	ET	f
74	f	Falkland Islands (Malvinas)	FK	f
75	f	Faroe Islands	FO	f
76	f	Finland	FI	f
77	f	Fiji	FJ	f
78	t	France	FR	f
79	f	French Guiana	GF	f
80	f	French Polynesia	PF	f
81	f	French Southern Territories	TF	f
82	f	Gabon	GA	f
83	f	Gambia	GM	f
84	f	Georgia	GE	f
85	f	Germany	DE	f
86	f	Ghana	GH	f
87	f	Gibraltar	GI	f
88	f	Greece	GR	f
89	f	Greenland	GL	f
90	f	Grenada	GD	f
91	f	Guadeloupe	GP	f
92	f	Guam	GU	f
93	f	Guatemala	GT	f
94	f	Guernsey	GG	f
95	f	Guinea	GN	f
96	f	Guinea-Bissau	GW	f
97	f	Guyana	GY	f
98	f	Haiti	HT	f
99	f	Heard Island and McDonald Islands	HM	f
100	f	Holy See (Vatican City State)	VA	f
101	f	Honduras	HN	f
102	f	Hong Kong	HK	f
103	t	Hungary	HU	f
104	f	Iceland	IS	f
105	t	India	IN	f
106	f	Indonesia	ID	f
107	f	Iran, Islamic Republic of	IR	f
108	f	Iraq	IQ	f
109	t	Ireland	IE	f
110	f	Isle of Man	IM	f
111	f	Israel	IL	f
112	f	Italy	IT	f
113	f	Jamaica	JM	f
114	f	Japan	JP	f
115	f	Jersey	JE	f
116	f	Jordan	JO	f
117	f	Kazakhstan	KZ	f
118	f	Kenya	KE	f
119	f	Kiribati	KI	f
120	f	Korea, Democratic People's Republic of	KP	f
121	f	Korea, Republic of	KR	f
122	f	Kuwait	KW	f
123	f	Kyrgyzstan	KG	f
124	f	Lao People's Democratic Republic	LA	f
125	f	Latvia	LV	f
126	f	Lebanon	LB	f
127	f	Lesotho	LS	f
128	f	Liberia	LR	f
129	f	Libyan Arab Jamahiriya	LY	f
130	f	Liechtenstein	LI	f
131	f	Lithuania	LT	f
132	f	Luxembourg	LU	f
133	f	Macao	MO	f
134	f	Macedonia	MK	f
135	f	Madagascar	MG	f
136	f	Malawi	MW	f
137	f	Malaysia	MY	f
138	f	Maldives	MV	f
139	f	Mali	ML	f
140	f	Malta	MT	f
141	f	Marshall Islands	MH	f
142	f	Martinique	MQ	f
143	f	Mauritania	MR	f
144	f	Mauritius	MU	f
145	f	Mayotte	YT	f
146	f	Mexico	MX	f
147	f	Micronesia, Federated States of	FM	f
148	f	Moldova, Republic of	MD	f
149	f	Monaco	MC	f
150	f	Mongolia	MN	f
151	f	Montenegro	ME	f
152	f	Montserrat	MS	f
153	f	Morocco	MA	f
154	f	Mozambique	MZ	f
155	f	Myanmar	MM	f
156	f	Namibia	NA	f
157	f	Nauru	NR	f
158	f	Nepal	NP	f
159	t	Netherlands	NL	f
160	f	New Caledonia	NC	f
161	t	New Zealand	NZ	f
2	t	Canada	CA	t
162	f	Nicaragua	NI	f
163	f	Niger	NE	f
164	f	Nigeria	NG	f
165	f	Niue	NU	f
166	f	Norfolk Island	NF	f
167	f	Northern Mariana Islands	MP	f
168	f	Norway	NO	f
169	f	Oman	OM	f
170	f	Pakistan	PK	f
171	f	Palau	PW	f
172	f	Palestine	PS	f
173	f	Panama	PA	f
174	f	Papua New Guinea	PG	f
175	f	Paraguay	PY	f
176	f	Peru	PE	f
177	f	Philippines	PH	f
178	f	Pitcairn	PN	f
179	f	Poland	PL	f
180	f	Portugal	PT	f
181	f	Puerto Rico	PR	f
182	f	Qatar	QA	f
183	f	Reunion	RE	f
184	t	Romania	RO	f
185	f	Russian Federation	RU	f
186	f	Rwanda	RW	f
187	f	Saint Barthélemy	BL	f
188	f	Saint Helena	SH	f
189	f	Saint Kitts and Nevis	KN	f
190	f	Saint Lucia	LC	f
191	f	Saint Martin (French part)	MF	f
192	f	Saint Pierre and Miquelon	PM	f
193	f	Saint Vincent and the Grenadines	VC	f
194	f	Samoa	WS	f
195	f	San Marino	SM	f
196	f	Sao Tome and Principe	ST	f
197	f	Saudi Arabia	SA	f
198	f	Senegal	SN	f
199	f	Serbia	RS	f
200	f	Seychelles	SC	f
201	f	Sierra Leone	SL	f
202	f	Singapore	SG	f
203	f	Sint Maarten (Dutch part)	SX	f
204	f	Slovakia	SK	f
205	f	Slovenia	SI	f
206	f	Solomon Islands	SB	f
207	f	Somalia	SO	f
208	f	South Africa	ZA	f
209	f	South Georgia and the South Sandwich Islands	GS	f
210	t	Spain	ES	f
211	f	Sri Lanka	LK	f
212	f	Sudan	SD	f
213	f	Suriname	SR	f
214	f	Svalbard and Jan Mayen	SJ	f
215	f	Swaziland	SZ	f
216	f	Sweden	SE	f
217	f	Switzerland	CH	f
218	f	Syrian Arab Republic	SY	f
219	f	Taiwan, Province of China	TW	f
220	f	Tajikistan	TJ	f
221	f	Tanzania, United Republic of	TZ	f
222	f	Thailand	TH	f
223	f	Timor-Leste	TL	f
224	f	Togo	TG	f
225	f	Tokelau	TK	f
226	f	Tonga	TO	f
227	f	Trinidad and Tobago	TT	f
228	f	Tunisia	TN	f
229	f	Turkey	TR	f
230	f	Turkmenistan	TM	f
231	f	Turks and Caicos Islands	TC	f
232	f	Tuvalu	TV	f
233	f	Uganda	UG	f
234	f	Ukraine	UA	f
235	f	United Arab Emirates	AE	f
236	f	United States Minor Outlying Islands	UM	f
237	f	Uruguay	UY	f
238	f	Uzbekistan	UZ	f
239	f	Vanuatu	VU	f
240	f	Venezuela, Bolivarian Republic of	VE	f
241	f	Viet Nam	VN	f
242	f	Virgin Islands, British	VG	f
243	f	Virgin Islands, U.S.	VI	f
244	f	Wallis and Futuna	WF	f
245	f	Western Sahara	EH	f
246	f	Yemen	YE	f
247	f	Zambia	ZM	f
248	f	Zimbabwe	ZW	f
1	t	Australia	AU	t
3	t	United Kingdom	GB	t
4	t	United States	US	t
\.


--
-- Data for Name: winter_location_states; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_location_states (id, country_id, name, code, is_enabled) FROM stdin;
1	4	Alabama	AL	t
2	4	Alaska	AK	t
3	4	American Samoa	AS	t
4	4	Arizona	AZ	t
5	4	Arkansas	AR	t
6	4	California	CA	t
7	4	Colorado	CO	t
8	4	Connecticut	CT	t
9	4	Delaware	DE	t
10	4	Dist. of Columbia	DC	t
11	4	Florida	FL	t
12	4	Georgia	GA	t
13	4	Guam	GU	t
14	4	Hawaii	HI	t
15	4	Idaho	ID	t
16	4	Illinois	IL	t
17	4	Indiana	IN	t
18	4	Iowa	IA	t
19	4	Kansas	KS	t
20	4	Kentucky	KY	t
21	4	Louisiana	LA	t
22	4	Maine	ME	t
23	4	Maryland	MD	t
24	4	Marshall Islands	MH	t
25	4	Massachusetts	MA	t
26	4	Michigan	MI	t
27	4	Micronesia	FM	t
28	4	Minnesota	MN	t
29	4	Mississippi	MS	t
30	4	Missouri	MO	t
31	4	Montana	MT	t
32	4	Nebraska	NE	t
33	4	Nevada	NV	t
34	4	New Hampshire	NH	t
35	4	New Jersey	NJ	t
36	4	New Mexico	NM	t
37	4	New York	NY	t
38	4	North Carolina	NC	t
39	4	North Dakota	ND	t
40	4	Northern Marianas	MP	t
41	4	Ohio	OH	t
42	4	Oklahoma	OK	t
43	4	Oregon	OR	t
44	4	Palau	PW	t
45	4	Pennsylvania	PA	t
46	4	Puerto Rico	PR	t
47	4	Rhode Island	RI	t
48	4	South Carolina	SC	t
49	4	South Dakota	SD	t
50	4	Tennessee	TN	t
51	4	Texas	TX	t
52	4	Utah	UT	t
53	4	Vermont	VT	t
54	4	Virginia	VA	t
55	4	Virgin Islands	VI	t
56	4	Washington	WA	t
57	4	West Virginia	WV	t
58	4	Wisconsin	WI	t
59	4	Wyoming	WY	t
60	35	Acre	AC	t
61	35	Alagoas	AL	t
62	35	Amapá	AP	t
63	35	Amazonas	AM	t
64	35	Bahia	BA	t
65	35	Ceará	CE	t
66	35	Distrito Federal	DF	t
67	35	Espírito Santo	ES	t
68	35	Goiás	GO	t
69	35	Maranhão	MA	t
70	35	Mato Grosso	MT	t
71	35	Mato Grosso do Sul	MS	t
72	35	Minas Gerais	MG	t
73	35	Pará	PA	t
74	35	Paraíba	PB	t
75	35	Paraná	PR	t
76	35	Pernambuco	PE	t
77	35	Piauí	PI	t
78	35	Rio de Janeiro	RJ	t
79	35	Rio Grande do Norte	RN	t
80	35	Rio Grande do Sul	RS	t
81	35	Rondônia	RO	t
82	35	Roraima	RR	t
83	35	Santa Catarina	SC	t
84	35	São Paulo	SP	t
85	35	Sergipe	SE	t
86	35	Tocantins	TO	t
87	2	Alberta	AB	t
88	2	British Columbia	BC	t
89	2	Manitoba	MB	t
90	2	New Brunswick	NB	t
91	2	Newfoundland and Labrador	NL	t
92	2	Northwest Territories	NT	t
93	2	Nova Scotia	NS	t
94	2	Nunavut	NU	t
95	2	Ontario	ON	t
96	2	Prince Edward Island	PE	t
97	2	Quebec	QC	t
98	2	Saskatchewan	SK	t
99	2	Yukon	YT	t
100	217	Aargau	AG	t
101	217	Appenzell Innerrhoden	AI	t
102	217	Appenzell Ausserrhoden	AR	t
103	217	Bern	BE	t
104	217	Basel-Landschaft	BL	t
105	217	Basel-Stadt	BS	t
106	217	Fribourg	FR	t
107	217	Genève	GE	t
108	217	Glarus	GL	t
109	217	Graubünden	GR	t
110	217	Jura	JU	t
111	217	Luzern	LU	t
112	217	Neuchâtel	NE	t
113	217	Nidwalden	NW	t
114	217	Obwalden	OW	t
115	217	St. Gallen	SG	t
116	217	Solothurn	SO	t
117	217	Schwyz	SZ	t
118	217	Thurgau	TG	t
119	217	Ticino	TI	t
120	217	Uri	UR	t
121	217	Vaud	VD	t
122	217	Valais	VS	t
123	217	Zug	ZG	t
124	217	Zürich	ZH	t
125	1	New South Wales	NSW	t
126	1	Queensland	QLD	t
127	1	South Australia	SA	t
128	1	Tasmania	TAS	t
129	1	Victoria	VIC	t
130	1	Western Australia	WA	t
131	1	Northern Territory	NT	t
132	1	Australian Capital Territory	ACT	t
133	85	Baden-Württemberg	BW	t
134	85	Bayern	BY	t
135	85	Berlin	BE	t
136	85	Brandenburg	BB	t
137	85	Bremen	HB	t
138	85	Hamburg	HH	t
139	85	Hessen	HE	t
140	85	Mecklenburg-Vorpommern	MV	t
141	85	Niedersachsen	NI	t
142	85	Nordrhein-Westfalen	NW	t
143	85	Rheinland-Pfalz	RP	t
144	85	Saarland	SL	t
145	85	Sachsen	SN	t
146	85	Sachsen-Anhalt	ST	t
147	85	Schleswig-Holstein	SH	t
148	85	Thüringen	TH	t
149	72	Harju	HA	t
150	72	Hiiu	HI	t
151	72	Ida-Viru	IV	t
152	72	Jõgeva	JR	t
153	72	Järva	JN	t
154	72	Lääne	LN	t
155	72	Lääne-Viru	LV	t
156	72	Põlva	PL	t
157	72	Pärnu	PR	t
158	72	Rapla	RA	t
159	72	Saare	SA	t
160	72	Tartu	TA	t
161	72	Valga	VG	t
162	72	Viljandi	VD	t
163	72	Võru	VR	t
164	109	Dublin	D	t
165	109	Wicklow	WW	t
166	109	Wexford	WX	t
167	109	Carlow	CW	t
168	109	Kildare	KE	t
169	109	Meath	MH	t
170	109	Louth	LH	t
171	109	Monaghan	MN	t
172	109	Cavan	CN	t
173	109	Longford	LD	t
174	109	Westmeath	WH	t
175	109	Offaly	OY	t
176	109	Laois	LS	t
177	109	Kilkenny	KK	t
178	109	Waterford	WD	t
179	109	Cork	C	t
180	109	Kerry	KY	t
181	109	Limerick	LK	t
182	109	North Tipperary	TN	t
183	109	South Tipperary	TS	t
184	109	Clare	CE	t
185	109	Galway	G	t
186	109	Mayo	MO	t
187	109	Roscommon	RN	t
188	109	Sligo	SO	t
189	109	Leitrim	LM	t
190	109	Donegal	DL	t
191	159	Drenthe	DR	t
192	159	Flevoland	FL	t
193	159	Friesland	FR	t
194	159	Gelderland	GE	t
195	159	Groningen	GR	t
196	159	Limburg	LI	t
197	159	Noord-Brabant	NB	t
198	159	Noord-Holland	NH	t
199	159	Overijssel	OV	t
200	159	Utrecht	UT	t
201	159	Zeeland	ZE	t
202	159	Zuid-Holland	ZH	t
203	3	Aberdeenshire	ABE	t
204	3	Anglesey	ALY	t
205	3	Angus	ANG	t
206	3	Argyll	ARG	t
207	3	Ayrshire	AYR	t
208	3	Banffshire	BAN	t
209	3	Bedfordshire	BED	t
210	3	Berkshire	BER	t
211	3	Berwickshire	BWS	t
212	3	Brecknockshire	BRE	t
213	3	Buckinghamshire	BUC	t
214	3	Bute	BUT	t
215	3	Caernarfonshire	CAE	t
216	3	Caithness	CAI	t
217	3	Cambridgeshire	CAM	t
218	3	Cardiganshire	CAR	t
219	3	Carmarthenshire	CMS	t
220	3	Cheshire	CHE	t
221	3	Clackmannanshire	CLA	t
222	3	Cleveland	CLE	t
223	3	Cornwall	COR	t
224	3	Cromartyshire	CRO	t
225	3	Cumberland	CBR	t
226	3	Cumbria	CUM	t
227	3	Denbighshire	DEN	t
228	3	Derbyshire	DER	t
229	3	Devon	DEV	t
230	3	Dorset	DOR	t
231	3	Dumbartonshire	DBS	t
232	3	Dumfriesshire	DUM	t
233	3	Durham	DUR	t
234	3	East Lothian	ELO	t
235	3	Essex	ESS	t
236	3	Flintshire	FLI	t
237	3	Fife	FIF	t
238	3	Glamorgan	GLA	t
239	3	Gloucestershire	GLO	t
240	3	Hampshire	HAM	t
241	3	Herefordshire	HER	t
242	3	Hertfordshire	HTF	t
243	3	Huntingdonshire	HUN	t
244	3	Inverness	INV	t
245	3	Kent	KEN	t
246	3	Kincardineshire	KCD	t
247	3	Kinross-shire	KIN	t
248	3	Kirkcudbrightshire	KIR	t
249	3	Lanarkshire	LKS	t
250	3	Lancashire	LAN	t
251	3	Leicestershire	LEI	t
252	3	Lincolnshire	LIN	t
253	3	London	LON	t
254	3	Manchester	MAN	t
255	3	Merionethshire	MER	t
256	3	Merseyside	MSY	t
257	3	Middlesex	MDX	t
258	3	Midlands	MID	t
259	3	Midlothian	MLT	t
260	3	Monmouthshire	MON	t
261	3	Montgomeryshire	MGY	t
262	3	Moray	MOR	t
263	3	Nairnshire	NAI	t
264	3	Norfolk	NOR	t
265	3	Northamptonshire	NMP	t
266	3	Northumberland	NUM	t
267	3	Nottinghamshire	NOT	t
268	3	Orkney	ORK	t
269	3	Oxfordshire	OXF	t
270	3	Peebleshire	PEE	t
271	3	Pembrokeshire	PEM	t
272	3	Perthshire	PER	t
273	3	Radnorshire	RAD	t
274	3	Renfrewshire	REN	t
275	3	Ross & Cromarty	ROS	t
276	3	Roxburghshire	ROX	t
277	3	Rutland	RUT	t
278	3	Selkirkshire	SEL	t
279	3	Shetland	SHE	t
280	3	Shropshire	SHR	t
281	3	Somerset	SOM	t
282	3	Staffordshire	STA	t
283	3	Stirlingshire	STI	t
284	3	Suffolk	SUF	t
285	3	Surrey	SUR	t
286	3	Sussex	SUS	t
287	3	Sutherland	SUT	t
288	3	Tyne & Wear	TYN	t
289	3	Warwickshire	WAR	t
290	3	West Lothian	WLO	t
291	3	Westmorland	WES	t
292	3	Wigtownshire	WIG	t
293	3	Wiltshire	WIL	t
294	3	Worcestershire	WOR	t
295	3	Yorkshire	YOR	t
296	184	Alba	AB	t
297	184	Arad	AR	t
298	184	Arges	AG	t
299	184	Bacău	BC	t
300	184	Bihor	BH	t
301	184	Bistrita - Nasaud Bistrita	BN	t
302	184	Botosani	BT	t
303	184	Brasov	BV	t
304	184	Braila	BR	t
305	184	Bucuresti	B	t
306	184	Buzau	BZ	t
307	184	Caras - Severin	CS	t
308	184	Calarasi	CL	t
309	184	Cluj	CJ	t
310	184	Constanta	CT	t
311	184	Covasna Sfantu Gheorghe	CV	t
312	184	Dambovita	DB	t
313	184	Dolj	DJ	t
314	184	Galati	GL	t
315	184	Giurgiu	GR	t
316	184	Gorj	GJ	t
317	184	Harghita	HR	t
318	184	Hunedoara	HD	t
319	184	Ialomita	IL	t
320	184	Iasi	IS	t
321	184	Ilfov	IF	t
322	184	Maramures	MM	t
323	184	Mehedinti	MH	t
324	184	Mures	MS	t
325	184	Neamt	NT	t
326	184	Olt	OT	t
327	184	Prahova Ploiesti	PH	t
328	184	Satu Mare	SM	t
329	184	Salaj	SJ	t
330	184	Sibiu	SB	t
331	184	Suceava	SV	t
332	184	Teleorman	TR	t
333	184	Timis	TM	t
334	184	Tulcea	TL	t
335	184	Vaslui	VS	t
336	184	Valcea	VL	t
337	184	Vrancea	VN	t
338	103	Budapest	BUD	t
339	103	Baranya	BAR	t
340	103	Bács-Kiskun	BKM	t
341	103	Békés	BEK	t
342	103	Borsod-Abaúj-Zemplén	BAZ	t
343	103	Csongrád	CSO	t
344	103	Fejér	FEJ	t
345	103	Győr-Moson-Sopron	GMS	t
346	103	Hajdú-Bihar	HBM	t
347	103	Heves	HEV	t
348	103	Jász-Nagykun-Szolnok	JNS	t
349	103	Komárom-Esztergom	KEM	t
350	103	Nógrád	NOG	t
351	103	Pest	PES	t
352	103	Somogy	SOM	t
353	103	Szabolcs-Szatmár-Bereg	SSB	t
354	103	Tolna	TOL	t
355	103	Vas	VAS	t
356	103	Veszprém	VES	t
357	103	Zala	ZAL	t
358	105	Andhra Pradesh	AP	t
359	105	Arunachal Pradesh	AR	t
360	105	Assam	AS	t
361	105	Bihar	BR	t
362	105	Chhattisgarh	CT	t
363	105	Goa	GA	t
364	105	Gujarat	GJ	t
365	105	Haryana	HR	t
366	105	Himachal Pradesh	HP	t
367	105	Jammu and Kashmir	JK	t
368	105	Jharkhand	JH	t
369	105	Karnataka	KA	t
370	105	Kerala	KL	t
371	105	Madhya Pradesh	MP	t
372	105	Maharashtra	MH	t
373	105	Manipur	MN	t
374	105	Meghalaya	ML	t
375	105	Mizoram	MZ	t
376	105	Nagaland	NL	t
377	105	Odisha	OR	t
378	105	Punjab	PB	t
379	105	Rajasthan	RJ	t
380	105	Sikkim	SK	t
381	105	Tamil Nadu	TN	t
382	105	Telangana	TG	t
383	105	Tripura	TR	t
384	105	Uttarakhand	UT	t
385	105	Uttar Pradesh	UP	t
386	105	West Bengal	WB	t
387	105	Andaman and Nicobar Islands	AN	t
388	105	Chandigarh	CH	t
389	105	Dadra and Nagar Haveli	DN	t
390	105	Daman and Diu	DD	t
391	105	Delhi	DL	t
392	105	Lakshadweep	LD	t
393	105	Puducherry	PY	t
394	78	Auvergne-Rhône-Alpes	ARA	t
395	78	Bourgogne-Franche-Comté	BFC	t
396	78	Bretagne	BZH	t
397	78	Centre–Val-de-Loire	CVL	t
398	78	Corse	COR	t
399	78	Guadeloupe	GP	t
400	78	Guyane	GF	t
401	78	Grand-Est	GE	t
402	78	Hauts-de-France	HF	t
403	78	Île-de-France	IDF	t
404	78	Martinique	MQ	t
405	78	Mayotte	YT	t
406	78	Normandie	NOR	t
407	78	Pays-de-la-Loire	PL	t
408	78	Nouvelle-Aquitaine	NA	t
409	78	Occitanie	OCC	t
410	78	Provence-Alpes-Côte-d'Azur	PACA	t
411	78	Réunion	RE	t
412	161	Northland	NTL	t
413	161	Auckland	AUK	t
414	161	Waikato	WKO	t
415	161	Bay of Plenty	BOP	t
416	161	Gisborne	GIS	t
417	161	Hawke's Bay	HKB	t
418	161	Taranaki	TKI	t
419	161	Manawatu-Wanganui	MWT	t
420	161	Wellington	WGN	t
421	161	Tasman	TAS	t
422	161	Nelson	NSN	t
423	161	Marlborough	MBH	t
424	161	West Coast	WTC	t
425	161	Canterbury	CAN	t
426	161	Otago Otago	OTA	t
427	161	Southland	STL	t
428	210	A Coruña (gl) [La Coruña]	ES-C	t
429	210	Araba (eu)	ES-VI	t
430	210	Albacete	ES-AB	t
431	210	Alacant (ca)	ES-A	t
432	210	Almería	ES-AL	t
433	210	Asturias	ES-O	t
434	210	Ávila	ES-AV	t
435	210	Badajoz	ES-BA	t
436	210	Balears (ca) [Baleares]	ES-PM	t
437	210	Barcelona [Barcelona]	ES-B	t
438	210	Burgos	ES-BU	t
439	210	Cáceres	ES-CC	t
440	210	Cádiz	ES-CA	t
441	210	Cantabria	ES-S	t
442	210	Castelló (ca)	ES-CS	t
443	210	Ciudad Real	ES-CR	t
444	210	Córdoba	ES-CO	t
445	210	Cuenca	ES-CU	t
446	210	Girona (ca) [Gerona]	ES-GI	t
447	210	Granada	ES-GR	t
448	210	Guadalajara	ES-GU	t
449	210	Gipuzkoa (eu)	ES-SS	t
450	210	Huelva	ES-H	t
451	210	Huesca	ES-HU	t
452	210	Jaén	ES-J	t
453	210	La Rioja	ES-LO	t
454	210	Las Palmas	ES-GC	t
455	210	León	ES-LE	t
456	210	Lleida (ca) [Lérida]	ES-L	t
457	210	Lugo (gl) [Lugo]	ES-LU	t
458	210	Madrid	ES-M	t
459	210	Málaga	ES-MA	t
460	210	Murcia	ES-MU	t
461	210	Nafarroa (eu)	ES-NA	t
462	210	Ourense (gl) [Orense]	ES-OR	t
463	210	Palencia	ES-P	t
464	210	Pontevedra (gl) [Pontevedra]	ES-PO	t
465	210	Salamanca	ES-SA	t
466	210	Santa Cruz de Tenerife	ES-TF	t
467	210	Segovia	ES-SG	t
468	210	Sevilla	ES-SE	t
469	210	Soria	ES-SO	t
470	210	Tarragona (ca) [Tarragona]	ES-T	t
471	210	Teruel	ES-TE	t
472	210	Toledo	ES-TO	t
473	210	València (ca)	ES-V	t
474	210	Valladolid	ES-VA	t
475	210	Bizkaia (eu)	ES-BI	t
476	210	Zamora	ES-ZA	t
477	210	Zaragoza	ES-Z	t
478	146	Aguascalientes	MX-AGU	t
479	146	Baja California	MX-BCN	t
480	146	Baja California Sur	MX-BCS	t
481	146	Campeche	MX-CAM	t
482	146	Chiapas	MX-CHP	t
483	146	Chihuahua	MX-CHH	t
484	146	Coahuila	MX-COA	t
485	146	Colima	MX-COL	t
486	146	Ciudad de México	MX-CMX​	t
487	146	Durango	MX-DUR	t
488	146	Guanajuato	MX-GUA	t
489	146	Guerrero	MX-GRO	t
490	146	Hidalgo	MX-HID	t
491	146	Jalisco	MX-JAL	t
492	146	Estado de México	MX-MEX	t
493	146	Michoacán	MX-MIC	t
494	146	Morelos	MX-MOR	t
495	146	Nayarit	MX-NAY	t
496	146	Nuevo León	MX-NLE	t
497	146	Oaxaca	MX-OAX	t
498	146	Puebla	MX-PUE	t
499	146	Querétaro	MX-QUE	t
500	146	Quintana Roo	MX-ROO	t
501	146	San Luis Potosí	MX-SLP	t
502	146	Sinaloa	MX-SIN	t
503	146	Sonora	MX-SON	t
504	146	Tabasco	MX-TAB	t
505	146	Tamaulipas	MX-TAM	t
506	146	Tlaxcala	MX-TLA	t
507	146	Veracruz	MX-VER	t
508	146	Yucatán	MX-YUC	t
509	146	Zacatecas	MX-ZAC	t
510	15	Buenos Aires	BA	t
511	15	Catamarca	CA	t
512	15	Chaco	CH	t
513	15	Chubut	CT	t
514	15	Córdoba	CB	t
515	15	Corrientes	CR	t
516	15	Entre Ríos	ER	t
517	15	Formosa	FO	t
518	15	Jujuy	JY	t
519	15	La Pampa	LP	t
520	15	La Rioja	LR	t
521	15	Mendoza	MZ	t
522	15	Misiones	MI	t
523	15	Neuquén	NQ	t
524	15	Río Negro	RN	t
525	15	Salta	SA	t
526	15	San Juan	SJ	t
527	15	San Luis	SL	t
528	15	Santa Cruz	SC	t
529	15	Santa Fe	SF	t
530	15	Santiago del Estero	SE	t
531	15	Tierra del Fuego	TF	t
532	15	Tucumán	TU	t
533	112	Agrigento	AG	t
534	112	Alessandria	AL	t
535	112	Ancona	AN	t
536	112	Aosta	AO	t
537	112	Arezzo	AR	t
538	112	Ascoli Piceno	AP	t
539	112	Asti	AT	t
540	112	Avellino	AV	t
541	112	Bari	BA	t
542	112	Belluno	BL	t
543	112	Benevento	BN	t
544	112	Bergamo	BG	t
545	112	Biella	BI	t
546	112	Bologna	BO	t
547	112	Bolzano	BZ	t
548	112	Brescia	BS	t
549	112	Brindisi	BR	t
550	112	Cagliari	CA	t
551	112	Caltanissetta	CL	t
552	112	Campobasso	CB	t
553	112	Caserta	CE	t
554	112	Catania	CT	t
555	112	Catanzaro	CZ	t
556	112	Chieti	CH	t
557	112	Como	CO	t
558	112	Cosenza	CS	t
559	112	Cremona	CR	t
560	112	Crotone	KR	t
561	112	Cuneo	CN	t
562	112	Enna	EN	t
563	112	Ferrara	FE	t
564	112	Firenze	FI	t
565	112	Foggia	FG	t
566	112	Forli'-Cesena	FO	t
567	112	Frosinone	FR	t
568	112	Genova	GE	t
569	112	Gorizia	GO	t
570	112	Grosseto	GR	t
571	112	Imperia	IM	t
572	112	Isernia	IS	t
573	112	La Spezia	SP	t
574	112	L'Aquila	AQ	t
575	112	Latina	LT	t
576	112	Lecce	LE	t
577	112	Lecco	LC	t
578	112	Livorno	LI	t
579	112	Lodi	LO	t
580	112	Lucca	LU	t
581	112	Macerata	MC	t
582	112	Mantova	MN	t
583	112	Massa-Carrara	MS	t
584	112	Matera	MT	t
585	112	Messina	ME	t
586	112	Milano	MI	t
587	112	Modena	MO	t
588	112	Napoli	NA	t
589	112	Novara	NO	t
590	112	Nuoro	NU	t
591	112	Oristano	OR	t
592	112	Padova	PD	t
593	112	Palermo	PA	t
594	112	Parma	PR	t
595	112	Pavia	PV	t
596	112	Perugia	PG	t
597	112	Pesaro e Urbino	PS	t
598	112	Pescara	PE	t
599	112	Piacenza	PC	t
600	112	Pisa	PI	t
601	112	Pistoia	PT	t
602	112	Pordenone	PN	t
603	112	Potenza	PZ	t
604	112	Prato	PO	t
605	112	Ragusa	RG	t
606	112	Ravenna	RA	t
607	112	Reggio di Calabria	RC	t
608	112	Reggio nell'Emilia	RE	t
609	112	Rieti	RI	t
610	112	Rimini	RN	t
611	112	Roma	RM	t
612	112	Rovigo	RO	t
613	112	Salerno	SA	t
614	112	Sassari	SS	t
615	112	Savona	SV	t
616	112	Siena	SI	t
617	112	Siracusa	SR	t
618	112	Sondrio	SO	t
619	112	Taranto	TA	t
620	112	Teramo	TE	t
621	112	Terni	TR	t
622	112	Torino	TO	t
623	112	Trapani	TP	t
624	112	Trento	TN	t
625	112	Treviso	TV	t
626	112	Trieste	TS	t
627	112	Udine	UD	t
628	112	Varese	VA	t
629	112	Venezia	VE	t
630	112	Verbano-Cusio-Ossola	VB	t
631	112	Vercelli	VC	t
632	112	Verona	VR	t
633	112	Vibo Valentia	VV	t
634	112	Vicenza	VI	t
635	112	Viterbo	VT	t
636	185	Адыгея	RU-AD	t
637	185	Башкортостан	RU-BA	t
638	185	Бурятия	RU-BU	t
639	185	Республика Алтай	RU-AL	t
640	185	Дагестан	RU-DA	t
641	185	Ингушетия	RU-IN	t
642	185	Кабардино-Балкария	RU-KB	t
643	185	Калмыкия	RU-KL	t
644	185	Карачаево-Черкесия	RU-KC	t
645	185	Карелия	RU-KR	t
646	185	Республика Коми	RU-KO	t
647	185	Марий Эл	RU-ME	t
648	185	Мордовия	RU-MO	t
649	185	Якутия	RU-SA	t
650	185	Северная Осетия	RU-SE	t
651	185	Татарстан	RU-TA	t
652	185	Тыва	RU-TY	t
653	185	Удмуртия	RU-UD	t
654	185	Хакасия	RU-KK	t
655	185	Чувашия	RU-CU	t
656	185	Алтайский край	RU-ALT	t
657	185	Краснодарский край	RU-KDA	t
658	185	Красноярский край	RU-KYA	t
659	185	Приморский край	RU-PRI	t
660	185	Ставропольский край	RU-STA	t
661	185	Хабаровский край	RU-KHA	t
662	185	Амурская область	RU-AMU	t
663	185	Архангельская область	RU-ARK	t
664	185	Астраханская область	RU-AST	t
665	185	Белгородская область	RU-BEL	t
666	185	Брянская область	RU-BRY	t
667	185	Владимирская область	RU-VLA	t
668	185	Волгоградская область	RU-VGG	t
669	185	Вологодская область	RU-VLG	t
670	185	Воронежская область	RU-VOR	t
671	185	Ивановская область	RU-IVA	t
672	185	Иркутская область	RU-IRK	t
673	185	Калининградская область	RU-KGD	t
674	185	Калужская область	RU-KLU	t
675	185	Камчатский край	RU-KAM	t
676	185	Кемеровская область	RU-KEM	t
677	185	Кировская область	RU-KIR	t
678	185	Костромская область	RU-KOS	t
679	185	Курганская область	RU-KGN	t
680	185	Курская область	RU-KRS	t
681	185	Ленинградская область	RU-LEN	t
682	185	Липецкая область	RU-LIP	t
683	185	Магаданская область	RU-MAG	t
684	185	Московская область	RU-MOS	t
685	185	Мурманская область	RU-MUR	t
686	185	Нижегородская область	RU-NIZ	t
687	185	Новгородская область	RU-NGR	t
688	185	Новосибирская область	RU-NVS	t
689	185	Омская область	RU-OMS	t
690	185	Оренбургская область	RU-ORE	t
691	185	Орловская область	RU-ORL	t
692	185	Пензенская область	RU-PNZ	t
693	185	Пермский край	RU-PER	t
694	185	Псковская область	RU-PSK	t
695	185	Ростовская область	RU-ROS	t
696	185	Рязанская область	RU-RYA	t
697	185	Самарская область	RU-SAM	t
698	185	Саратовская область	RU-SAR	t
699	185	Сахалинская область	RU-SAK	t
700	185	Свердловская область	RU-SVE	t
701	185	Смоленская область	RU-SMO	t
702	185	Тамбовская область	RU-TAM	t
703	185	Тверская область	RU-TVE	t
704	185	Томская область	RU-TOM	t
705	185	Тульская область	RU-TUL	t
706	185	Тюменская область	RU-TYU	t
707	185	Ульяновская область	RU-ULY	t
708	185	Челябинская область	RU-CHE	t
709	185	Забайкальский край	RU-ZAB	t
710	185	Ярославская область	RU-YAR	t
711	185	Москва	RU-MOW	t
712	185	Санкт-Петербург	RU-SPE	t
713	185	Еврейская автономная область	RU-YEV	t
714	185	Крым	UA-43	t
715	185	Ненецкий автономный округ	RU-NEN	t
716	185	Ханты-Мансийский автономный округ - Югра	RU-KHM	t
717	185	Чукотский автономный округ	RU-CHU	t
718	185	Ямало-Ненецкий автономный округ	RU-YAN	t
719	185	Севастополь	UA-40	t
720	185	Чечня	RU-CE	t
\.


--
-- Data for Name: winter_translate_attributes; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_attributes (id, locale, model_id, model_type, attribute_data) FROM stdin;
1	ar	9e95fdfa-b625-41d9-8f01-15d71f6b7552	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
2	ku	9e95fdfa-b625-41d9-8f01-15d71f6b7552	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
3	ar	9e95fe34-4596-4431-865c-a5a8d2a638c4	Acorn\\Location\\Models\\Location	{"name":""}
4	ku	9e95fe34-4596-4431-865c-a5a8d2a638c4	Acorn\\Location\\Models\\Location	{"name":""}
7	ar	9ea0cebf-6a5c-4ab8-9912-a387123f1c02	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
8	ku	9ea0cebf-6a5c-4ab8-9912-a387123f1c02	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
9	ar	9ea1ed07-6885-4b3f-b37c-1482c1a21624	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
10	ku	9ea1ed07-6885-4b3f-b37c-1482c1a21624	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
11	ar	9ea47ad3-7e86-4dde-8cd4-b63f1990ca35	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
12	ku	9ea47ad3-7e86-4dde-8cd4-b63f1990ca35	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
13	ar	c6bb2023-22d1-4f10-8767-89e159b618a6	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
14	ku	c6bb2023-22d1-4f10-8767-89e159b618a6	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
15	ar	076c0630-99cc-4324-9f67-c1c202a19b58	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
16	ku	076c0630-99cc-4324-9f67-c1c202a19b58	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
17	ar	996bf95c-e86b-4653-8d1d-440923f12cfd	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
18	ku	996bf95c-e86b-4653-8d1d-440923f12cfd	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
19	ar	a582b1ba-5d71-42d2-b776-46de370b3575	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
20	ku	a582b1ba-5d71-42d2-b776-46de370b3575	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
21	ar	9ea60a63-4050-466c-9947-d6a335a2f7bf	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
22	ku	9ea60a63-4050-466c-9947-d6a335a2f7bf	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
23	ar	9ea60bc4-324d-4091-baf9-6666d6183078	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
24	ku	9ea60bc4-324d-4091-baf9-6666d6183078	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
25	ar	9ea60dbe-8014-467f-ae96-b6083f2325c0	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
26	ku	9ea60dbe-8014-467f-ae96-b6083f2325c0	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
27	ar	9ea60dd4-96f6-457c-a10b-19d4ed657d40	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
28	ku	9ea60dd4-96f6-457c-a10b-19d4ed657d40	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
29	ar	9ea63f4c-7743-4a49-9963-856f0e1e4e9d	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
30	ku	9ea63f4c-7743-4a49-9963-856f0e1e4e9d	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
31	ar	9ea6417c-516e-4a0e-9637-924101c5b9b1	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
32	ku	9ea6417c-516e-4a0e-9637-924101c5b9b1	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
33	ar	9ea68ea6-ed7b-42c2-bc30-37c10be1c285	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
34	ku	9ea68ea6-ed7b-42c2-bc30-37c10be1c285	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
35	ar	9ea6ec5b-91fc-4629-bfa4-d218886b6c22	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
36	ku	9ea6ec5b-91fc-4629-bfa4-d218886b6c22	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
37	ar	9ea84304-5bc0-41a4-aa63-6269ed01a9bf	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
38	ku	9ea84304-5bc0-41a4-aa63-6269ed01a9bf	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
39	ar	9ea8435c-603a-4e8e-a422-b074ad26b59c	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
40	ku	9ea8435c-603a-4e8e-a422-b074ad26b59c	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
41	ar	9ea85983-2cd8-4e46-8aa6-d3691f2d9a84	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
42	ku	9ea85983-2cd8-4e46-8aa6-d3691f2d9a84	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
43	ar	d21483ec-5840-4894-9dbc-40125ed96835	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
44	ku	d21483ec-5840-4894-9dbc-40125ed96835	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
45	ar	9ea85e96-a848-4004-a4a8-48cb18f7f6ec	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
46	ku	9ea85e96-a848-4004-a4a8-48cb18f7f6ec	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
47	ar	9ea85f4e-0909-4534-975b-067544d30e86	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
48	ku	9ea85f4e-0909-4534-975b-067544d30e86	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
49	ar	9ea85f73-cca5-4aca-9d7e-55f9f5ab1409	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
50	ku	9ea85f73-cca5-4aca-9d7e-55f9f5ab1409	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
51	ar	9eaaacf0-a713-4b6b-9a72-4570887c83fe	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
52	ku	9eaaacf0-a713-4b6b-9a72-4570887c83fe	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
53	ar	9eac0755-4691-4f86-acab-8e1e10649245	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
54	ku	9eac0755-4691-4f86-acab-8e1e10649245	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
55	ar	5efa30cd-a16f-4d94-b8ec-604b4625b516	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
56	ku	5efa30cd-a16f-4d94-b8ec-604b4625b516	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
57	ar	a7d5143d-7e99-4d2b-92c9-86e7429adfa7	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
58	ku	a7d5143d-7e99-4d2b-92c9-86e7429adfa7	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
59	ar	9eac27c4-7d21-4424-b54c-80e036f939cd	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
60	ku	9eac27c4-7d21-4424-b54c-80e036f939cd	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
61	ar	f5b2f310-2118-4a93-b7b9-2ae9c7d7925a	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
62	ku	f5b2f310-2118-4a93-b7b9-2ae9c7d7925a	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
63	ar	9eb2644c-d933-45f7-8d7b-53305a08d026	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
64	ku	9eb2644c-d933-45f7-8d7b-53305a08d026	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
65	ar	cae7ba7c-1b63-11f0-8a05-c36be60d3d46	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
66	ku	cae7ba7c-1b63-11f0-8a05-c36be60d3d46	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
75	ar	f334763c-1b63-11f0-aab4-4f7e5f7e30cb	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
76	ku	f334763c-1b63-11f0-aab4-4f7e5f7e30cb	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
77	ar	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	Acorn\\User\\Models\\UserGroupType	{"name":""}
78	ku	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	Acorn\\User\\Models\\UserGroupType	{"name":""}
79	ar	9ec87e7c-cb27-4774-a024-6f4df6b3c61e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
80	ku	9ec87e7c-cb27-4774-a024-6f4df6b3c61e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
82	ku	69e907ec-edce-4e2a-ba01-31628baf447d	Acorn\\Exam\\Models\\Interview	{"name":"","description":""}
81	ar	69e907ec-edce-4e2a-ba01-31628baf447d	Acorn\\Exam\\Models\\Interview	{"name":"Arab","description":""}
83	ar	9ecef4a3-734e-4193-9e2e-f2b04c46349b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
84	ku	9ecef4a3-734e-4193-9e2e-f2b04c46349b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
85	ar	9ed44ac1-8455-45b2-a2f3-1164622ec5a1	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
86	ku	9ed44ac1-8455-45b2-a2f3-1164622ec5a1	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
87	ar	68a980b0-012b-4703-9bf4-938548b64a1a	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
88	ku	68a980b0-012b-4703-9bf4-938548b64a1a	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
89	ar	37a9ae02-76c1-4396-b2a3-c2fc5357caef	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
90	ku	37a9ae02-76c1-4396-b2a3-c2fc5357caef	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
91	ar	9ed8b261-9ba8-4cb7-9008-7e77068afd1b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
92	ku	9ed8b261-9ba8-4cb7-9008-7e77068afd1b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
93	ar	9eda63ea-1b4f-4e2e-bb54-3dcb69d08f1e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
94	ku	9eda63ea-1b4f-4e2e-bb54-3dcb69d08f1e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
95	ar	9edac54f-2fb0-413d-83a2-7fa7ca5e7423	Acorn\\University\\Models\\Semester	{"name":"","description":""}
96	ku	9edac54f-2fb0-413d-83a2-7fa7ca5e7423	Acorn\\University\\Models\\Semester	{"name":"","description":""}
97	ar	9edac55d-ff15-4982-915c-2835df07cb12	Acorn\\University\\Models\\Semester	{"name":"","description":""}
98	ku	9edac55d-ff15-4982-915c-2835df07cb12	Acorn\\University\\Models\\Semester	{"name":"","description":""}
99	ar	9edac56c-d36b-4495-a2c2-2d96e75de113	Acorn\\University\\Models\\Semester	{"name":"","description":""}
100	ku	9edac56c-d36b-4495-a2c2-2d96e75de113	Acorn\\University\\Models\\Semester	{"name":"","description":""}
101	ar	9edac808-adee-45fe-a394-6a769b772b83	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
102	ku	9edac808-adee-45fe-a394-6a769b772b83	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
103	ar	9edac813-5423-417c-8b8b-020606b35a76	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
104	ku	9edac813-5423-417c-8b8b-020606b35a76	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
105	ar	9edacc87-72c5-4a18-aa3d-5bd94fd64909	Acorn\\University\\Models\\Project	{"name":"","description":""}
106	ku	9edacc87-72c5-4a18-aa3d-5bd94fd64909	Acorn\\University\\Models\\Project	{"name":"","description":""}
107	ar	9edc994f-ecc0-485d-9f7a-0e36a186dbc5	Acorn\\University\\Models\\Project	{"name":"","description":""}
108	ku	9edc994f-ecc0-485d-9f7a-0e36a186dbc5	Acorn\\University\\Models\\Project	{"name":"","description":""}
109	ar	9edc9b31-1b8a-49a2-9b4e-41d732015290	Acorn\\University\\Models\\ProjectStudent	{"name":"","description":""}
110	ku	9edc9b31-1b8a-49a2-9b4e-41d732015290	Acorn\\University\\Models\\ProjectStudent	{"name":"","description":""}
111	ar	9ede9377-9aa9-4b3f-9d61-3b5de579ae9e	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
112	ku	9ede9377-9aa9-4b3f-9d61-3b5de579ae9e	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
113	ar	6b4bae9a-149f-11f0-a4e5-779d31ace22e	Acorn\\University\\Models\\MaterialType	{"name":"","description":""}
114	ku	6b4bae9a-149f-11f0-a4e5-779d31ace22e	Acorn\\University\\Models\\MaterialType	{"name":"","description":""}
115	ar	15f02b5c-2bff-11f0-8074-4bf737ba6a74	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
116	ku	15f02b5c-2bff-11f0-8074-4bf737ba6a74	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
117	ar	9ee28508-e4dc-4734-9426-9ca21608c987	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
118	ku	9ee28508-e4dc-4734-9426-9ca21608c987	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
119	ar	9ee289d9-dcb8-4b36-87a9-049575ee43fa	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
120	ku	9ee289d9-dcb8-4b36-87a9-049575ee43fa	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
121	ar	958b8af0-2e7f-11f0-b4b4-9f4a22fbe4eb	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
122	ku	958b8af0-2e7f-11f0-b4b4-9f4a22fbe4eb	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
123	ar	958b952c-2e7f-11f0-b4b6-0f8c2c07f33e	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
124	ku	958b952c-2e7f-11f0-b4b6-0f8c2c07f33e	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
125	ar	9ee46f13-b23e-4ab7-998a-b2585f1a41ad	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
126	ku	9ee46f13-b23e-4ab7-998a-b2585f1a41ad	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
127	ar	9ee52bda-2631-48db-ac33-44630c76e83c	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
128	ku	9ee52bda-2631-48db-ac33-44630c76e83c	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
129	ar	9ee52f50-d22a-471e-bdeb-b13d81b1afb2	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
130	ku	9ee52f50-d22a-471e-bdeb-b13d81b1afb2	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
131	ar	fb9806d4-2beb-11f0-9893-2ba7af07260a	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
132	ku	fb9806d4-2beb-11f0-9893-2ba7af07260a	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
137	ar	529bd45a-1b6c-11f0-99b6-b7f647885dbc	Acorn\\University\\Models\\Year	{"description":""}
138	ku	529bd45a-1b6c-11f0-99b6-b7f647885dbc	Acorn\\University\\Models\\Year	{"description":""}
139	ar	543d0928-1b6c-11f0-abc1-8bd8fff1240d	Acorn\\University\\Models\\Year	{"description":""}
140	ku	543d0928-1b6c-11f0-abc1-8bd8fff1240d	Acorn\\University\\Models\\Year	{"description":""}
141	ku	61c051fa-2b47-11f0-bc0f-ab4c8b696730	Acorn\\University\\Models\\Semester	{"name":"","description":""}
142	ar	61c051fa-2b47-11f0-bc0f-ab4c8b696730	Acorn\\University\\Models\\Semester	{"name":"","description":""}
143	ku	61eb583c-2b47-11f0-adc3-ef976031065b	Acorn\\University\\Models\\Semester	{"name":"","description":""}
144	ar	61eb583c-2b47-11f0-adc3-ef976031065b	Acorn\\University\\Models\\Semester	{"name":"","description":""}
145	ku	6212587e-2b47-11f0-b854-631a30042bb5	Acorn\\University\\Models\\Semester	{"name":"","description":""}
146	ar	6212587e-2b47-11f0-b854-631a30042bb5	Acorn\\University\\Models\\Semester	{"name":"","description":""}
147	ku	7f5c3dc8-2e53-11f0-8600-6ff513625846	Acorn\\University\\Models\\Material	{"name":"","description":""}
148	ar	7f5c3dc8-2e53-11f0-8600-6ff513625846	Acorn\\University\\Models\\Material	{"name":"","description":""}
149	ku	7f5c4156-2e53-11f0-8601-43470f236a9e	Acorn\\University\\Models\\Material	{"name":"","description":""}
150	ar	7f5c4156-2e53-11f0-8601-43470f236a9e	Acorn\\University\\Models\\Material	{"name":"","description":""}
151	ku	2d6697a7-62c2-472e-93bf-ddae492efdf8	Acorn\\University\\Models\\Hierarchy	{"description":""}
152	ar	2d6697a7-62c2-472e-93bf-ddae492efdf8	Acorn\\University\\Models\\Hierarchy	{"description":""}
153	ku	f9ae3f21-017d-4fb9-a97f-7add420364fc	Acorn\\University\\Models\\Hierarchy	{"description":""}
154	ar	f9ae3f21-017d-4fb9-a97f-7add420364fc	Acorn\\University\\Models\\Hierarchy	{"description":""}
\.


--
-- Data for Name: winter_translate_indexes; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_indexes (id, locale, model_id, model_type, item, value) FROM stdin;
\.


--
-- Data for Name: winter_translate_locales; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_locales (id, code, name, is_default, is_enabled, sort_order) FROM stdin;
1	en	English	t	t	1
2	ar	Arabic	f	t	2
3	ku	Kurdish	f	t	3
\.


--
-- Data for Name: winter_translate_messages; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_messages (id, code, message_data, found, code_pre_2_1_0) FROM stdin;
\.


--
-- Name: acorn_reporting_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.acorn_reporting_reports_id_seq', 1, false);


--
-- Name: acorn_university_year_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.acorn_university_year_seq', 1, true);


--
-- Name: backend_access_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_access_log_id_seq', 14, true);


--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_groups_id_seq', 1, true);


--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_preferences_id_seq', 22, true);


--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_roles_id_seq', 2, true);


--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_throttle_id_seq', 3, true);


--
-- Name: backend_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_users_id_seq', 6, true);


--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.cms_theme_data_id_seq', 1, false);


--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.cms_theme_logs_id_seq', 1, false);


--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.cms_theme_templates_id_seq', 1, false);


--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.deferred_bindings_id_seq', 7, true);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.migrations_id_seq', 51, true);


--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_location_countries_id_seq', 248, true);


--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_location_states_id_seq', 720, true);


--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_attributes_id_seq', 154, true);


--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_indexes_id_seq', 1, false);


--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_locales_id_seq', 3, true);


--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_messages_id_seq', 1, false);


--
-- Name: system_event_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_event_logs_id_seq', 4258, true);


--
-- Name: system_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_files_id_seq', 3, true);


--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_mail_layouts_id_seq', 2, true);


--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_mail_partials_id_seq', 1, false);


--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_mail_templates_id_seq', 1, false);


--
-- Name: system_parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_parameters_id_seq', 7, true);


--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_plugin_history_id_seq', 397, true);


--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_plugin_versions_id_seq', 14, true);


--
-- Name: system_request_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_request_logs_id_seq', 1, false);


--
-- Name: system_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_revisions_id_seq', 1, false);


--
-- Name: system_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_settings_id_seq', 1, true);


--
-- Name: acorn_calendar_calendars acorn_calendar_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_calendars_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_part_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_part_user_group_pkey PRIMARY KEY (event_part_id, user_group_id);


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_pkey PRIMARY KEY (event_part_id, user_id, role_id);


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_statuses acorn_calendar_event_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_statuses
    ADD CONSTRAINT acorn_calendar_event_statuses_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_types acorn_calendar_event_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_types
    ADD CONSTRAINT acorn_calendar_event_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_events acorn_calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_instances acorn_calendar_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_instances
    ADD CONSTRAINT acorn_calendar_instances_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_calculation_course_materials acorn_exam_calculation_course_material_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT acorn_exam_calculation_course_material_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_calculation_courses acorn_exam_calculation_course_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT acorn_exam_calculation_course_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_calculation_material_types acorn_exam_calculation_material_type_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT acorn_exam_calculation_material_type_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_calculation_types acorn_exam_calculation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_types
    ADD CONSTRAINT acorn_exam_calculation_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_calculations acorn_exam_calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT acorn_exam_calculations_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_exam_materials acorn_exam_exam_material_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT acorn_exam_exam_material_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_exams acorn_exam_exams_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT acorn_exam_exams_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_interview_students acorn_exam_interview_student_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT acorn_exam_interview_student_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_interviews acorn_exam_interviews_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT acorn_exam_interviews_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_material_types acorn_exam_material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT acorn_exam_material_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_materials acorn_exam_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT acorn_exam_materials_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_scores acorn_exam_results_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT acorn_exam_results_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_types acorn_exam_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT acorn_exam_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_lookup acorn_location_location_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_lookup
    ADD CONSTRAINT acorn_location_location_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_label acorn_messaging_label_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_label
    ADD CONSTRAINT acorn_messaging_label_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_message acorn_messaging_message_externalid_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message
    ADD CONSTRAINT acorn_messaging_message_externalid_unique UNIQUE ("externalID");


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_pkey PRIMARY KEY (message_id, instance_id);


--
-- Name: acorn_messaging_message_message acorn_messaging_message_message_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_message
    ADD CONSTRAINT acorn_messaging_message_message_pkey PRIMARY KEY (message1_id, message2_id, relationship);


--
-- Name: acorn_messaging_message acorn_messaging_message_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message
    ADD CONSTRAINT acorn_messaging_message_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_pkey PRIMARY KEY (message_id, user_group_id);


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_pkey PRIMARY KEY (message_id, user_id);


--
-- Name: acorn_messaging_status acorn_messaging_status_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_status
    ADD CONSTRAINT acorn_messaging_status_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_pkey PRIMARY KEY (message_id, status_id);


--
-- Name: acorn_reporting_reports acorn_reporting_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_reporting_reports
    ADD CONSTRAINT acorn_reporting_reports_pkey PRIMARY KEY (id);


--
-- Name: acorn_servers acorn_servers_hostname_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT acorn_servers_hostname_unique UNIQUE (hostname);


--
-- Name: acorn_servers acorn_servers_id_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT acorn_servers_id_unique UNIQUE (id);


--
-- Name: acorn_university_course_years acorn_university_academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_years
    ADD CONSTRAINT acorn_university_academic_years_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_course_language acorn_university_course_language_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_language
    ADD CONSTRAINT acorn_university_course_language_pkey PRIMARY KEY (course_id, language_id);


--
-- Name: acorn_university_course_materials acorn_university_course_material_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT acorn_university_course_material_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_courses acorn_university_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_courses
    ADD CONSTRAINT acorn_university_courses_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_departments acorn_university_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_departments
    ADD CONSTRAINT acorn_university_departments_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_education_authorities acorn_university_education_authorities_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_education_authorities
    ADD CONSTRAINT acorn_university_education_authorities_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_entities acorn_university_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT acorn_university_entities_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_faculties acorn_university_faculties_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_faculties
    ADD CONSTRAINT acorn_university_faculties_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_hierarchies acorn_university_hierarchies_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT acorn_university_hierarchies_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_lectures acorn_university_lectures_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT acorn_university_lectures_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_project_students acorn_university_project_students_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT acorn_university_project_students_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_projects acorn_university_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT acorn_university_projects_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_schools acorn_university_schools_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_schools
    ADD CONSTRAINT acorn_university_schools_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_academic_year_semesters acorn_university_semester_year_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT acorn_university_semester_year_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_semesters acorn_university_semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT acorn_university_semesters_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_student_codes acorn_university_student_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT acorn_university_student_codes_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_student_statuses acorn_university_student_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_statuses
    ADD CONSTRAINT acorn_university_student_statuses_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_students acorn_university_students_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_students
    ADD CONSTRAINT acorn_university_students_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_teachers acorn_university_teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_teachers
    ADD CONSTRAINT acorn_university_teachers_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_universities acorn_university_universities_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_universities
    ADD CONSTRAINT acorn_university_universities_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_academic_years acorn_university_years_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT acorn_university_years_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_language_user acorn_user_language_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_pkey PRIMARY KEY (user_id, language_id);


--
-- Name: acorn_user_languages acorn_user_languages_name_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_languages
    ADD CONSTRAINT acorn_user_languages_name_unique UNIQUE (name);


--
-- Name: acorn_user_languages acorn_user_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_languages
    ADD CONSTRAINT acorn_user_languages_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_role_user acorn_user_role_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT acorn_user_role_user_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: acorn_user_roles acorn_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_roles
    ADD CONSTRAINT acorn_user_roles_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_throttle acorn_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_throttle
    ADD CONSTRAINT acorn_user_throttle_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_group acorn_user_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT acorn_user_user_group_pkey PRIMARY KEY (user_id, user_group_id);


--
-- Name: acorn_user_user_group_types acorn_user_user_group_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_types
    ADD CONSTRAINT acorn_user_user_group_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_group_version acorn_user_user_group_version_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_version
    ADD CONSTRAINT acorn_user_user_group_version_pkey PRIMARY KEY (user_id, user_group_version_id);


--
-- Name: acorn_user_user_group_versions acorn_user_user_group_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT acorn_user_user_group_versions_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_groups acorn_user_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_users acorn_user_users_email_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_email_unique UNIQUE (email);


--
-- Name: acorn_user_users acorn_user_users_login_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_login_unique UNIQUE (username);


--
-- Name: acorn_user_users acorn_user_users_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_pkey PRIMARY KEY (id);


--
-- Name: backend_access_log backend_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_access_log
    ADD CONSTRAINT backend_access_log_pkey PRIMARY KEY (id);


--
-- Name: backend_user_groups backend_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT backend_user_groups_pkey PRIMARY KEY (id);


--
-- Name: backend_user_preferences backend_user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_preferences
    ADD CONSTRAINT backend_user_preferences_pkey PRIMARY KEY (id);


--
-- Name: backend_user_roles backend_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT backend_user_roles_pkey PRIMARY KEY (id);


--
-- Name: backend_user_throttle backend_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_throttle
    ADD CONSTRAINT backend_user_throttle_pkey PRIMARY KEY (id);


--
-- Name: backend_users_groups backend_users_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users_groups
    ADD CONSTRAINT backend_users_groups_pkey PRIMARY KEY (user_id, user_group_id);


--
-- Name: backend_users backend_users_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT backend_users_pkey PRIMARY KEY (id);


--
-- Name: cache cache_key_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_key_unique UNIQUE (key);


--
-- Name: cms_theme_data cms_theme_data_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_data
    ADD CONSTRAINT cms_theme_data_pkey PRIMARY KEY (id);


--
-- Name: cms_theme_logs cms_theme_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_logs
    ADD CONSTRAINT cms_theme_logs_pkey PRIMARY KEY (id);


--
-- Name: cms_theme_templates cms_theme_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_templates
    ADD CONSTRAINT cms_theme_templates_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_groups code; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT code UNIQUE (code);


--
-- Name: acorn_university_course_materials course_semester_year_course_year_material; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT course_semester_year_course_year_material UNIQUE (course_id, academic_year_semester_id, course_year_id, material_id);


--
-- Name: deferred_bindings deferred_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.deferred_bindings
    ADD CONSTRAINT deferred_bindings_pkey PRIMARY KEY (id);


--
-- Name: backend_users email_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- Name: acorn_university_hierarchies entity_parent_year; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT entity_parent_year UNIQUE NULLS NOT DISTINCT (entity_id, parent_id, academic_year_id);


--
-- Name: acorn_exam_exam_materials exam_course_material; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT exam_course_material UNIQUE (exam_id, course_material_id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: acorn_university_entities import_source; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT import_source UNIQUE (import_source);


--
-- Name: acorn_university_hierarchies import_source_hierarchies; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT import_source_hierarchies UNIQUE (import_source);


--
-- Name: acorn_user_user_groups import_source_user_groups; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT import_source_user_groups UNIQUE (import_source);


--
-- Name: acorn_user_users import_source_users; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT import_source_users UNIQUE (import_source);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_addresses location_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT location_addresses_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_area_types location_area_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT location_area_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_areas location_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT location_areas_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_gps location_gps_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT location_gps_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_locations location_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT location_locations_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_types location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT location_types_pkey PRIMARY KEY (id);


--
-- Name: backend_users login_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT login_unique UNIQUE (login);


--
-- Name: acorn_university_materials material_name; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT material_name UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: backend_user_groups name_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT name_unique UNIQUE (name);


--
-- Name: winter_location_countries rainlab_location_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_countries
    ADD CONSTRAINT rainlab_location_countries_pkey PRIMARY KEY (id);


--
-- Name: winter_location_states rainlab_location_states_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_states
    ADD CONSTRAINT rainlab_location_states_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_attributes rainlab_translate_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_attributes
    ADD CONSTRAINT rainlab_translate_attributes_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_indexes rainlab_translate_indexes_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_indexes
    ADD CONSTRAINT rainlab_translate_indexes_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_locales rainlab_translate_locales_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_locales
    ADD CONSTRAINT rainlab_translate_locales_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_messages rainlab_translate_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_messages
    ADD CONSTRAINT rainlab_translate_messages_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_mail_blockers rainlab_user_mail_blockers_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_mail_blockers
    ADD CONSTRAINT rainlab_user_mail_blockers_pkey PRIMARY KEY (id);


--
-- Name: backend_user_roles role_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT role_unique UNIQUE (name);


--
-- Name: sessions sessions_id_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_id_unique UNIQUE (id);


--
-- Name: acorn_exam_scores student_exam_material; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT student_exam_material UNIQUE (student_id, exam_material_id);


--
-- Name: system_event_logs system_event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_event_logs
    ADD CONSTRAINT system_event_logs_pkey PRIMARY KEY (id);


--
-- Name: system_files system_files_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_files
    ADD CONSTRAINT system_files_pkey PRIMARY KEY (id);


--
-- Name: system_mail_layouts system_mail_layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_layouts
    ADD CONSTRAINT system_mail_layouts_pkey PRIMARY KEY (id);


--
-- Name: system_mail_partials system_mail_partials_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_partials
    ADD CONSTRAINT system_mail_partials_pkey PRIMARY KEY (id);


--
-- Name: system_mail_templates system_mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_templates
    ADD CONSTRAINT system_mail_templates_pkey PRIMARY KEY (id);


--
-- Name: system_parameters system_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_parameters
    ADD CONSTRAINT system_parameters_pkey PRIMARY KEY (id);


--
-- Name: system_plugin_history system_plugin_history_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_history
    ADD CONSTRAINT system_plugin_history_pkey PRIMARY KEY (id);


--
-- Name: system_plugin_versions system_plugin_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_versions
    ADD CONSTRAINT system_plugin_versions_pkey PRIMARY KEY (id);


--
-- Name: system_request_logs system_request_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_request_logs
    ADD CONSTRAINT system_request_logs_pkey PRIMARY KEY (id);


--
-- Name: system_revisions system_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_revisions
    ADD CONSTRAINT system_revisions_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_entities unique_user_group_id; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT unique_user_group_id UNIQUE (user_group_id);


--
-- Name: acorn_calendar_instances_date_event_part_id_instance_; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_calendar_instances_date_event_part_id_instance_ ON public.acorn_calendar_instances USING btree (date, event_part_id, instance_num);


--
-- Name: acorn_user_mail_blockers_email_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_mail_blockers_email_index ON public.acorn_user_mail_blockers USING btree (email);


--
-- Name: acorn_user_mail_blockers_template_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_mail_blockers_template_index ON public.acorn_user_mail_blockers USING btree (template);


--
-- Name: acorn_user_mail_blockers_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_mail_blockers_user_id_index ON public.acorn_user_mail_blockers USING btree (user_id);


--
-- Name: acorn_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_throttle_ip_address_index ON public.acorn_user_throttle USING btree (ip_address);


--
-- Name: acorn_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_throttle_user_id_index ON public.acorn_user_throttle USING btree (user_id);


--
-- Name: acorn_user_user_groups_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_user_groups_code_index ON public.acorn_user_user_groups USING btree (code);


--
-- Name: acorn_user_users_activation_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_users_activation_code_index ON public.acorn_user_users USING btree (activation_code);


--
-- Name: acorn_user_users_login_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_users_login_index ON public.acorn_user_users USING btree (username);


--
-- Name: acorn_user_users_reset_password_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_users_reset_password_code_index ON public.acorn_user_users USING btree (reset_password_code);


--
-- Name: act_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX act_code_index ON public.backend_users USING btree (activation_code);


--
-- Name: admin_role_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX admin_role_index ON public.backend_users USING btree (role_id);


--
-- Name: backend_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX backend_user_throttle_ip_address_index ON public.backend_user_throttle USING btree (ip_address);


--
-- Name: backend_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX backend_user_throttle_user_id_index ON public.backend_user_throttle USING btree (user_id);


--
-- Name: cms_theme_data_theme_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_data_theme_index ON public.cms_theme_data USING btree (theme);


--
-- Name: cms_theme_logs_theme_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_logs_theme_index ON public.cms_theme_logs USING btree (theme);


--
-- Name: cms_theme_logs_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_logs_type_index ON public.cms_theme_logs USING btree (type);


--
-- Name: cms_theme_logs_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_logs_user_id_index ON public.cms_theme_logs USING btree (user_id);


--
-- Name: cms_theme_templates_path_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_templates_path_index ON public.cms_theme_templates USING btree (path);


--
-- Name: cms_theme_templates_source_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_templates_source_index ON public.cms_theme_templates USING btree (source);


--
-- Name: code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX code_index ON public.backend_user_groups USING btree (code);


--
-- Name: course_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX course_material_id ON public.acorn_exam_result_internals USING btree (course_material_id);


--
-- Name: deferred_bindings_master_field_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_master_field_index ON public.deferred_bindings USING btree (master_field);


--
-- Name: deferred_bindings_master_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_master_type_index ON public.deferred_bindings USING btree (master_type);


--
-- Name: deferred_bindings_session_key_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_session_key_index ON public.deferred_bindings USING btree (session_key);


--
-- Name: deferred_bindings_slave_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_slave_id_index ON public.deferred_bindings USING btree (slave_id);


--
-- Name: deferred_bindings_slave_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_slave_type_index ON public.deferred_bindings USING btree (slave_type);


--
-- Name: dr_acorn_location_addresses_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_addresses_replica_identity ON public.acorn_location_addresses USING btree (server_id, id);


--
-- Name: dr_acorn_location_area_types_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_area_types_replica_identity ON public.acorn_location_area_types USING btree (server_id, id);


--
-- Name: dr_acorn_location_areas_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_areas_replica_identity ON public.acorn_location_areas USING btree (server_id, id);


--
-- Name: dr_acorn_location_gps_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_gps_replica_identity ON public.acorn_location_gps USING btree (server_id, id);


--
-- Name: dr_acorn_location_location_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_location_replica_identity ON public.acorn_location_locations USING btree (server_id, id);


--
-- Name: dr_acorn_location_types_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_types_replica_identity ON public.acorn_location_types USING btree (server_id, id);


--
-- Name: fki_academic_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_academic_year_id ON public.acorn_university_course_materials USING btree (course_year_id);


--
-- Name: fki_course_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_course_id ON public.acorn_university_course_language USING btree (course_id);


--
-- Name: fki_course_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_course_material_id ON public.acorn_exam_exam_materials USING btree (course_material_id);


--
-- Name: fki_created_at_event_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_created_at_event_id ON public.acorn_university_entities USING btree (created_at_event_id);


--
-- Name: fki_created_by_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_created_by_user_id ON public.acorn_university_entities USING btree (created_by_user_id);


--
-- Name: fki_enrollment_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_enrollment_year_id ON public.acorn_university_course_materials USING btree (enrollment_academic_year_id);


--
-- Name: fki_entity_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_entity_id ON public.acorn_university_universities USING btree (id);


--
-- Name: fki_event_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_event_id ON public.acorn_exam_interview_students USING btree (event_id);


--
-- Name: fki_exam_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_exam_id ON public.acorn_exam_exam_materials USING btree (exam_id);


--
-- Name: fki_exam_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_exam_material_id ON public.acorn_exam_scores USING btree (exam_material_id);


--
-- Name: fki_interview_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_interview_id ON public.acorn_exam_interview_students USING btree (interview_id);


--
-- Name: fki_language_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_language_id ON public.acorn_university_course_language USING btree (language_id);


--
-- Name: fki_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_material_id ON public.acorn_exam_exam_materials USING btree (course_material_id);


--
-- Name: fki_owner_student_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_owner_student_id ON public.acorn_university_project_students USING btree (owner_student_id);


--
-- Name: fki_owner_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_owner_user_id ON public.acorn_university_project_students USING btree (owner_student_id);


--
-- Name: fki_parent_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_parent_id ON public.acorn_university_hierarchies USING btree (parent_id);


--
-- Name: fki_project_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_project_id ON public.acorn_exam_exam_materials USING btree (project_id);


--
-- Name: fki_semester_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_semester_id ON public.acorn_university_academic_year_semesters USING btree (semester_id);


--
-- Name: fki_semester_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_semester_year_id ON public.acorn_university_course_materials USING btree (academic_year_semester_id);


--
-- Name: fki_server_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_server_id ON public.acorn_university_entities USING btree (server_id);


--
-- Name: fki_student_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_student_id ON public.acorn_exam_scores USING btree (student_id);


--
-- Name: fki_teacher_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_teacher_id ON public.acorn_exam_interview_students USING btree (teacher_id);


--
-- Name: fki_type_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_type_id ON public.acorn_location_locations USING btree (type_id);


--
-- Name: fki_updated_at_event_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_updated_at_event_id ON public.acorn_university_entities USING btree (updated_at_event_id);


--
-- Name: fki_updated_by_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_updated_by_user_id ON public.acorn_university_entities USING btree (updated_by_user_id);


--
-- Name: fki_user_group_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_user_group_id ON public.acorn_university_entities USING btree (user_group_id);


--
-- Name: fki_user_group_version_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_user_group_version_id ON public.acorn_university_entities USING btree (user_group_id);


--
-- Name: fki_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_user_id ON public.acorn_user_user_group_version USING btree (user_id);


--
-- Name: fki_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_year_id ON public.acorn_university_hierarchies USING btree (academic_year_id);


--
-- Name: item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX item_index ON public.system_parameters USING btree (namespace, "group", item);


--
-- Name: jobs_queue_reserved_at_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX jobs_queue_reserved_at_index ON public.jobs USING btree (queue, reserved_at);


--
-- Name: name_regexp; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX name_regexp ON public.acorn_exam_result_internals USING gin (name public.gin_trgm_ops);


--
-- Name: rainlab_location_countries_name_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX rainlab_location_countries_name_index ON public.winter_location_countries USING btree (name);


--
-- Name: rainlab_location_states_country_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX rainlab_location_states_country_id_index ON public.winter_location_states USING btree (country_id);


--
-- Name: rainlab_location_states_name_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX rainlab_location_states_name_index ON public.winter_location_states USING btree (name);


--
-- Name: reset_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX reset_code_index ON public.backend_users USING btree (reset_password_code);


--
-- Name: role_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX role_code_index ON public.backend_user_roles USING btree (code);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: student_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX student_id ON public.acorn_exam_result_internals USING btree (student_id);


--
-- Name: system_event_logs_level_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_event_logs_level_index ON public.system_event_logs USING btree (level);


--
-- Name: system_files_attachment_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_files_attachment_id_index ON public.system_files USING btree (attachment_id);


--
-- Name: system_files_attachment_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_files_attachment_type_index ON public.system_files USING btree (attachment_type);


--
-- Name: system_files_field_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_files_field_index ON public.system_files USING btree (field);


--
-- Name: system_mail_templates_layout_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_mail_templates_layout_id_index ON public.system_mail_templates USING btree (layout_id);


--
-- Name: system_plugin_history_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_plugin_history_code_index ON public.system_plugin_history USING btree (code);


--
-- Name: system_plugin_history_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_plugin_history_type_index ON public.system_plugin_history USING btree (type);


--
-- Name: system_plugin_versions_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_plugin_versions_code_index ON public.system_plugin_versions USING btree (code);


--
-- Name: system_revisions_field_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_revisions_field_index ON public.system_revisions USING btree (field);


--
-- Name: system_revisions_revisionable_id_revisionable_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_revisions_revisionable_id_revisionable_type_index ON public.system_revisions USING btree (revisionable_id, revisionable_type);


--
-- Name: system_revisions_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_revisions_user_id_index ON public.system_revisions USING btree (user_id);


--
-- Name: system_settings_item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_settings_item_index ON public.system_settings USING btree (item);


--
-- Name: user_item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX user_item_index ON public.backend_user_preferences USING btree (user_id, namespace, "group", item);


--
-- Name: winter_translate_attributes_locale_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_attributes_locale_index ON public.winter_translate_attributes USING btree (locale);


--
-- Name: winter_translate_attributes_model_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_attributes_model_id_index ON public.winter_translate_attributes USING btree (model_id);


--
-- Name: winter_translate_attributes_model_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_attributes_model_type_index ON public.winter_translate_attributes USING btree (model_type);


--
-- Name: winter_translate_indexes_item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_item_index ON public.winter_translate_indexes USING btree (item);


--
-- Name: winter_translate_indexes_locale_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_locale_index ON public.winter_translate_indexes USING btree (locale);


--
-- Name: winter_translate_indexes_model_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_model_id_index ON public.winter_translate_indexes USING btree (model_id);


--
-- Name: winter_translate_indexes_model_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_model_type_index ON public.winter_translate_indexes USING btree (model_type);


--
-- Name: winter_translate_locales_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_locales_code_index ON public.winter_translate_locales USING btree (code);


--
-- Name: winter_translate_locales_name_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_locales_name_index ON public.winter_translate_locales USING btree (name);


--
-- Name: winter_translate_messages_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_messages_code_index ON public.winter_translate_messages USING btree (code);


--
-- Name: winter_translate_messages_code_pre_2_1_0_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_messages_code_pre_2_1_0_index ON public.winter_translate_messages USING btree (code_pre_2_1_0);


--
-- Name: acorn_exam_tokens _RETURN; Type: RULE; Schema: public; Owner: university
--

CREATE OR REPLACE VIEW public.acorn_exam_tokens AS
 SELECT (concat(sc.student_id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['score'::character varying, ug.name, m.name, ay.name, mt.name, e.name, et.name, s.code, (
        CASE
            WHEN em.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['score'::character varying, ug.name, m.name, ay.name, mt.name, e.name, et.name, s.code, (
        CASE
            WHEN em.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying]) AS name,
    sc.student_id,
    ays.academic_year_id,
    em.exam_id,
    em.course_material_id,
    cm.course_id,
    cm.material_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    (sc.score)::character varying AS expression,
    em.minimum,
    em.maximum,
    em.required,
    'data'::text AS expression_type,
    false AS needs_evaluate
   FROM ((((((((((((public.acorn_exam_scores sc
     JOIN public.acorn_university_students s ON ((sc.student_id = s.id)))
     JOIN public.acorn_exam_exam_materials em ON ((sc.exam_material_id = em.id)))
     JOIN public.acorn_exam_exams e ON ((em.exam_id = e.id)))
     JOIN public.acorn_exam_types et ON ((e.type_id = et.id)))
     JOIN public.acorn_university_course_materials cm ON ((em.course_material_id = cm.id)))
     JOIN public.acorn_university_academic_year_semesters ays ON ((cm.academic_year_semester_id = ays.id)))
     JOIN public.acorn_university_academic_years ay ON ((ay.id = ays.academic_year_id)))
     JOIN public.acorn_university_courses c ON ((cm.course_id = c.id)))
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_user_user_groups ug ON ((en.user_group_id = ug.id)))
     JOIN public.acorn_university_materials m ON ((cm.material_id = m.id)))
     JOIN public.acorn_university_material_types mt ON ((m.material_type_id = mt.id)))
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['material'::character varying, ugs.name, m.name, ay.name, mt.name, s.code, (
        CASE
            WHEN cm.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying, 'result'::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['material'::character varying, ugs.name, m.name, ay.name, mt.name, s.code, (
        CASE
            WHEN cm.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying, 'result'::character varying]) AS name,
    s.id AS student_id,
    ays.academic_year_id,
    NULL::uuid AS exam_id,
    cm.id AS course_material_id,
    cm.course_id,
    cm.material_id,
        CASE
            WHEN (NOT (cacm.expression IS NULL)) THEN cacm.id
            WHEN (NOT (camt.expression IS NULL)) THEN camt.id
            ELSE NULL::uuid
        END AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    replace(replace(replace(replace(replace((
        CASE
            WHEN (NOT (cacm.expression IS NULL)) THEN cacm.expression
            WHEN (NOT (camt.expression IS NULL)) THEN camt.expression
            ELSE NULL::character varying
        END)::text, ('<course>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ugs.name]))::text), ('<material>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[m.name]))::text), ('<material-type>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[mt.name]))::text), ('<year>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ay.name]))::text), ('<student>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[s.code]))::text) AS expression,
    cm.minimum,
    cm.maximum,
    cm.required,
    'expression'::text AS expression_type,
    true AS needs_evaluate
   FROM (((((((((((((((public.acorn_university_course_materials cm
     JOIN public.acorn_university_academic_year_semesters ays ON ((cm.academic_year_semester_id = ays.id)))
     JOIN public.acorn_university_academic_years ay ON ((ay.id = ays.academic_year_id)))
     JOIN public.acorn_university_courses c ON ((cm.course_id = c.id)))
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_university_hierarchies hi ON (((hi.entity_id = en.id) AND (hi.academic_year_id = ay.id))))
     JOIN public.acorn_user_user_group_versions ugv ON ((hi.user_group_version_id = ugv.id)))
     JOIN public.acorn_user_user_groups ugs ON ((ugv.user_group_id = ugs.id)))
     JOIN public.acorn_user_user_group_version ug ON ((ugv.id = ug.user_group_version_id)))
     JOIN public.acorn_university_students s ON ((ug.user_id = s.user_id)))
     JOIN public.acorn_university_materials m ON ((cm.material_id = m.id)))
     JOIN public.acorn_university_material_types mt ON ((m.material_type_id = mt.id)))
     LEFT JOIN public.acorn_exam_calculation_material_types cmt ON (((mt.id = cmt.material_type_id) AND (cmt.academic_year_id = ays.academic_year_id))))
     LEFT JOIN public.acorn_exam_calculations camt ON ((cmt.calculation_id = camt.id)))
     LEFT JOIN public.acorn_exam_calculation_course_materials ccm ON (((ccm.course_material_id = cm.id) AND (ccm.academic_year_id = ays.academic_year_id))))
     LEFT JOIN public.acorn_exam_calculations cacm ON ((ccm.calculation_id = cacm.id)))
  WHERE (NOT ((cacm.expression IS NULL) AND (camt.expression IS NULL)))
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['course'::character varying, ugs.name, ay.name, cac.name, ct.name, s.code, (
        CASE
            WHEN cac.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying, 'result'::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['course'::character varying, ugs.name, ay.name, cac.name, ct.name, s.code, (
        CASE
            WHEN cac.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying, 'result'::character varying]) AS name,
    s.id AS student_id,
    cc.academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    c.id AS course_id,
    NULL::uuid AS material_id,
    cac.id AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    replace(replace(replace((cac.expression)::text, ('<course>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ugs.name]))::text), ('<year>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ay.name]))::text), ('<student>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[s.code]))::text) AS expression,
    cac.minimum,
    cac.maximum,
    cac.required,
    'expression'::text AS expression_type,
    true AS needs_evaluate
   FROM ((((((((((public.acorn_university_courses c
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_exam_calculation_courses cc ON ((c.id = cc.course_id)))
     JOIN public.acorn_university_academic_years ay ON ((cc.academic_year_id = ay.id)))
     JOIN public.acorn_exam_calculations cac ON ((cc.calculation_id = cac.id)))
     JOIN public.acorn_exam_calculation_types ct ON ((cac.calculation_type_id = ct.id)))
     JOIN public.acorn_university_hierarchies hi ON (((hi.entity_id = en.id) AND (hi.academic_year_id = ay.id))))
     JOIN public.acorn_user_user_group_versions ugv ON ((hi.user_group_version_id = ugv.id)))
     JOIN public.acorn_user_user_groups ugs ON ((ugv.user_group_id = ugs.id)))
     JOIN public.acorn_user_user_group_version ug ON ((ugv.id = ug.user_group_version_id)))
     JOIN public.acorn_university_students s ON ((ug.user_id = s.user_id)))
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['student'::character varying, s.code, ay.name, 'age'::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['student'::character varying, s.code, ay.name, 'age'::character varying]) AS name,
    s.id AS student_id,
    ay.id AS academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS material_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    (EXTRACT(year FROM age(ay.start, u.birth_date)))::character varying AS expression,
    NULL::double precision AS minimum,
    NULL::double precision AS maximum,
    NULL::boolean AS required,
    'formulae'::text AS expression_type,
    false AS needs_evaluate
   FROM (public.acorn_university_students s
     JOIN public.acorn_user_users u ON ((s.user_id = u.id))),
    public.acorn_university_academic_years ay
UNION ALL
 SELECT (concat('::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['course'::character varying, ugs.name, ay.name, 'count'::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['course'::character varying, ugs.name, ay.name, 'count'::character varying]) AS name,
    NULL::uuid AS student_id,
    ay.id AS academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    c.id AS course_id,
    NULL::uuid AS material_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    (count(ug.user_id))::character varying AS expression,
    NULL::double precision AS minimum,
    NULL::double precision AS maximum,
    NULL::boolean AS required,
    'formulae'::text AS expression_type,
    false AS needs_evaluate
   FROM ((((((public.acorn_university_courses c
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_university_hierarchies hi ON ((hi.entity_id = en.id)))
     JOIN public.acorn_user_user_group_versions ugv ON ((hi.user_group_version_id = ugv.id)))
     JOIN public.acorn_user_user_groups ugs ON ((ugv.user_group_id = ugs.id)))
     LEFT JOIN public.acorn_user_user_group_version ug ON ((ugv.id = ug.user_group_version_id)))
     JOIN public.acorn_university_academic_years ay ON ((hi.academic_year_id = ay.id)))
  GROUP BY c.id, en.id, ugs.name, ay.id
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['calculation'::character varying, s.code, ay.name, c.name])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['calculation'::character varying, s.code, ay.name, c.name]) AS name,
    s.id AS student_id,
    ay.id AS academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS material_id,
    c.id AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    replace(replace((c.expression)::text, ('<student>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[s.code]))::text), ('<year>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ay.name]))::text) AS expression,
    c.minimum,
    c.maximum,
    c.required,
    'expression'::text AS expression_type,
    true AS needs_evaluate
   FROM public.acorn_exam_calculations c,
    public.acorn_university_students s,
    public.acorn_university_academic_years ay
  WHERE (NOT (replace(replace((c.expression)::text, ('<student>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[s.code]))::text), ('<year>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ay.name]))::text) ~~ '%<%'::text))
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['project'::character varying, s.code, p.name])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['project'::character varying, s.code, p.name]) AS name,
    s.id AS student_id,
    NULL::uuid AS academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS material_id,
    NULL::uuid AS calculation_id,
    p.id AS project_id,
    NULL::uuid AS interview_id,
    (p.score)::character varying AS expression,
    pr.minimum,
    pr.maximum,
    pr.required,
    'data'::text AS expression_type,
    false AS needs_evaluate
   FROM ((public.acorn_university_project_students p
     JOIN public.acorn_university_projects pr ON ((p.project_id = pr.id)))
     JOIN public.acorn_university_students s ON ((p.owner_student_id = s.id)))
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['interview'::character varying, s.code, i.name])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['interview'::character varying, s.code, i.name]) AS name,
    s.id AS student_id,
    NULL::uuid AS academic_year_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS material_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    i.id AS interview_id,
    (iss.score)::character varying AS expression,
    i.minimum,
    i.maximum,
    i.required,
    'data'::text AS expression_type,
    false AS needs_evaluate
   FROM ((public.acorn_exam_interview_students iss
     JOIN public.acorn_university_students s ON ((iss.student_id = s.id)))
     JOIN public.acorn_exam_interviews i ON ((iss.interview_id = i.id)));


--
-- Name: acorn_calendar_event_parts tr_acorn_calendar_events_generate_event_instances; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_events_generate_event_instances AFTER INSERT OR UPDATE ON public.acorn_calendar_event_parts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_events_generate_event_instances();


--
-- Name: acorn_exam_calculation_course_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_calculation_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_calculation_courses tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_calculation_courses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_calculation_material_types tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_calculation_material_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_calculation_types tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_calculation_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_calculations tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_calculations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_exam_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_exam_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_exams tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_exams FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_interview_students tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_interview_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_interviews tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_interviews FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_scores tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_scores FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_types tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_academic_year_semesters tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_academic_year_semesters FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_academic_years tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_academic_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_course_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_course_years tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_course_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_entities tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_entities FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_hierarchies tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_hierarchies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_lectures tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_lectures FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_material_types tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_material_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_project_students tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_project_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_projects tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_projects FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_semesters tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_semesters FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_student_codes tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_student_codes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_student_statuses tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_student_statuses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_location_addresses tr_acorn_location_addresses_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_addresses_new_replicated_row BEFORE INSERT ON public.acorn_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_addresses ENABLE ALWAYS TRIGGER tr_acorn_location_addresses_new_replicated_row;


--
-- Name: acorn_location_addresses tr_acorn_location_addresses_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_addresses_server_id BEFORE INSERT ON public.acorn_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_area_types tr_acorn_location_area_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_area_types_new_replicated_row BEFORE INSERT ON public.acorn_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_area_types ENABLE ALWAYS TRIGGER tr_acorn_location_area_types_new_replicated_row;


--
-- Name: acorn_location_area_types tr_acorn_location_area_types_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_area_types_server_id BEFORE INSERT ON public.acorn_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_areas tr_acorn_location_areas_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_areas_new_replicated_row BEFORE INSERT ON public.acorn_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_areas ENABLE ALWAYS TRIGGER tr_acorn_location_areas_new_replicated_row;


--
-- Name: acorn_location_areas tr_acorn_location_areas_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_areas_server_id BEFORE INSERT ON public.acorn_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_gps tr_acorn_location_gps_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_gps_new_replicated_row BEFORE INSERT ON public.acorn_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_gps ENABLE ALWAYS TRIGGER tr_acorn_location_gps_new_replicated_row;


--
-- Name: acorn_location_gps tr_acorn_location_gps_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_gps_server_id BEFORE INSERT ON public.acorn_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_locations tr_acorn_location_locations_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_locations_new_replicated_row BEFORE INSERT ON public.acorn_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_locations ENABLE ALWAYS TRIGGER tr_acorn_location_locations_new_replicated_row;


--
-- Name: acorn_location_locations tr_acorn_location_locations_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_locations_server_id BEFORE INSERT ON public.acorn_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_types tr_acorn_location_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_types_new_replicated_row BEFORE INSERT ON public.acorn_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_types ENABLE ALWAYS TRIGGER tr_acorn_location_types_new_replicated_row;


--
-- Name: acorn_location_types tr_acorn_location_types_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_types_server_id BEFORE INSERT ON public.acorn_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_calculation_course_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_calculation_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_calculation_courses tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_calculation_courses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_calculation_material_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_calculation_material_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_calculation_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_calculation_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_calculations tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_calculations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_exam_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_exam_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_exams tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_exams FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_interview_students tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_interview_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_interviews tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_interviews FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_scores tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_scores FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_academic_year_semesters tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_academic_year_semesters FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_academic_years tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_academic_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_course_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_course_years tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_course_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_entities tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_entities FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_hierarchies tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_hierarchies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_lectures tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_lectures FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_material_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_material_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_project_students tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_project_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_projects tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_projects FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_semesters tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_semesters FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_student_codes tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_student_codes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_student_statuses tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_student_statuses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_students tr_acorn_university_change_code; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_university_change_code AFTER INSERT OR UPDATE ON public.acorn_university_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_university_change_code();


--
-- Name: acorn_university_course_materials tr_acorn_university_enrollment_year; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_university_enrollment_year BEFORE INSERT OR UPDATE ON public.acorn_university_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_university_enrollment_year();


--
-- Name: acorn_university_hierarchies tr_acorn_university_hierarchies_delete_version; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_university_hierarchies_delete_version AFTER DELETE ON public.acorn_university_hierarchies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_university_hierarchies_delete_version();


--
-- Name: acorn_user_user_group_version tr_acorn_university_hierarchies_descendants_update; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_university_hierarchies_descendants_update AFTER INSERT OR DELETE OR UPDATE ON public.acorn_user_user_group_version FOR EACH STATEMENT EXECUTE FUNCTION public.fn_acorn_university_hierarchies_descendants_update();


--
-- Name: acorn_university_hierarchies tr_acorn_university_hierarchies_new_version; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_university_hierarchies_new_version BEFORE INSERT ON public.acorn_university_hierarchies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_university_hierarchies_new_version();


--
-- Name: acorn_university_student_codes tr_acorn_university_new_code; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_university_new_code BEFORE INSERT ON public.acorn_university_student_codes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_university_new_code();


--
-- Name: acorn_user_user_groups tr_acorn_user_user_group_first_version; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_user_user_group_first_version AFTER INSERT ON public.acorn_user_user_groups FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_user_user_group_first_version();


--
-- Name: acorn_user_user_group_versions tr_acorn_user_user_group_version; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_user_user_group_version BEFORE INSERT ON public.acorn_user_user_group_versions FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_user_user_group_version();


--
-- Name: acorn_university_hierarchies academic_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT academic_year_id FOREIGN KEY (academic_year_id) REFERENCES public.acorn_university_academic_years(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT academic_year_id ON acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT academic_year_id ON public.acorn_university_hierarchies IS 'global-scope: to
name-object: true';


--
-- Name: acorn_university_academic_year_semesters academic_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT academic_year_id FOREIGN KEY (academic_year_id) REFERENCES public.acorn_university_academic_years(id) NOT VALID;


--
-- Name: CONSTRAINT academic_year_id ON acorn_university_academic_year_semesters; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT academic_year_id ON public.acorn_university_academic_year_semesters IS 'global-scope: to
name-object: true';


--
-- Name: acorn_exam_calculation_courses academic_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT academic_year_id FOREIGN KEY (academic_year_id) REFERENCES public.acorn_university_academic_years(id) NOT VALID;


--
-- Name: CONSTRAINT academic_year_id ON acorn_exam_calculation_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT academic_year_id ON public.acorn_exam_calculation_courses IS 'name-object: true';


--
-- Name: acorn_exam_calculation_material_types academic_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT academic_year_id FOREIGN KEY (academic_year_id) REFERENCES public.acorn_university_academic_years(id);


--
-- Name: CONSTRAINT academic_year_id ON acorn_exam_calculation_material_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT academic_year_id ON public.acorn_exam_calculation_material_types IS 'name-object: true';


--
-- Name: acorn_exam_calculation_course_materials academic_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT academic_year_id FOREIGN KEY (academic_year_id) REFERENCES public.acorn_university_academic_years(id);


--
-- Name: CONSTRAINT academic_year_id ON acorn_exam_calculation_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT academic_year_id ON public.acorn_exam_calculation_course_materials IS 'name-object: true';


--
-- Name: acorn_university_course_materials academic_year_semester_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT academic_year_semester_id FOREIGN KEY (academic_year_semester_id) REFERENCES public.acorn_university_academic_year_semesters(id) NOT VALID;


--
-- Name: CONSTRAINT academic_year_semester_id ON acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT academic_year_semester_id ON public.acorn_university_course_materials IS 'name-object: true';


--
-- Name: acorn_calendar_calendars acorn_calendar_calendars_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_calendars_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_calendars acorn_calendar_calendars_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_calendars_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_part_user_group_event_part_id_fo; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_part_user_group_event_part_id_fo FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_part_user_group_user_group_id_fo; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_part_user_group_user_group_id_fo FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_event_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_event_id_foreign FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_locked_by_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_locked_by_user_id_foreign FOREIGN KEY (locked_by_user_id) REFERENCES public.backend_users(id) ON DELETE SET NULL;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_parent_event_part_id_forei; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_parent_event_part_id_forei FOREIGN KEY (parent_event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acorn_calendar_event_statuses(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_type_id_foreign FOREIGN KEY (type_id) REFERENCES public.acorn_calendar_event_types(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_statuses acorn_calendar_event_statuses_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_statuses
    ADD CONSTRAINT acorn_calendar_event_statuses_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_types acorn_calendar_event_types_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_types
    ADD CONSTRAINT acorn_calendar_event_types_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_events_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_events_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_events_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_instances acorn_calendar_instances_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_instances
    ADD CONSTRAINT acorn_calendar_instances_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_instance_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_instance_id_foreign FOREIGN KEY (instance_id) REFERENCES public.acorn_calendar_instances(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_user_group_id_fore; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_user_group_id_fore FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_message_id_foreig; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_message_id_foreig FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acorn_messaging_status(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_user_language_user acorn_user_language_user_language_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_language_id_foreign FOREIGN KEY (language_id) REFERENCES public.acorn_user_languages(id);


--
-- Name: acorn_user_language_user acorn_user_language_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_user_user_groups acorn_user_user_groups_parent_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_parent_user_group_id_foreign FOREIGN KEY (parent_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE SET NULL;


--
-- Name: acorn_user_user_groups acorn_user_user_groups_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_type_id_foreign FOREIGN KEY (type_id) REFERENCES public.acorn_user_user_group_types(id) ON DELETE SET NULL;


--
-- Name: acorn_location_locations address_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT address_id FOREIGN KEY (address_id) REFERENCES public.acorn_location_addresses(id) NOT VALID;


--
-- Name: acorn_location_addresses addresses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT addresses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_addresses area_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT area_id FOREIGN KEY (area_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_location_areas area_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT area_type_id FOREIGN KEY (area_type_id) REFERENCES public.acorn_location_area_types(id);


--
-- Name: acorn_location_area_types area_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT area_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_areas areas_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT areas_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: backend_users backend_users_acorn_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT backend_users_acorn_user_user_id_foreign FOREIGN KEY (acorn_user_user_id) REFERENCES public.acorn_user_users(id) ON DELETE SET NULL;


--
-- Name: acorn_exam_calculation_courses calculation_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT calculation_id FOREIGN KEY (calculation_id) REFERENCES public.acorn_exam_calculations(id) NOT VALID;


--
-- Name: CONSTRAINT calculation_id ON acorn_exam_calculation_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT calculation_id ON public.acorn_exam_calculation_courses IS 'name-object: true';


--
-- Name: acorn_exam_calculation_material_types calculation_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT calculation_id FOREIGN KEY (calculation_id) REFERENCES public.acorn_exam_calculations(id);


--
-- Name: CONSTRAINT calculation_id ON acorn_exam_calculation_material_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT calculation_id ON public.acorn_exam_calculation_material_types IS 'name-object: true';


--
-- Name: acorn_exam_calculation_course_materials calculation_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT calculation_id FOREIGN KEY (calculation_id) REFERENCES public.acorn_exam_calculations(id);


--
-- Name: CONSTRAINT calculation_id ON acorn_exam_calculation_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT calculation_id ON public.acorn_exam_calculation_course_materials IS 'name-object: true';


--
-- Name: acorn_exam_calculations calculation_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT calculation_type_id FOREIGN KEY (calculation_type_id) REFERENCES public.acorn_exam_calculation_types(id) NOT VALID;


--
-- Name: acorn_university_course_materials course_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT course_id FOREIGN KEY (course_id) REFERENCES public.acorn_university_courses(id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT course_id ON acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT course_id ON public.acorn_university_course_materials IS 'name-object: true';


--
-- Name: acorn_university_course_language course_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_language
    ADD CONSTRAINT course_id FOREIGN KEY (course_id) REFERENCES public.acorn_university_courses(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_exam_calculation_courses course_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT course_id FOREIGN KEY (course_id) REFERENCES public.acorn_university_courses(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT course_id ON acorn_exam_calculation_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT course_id ON public.acorn_exam_calculation_courses IS 'name-object: true';


--
-- Name: acorn_exam_interview_students course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) NOT VALID;


--
-- Name: acorn_university_project_students course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) NOT VALID;


--
-- Name: acorn_university_lectures course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id);


--
-- Name: CONSTRAINT course_material_id ON acorn_university_lectures; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT course_material_id ON public.acorn_university_lectures IS 'nameObject: true';


--
-- Name: acorn_exam_calculation_course_materials course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT course_material_id ON acorn_exam_calculation_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT course_material_id ON public.acorn_exam_calculation_course_materials IS 'name-object: true';


--
-- Name: acorn_exam_exam_materials course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_university_course_materials course_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT course_year_id FOREIGN KEY (course_year_id) REFERENCES public.acorn_university_course_years(id) NOT VALID;


--
-- Name: CONSTRAINT course_year_id ON acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT course_year_id ON public.acorn_university_course_materials IS 'name-object: true';


--
-- Name: acorn_university_academic_years created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_hierarchies created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_material_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exams created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculations created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_scores created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_course_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_project_students created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interviews created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interview_students created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_entities created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_year_semesters created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_course_years created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_years
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semesters created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_projects created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_exam_calculation_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_lectures created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculation_course_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculation_material_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculation_courses created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_student_statuses created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_statuses
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_student_codes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_years created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_hierarchies created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_material_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exams created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculations created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_scores created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_course_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_project_students created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interviews created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interview_students created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_entities created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_academic_year_semesters created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_course_years created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_years
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_semesters created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_projects created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_exam_calculation_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_lectures created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculation_course_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculation_material_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculation_courses created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_student_statuses created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_statuses
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_student_codes created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_course_materials enrollment_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT enrollment_year_id FOREIGN KEY (enrollment_academic_year_id) REFERENCES public.acorn_university_academic_years(id) NOT VALID;


--
-- Name: CONSTRAINT enrollment_year_id ON acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT enrollment_year_id ON public.acorn_university_course_materials IS 'global-scope: to';


--
-- Name: acorn_university_education_authorities entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_education_authorities
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_education_authorities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_education_authorities IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_courses entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_courses
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_courses IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_departments entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_departments
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_departments; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_departments IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_faculties entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_faculties
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_faculties; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_faculties IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_schools entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_schools
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_schools; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_schools IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_universities entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_universities
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_universities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_universities IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_hierarchies entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_hierarchies IS 'global-scope: from
tab-location: 3
name-object: true
multi:
  valueFrom: htmlName
  html: true
';


--
-- Name: acorn_university_student_codes entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id);


--
-- Name: acorn_exam_interview_students event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_year_semesters event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_lectures event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: CONSTRAINT event_id ON acorn_university_lectures; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT event_id ON public.acorn_university_lectures IS 'type: 1to1';


--
-- Name: acorn_exam_exam_materials exam_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT exam_id FOREIGN KEY (exam_id) REFERENCES public.acorn_exam_exams(id) NOT VALID;


--
-- Name: acorn_exam_scores exam_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT exam_material_id FOREIGN KEY (exam_material_id) REFERENCES public.acorn_exam_exam_materials(id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT exam_material_id ON acorn_exam_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT exam_material_id ON public.acorn_exam_scores IS 'type: Xto1';


--
-- Name: acorn_location_gps gps_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT gps_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_areas gps_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id);


--
-- Name: acorn_location_addresses gps_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id) NOT VALID;


--
-- Name: acorn_exam_interview_students interview_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT interview_id FOREIGN KEY (interview_id) REFERENCES public.acorn_exam_interviews(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials interview_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT interview_id FOREIGN KEY (interview_id) REFERENCES public.acorn_exam_interviews(id) NOT VALID;


--
-- Name: acorn_university_course_language language_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_language
    ADD CONSTRAINT language_id FOREIGN KEY (language_id) REFERENCES public.acorn_user_languages(id) NOT VALID;


--
-- Name: acorn_user_user_groups location_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_servers location_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) ON DELETE SET NULL;


--
-- Name: acorn_location_locations locations_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT locations_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_course_materials material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT material_id FOREIGN KEY (material_id) REFERENCES public.acorn_university_materials(id);


--
-- Name: CONSTRAINT material_id ON acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT material_id ON public.acorn_university_course_materials IS 'name-object: true';


--
-- Name: acorn_exam_calculation_material_types material_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT material_type_id FOREIGN KEY (material_type_id) REFERENCES public.acorn_university_material_types(id);


--
-- Name: CONSTRAINT material_type_id ON acorn_exam_calculation_material_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT material_type_id ON public.acorn_exam_calculation_material_types IS 'name-object: true';


--
-- Name: acorn_university_project_students owner_student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT owner_student_id FOREIGN KEY (owner_student_id) REFERENCES public.acorn_university_students(id) NOT VALID;


--
-- Name: CONSTRAINT owner_student_id ON acorn_university_project_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT owner_student_id ON public.acorn_university_project_students IS 'tab-location: 2';


--
-- Name: acorn_location_areas parent_area_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT parent_area_id FOREIGN KEY (parent_area_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_university_hierarchies parent_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT parent_id FOREIGN KEY (parent_id) REFERENCES public.acorn_university_hierarchies(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT parent_id ON acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT parent_id ON public.acorn_university_hierarchies IS 'name-object: true
multi:
  valueFrom: htmlName
  html: true
';


--
-- Name: acorn_location_types parent_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT parent_type_id FOREIGN KEY (parent_type_id) REFERENCES public.acorn_location_types(id);


--
-- Name: acorn_university_project_students project_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT project_id FOREIGN KEY (project_id) REFERENCES public.acorn_university_projects(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials project_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT project_id FOREIGN KEY (project_id) REFERENCES public.acorn_university_projects(id) NOT VALID;


--
-- Name: acorn_user_role_user role_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT role_id FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id);


--
-- Name: acorn_university_academic_year_semesters semester_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT semester_id FOREIGN KEY (semester_id) REFERENCES public.acorn_university_semesters(id) NOT VALID;


--
-- Name: CONSTRAINT semester_id ON acorn_university_academic_year_semesters; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT semester_id ON public.acorn_university_academic_year_semesters IS 'name-object: true';


--
-- Name: acorn_location_locations server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_gps server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_addresses server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_area_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_areas server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_university_hierarchies server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_academic_years server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_material_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_exams server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_calculations server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_scores server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_university_course_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_university_project_students server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_interviews server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_interview_students server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_entities server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_academic_year_semesters server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_course_years server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_years
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_semesters server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_projects server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_exam_calculation_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_lectures server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_calculation_course_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_calculation_material_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_calculation_courses server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_student_statuses server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_statuses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_student_codes server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_interview_students student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT student_id FOREIGN KEY (student_id) REFERENCES public.acorn_university_students(id) NOT VALID;


--
-- Name: CONSTRAINT student_id ON acorn_exam_interview_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT student_id ON public.acorn_exam_interview_students IS 'tab-location: 2';


--
-- Name: acorn_university_student_status student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_status
    ADD CONSTRAINT student_id FOREIGN KEY (student_id) REFERENCES public.acorn_university_students(id) ON DELETE CASCADE;


--
-- Name: acorn_exam_scores student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT student_id FOREIGN KEY (student_id) REFERENCES public.acorn_university_students(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT student_id ON acorn_exam_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT student_id ON public.acorn_exam_scores IS 'field-exclude: true';


--
-- Name: acorn_university_student_codes student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT student_id FOREIGN KEY (student_id) REFERENCES public.acorn_university_students(id) ON DELETE CASCADE;


--
-- Name: acorn_university_student_status student_status_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_status
    ADD CONSTRAINT student_status_id FOREIGN KEY (student_status_id) REFERENCES public.acorn_university_student_statuses(id);


--
-- Name: acorn_exam_interview_students teacher_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT teacher_id FOREIGN KEY (teacher_id) REFERENCES public.acorn_university_teachers(id) NOT VALID;


--
-- Name: acorn_location_locations type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_location_types(id) NOT VALID;


--
-- Name: acorn_exam_exams type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_exam_types(id) NOT VALID;


--
-- Name: acorn_university_materials type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT type_id FOREIGN KEY (material_type_id) REFERENCES public.acorn_university_material_types(id) NOT VALID;


--
-- Name: acorn_location_types types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_academic_years updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_hierarchies updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_material_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exams updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculations updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_scores updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_course_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_project_students updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interviews updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interview_students updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_entities updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_year_semesters updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_course_years updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_years
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semesters updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_projects updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_exam_calculation_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_lectures updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculation_course_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculation_material_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculation_courses updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_student_statuses updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_statuses
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_student_codes updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_years updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_hierarchies updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_material_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exams updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculations updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_scores updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_course_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_project_students updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interviews updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interview_students updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_entities updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_academic_year_semesters updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_year_semesters
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_course_years updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_years
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_semesters updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_projects updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_exam_calculation_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_lectures updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_lectures
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculation_course_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_course_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculation_material_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_material_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculation_courses updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculation_courses
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_student_statuses updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_statuses
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_student_codes updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_student_codes
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_project_students user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_university_entities user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT user_group_id ON acorn_university_entities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_group_id ON public.acorn_university_entities IS 'type: 1to1';


--
-- Name: acorn_user_user_group user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_user_user_group_versions user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_university_hierarchies user_group_version_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT user_group_version_id FOREIGN KEY (user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT user_group_version_id ON acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_group_version_id ON public.acorn_university_hierarchies IS 'type: 1to1
';


--
-- Name: acorn_user_user_group_version user_group_version_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_version
    ADD CONSTRAINT user_group_version_id FOREIGN KEY (user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_university_teachers user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_teachers
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: CONSTRAINT user_id ON acorn_university_teachers; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_id ON public.acorn_university_teachers IS 'type: leaf';


--
-- Name: acorn_user_role_user user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_user_user_group_version user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_version
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_user_user_group user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_university_students user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_students
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT user_id ON acorn_university_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_id ON public.acorn_university_students IS 'type: leaf';


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO token_1 WITH GRANT OPTION;
GRANT ALL ON SCHEMA public TO admin WITH GRANT OPTION;


--
-- Name: FUNCTION cube_in(cstring); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_in(cstring) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO frontend;


--
-- Name: FUNCTION cube_out(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_out(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO frontend;


--
-- Name: FUNCTION cube_recv(internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_recv(internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO frontend;


--
-- Name: FUNCTION cube_send(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_send(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO frontend;


--
-- Name: FUNCTION gtrgm_in(cstring); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_out(public.gtrgm); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION bytea_to_text(data bytea); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO frontend;


--
-- Name: FUNCTION cube(double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO frontend;


--
-- Name: FUNCTION cube(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision) TO frontend;


--
-- Name: FUNCTION cube(double precision[], double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO frontend;


--
-- Name: FUNCTION cube(double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO frontend;


--
-- Name: FUNCTION cube(public.cube, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO frontend;


--
-- Name: FUNCTION cube(public.cube, double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO frontend;


--
-- Name: FUNCTION cube_cmp(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_contained(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_contains(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO frontend;


--
-- Name: FUNCTION cube_coord_llur(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO frontend;


--
-- Name: FUNCTION cube_dim(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO frontend;


--
-- Name: FUNCTION cube_distance(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_enlarge(public.cube, double precision, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO frontend;


--
-- Name: FUNCTION cube_eq(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_ge(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_gt(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_inter(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_is_point(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO frontend;


--
-- Name: FUNCTION cube_le(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_ll_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO frontend;


--
-- Name: FUNCTION cube_lt(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_ne(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_overlap(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_size(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_size(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO frontend;


--
-- Name: FUNCTION cube_subset(public.cube, integer[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO frontend;


--
-- Name: FUNCTION cube_union(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION cube_ur_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO frontend;


--
-- Name: FUNCTION distance_chebyshev(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION distance_taxicab(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO frontend;


--
-- Name: FUNCTION earth(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth() TO frontend;


--
-- Name: FUNCTION gc_to_sec(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO frontend;


--
-- Name: FUNCTION earth_box(public.earth, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO frontend;


--
-- Name: FUNCTION sec_to_gc(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO frontend;


--
-- Name: FUNCTION earth_distance(public.earth, public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO frontend;


--
-- Name: FUNCTION fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_avg(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_avg() TO sz;
GRANT ALL ON FUNCTION public.fn_acorn_avg() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_avg() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_avg() TO frontend;


--
-- Name: FUNCTION fn_acorn_avg(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_events_generate_event_instances(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_is_date(s character varying, d timestamp without time zone); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_seed(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO frontend;


--
-- Name: FUNCTION fn_acorn_calendar_trigger_activity_event(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO frontend;


--
-- Name: FUNCTION fn_acorn_count(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_count() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_count() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_count() TO frontend;


--
-- Name: FUNCTION fn_acorn_count(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_exam_action_results_refresh(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_action_results_refresh() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_action_results_refresh() TO frontend;


--
-- Name: FUNCTION fn_acorn_exam_token_name(VARIADIC p_titles character varying[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_exam_token_name_internal(p_titles character varying[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_exam_token_name_internal(p_title character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_title character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_title character varying) TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_title character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_exam_tokenize(p_expr character varying, level integer); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer) TO frontend;


--
-- Name: FUNCTION fn_acorn_first(anyelement, anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO frontend;


--
-- Name: FUNCTION fn_acorn_last(anyelement, anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO frontend;


--
-- Name: FUNCTION fn_acorn_max(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_max() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_max() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_max() TO frontend;


--
-- Name: FUNCTION fn_acorn_max(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_min(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_min() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_min() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_min() TO frontend;


--
-- Name: FUNCTION fn_acorn_min(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_new_replicated_row(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO frontend;


--
-- Name: FUNCTION fn_acorn_reset_sequences(schema_like character varying, table_like character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_server_id(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO frontend;


--
-- Name: FUNCTION fn_acorn_sum(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_sum() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sum() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sum() TO frontend;


--
-- Name: FUNCTION fn_acorn_sum(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_sum(ints character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_sum(ints character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sum(ints character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sum(ints character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_sumproduct(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_sumproduct() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sumproduct() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sumproduct() TO frontend;


--
-- Name: FUNCTION fn_acorn_sumproduct(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) TO frontend;


--
-- Name: FUNCTION fn_acorn_table_counts(_schema character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_truncate_database(schema_like character varying, table_like character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO frontend;


--
-- Name: FUNCTION fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_action_academic_years_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_action_academic_years_import_2024(import_students boolean, import_bakeloria_2023_2024 boolean, use_counties_as_schools boolean); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_action_academic_years_import_2024(import_students boolean, import_bakeloria_2023_2024 boolean, use_counties_as_schools boolean) TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_action_academic_years_import_2024(import_students boolean, import_bakeloria_2023_2024 boolean, use_counties_as_schools boolean) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean) TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_action_hierarchies_clear(model_id uuid, user_id uuid, p_clear_course_materials boolean, p_for_enrollment_year boolean, p_clear_exams_and_scores boolean, p_confirm boolean) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_action_hierarchies_copy_to(model_id uuid, user_id uuid, p_academic_year_id uuid, p_promote_successful_students boolean, p_copy_materials boolean, p_copy_seminars boolean, p_copy_calculations boolean) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_change_code(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_change_code() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_university_change_code() TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_change_code() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_enrollment_year(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_enrollment_year() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_university_enrollment_year() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_university_enrollment_year() TO frontend;


--
-- Name: FUNCTION fn_acorn_university_hierarchies_delete_version(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_hierarchies_delete_version() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_university_hierarchies_delete_version() TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_hierarchies_delete_version() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_hierarchies_new_version(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_hierarchies_new_version() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_university_hierarchies_new_version() TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_hierarchies_new_version() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_university_new_code(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_university_new_code() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_university_new_code() TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_university_new_code() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_user_code(name character varying, word integer, length integer); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_user_code(name character varying, word integer, length integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_code(name character varying, word integer, length integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_code(name character varying, word integer, length integer) TO frontend;


--
-- Name: FUNCTION fn_acorn_user_code_acronym(name character varying, word integer, length integer); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer, length integer) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer, length integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer, length integer) TO frontend;


--
-- Name: FUNCTION fn_acorn_user_get_seed_user(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO frontend;


--
-- Name: FUNCTION fn_acorn_user_user_group_first_version(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_user_user_group_first_version() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_user_group_first_version() TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_user_user_group_first_version() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_user_user_group_version(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_user_user_group_version() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_user_group_version() TO frontend;
GRANT ALL ON FUNCTION public.fn_acorn_user_user_group_version() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_consistent(internal, public.cube, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO frontend;


--
-- Name: FUNCTION g_cube_distance(internal, public.cube, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO frontend;


--
-- Name: FUNCTION g_cube_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO frontend;


--
-- Name: FUNCTION g_cube_picksplit(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO frontend;


--
-- Name: FUNCTION g_cube_same(public.cube, public.cube, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO frontend;


--
-- Name: FUNCTION g_cube_union(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO frontend;


--
-- Name: FUNCTION geo_distance(point, point); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.geo_distance(point, point) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO frontend;


--
-- Name: FUNCTION gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO frontend;
GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gin_extract_value_trgm(text, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO frontend;
GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO frontend;
GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO frontend;
GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_compress(internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_consistent(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_decompress(internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_distance(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_options(internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_picksplit(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_same(public.gtrgm, public.gtrgm, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_union(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO frontend;
GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION hostname(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.hostname() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.hostname() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.hostname() TO frontend;


--
-- Name: FUNCTION http(request public.http_request); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http(request public.http_request) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO frontend;


--
-- Name: FUNCTION http_delete(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO frontend;


--
-- Name: FUNCTION http_delete(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO frontend;


--
-- Name: FUNCTION http_get(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_get(uri character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO frontend;


--
-- Name: FUNCTION http_get(uri character varying, data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO frontend;


--
-- Name: FUNCTION http_head(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_head(uri character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO frontend;


--
-- Name: FUNCTION http_header(field character varying, value character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO frontend;


--
-- Name: FUNCTION http_list_curlopt(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_list_curlopt() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO frontend;


--
-- Name: FUNCTION http_patch(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO frontend;


--
-- Name: FUNCTION http_post(uri character varying, data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO frontend;


--
-- Name: FUNCTION http_post(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO frontend;


--
-- Name: FUNCTION http_put(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO frontend;


--
-- Name: FUNCTION http_reset_curlopt(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_reset_curlopt() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO frontend;


--
-- Name: FUNCTION http_set_curlopt(curlopt character varying, value character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO frontend;


--
-- Name: FUNCTION latitude(public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.latitude(public.earth) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO frontend;


--
-- Name: FUNCTION ll_to_earth(double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO frontend;


--
-- Name: FUNCTION longitude(public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.longitude(public.earth) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO frontend;


--
-- Name: FUNCTION postgres_fdw_disconnect(text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.postgres_fdw_disconnect(text) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.postgres_fdw_disconnect(text) TO frontend;


--
-- Name: FUNCTION postgres_fdw_disconnect_all(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.postgres_fdw_disconnect_all() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.postgres_fdw_disconnect_all() TO frontend;


--
-- Name: FUNCTION postgres_fdw_get_connections(OUT server_name text, OUT valid boolean); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.postgres_fdw_get_connections(OUT server_name text, OUT valid boolean) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.postgres_fdw_get_connections(OUT server_name text, OUT valid boolean) TO frontend;


--
-- Name: FUNCTION postgres_fdw_handler(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.postgres_fdw_handler() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.postgres_fdw_handler() TO frontend;


--
-- Name: FUNCTION postgres_fdw_validator(text[], oid); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.postgres_fdw_validator(text[], oid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.postgres_fdw_validator(text[], oid) TO frontend;


--
-- Name: FUNCTION set_limit(real); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.set_limit(real) TO frontend;
GRANT ALL ON FUNCTION public.set_limit(real) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION show_limit(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.show_limit() TO frontend;
GRANT ALL ON FUNCTION public.show_limit() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION show_trgm(text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.show_trgm(text) TO frontend;
GRANT ALL ON FUNCTION public.show_trgm(text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION similarity(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.similarity(text, text) TO frontend;
GRANT ALL ON FUNCTION public.similarity(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION similarity_dist(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO frontend;
GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION similarity_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.similarity_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.similarity_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO frontend;
GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION text_to_bytea(data text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO frontend;


--
-- Name: FUNCTION urlencode(string bytea); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(string bytea) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO frontend;


--
-- Name: FUNCTION urlencode(data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO frontend;


--
-- Name: FUNCTION urlencode(string character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(string character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO frontend;


--
-- Name: FUNCTION word_similarity(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.word_similarity(text, text) TO frontend;
GRANT ALL ON FUNCTION public.word_similarity(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_op(text, text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO frontend;
GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION agg_acorn_first(anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO admin WITH GRANT OPTION;


--
-- Name: FUNCTION agg_acorn_last(anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO admin WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_calendars; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_calendars TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_calendars TO frontend;


--
-- Name: TABLE acorn_calendar_event_part_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_event_part_user TO frontend;


--
-- Name: TABLE acorn_calendar_event_part_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_event_part_user_group TO frontend;


--
-- Name: TABLE acorn_calendar_event_parts; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_parts TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_event_parts TO frontend;


--
-- Name: TABLE acorn_calendar_event_statuses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_event_statuses TO frontend;


--
-- Name: TABLE acorn_calendar_event_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_event_types TO frontend;


--
-- Name: TABLE acorn_calendar_events; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_events TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_events TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_events TO frontend;


--
-- Name: TABLE acorn_calendar_instances; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_instances TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_instances TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_calendar_instances TO frontend;


--
-- Name: TABLE acorn_exam_calculation_course_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_calculation_course_materials TO admin WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_calculation_course_materials TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_calculation_course_materials TO frontend;


--
-- Name: TABLE acorn_exam_calculation_courses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_calculation_courses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_calculation_courses TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_calculation_courses TO frontend;


--
-- Name: TABLE acorn_exam_calculation_material_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_calculation_material_types TO admin WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_calculation_material_types TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_calculation_material_types TO frontend;


--
-- Name: TABLE acorn_exam_calculation_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_calculation_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_calculation_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_calculation_types TO frontend;


--
-- Name: TABLE acorn_exam_calculations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_calculations TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_calculations TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_calculations TO frontend;


--
-- Name: TABLE acorn_exam_exam_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_exam_materials TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_exam_materials TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_exam_materials TO frontend;


--
-- Name: TABLE acorn_exam_exams; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_exams TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_exams TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_exams TO frontend;


--
-- Name: TABLE acorn_exam_tokens; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_tokens TO admin WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_tokens TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_tokens TO frontend;


--
-- Name: TABLE acorn_exam_result_internals; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_result_internals TO admin WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_result_internals TO sz;
GRANT ALL ON TABLE public.acorn_exam_result_internals TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_result_internals TO frontend;


--
-- Name: TABLE acorn_exam_results; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_results TO admin WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_results TO sz;
GRANT ALL ON TABLE public.acorn_exam_results TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_results TO frontend;


--
-- Name: TABLE acorn_exam_scores; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_scores TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_scores TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_scores TO frontend;


--
-- Name: TABLE acorn_exam_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_types TO frontend;


--
-- Name: TABLE acorn_university_academic_year_semesters; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_academic_year_semesters TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_academic_year_semesters TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_academic_year_semesters TO frontend;


--
-- Name: SEQUENCE acorn_university_year_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.acorn_university_year_seq TO token_1 WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.acorn_university_year_seq TO frontend;


--
-- Name: TABLE acorn_university_academic_years; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_academic_years TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_academic_years TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_academic_years TO frontend;


--
-- Name: TABLE acorn_university_course_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_course_materials TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_course_materials TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_course_materials TO frontend;


--
-- Name: TABLE acorn_university_courses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_courses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_courses TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_courses TO frontend;


--
-- Name: TABLE acorn_university_entities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_entities TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_entities TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_entities TO frontend;


--
-- Name: TABLE acorn_university_hierarchies; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_hierarchies TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_hierarchies TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_hierarchies TO frontend;


--
-- Name: TABLE acorn_university_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_materials TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_materials TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_materials TO frontend;


--
-- Name: TABLE acorn_university_students; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_students TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_students TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_students TO frontend;


--
-- Name: TABLE acorn_user_user_group_version; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_version TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_user_group_version TO frontend;
GRANT ALL ON TABLE public.acorn_user_user_group_version TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_groups TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_groups TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_user_groups TO frontend;


--
-- Name: TABLE acorn_user_users; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_users TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_users TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_users TO frontend;


--
-- Name: TABLE acorn_exam_data_entry_scores; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_data_entry_scores TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_data_entry_scores TO frontend;
GRANT ALL ON TABLE public.acorn_exam_data_entry_scores TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_interview_students; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_interview_students TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_interview_students TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_interview_students TO frontend;


--
-- Name: TABLE acorn_exam_interviews; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_interviews TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_exam_interviews TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_exam_interviews TO frontend;


--
-- Name: TABLE acorn_location_addresses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_addresses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_addresses TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_addresses TO frontend;


--
-- Name: TABLE acorn_location_area_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_area_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_area_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_area_types TO frontend;


--
-- Name: TABLE acorn_location_areas; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_areas TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_areas TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_areas TO frontend;


--
-- Name: TABLE acorn_location_gps; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_gps TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_gps TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_gps TO frontend;


--
-- Name: TABLE acorn_location_locations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_locations TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_locations TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_locations TO frontend;


--
-- Name: TABLE acorn_location_lookup; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_lookup TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_lookup TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_lookup TO frontend;


--
-- Name: TABLE acorn_location_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_location_types TO frontend;


--
-- Name: TABLE acorn_messaging_action; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_action TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_action TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_action TO frontend;


--
-- Name: TABLE acorn_messaging_label; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_label TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_label TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_label TO frontend;


--
-- Name: TABLE acorn_messaging_message; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_message TO frontend;


--
-- Name: TABLE acorn_messaging_message_instance; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_instance TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_message_instance TO frontend;


--
-- Name: TABLE acorn_messaging_message_message; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_message TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_message_message TO frontend;


--
-- Name: TABLE acorn_messaging_message_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_message_user TO frontend;


--
-- Name: TABLE acorn_messaging_message_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_message_user_group TO frontend;


--
-- Name: TABLE acorn_messaging_status; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_status TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_status TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_status TO frontend;


--
-- Name: TABLE acorn_messaging_user_message_status; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_messaging_user_message_status TO frontend;


--
-- Name: TABLE acorn_reporting_reports; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_reporting_reports TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_reporting_reports TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_reporting_reports TO frontend;


--
-- Name: SEQUENCE acorn_reporting_reports_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.acorn_reporting_reports_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.acorn_reporting_reports_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.acorn_reporting_reports_id_seq TO frontend;


--
-- Name: TABLE acorn_servers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_servers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_servers TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_servers TO frontend;


--
-- Name: TABLE acorn_university_course_language; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_course_language TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_course_language TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_course_language TO frontend;


--
-- Name: TABLE acorn_university_course_years; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_course_years TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_course_years TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_course_years TO frontend;


--
-- Name: TABLE acorn_university_departments; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_departments TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_departments TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_departments TO frontend;


--
-- Name: TABLE acorn_university_education_authorities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_education_authorities TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_education_authorities TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_education_authorities TO frontend;


--
-- Name: TABLE acorn_university_faculties; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_faculties TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_faculties TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_faculties TO frontend;


--
-- Name: TABLE acorn_university_lectures; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_lectures TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_lectures TO frontend;


--
-- Name: TABLE acorn_university_material_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_material_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_material_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_material_types TO frontend;


--
-- Name: TABLE acorn_university_project_students; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_project_students TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_project_students TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_project_students TO frontend;


--
-- Name: TABLE acorn_university_projects; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_projects TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_projects TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_projects TO frontend;


--
-- Name: TABLE acorn_university_schools; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_schools TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_schools TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_schools TO frontend;


--
-- Name: TABLE acorn_university_semesters; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_semesters TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_semesters TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_semesters TO frontend;


--
-- Name: TABLE acorn_university_teachers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_teachers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_teachers TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_teachers TO frontend;


--
-- Name: TABLE acorn_university_universities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_universities TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_university_universities TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_university_universities TO frontend;


--
-- Name: TABLE acorn_user_language_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_language_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_language_user TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_language_user TO frontend;


--
-- Name: TABLE acorn_user_languages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_languages TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_languages TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_languages TO frontend;


--
-- Name: TABLE acorn_user_mail_blockers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_mail_blockers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_mail_blockers TO frontend;


--
-- Name: TABLE acorn_user_role_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_role_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_role_user TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_role_user TO frontend;


--
-- Name: TABLE acorn_user_roles; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_roles TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_roles TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_roles TO frontend;


--
-- Name: TABLE acorn_user_throttle; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_throttle TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_throttle TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_throttle TO frontend;


--
-- Name: TABLE acorn_user_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_user_group TO frontend;


--
-- Name: TABLE acorn_user_user_group_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_user_group_types TO frontend;


--
-- Name: TABLE acorn_user_user_group_version_usages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.acorn_user_user_group_version_usages TO frontend;


--
-- Name: TABLE backend_access_log; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_access_log TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_access_log TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_access_log TO frontend;


--
-- Name: SEQUENCE backend_access_log_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.backend_access_log_id_seq TO frontend;


--
-- Name: TABLE backend_user_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_groups TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_groups TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_user_groups TO frontend;


--
-- Name: SEQUENCE backend_user_groups_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.backend_user_groups_id_seq TO frontend;


--
-- Name: TABLE backend_user_preferences; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_preferences TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_preferences TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_user_preferences TO frontend;


--
-- Name: SEQUENCE backend_user_preferences_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.backend_user_preferences_id_seq TO frontend;


--
-- Name: TABLE backend_user_roles; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_roles TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_roles TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_user_roles TO frontend;


--
-- Name: SEQUENCE backend_user_roles_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.backend_user_roles_id_seq TO frontend;


--
-- Name: TABLE backend_user_throttle; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_throttle TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_throttle TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_user_throttle TO frontend;


--
-- Name: SEQUENCE backend_user_throttle_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.backend_user_throttle_id_seq TO frontend;


--
-- Name: TABLE backend_users; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_users TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_users TO frontend;


--
-- Name: TABLE backend_users_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_users_groups TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users_groups TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.backend_users_groups TO frontend;


--
-- Name: SEQUENCE backend_users_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_users_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.backend_users_id_seq TO frontend;


--
-- Name: TABLE cache; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cache TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cache TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.cache TO frontend;


--
-- Name: TABLE cms_theme_data; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_data TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_data TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.cms_theme_data TO frontend;


--
-- Name: SEQUENCE cms_theme_data_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.cms_theme_data_id_seq TO frontend;


--
-- Name: TABLE cms_theme_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_logs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_logs TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.cms_theme_logs TO frontend;


--
-- Name: SEQUENCE cms_theme_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.cms_theme_logs_id_seq TO frontend;


--
-- Name: TABLE cms_theme_templates; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_templates TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_templates TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.cms_theme_templates TO frontend;


--
-- Name: SEQUENCE cms_theme_templates_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.cms_theme_templates_id_seq TO frontend;


--
-- Name: TABLE deferred_bindings; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.deferred_bindings TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.deferred_bindings TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.deferred_bindings TO frontend;


--
-- Name: SEQUENCE deferred_bindings_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.deferred_bindings_id_seq TO frontend;


--
-- Name: TABLE failed_jobs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.failed_jobs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.failed_jobs TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.failed_jobs TO frontend;


--
-- Name: SEQUENCE failed_jobs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.failed_jobs_id_seq TO frontend;


--
-- Name: TABLE job_batches; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.job_batches TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.job_batches TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.job_batches TO frontend;


--
-- Name: TABLE jobs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.jobs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.jobs TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.jobs TO frontend;


--
-- Name: SEQUENCE jobs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.jobs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.jobs_id_seq TO frontend;


--
-- Name: TABLE migrations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.migrations TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.migrations TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.migrations TO frontend;


--
-- Name: SEQUENCE migrations_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.migrations_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.migrations_id_seq TO frontend;


--
-- Name: TABLE winter_location_countries; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_location_countries TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_countries TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.winter_location_countries TO frontend;


--
-- Name: SEQUENCE rainlab_location_countries_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.rainlab_location_countries_id_seq TO frontend;


--
-- Name: TABLE winter_location_states; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_location_states TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_states TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.winter_location_states TO frontend;


--
-- Name: SEQUENCE rainlab_location_states_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.rainlab_location_states_id_seq TO frontend;


--
-- Name: TABLE winter_translate_attributes; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_attributes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_attributes TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.winter_translate_attributes TO frontend;


--
-- Name: SEQUENCE rainlab_translate_attributes_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.rainlab_translate_attributes_id_seq TO frontend;


--
-- Name: TABLE winter_translate_indexes; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_indexes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_indexes TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.winter_translate_indexes TO frontend;


--
-- Name: SEQUENCE rainlab_translate_indexes_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.rainlab_translate_indexes_id_seq TO frontend;


--
-- Name: TABLE winter_translate_locales; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_locales TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_locales TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.winter_translate_locales TO frontend;


--
-- Name: SEQUENCE rainlab_translate_locales_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.rainlab_translate_locales_id_seq TO frontend;


--
-- Name: TABLE winter_translate_messages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_messages TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_messages TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.winter_translate_messages TO frontend;


--
-- Name: SEQUENCE rainlab_translate_messages_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.rainlab_translate_messages_id_seq TO frontend;


--
-- Name: TABLE sessions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.sessions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.sessions TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.sessions TO frontend;


--
-- Name: TABLE system_event_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_event_logs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_event_logs TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_event_logs TO frontend;


--
-- Name: SEQUENCE system_event_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_event_logs_id_seq TO frontend;


--
-- Name: TABLE system_files; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_files TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_files TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_files TO frontend;


--
-- Name: SEQUENCE system_files_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_files_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_files_id_seq TO frontend;


--
-- Name: TABLE system_mail_layouts; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_layouts TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_layouts TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_mail_layouts TO frontend;


--
-- Name: SEQUENCE system_mail_layouts_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_mail_layouts_id_seq TO frontend;


--
-- Name: TABLE system_mail_partials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_partials TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_partials TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_mail_partials TO frontend;


--
-- Name: SEQUENCE system_mail_partials_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_mail_partials_id_seq TO frontend;


--
-- Name: TABLE system_mail_templates; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_templates TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_templates TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_mail_templates TO frontend;


--
-- Name: SEQUENCE system_mail_templates_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_mail_templates_id_seq TO frontend;


--
-- Name: TABLE system_parameters; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_parameters TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_parameters TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_parameters TO frontend;


--
-- Name: SEQUENCE system_parameters_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_parameters_id_seq TO frontend;


--
-- Name: TABLE system_plugin_history; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_plugin_history TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_history TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_plugin_history TO frontend;


--
-- Name: SEQUENCE system_plugin_history_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_plugin_history_id_seq TO frontend;


--
-- Name: TABLE system_plugin_versions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_plugin_versions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_versions TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_plugin_versions TO frontend;


--
-- Name: SEQUENCE system_plugin_versions_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_plugin_versions_id_seq TO frontend;


--
-- Name: TABLE system_request_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_request_logs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_request_logs TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_request_logs TO frontend;


--
-- Name: SEQUENCE system_request_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_request_logs_id_seq TO frontend;


--
-- Name: TABLE system_revisions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_revisions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_revisions TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_revisions TO frontend;


--
-- Name: SEQUENCE system_revisions_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_revisions_id_seq TO frontend;


--
-- Name: TABLE system_settings; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_settings TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_settings TO admin WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.system_settings TO frontend;


--
-- Name: SEQUENCE system_settings_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_settings_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO admin WITH GRANT OPTION;
GRANT SELECT,USAGE ON SEQUENCE public.system_settings_id_seq TO frontend;


--
-- Name: TABLE university_mofadala_branches; Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON TABLE public.university_mofadala_branches TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.university_mofadala_branches TO frontend;


--
-- Name: TABLE university_mofadala_departments; Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON TABLE public.university_mofadala_departments TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.university_mofadala_departments TO frontend;


--
-- Name: TABLE university_mofadala_universities; Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON TABLE public.university_mofadala_universities TO token_1 WITH GRANT OPTION;
GRANT SELECT,TRIGGER ON TABLE public.university_mofadala_universities TO frontend;


--
-- Name: acorn_exam_result_internals; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: university
--

REFRESH MATERIALIZED VIEW public.acorn_exam_result_internals;


--
-- PostgreSQL database dump complete
--

