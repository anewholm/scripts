CREATE SEQUENCE IF NOT EXISTS public.rainlab_translate_attributes_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;
CREATE SEQUENCE IF NOT EXISTS public.rainlab_translate_indexes_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;
CREATE SEQUENCE IF NOT EXISTS public.rainlab_translate_locales_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;
CREATE SEQUENCE IF NOT EXISTS public.rainlab_translate_messages_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;



CREATE TABLE IF NOT EXISTS public.winter_translate_attributes
(
    id integer NOT NULL DEFAULT nextval('rainlab_translate_attributes_id_seq'::regclass),
    locale character varying(255) COLLATE pg_catalog."default" NOT NULL,
    model_id character varying(255) COLLATE pg_catalog."default",
    model_type character varying(255) COLLATE pg_catalog."default",
    attribute_data text COLLATE pg_catalog."default",
    CONSTRAINT rainlab_translate_attributes_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_attributes_locale_index
    ON public.winter_translate_attributes USING btree
    (locale COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_attributes_model_id_index
    ON public.winter_translate_attributes USING btree
    (model_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_attributes_model_type_index
    ON public.winter_translate_attributes USING btree
    (model_type COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS public.winter_translate_indexes
(
    id integer NOT NULL DEFAULT nextval('rainlab_translate_indexes_id_seq'::regclass),
    locale character varying(255) COLLATE pg_catalog."default" NOT NULL,
    model_id character varying(255) COLLATE pg_catalog."default",
    model_type character varying(255) COLLATE pg_catalog."default",
    item character varying(255) COLLATE pg_catalog."default",
    value text COLLATE pg_catalog."default",
    CONSTRAINT rainlab_translate_indexes_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_indexes_item_index
    ON public.winter_translate_indexes USING btree
    (item COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_indexes_locale_index
    ON public.winter_translate_indexes USING btree
    (locale COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_indexes_model_id_index
    ON public.winter_translate_indexes USING btree
    (model_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_indexes_model_type_index
    ON public.winter_translate_indexes USING btree
    (model_type COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS public.winter_translate_locales
(
    id integer NOT NULL DEFAULT nextval('rainlab_translate_locales_id_seq'::regclass),
    code character varying(255) COLLATE pg_catalog."default" NOT NULL,
    name character varying(255) COLLATE pg_catalog."default",
    is_default boolean NOT NULL DEFAULT false,
    is_enabled boolean NOT NULL DEFAULT false,
    sort_order integer NOT NULL DEFAULT 0,
    CONSTRAINT rainlab_translate_locales_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_locales_code_index
    ON public.winter_translate_locales USING btree
    (code COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_locales_name_index
    ON public.winter_translate_locales USING btree
    (name COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS public.winter_translate_messages
(
    id integer NOT NULL DEFAULT nextval('rainlab_translate_messages_id_seq'::regclass),
    code character varying(255) COLLATE pg_catalog."default",
    message_data text COLLATE pg_catalog."default",
    found boolean NOT NULL DEFAULT true,
    code_pre_2_1_0 character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT rainlab_translate_messages_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rainlab_translate_messages_code_index
    ON public.winter_translate_messages USING btree
    (code COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS winter_translate_messages_code_pre_2_1_0_index
    ON public.winter_translate_messages USING btree
    (code_pre_2_1_0 COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.winter_translate_attributes
    OWNER to university;
ALTER TABLE IF EXISTS public.winter_translate_indexes
    OWNER to university;
ALTER TABLE IF EXISTS public.winter_translate_locales
    OWNER to university;
ALTER TABLE IF EXISTS public.winter_translate_messages
    OWNER to university;
	
ALTER SEQUENCE public.rainlab_translate_attributes_id_seq
    OWNER TO university;
ALTER SEQUENCE public.rainlab_translate_indexes_id_seq
    OWNER TO university;
ALTER SEQUENCE public.rainlab_translate_locales_id_seq
    OWNER TO university;
ALTER SEQUENCE public.rainlab_translate_messages_id_seq
    OWNER TO university;


ALTER SEQUENCE public.rainlab_translate_attributes_id_seq
    OWNED BY public.winter_translate_attributes.id;
ALTER SEQUENCE public.rainlab_translate_indexes_id_seq
    OWNED BY public.winter_translate_indexes.id;
ALTER SEQUENCE public.rainlab_translate_locales_id_seq
    OWNED BY public.winter_translate_locales.id;
ALTER SEQUENCE public.rainlab_translate_messages_id_seq
    OWNED BY public.winter_translate_messages.id;

