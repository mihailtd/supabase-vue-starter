CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION supabase_admin;

GRANT usage ON SCHEMA storage TO postgres, anon, authenticated, service_role;

ALTER DEFAULT privileges IN SCHEMA storage GRANT ALL ON tables TO postgres, anon, authenticated, service_role;

ALTER DEFAULT privileges IN SCHEMA storage GRANT ALL ON functions TO postgres, anon, authenticated, service_role;

ALTER DEFAULT privileges IN SCHEMA storage GRANT ALL ON sequences TO postgres, anon, authenticated, service_role;

CREATE TABLE "storage"."buckets" (
  "id" text NOT NULL,
  "name" text NOT NULL,
  "owner" uuid,
  "created_at" timestamptz DEFAULT now(),
  "updated_at" timestamptz DEFAULT now(),
  CONSTRAINT "buckets_owner_fkey" FOREIGN KEY ("owner") REFERENCES "auth"."users" ("id"),
  PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "bname" ON "storage"."buckets" USING BTREE ("name");

CREATE TABLE "storage"."objects" (
  "id" uuid NOT NULL DEFAULT extensions.uuid_generate_v4 (),
  "bucket_id" text,
  "name" text,
  "owner" uuid,
  "created_at" timestamptz DEFAULT now(),
  "updated_at" timestamptz DEFAULT now(),
  "last_accessed_at" timestamptz DEFAULT now(),
  "metadata" jsonb,
  CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets" ("id"),
  CONSTRAINT "objects_owner_fkey" FOREIGN KEY ("owner") REFERENCES "auth"."users" ("id"),
  PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "bucketid_objname" ON "storage"."objects" USING BTREE ("bucket_id", "name");

CREATE INDEX name_prefix_search ON storage.objects (name text_pattern_ops);

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

CREATE FUNCTION storage.foldername (name text)
  RETURNS text[]
  LANGUAGE plpgsql
  AS $function$
DECLARE
  _parts text[];
BEGIN
  SELECT
    string_to_array(name, '/') INTO _parts;
  RETURN _parts[1:array_length(_parts, 1) - 1];
END
$function$;

CREATE FUNCTION storage.filename (name text)
  RETURNS text
  LANGUAGE plpgsql
  AS $function$
DECLARE
  _parts text[];
BEGIN
  SELECT
    string_to_array(name, '/') INTO _parts;
  RETURN _parts[array_length(_parts, 1)];
END
$function$;

CREATE FUNCTION storage.extension (name text)
  RETURNS text
  LANGUAGE plpgsql
  AS $function$
DECLARE
  _parts text[];
  _filename text;
BEGIN
  SELECT
    string_to_array(name, '/') INTO _parts;
  SELECT
    _parts[array_length(_parts, 1)] INTO _filename;
  -- @todo return the last part instead of 2
  RETURN split_part(_filename, '.', 2);
END
$function$;

CREATE FUNCTION storage.search (prefix text, bucketname text, limits int DEFAULT 100, levels int DEFAULT 1, offsets int DEFAULT 0)
  RETURNS TABLE (
    name text,
    id uuid,
    updated_at timestamptz,
    created_at timestamptz,
    last_accessed_at timestamptz,
    metadata jsonb)
  LANGUAGE plpgsql
  AS $function$
DECLARE
  _bucketId text;
BEGIN
  -- will be replaced by migrations when server starts
  -- saving space for cloud-init
END
$function$;

-- create migrations table
-- https://github.com/ThomWright/postgres-migrations/blob/master/src/migrations/0_create-migrations-table.sql
-- we add this table here and not let it be auto-created so that the permissions are properly applied to it
CREATE TABLE IF NOT EXISTS storage.migrations (
  id integer PRIMARY KEY,
  name varchar(100) UNIQUE NOT NULL,
  hash varchar(40) NOT NULL, -- sha1 hex encoded hash of the file name and contents, to ensure it hasn't been altered since applying the migration
  executed_at timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE USER supabase_storage_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;

GRANT ALL PRIVILEGES ON SCHEMA storage TO supabase_storage_admin;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;

ALTER USER supabase_storage_admin SET search_path = "storage";

ALTER TABLE "storage".objects OWNER TO supabase_storage_admin;

ALTER TABLE "storage".buckets OWNER TO supabase_storage_admin;

ALTER TABLE "storage".migrations OWNER TO supabase_storage_admin;

ALTER FUNCTION "storage".foldername (text) OWNER TO supabase_storage_admin;

ALTER FUNCTION "storage".filename (text) OWNER TO supabase_storage_admin;

ALTER FUNCTION "storage".extension (text) OWNER TO supabase_storage_admin;

ALTER FUNCTION "storage".search (text, text, int, int, int) OWNER TO supabase_storage_admin;
