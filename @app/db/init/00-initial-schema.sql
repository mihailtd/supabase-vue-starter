-- Set up realtime
CREATE SCHEMA IF NOT EXISTS realtime;

-- create publication supabase_realtime; -- defaults to empty publication
CREATE publication supabase_realtime;

-- Supabase super admin
CREATE USER supabase_admin;

ALTER USER supabase_admin WITH superuser createdb createrole replication bypassrls;

-- Extension namespacing
CREATE SCHEMA IF NOT EXISTS extensions;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;

-- Set up auth roles for the developer
CREATE ROLE anon nologin noinherit;

CREATE ROLE authenticated nologin noinherit;

-- "logged in" user: web_user, app_user, etc
CREATE ROLE service_role nologin noinherit bypassrls;

-- allow developers to create JWT's that bypass their policies
CREATE USER authenticator noinherit;

GRANT anon TO authenticator;

GRANT authenticated TO authenticator;

GRANT service_role TO authenticator;

GRANT supabase_admin TO authenticator;

GRANT usage ON SCHEMA public TO postgres, anon, authenticated, service_role;

ALTER DEFAULT privileges IN SCHEMA public GRANT ALL ON tables TO postgres, anon, authenticated, service_role;

ALTER DEFAULT privileges IN SCHEMA public GRANT ALL ON functions TO postgres, anon, authenticated, service_role;

ALTER DEFAULT privileges IN SCHEMA public GRANT ALL ON sequences TO postgres, anon, authenticated, service_role;

-- Allow Extensions to be used in the API
GRANT usage ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Set up namespacing
ALTER USER supabase_admin SET search_path TO public, extensions;

-- don't include the "auth" schema
-- These are required so that the users receive grants whenever "supabase_admin" creates tables/function
ALTER DEFAULT privileges FOR USER supabase_admin IN SCHEMA public GRANT ALL ON sequences TO postgres, anon,
  authenticated, service_role;

ALTER DEFAULT privileges FOR USER supabase_admin IN SCHEMA public GRANT ALL ON tables TO postgres, anon, authenticated,
  service_role;

ALTER DEFAULT privileges FOR USER supabase_admin IN SCHEMA public GRANT ALL ON functions TO postgres, anon,
  authenticated, service_role;

-- Set short statement/query timeouts for API roles
ALTER ROLE anon SET statement_timeout = '3s';

ALTER ROLE authenticated SET statement_timeout = '8s';
