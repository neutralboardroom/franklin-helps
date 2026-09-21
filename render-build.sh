#!/usr/bin/env bash
set -euo pipefail

rm -rf public
mkdir -p public

python3 - <<'PY'
from pathlib import Path
import base64, hashlib, zipfile

source = Path("deploy/source.b64")
assert source.is_file(), "deploy/source.b64 missing"
encoded = "".join(source.read_text(encoding="ascii").split())
data = base64.b64decode(encoded, validate=True)
actual = hashlib.sha256(data).hexdigest()
expected = "70a3e10f90132b98d7a7432fb17bc40aa4c68ca89fe063af13ef3e5f5c0d3de0"
print(f"Franklin Helps source bundle SHA-256: {actual}")
assert actual == expected, f"source bundle SHA mismatch: {actual}"
bundle = Path("/tmp/franklin-helps-source.zip")
bundle.write_bytes(data)
with zipfile.ZipFile(bundle, "r") as zf:
    bad = zf.testzip()
    assert bad is None, f"ZIP CRC failure at {bad}"
    zf.extractall("public")
assert Path("public/index.html").is_file(), "public/index.html missing"
print("Franklin Helps FH-MAIN-0.1.17 source bundle verified and extracted.")
PY
