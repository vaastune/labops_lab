-- ops-setup.sql: run ONCE as the administrator (postgres) to prepare the lab.
-- Safe to run again: it removes what it created before and creates it again.
-- disconnect anyone still using the lab databases, otherwise DROP DATABASE is refused

SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE datname IN ('opslab', 'opslab_ci', 'opslab_restore') AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS opslab;
DROP DATABASE IF EXISTS opslab_ci;
DROP DATABASE IF EXISTS opslab_restore;
DO $$
BEGIN
 IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ops_user') THEN
 DROP OWNED BY ops_user;
 DROP ROLE ops_user;
 END IF;
END $$;
-- The automation account: can create scratch databases, read monitoring views,
-- and change ONLY these three settings (PostgreSQL 15+ parameter privileges).
CREATE ROLE ops_user LOGIN PASSWORD 'ops_pass_123' CREATEDB;
GRANT pg_monitor TO ops_user;
GRANT ALTER SYSTEM ON PARAMETER work_mem, log_min_duration_statement, idle_in_transaction_session_timeout TO
ops_user;
CREATE DATABASE opslab OWNER ops_user;
-- function privileges belong to ONE database, so connect to opslab first
\c opslab
GRANT EXECUTE ON FUNCTION pg_reload_conf() TO ops_user;
