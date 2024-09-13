CREATE SCHEMA IF NOT EXISTS "public";
-- Extra schema to sandbox extensible product tables
CREATE SCHEMA IF NOT EXISTS "product";
SET search_path TO public,product;

-- In-built
create extension IF NOT EXISTS "cube";
-- select (point(-0.1277,51.5073) <@> point(-74.006,40.7144)) as distance;
create extension IF NOT EXISTS "earthdistance";

-- Installed by acorn-setup-laptop
create extension IF NOT EXISTS "hostname";
create extension IF NOT EXISTS "http";
