#!/usr/bin/env bash
# restore.sh: restore a backup into a NEW database. Never touches the live database by default.
# bash scripts/restore.sh backups/opslab-20261123-101500.dump opslab_restore
# CONFIRM=yes bash scripts/restore.sh <file> <db> (needed if <db> already exists: it is dropped first)
set -euo pipefail
source "$(dirname "$0")/lib.sh"
file="${1:?usage: restore.sh <backup-file> <target-db>}"
target="${2:?usage: restore.sh <backup-file> <target-db>}"
[ -f "$file" ] || die "no such file: $file"
[ "$target" != "$PGDATABASE" ] || die "refusing to restore over the live database ($PGDATABASE)"
[ "$target" != "postgres" ] || die "refusing to restore into 'postgres'"
# the name travels as a psql variable (:'t'), never glued into the SQL text
exists=$(psql -X -tA -v t="$target" <<< "SELECT 1 FROM pg_database WHERE datname = :'t'")
if [ -n "$exists" ]; then
 [ "${CONFIRM:-}" = "yes" ] || die "database '$target' exists. Run again with CONFIRM=yes to drop and
recreate it"
 log "dropping $target"
 dropdb "$target"
fi
createdb "$target"
log "restoring $file into $target"
# scratch copy: skip owners and grants (grants on system objects need a superuser to restore)
pg_restore --no-owner --no-acl --exit-on-error -d "$target" "$file"
tables=$(psql -X -tAd "$target" -c "SELECT count(*) FROM information_schema.tables WHERE table_schema =
'public'")
log "restore finished: $tables tables in $target"
