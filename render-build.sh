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

# Apply the exact FH-MAIN-0.1.19 sitewide language / hierarchy / header-logo patch.
cat \
  deploy/patch19.part00.b64 \
  deploy/patch19.part01.b64 \
  deploy/patch19.part02.b64 \
  deploy/patch19.part03.b64 \
  deploy/patch19.fix04a.b64 \
  deploy/patch19.fix04b.b64 \
  deploy/patch19.part05.b64 \
  deploy/patch19.fix06a.b64 \
  deploy/patch19.fix06b.b64 \
  deploy/patch19.part07.b64 \
  deploy/patch19.part08.b64 \
  deploy/patch19.part09.b64 \
  | tr -d '\n' | base64 -d > /tmp/franklin-helps-0.1.19.patch.gz

python3 - <<'PY'
from pathlib import Path
import gzip, hashlib, subprocess

gz = Path("/tmp/franklin-helps-0.1.19.patch.gz").read_bytes()
gz_sha = hashlib.sha256(gz).hexdigest()
expected_gz_sha = "b01403fa391ca94e435167ff8decb5c47076bad5cd70eacf97c5857ff94f7a61"
print(f"Franklin Helps 0.1.19 patch gzip SHA-256: {gz_sha}")
assert gz_sha == expected_gz_sha, f"0.1.19 gzip patch SHA mismatch: {gz_sha}"

patch = gzip.decompress(gz)
patch_sha = hashlib.sha256(patch).hexdigest()
expected_patch_sha = "61073cbca88663cda6b9d2f42b6b2dd0443f1794b86a2b5dd05f808eacad520f"
print(f"Franklin Helps 0.1.19 patch SHA-256: {patch_sha}")
assert patch_sha == expected_patch_sha, f"0.1.19 patch SHA mismatch: {patch_sha}"

patch_path = Path("/tmp/franklin-helps-0.1.19.patch")
patch_path.write_bytes(patch)
subprocess.run(
    ["git", "apply", "--whitespace=nowarn", str(patch_path)],
    check=True,
)

rows = []
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel = p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree_hash = hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()
expected_tree_hash = "4b35666e9ae5f2966a37b94f94399e5b7c4d884c527674af69c9f4c561645aef"
print(f"Franklin Helps FH-MAIN-0.1.19 public tree SHA-256: {tree_hash}")
assert len(rows) == 85, f"unexpected public file count: {len(rows)}"
assert tree_hash == expected_tree_hash, f"0.1.19 public tree SHA mismatch: {tree_hash}"
assert Path("public/index.html").is_file(), "public/index.html missing after 0.1.19 patch"
print("Franklin Helps FH-MAIN-0.1.19 exact public tree verified.")
PY


# Apply exact FH-MAIN-0.1.20 donor-outreach-readiness site overlay.
cat \
  deploy/overlay20.part01.b64 \
  deploy/overlay20.part02.b64 \
  deploy/overlay20.part03.b64 \
  deploy/overlay20.part04.b64 \
  deploy/overlay20.part05.b64 \
  deploy/overlay20.part06.b64 \
  deploy/overlay20.part07.b64 \
  deploy/overlay20.part08.b64 \
  | tr -d '\n' | base64 -d > /tmp/franklin-helps-overlay-0.1.20.zip

python3 - <<'PY'
from pathlib import Path
import hashlib, zipfile

overlay = Path("/tmp/franklin-helps-overlay-0.1.20.zip")
data = overlay.read_bytes()
actual = hashlib.sha256(data).hexdigest()
expected = "e17af3fe5a1c58036bc57d1e523fe962ce9c1e920e34f8f81a0b4b6e1daa5d24"
print(f"Franklin Helps 0.1.20 overlay SHA-256: {actual}")
assert actual == expected, f"0.1.20 overlay SHA mismatch: {actual}"

with zipfile.ZipFile(overlay, "r") as zf:
    bad = zf.testzip()
    assert bad is None, f"0.1.20 overlay ZIP CRC failure at {bad}"
    zf.extractall("public")

rows = []
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel = p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree_hash = hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()
expected_tree_hash = "968f0246749797962bcbe8be3970da257b2f3cdc3e4a764a05ca0a973e1eadfe"
print(f"Franklin Helps FH-MAIN-0.1.20 public tree SHA-256: {tree_hash}")
assert len(rows) == 85, f"unexpected public file count: {len(rows)}"
assert tree_hash == expected_tree_hash, f"0.1.20 public tree SHA mismatch: {tree_hash}"
assert Path("public/index.html").is_file(), "public/index.html missing after 0.1.20 overlay"
print("Franklin Helps FH-MAIN-0.1.20 exact public tree verified.")
PY


# Apply exact FH-MAIN-0.1.21 V5 final outreach-polish patch.
tr -d '\n' < deploy/patch21.b64 | base64 -d > /tmp/franklin-helps-0.1.21.patch.gz

python3 - <<'PY'
from pathlib import Path
import gzip, hashlib, subprocess

gz = Path("/tmp/franklin-helps-0.1.21.patch.gz").read_bytes()
gz_sha = hashlib.sha256(gz).hexdigest()
expected_gz_sha = "f739184be1ace14fb4e1c6005a479f9f22dd88d01461893a230f528908d080b0"
print(f"Franklin Helps 0.1.21 patch gzip SHA-256: {gz_sha}")
assert gz_sha == expected_gz_sha, f"0.1.21 gzip patch SHA mismatch: {gz_sha}"

patch = gzip.decompress(gz)
patch_sha = hashlib.sha256(patch).hexdigest()
expected_patch_sha = "005bbeb24ca4d1252f77781b515666cdf76110679c4bf43905c03c07abf3f355"
print(f"Franklin Helps 0.1.21 patch SHA-256: {patch_sha}")
assert patch_sha == expected_patch_sha, f"0.1.21 patch SHA mismatch: {patch_sha}"

patch_path = Path("/tmp/franklin-helps-0.1.21.patch")
patch_path.write_bytes(patch)
subprocess.run(["git", "apply", "--whitespace=nowarn", str(patch_path)], check=True)

rows = []
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel = p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree_hash = hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()
expected_tree_hash = "e5387ce7c5cbf3da7f424260b48d2b62d52f2fcd8fb1fc3e10c4daf5a2cccdfe"
print(f"Franklin Helps FH-MAIN-0.1.21 public tree SHA-256: {tree_hash}")
assert len(rows) == 84, f"unexpected public file count: {len(rows)}"
assert tree_hash == expected_tree_hash, f"0.1.21 public tree SHA mismatch: {tree_hash}"
assert Path("public/index.html").is_file(), "public/index.html missing after 0.1.21 patch"
print("Franklin Helps FH-MAIN-0.1.21 exact public tree verified.")
PY
