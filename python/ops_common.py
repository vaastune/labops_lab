"""ops_common.py: helpers shared by the Python tools."""
import os
import pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
def load_env():
    """Load .env and config/ops.env. A variable that is already set is never overwritten."""
    for name in (".env", "config/ops.env"):
        path = ROOT / name
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ.setdefault(key.strip(), value.strip())
