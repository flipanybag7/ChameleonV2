import json, subprocess, sys
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "tools" / "profilectl.py"

def run(root, *args):
    return subprocess.check_output([sys.executable, str(SCRIPT), "--root", str(root), *args], text=True).strip()

def test_profile_lifecycle(tmp_path):
    pid = run(tmp_path, "profile", "create", "alpha")
    run(tmp_path, "profile", "assign-app", pid, "com.example.app")
    run(tmp_path, "profile", "set-proxy", pid, "socks5", "127.0.0.1", "1080")
    run(tmp_path, "profile", "set-location", pid, "60.17", "24.94", "Helsinki")
    obj = json.loads(run(tmp_path, "profile", "show", pid))
    assert obj["apps"]["com.example.app"]["data_namespace"]
    assert obj["proxy"]["port"] == 1080
    assert obj["location"]["label"] == "Helsinki"

def test_backup_roundtrip(tmp_path):
    pid = run(tmp_path / "a", "profile", "create", "alpha")
    backup = tmp_path / "backup.json"
    run(tmp_path / "a", "backup", "export", backup)
    run(tmp_path / "b", "backup", "import", backup)
    assert pid in json.loads(run(tmp_path / "b", "profile", "show", pid))["id"]
