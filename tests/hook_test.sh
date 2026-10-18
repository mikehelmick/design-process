#!/usr/bin/env bash
# Runs the SessionStart hook command from a plugin root containing a space and
# checks it emits valid context JSON naming only skills that exist.
set -euo pipefail
src="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
root="$tmp/with space"
mkdir -p "$root" && cp -R "$src/hooks" "$src/skills" "$root/"
python3 - "$root" <<'PY'
import json, os, re, subprocess, sys
root = sys.argv[1]
entry = json.load(open(os.path.join(root, "hooks/hooks.json")))["hooks"]["SessionStart"][0]
assert entry["matcher"] == "startup|clear|compact", entry["matcher"]
hook = entry["hooks"][0]
out = subprocess.run([hook.get("shell", "bash"), "-c", hook["command"]], check=True,
                     capture_output=True, text=True,
                     env={**os.environ, "CLAUDE_PLUGIN_ROOT": root}).stdout
d = json.loads(out)["hookSpecificOutput"]
assert d["hookEventName"] == "SessionStart"
c = d["additionalContext"]
for s in ["design-process:design", "docs/design/"]:
    assert s in c, s
for name in set(re.findall(r"design-process:([\w-]+)", c)):
    assert os.path.isfile(os.path.join(root, "skills", name, "SKILL.md")), f"missing skill {name}"
print("ok")
PY
