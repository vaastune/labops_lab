#!/usr/bin/env python3
"""db_report.py: print a small health report as JSON. Exit code 1 if something needs attention."""
import json
import os
import sys
import psycopg2
from ops_common import load_env
load_env()
CONN_WARN = int(os.environ.get("CONN_WARN", "80"))
IDLE_TX_SECONDS = int(os.environ.get("IDLE_TX_SECONDS", "60"))
def main():
 conn = psycopg2.connect(connect_timeout=5) # reads PGHOST, PGUSER, PGPASSWORD, PGDATABASE
 conn.set_session(readonly=True, autocommit=True) # a report must never change data
 cur = conn.cursor()
 report = {}
 cur.execute("SHOW server_version")
 report["server_version"] = cur.fetchone()[0]
 cur.execute("SELECT current_database(), pg_size_pretty(pg_database_size(current_database()))")
 report["database"], report["size"] = cur.fetchone()
 cur.execute("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()")
 report["connections"] = cur.fetchone()[0]
 cur.execute(
 """SELECT pid, now() - xact_start
 FROM pg_stat_activity
 WHERE state = 'idle in transaction'
 AND now() - xact_start > make_interval(secs => %s)""",
 (IDLE_TX_SECONDS,),
 )
 report["idle_in_transaction"] = [{"pid": pid, "age": str(age)} for pid, age in cur.fetchall()]
 cur.execute(
 """SELECT c.relname, pg_size_pretty(pg_total_relation_size(c.oid))
 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'public' AND c.relkind = 'r'
 ORDER BY pg_total_relation_size(c.oid) DESC
 LIMIT %s""",
 (5,),
 )
 report["biggest_tables"] = [{"table": t, "size": s} for t, s in cur.fetchall()]
 problems = []
 if report["connections"] >= CONN_WARN:
  problems.append(f"connections {report['connections']} >= {CONN_WARN}")
 if report["idle_in_transaction"]:
  problems.append(f"{len(report['idle_in_transaction'])} session(s) idle in transaction")
 report["problems"] = problems
 print(json.dumps(report, indent=2))
 return 1 if problems else 0

if __name__ == "__main__":
 sys.exit(main())
