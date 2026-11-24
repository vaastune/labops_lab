#!/usr/bin/env bash
# heartbeat.sh: write one row. Proves that the scheduler and the database are both alive.
# Safe to run any number of times: the table is created only if it does not exist yet.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS heartbeat (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 beat_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO heartbeat DEFAULT VALUES;
SQL
log "heartbeat written"
