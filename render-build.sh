#!/usr/bin/env bash
set -euo pipefail

rm -rf public
mkdir -p public

python3 - <<'PY'
from pathlib import Path
import base64, hashlib, zipfile

# Exact deployed FH-MAIN-0.1.17 public bundle retained as the no-regression base.
source = Path("deploy/source.b64")
assert source.is_file(), "deploy/source.b64 missing"
encoded = "".join(source.read_text(encoding="ascii").split())
data = base64.b64decode(encoded, validate=True)
actual = hashlib.sha256(data).hexdigest()
expected = "70a3e10f90132b98d7a7432fb17bc40aa4c68ca89fe063af13ef3e5f5c0d3de0"
print(f"Franklin Helps 0.1.17 base bundle SHA-256: {actual}")
assert actual == expected, f"base bundle SHA mismatch: {actual}"
bundle = Path("/tmp/franklin-helps-base.zip")
bundle.write_bytes(data)
with zipfile.ZipFile(bundle, "r") as zf:
    bad = zf.testzip()
    assert bad is None, f"base ZIP CRC failure at {bad}"
    zf.extractall("public")

# Exact FH-MAIN-0.1.18 changed-file overlay produced from the sealed release.
parts = [Path(f"deploy/overlay18.part{i}.b64") for i in range(1, 5)]
for part in parts:
    assert part.is_file(), f"{part} missing"
overlay_encoded = "".join("".join(p.read_text(encoding="ascii").split()) for p in parts)
overlay_data = base64.b64decode(overlay_encoded, validate=True)
overlay_actual = hashlib.sha256(overlay_data).hexdigest()
overlay_expected = "25ab2e0c8dc7a1c1f8edfd940ff716cf004364aa93c8ddd57f73de12b748d8fe"
print(f"Franklin Helps 0.1.18 overlay SHA-256: {overlay_actual}")
assert overlay_actual == overlay_expected, f"overlay SHA mismatch: {overlay_actual}"
overlay = Path("/tmp/franklin-helps-overlay-0.1.18.zip")
overlay.write_bytes(overlay_data)
with zipfile.ZipFile(overlay, "r") as zf:
    bad = zf.testzip()
    assert bad is None, f"overlay ZIP CRC failure at {bad}"
    zf.extractall("public")

# Verify the exact resulting public file tree against the sealed 0.1.18 bundle.
rows = []
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel = p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree_hash = hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()
expected_tree_hash = "791c7e8b7b1f9dced707693835f77618ddfea3b29d97e8d87be8ebbb118b393e"
print(f"Franklin Helps FH-MAIN-0.1.18 public tree SHA-256: {tree_hash}")
assert len(rows) == 85, f"unexpected public file count: {len(rows)}"
assert tree_hash == expected_tree_hash, f"public tree SHA mismatch: {tree_hash}"
assert Path("public/index.html").is_file(), "public/index.html missing"
print("Franklin Helps FH-MAIN-0.1.18 exact public tree verified and extracted.")
PY
