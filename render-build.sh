#!/usr/bin/env bash
set -euo pipefail

rm -rf public
mkdir -p public

python3 - <<'PY'
from pathlib import Path
import base64, hashlib, zipfile

parts = sorted(Path("deploy").glob("source.part-*"))
assert len(parts) == 6, f"expected 6 source chunks, found {len(parts)}"
encoded = "".join(p.read_text(encoding="ascii").strip() for p in parts)
data = base64.b64decode(encoded, validate=True)
actual = hashlib.sha256(data).hexdigest()
expected = "db3d25d3a2a3e77dcf94385a22f45c6eb6389f26950a61db261fb37417099c50"
print(f"Franklin Helps source bundle SHA-256: {actual}")
assert actual == expected, f"source bundle SHA mismatch: {actual}"
bundle = Path("/tmp/franklin-helps-source.zip")
bundle.write_bytes(data)
with zipfile.ZipFile(bundle, "r") as zf:
    bad = zf.testzip()
    assert bad is None, f"ZIP CRC failure at {bad}"
    zf.extractall("public")
assert Path("public/index.html").is_file(), "public/index.html missing"
print("Franklin Helps source bundle verified and extracted.")
PY
