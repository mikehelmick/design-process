#!/usr/bin/env bash
# Repo with an existing helper, a documented style deviation, and a feature
# branch whose diff re-implements the helper non-idiomatically.
# Keep identical to evals/review-others/scripts/setup.sh (each case needs its own copy).
set -euo pipefail
git symbolic-ref HEAD refs/heads/main
cat > CLAUDE.md <<'MD'
# Conventions
- Function names use camelCase (deliberate deviation from PEP 8; matches our JS codebase).
MD
mkdir -p app
cat > app/text.py <<'PY'
import re


def makeSlug(value):
    """Lowercase, replace non-alphanumerics with '-', strip dashes."""
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
PY
git add -A && git -c user.email=e@x -c user.name=eval commit -qm "Base"
git checkout -qb feature
cat > app/posts.py <<'PY'
def buildPostUrls(titles):
    urls = []
    for i in range(len(titles)):
        t = titles[i].lower()
        s = ""
        for ch in t:
            if ch.isalnum():
                s = s + ch
            else:
                s = s + "-"
        while "--" in s:
            s = s.replace("--", "-")
        s = s.strip("-")
        urls.append("/posts/" + s)
    return urls


def sessionCookie(commit):
    # Clients read this value back on the next request.
    return {"name": "session", "value": commit.timestamp.isoformat()}
PY
git add -A && git -c user.email=e@x -c user.name=eval commit -qm "Add post URLs"
git diff main...feature > feature.diff
