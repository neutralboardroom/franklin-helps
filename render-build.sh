#!/usr/bin/env bash
set -euo pipefail
rm -rf public
mkdir -p public
python3 -m zipfile -e FRANKLIN_HELPS__GITHUB_RENDER_SOURCE__FH-MAIN-0.1.11.zip public
# Fail closed if the public entry point is missing.
test -f public/index.html