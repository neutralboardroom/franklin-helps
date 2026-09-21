#!/usr/bin/env bash
set -euo pipefail

rm -rf public
mkdir -p public

cat deploy/source.part-* | base64 -d > /tmp/franklin-helps-source.zip

EXPECTED="db3d25d3a2a3e77dcf94385a22f45c6eb6389f26950a61db261fb37417099c50"
ACTUAL="$(sha256sum /tmp/franklin-helps-source.zip | awk '{print $1}')"
test "$ACTUAL" = "$EXPECTED"

python3 -m zipfile -e /tmp/franklin-helps-source.zip public

test -f public/index.html
