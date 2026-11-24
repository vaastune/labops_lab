#!/usr/bin/env bash
# lib.sh: shared helpers. Other scripts "source" this file. Do not run it directly.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$PATH:/usr/lib/postgresql/16/bin" # cron starts with a very small PATH
export PGOPTIONS="-c client_min_messages=warning" # hide harmless NOTICE lines
# Load KEY=VALUE lines, but never overwrite a variable that is already set.
load_env_file() {
 [ -f "$1" ] || return 0
 while IFS='=' read -r key value; do
 case "$key" in ''|\#*) continue ;; esac
 if [ -z "${!key:-}" ]; then export "$key=$value"; fi
 done < "$1"
}
load_env_file "$ROOT/.env" # secrets (not in Git)
load_env_file "$ROOT/config/ops.env" # settings (in Git)
mkdir -p "$ROOT/logs" "$ROOT/backups"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [$(basename "$0")] $*" | tee -a "$ROOT/logs/ops.log"; }
die() { log "ERROR: $*"; exit 1; }
