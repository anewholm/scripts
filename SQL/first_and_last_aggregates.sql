-- Create a function that always returns the first non-NULL value:
CREATE OR REPLACE FUNCTION public.fn_acorn_lojistiks_first_agg (anyelement, anyelement)
  RETURNS anyelement
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE AS
'SELECT $1';

-- Then wrap an aggregate around it:
CREATE OR REPLACE AGGREGATE public.agg_acorn_lojistiks_first (anyelement) (
  SFUNC    = public.fn_acorn_lojistiks_first_agg
, STYPE    = anyelement
, PARALLEL = safe
);

-- Create a function that always returns the last non-NULL value:
CREATE OR REPLACE FUNCTION public.fn_acorn_lojistiks_last_agg (anyelement, anyelement)
  RETURNS anyelement
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE AS
'SELECT $2';

-- Then wrap an aggregate around it:
CREATE OR REPLACE AGGREGATE public.agg_acorn_lojistiks_last (anyelement) (
  SFUNC    = public.fn_acorn_lojistiks_last_agg
, STYPE    = anyelement
, PARALLEL = safe
);
