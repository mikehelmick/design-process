#!/usr/bin/env bash
# Minimal existing CLI so the case tests sizing, not code discovery.
set -euo pipefail
cat > cli.py <<'PY'
import argparse
import logging


def main(argv=None):
    parser = argparse.ArgumentParser(prog="tool")
    parser.add_argument("name")
    args = parser.parse_args(argv)
    logging.basicConfig(level=logging.INFO)
    logging.info("hello %s", args.name)


if __name__ == "__main__":
    main()
PY
git add cli.py && git -c user.email=e@x -c user.name=eval commit -qm "Add CLI"
