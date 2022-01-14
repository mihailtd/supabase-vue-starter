ALTER ROLE postgres SET search_path TO "\$user", public, extensions;

CREATE OR REPLACE FUNCTION extensions.notify_api_restart ()
  RETURNS event_trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  NOTIFY ddl_command_end;
END;
$$;

CREATE EVENT TRIGGER api_restart ON ddl_command_end
  EXECUTE PROCEDURE extensions.notify_api_restart ();

COMMENT ON FUNCTION extensions.notify_api_restart IS 'Sends a notification to the API to restart. If your database schema has changed, this is required so that Supabase can rebuild the relationships.';

-- Trigger for pg_cron
CREATE OR REPLACE FUNCTION extensions.grant_pg_cron_access ()
  RETURNS event_trigger
  LANGUAGE plpgsql
  AS $$
DECLARE
  schema_is_cron bool;
BEGIN
  schema_is_cron = (
    SELECT
      n.nspname = 'cron'
    FROM
      pg_event_trigger_ddl_commands () AS ev
    LEFT JOIN pg_catalog.pg_namespace AS n ON ev.objid = n.oid);
  IF schema_is_cron THEN
    GRANT usage ON SCHEMA cron TO postgres WITH GRANT option;
    ALTER DEFAULT privileges IN SCHEMA cron GRANT ALL ON tables TO postgres WITH GRANT option;
    ALTER DEFAULT privileges IN SCHEMA cron GRANT ALL ON functions TO postgres WITH GRANT option;
    ALTER DEFAULT privileges IN SCHEMA cron GRANT ALL ON sequences TO postgres WITH GRANT option;
    ALTER DEFAULT privileges FOR USER supabase_admin IN SCHEMA cron GRANT ALL ON sequences TO postgres WITH GRANT option;
    ALTER DEFAULT privileges FOR USER supabase_admin IN SCHEMA cron GRANT ALL ON tables TO postgres WITH GRANT option;
    ALTER DEFAULT privileges FOR USER supabase_admin IN SCHEMA cron GRANT ALL ON functions TO postgres WITH GRANT option;
    GRANT ALL privileges ON ALL tables IN SCHEMA cron TO postgres WITH GRANT option;
  END IF;
END;
$$;

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
  WHEN TAG IN ('CREATE SCHEMA')
    EXECUTE PROCEDURE extensions.grant_pg_cron_access ();

COMMENT ON FUNCTION extensions.grant_pg_cron_access IS 'Grants access to pg_cron';

-- Supabase dashboard user
CREATE ROLE dashboard_user NOSUPERUSER CREATEDB CREATEROLE REPLICATION;

GRANT ALL ON DATABASE postgres TO dashboard_user;

GRANT ALL ON SCHEMA auth TO dashboard_user;

GRANT ALL ON SCHEMA extensions TO dashboard_user;

GRANT ALL ON SCHEMA storage TO dashboard_user;

GRANT ALL ON ALL TABLES IN SCHEMA auth TO dashboard_user;

GRANT ALL ON ALL TABLES IN SCHEMA extensions TO dashboard_user;

-- GRANT ALL ON ALL TABLES IN SCHEMA storage TO dashboard_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO dashboard_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO dashboard_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA extensions TO dashboard_user;

GRANT ALL ON ALL ROUTINES IN SCHEMA auth TO dashboard_user;

GRANT ALL ON ALL ROUTINES IN SCHEMA storage TO dashboard_user;

GRANT ALL ON ALL ROUTINES IN SCHEMA extensions TO dashboard_user;
