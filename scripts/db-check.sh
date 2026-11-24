#!/usr/bin/env bash
# db-check.sh: a quick health check. Exit code 0 = healthy, 1 = needs attention.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
log "checking $PGDATABASE on $PGHOST"
pg_isready -q || die "database is not accepting connections"
conns=$(psql -X -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()")
max=$(psql -X -tAc "SHOW max_connections")
log "connections: $conns of $max"
if [ "$conns" -ge "$CONN_WARN" ]; then
 die "too many connections ($conns >= $CONN_WARN)"
fi
size=$(psql -X -tAc "SELECT pg_size_pretty(pg_database_size(current_database()))")
log "database size: $size"
log "OK"
