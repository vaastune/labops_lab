#!/usr/bin/env bash
# backup.sh: dump the database to backups/, verify it, keep only the newest BACKUP_KEEP files.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
stamp=$(date +%Y%m%d-%H%M%S)
file="$ROOT/backups/${PGDATABASE}-${stamp}.dump"
tmp="${file}.partial"
log "backup start: $PGDATABASE -> $file"
pg_dump -Fc -f "$tmp" "$PGDATABASE" || { rm -f -- "$tmp"; die "pg_dump failed"; }
mv -- "$tmp" "$file" # only a complete file gets the final name
pg_restore --list "$file" > /dev/null || die "backup is not readable: $file"
log "backup OK: $(du -h "$file" | cut -f1)"
# retention: remove everything except the newest BACKUP_KEEP backups
ls -1t "$ROOT"/backups/"${PGDATABASE}"-*.dump | tail -n +"$((BACKUP_KEEP + 1))" | while read -r old; do
 log "removing old backup: $old"
 rm -f -- "$old"
done
