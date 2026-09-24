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


# Apply exact FH-MAIN-0.1.22 owner live-screen review overlay.
tr -d '\n' < deploy/overlay22.b64 | base64 -d > /tmp/franklin-helps-overlay-0.1.22.zip

python3 - <<'PY'
from pathlib import Path
import hashlib, zipfile

overlay = Path("/tmp/franklin-helps-overlay-0.1.22.zip")
data = overlay.read_bytes()
actual = hashlib.sha256(data).hexdigest()
expected = "5e1218f25bd1f29f1b8771c42ecf2947081354bb57db5048321154243ff3c773"
print(f"Franklin Helps 0.1.22 overlay SHA-256: {actual}")
assert actual == expected, f"0.1.22 overlay SHA mismatch: {actual}"

with zipfile.ZipFile(overlay, "r") as zf:
    bad = zf.testzip()
    assert bad is None, f"0.1.22 overlay ZIP CRC failure at {bad}"
    zf.extractall("public")

rows = []
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel = p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree_hash = hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()
expected_tree_hash = "178d3604b5a8a6b23f0cf657b1974afc2e862a2e29422b73b0907615ad5f3222"
print(f"Franklin Helps FH-MAIN-0.1.22 public tree SHA-256: {tree_hash}")
assert len(rows) == 84, f"unexpected public file count: {len(rows)}"
assert tree_hash == expected_tree_hash, f"0.1.22 public tree SHA mismatch: {tree_hash}"
assert Path("public/index.html").is_file(), "public/index.html missing after 0.1.22 overlay"
print("Franklin Helps FH-MAIN-0.1.22 exact public tree verified.")
PY


# Apply exact FH-MAIN-0.1.23 full static bundle.
tr -d '\n' < deploy/static23.b64 | base64 -d > /tmp/franklin-helps-static-0.1.23.zip
python3 - <<'PY'
from pathlib import Path
import hashlib, zipfile, shutil
bundle=Path("/tmp/franklin-helps-static-0.1.23.zip")
expected_bundle="c7340e879ed42f66fc4535732c3e5b9f859c908ec92392e88d32d41a6e5e044f"
actual=hashlib.sha256(bundle.read_bytes()).hexdigest()
print(f"Franklin Helps 0.1.23 static bundle SHA-256: {actual}")
assert actual==expected_bundle, (actual, expected_bundle)
with zipfile.ZipFile(bundle) as z:
    bad=z.testzip()
    assert bad is None, bad
    z.extractall("public")
rows=[]
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel=p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree=hashlib.sha256("".join(rows).encode()).hexdigest()
expected_tree="b3250b8546ad6f368882ebda493c7f87d57a951fed857f804ea1cabd00d60f12"
print(f"Franklin Helps FH-MAIN-0.1.23 public tree SHA-256: {tree}")
assert len(rows)==84, len(rows)
assert tree==expected_tree, (tree,expected_tree)
assert Path("public/index.html").is_file()
print("Franklin Helps FH-MAIN-0.1.23 exact public tree verified.")
PY


# Apply exact FH-MAIN-0.1.24 full live-site-audit static bundle.
tr -d '\n' < deploy/static24.b64 | base64 -d > /tmp/franklin-helps-static-0.1.24.zip
python3 - <<'PY'
from pathlib import Path
import hashlib, zipfile
bundle=Path("/tmp/franklin-helps-static-0.1.24.zip")
expected_bundle="d1c616e1632681fc3708282b8c2df323144020bbab2651b0fd725b8f7f661405"
actual=hashlib.sha256(bundle.read_bytes()).hexdigest()
print(f"Franklin Helps 0.1.24 static bundle SHA-256: {actual}")
assert actual==expected_bundle, (actual, expected_bundle)
with zipfile.ZipFile(bundle) as z:
    bad=z.testzip()
    assert bad is None, bad
    z.extractall("public")
rows=[]
for p in sorted(x for x in Path("public").rglob("*") if x.is_file()):
    rel=p.relative_to("public").as_posix()
    rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n")
tree=hashlib.sha256("".join(rows).encode()).hexdigest()
expected_tree="2ef35e0a2eeb7d71627c967ed6a523f5b5fcea0415ce5d33be43501593bf73ae"
print(f"Franklin Helps FH-MAIN-0.1.24 public tree SHA-256: {tree}")
assert len(rows)==84, len(rows)
assert tree==expected_tree, (tree,expected_tree)
assert Path("public/index.html").is_file()
print("Franklin Helps FH-MAIN-0.1.24 exact public tree verified.")
PY


# Apply exact FH-MAIN-0.1.25 food + essential-prescription scope / supporter-choice patch.
tr -d '\n' < deploy/patch25.b64 | base64 -d > /tmp/franklin-helps-0.1.25.patch.gz
python3 - <<'PY'
from pathlib import Path
import gzip, hashlib, subprocess

gz = Path('/tmp/franklin-helps-0.1.25.patch.gz').read_bytes()
expected_gz = '6d59d137e4ea2eb166792d692a2e19b51a70a674ba19160a4b7baf7f929fb953'
actual_gz = hashlib.sha256(gz).hexdigest()
print(f'Franklin Helps 0.1.25 patch gzip SHA-256: {actual_gz}')
assert actual_gz == expected_gz, (actual_gz, expected_gz)
patch = gzip.decompress(gz)
expected_patch = '91f536ec6625e525e38eca8e85223fe6f93d9d84faf7ed6561832538c4a37bcf'
actual_patch = hashlib.sha256(patch).hexdigest()
print(f'Franklin Helps 0.1.25 patch SHA-256: {actual_patch}')
assert actual_patch == expected_patch, (actual_patch, expected_patch)
pp = Path('/tmp/franklin-helps-0.1.25.patch')
pp.write_bytes(patch)
subprocess.run(['git','apply','--whitespace=nowarn',str(pp)], check=True)
rows=[]
for p in sorted(x for x in Path('public').rglob('*') if x.is_file()):
    rel=p.relative_to('public').as_posix()
    rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n')
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected_tree='ea6d2d4749a6c1a89d2628738b2cf880decfb6f9e80eebe931eea3303c21b15b'
print(f'Franklin Helps FH-MAIN-0.1.25 public tree SHA-256: {tree}')
assert len(rows)==84, len(rows)
assert tree==expected_tree, (tree,expected_tree)
assert Path('public/index.html').is_file()
print('Franklin Helps FH-MAIN-0.1.25 exact public tree verified.')
PY


# Apply exact FH-MAIN-0.1.26 owner live-review and local-identity patch.
tr -d '\n' < deploy/patch26.b64 | base64 -d > /tmp/franklin-helps-0.1.26.patch.gz
python3 - <<'PY'
from pathlib import Path
import gzip, hashlib, subprocess

gz=Path('/tmp/franklin-helps-0.1.26.patch.gz').read_bytes()
expected_gz='5220e9c3b6a9ce27b787d1a540199c43fce733f642c2d295b70154961972404a'
actual_gz=hashlib.sha256(gz).hexdigest()
print(f'Franklin Helps 0.1.26 patch gzip SHA-256: {actual_gz}')
assert actual_gz==expected_gz,(actual_gz,expected_gz)
patch=gzip.decompress(gz)
expected_patch='a1de22dd4b71b643483ef6257ac6077d9c412257bc3ef388cc8989314f9e9863'
actual_patch=hashlib.sha256(patch).hexdigest()
print(f'Franklin Helps 0.1.26 patch SHA-256: {actual_patch}')
assert actual_patch==expected_patch,(actual_patch,expected_patch)
pp=Path('/tmp/franklin-helps-0.1.26.patch')
pp.write_bytes(patch)
subprocess.run(['git','apply','--whitespace=nowarn',str(pp)],check=True)
rows=[]
for p in sorted(x for x in Path('public').rglob('*') if x.is_file()):
    rel=p.relative_to('public').as_posix()
    rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n')
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected_tree='bffcd67dccf1225f3ea04fff24d3c87bffc57db844bcd6e89a4f7978982309fa'
print(f'Franklin Helps FH-MAIN-0.1.26 public tree SHA-256: {tree}')
assert len(rows)==84,len(rows)
assert tree==expected_tree,(tree,expected_tree)
assert Path('public/index.html').is_file()
print('Franklin Helps FH-MAIN-0.1.26 exact public tree verified.')
PY


# Apply exact FH-MAIN-0.1.27 medication-access bridge and header-logo patch.
tr -d '\n' < deploy/patch27.b64 | base64 -d > /tmp/franklin-helps-0.1.27.patch.gz
python3 - <<'PY'
from pathlib import Path
import gzip, hashlib, subprocess

gz=Path('/tmp/franklin-helps-0.1.27.patch.gz').read_bytes()
expected_gz='b73a4e6b8fb8a38860cfa96f55907ccbffa0c3a966d6db8b17a879dc2a8dba4e'
actual_gz=hashlib.sha256(gz).hexdigest()
print(f'Franklin Helps 0.1.27 patch gzip SHA-256: {actual_gz}')
assert actual_gz==expected_gz,(actual_gz,expected_gz)
patch=gzip.decompress(gz)
expected_patch='659716bdefd9ee35ae207716cb362114212374226ba10e1f1ae870e4fad74688'
actual_patch=hashlib.sha256(patch).hexdigest()
print(f'Franklin Helps 0.1.27 patch SHA-256: {actual_patch}')
assert actual_patch==expected_patch,(actual_patch,expected_patch)
pp=Path('/tmp/franklin-helps-0.1.27.patch')
pp.write_bytes(patch)
subprocess.run(['git','apply','--whitespace=nowarn',str(pp)],check=True)
rows=[]
for p in sorted(x for x in Path('public').rglob('*') if x.is_file()):
    rel=p.relative_to('public').as_posix()
    rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n')
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected_tree='131dc3c28d5623d20dacd8411f063e94ed5a8c7e83ac5f07e6860f47b8859ab7'
print(f'Franklin Helps FH-MAIN-0.1.27 public tree SHA-256: {tree}')
assert len(rows)==86,len(rows)
assert tree==expected_tree,(tree,expected_tree)
assert Path('public/index.html').is_file()
print('Franklin Helps FH-MAIN-0.1.27 exact public tree verified.')
PY


# Apply exact FH-MAIN-0.1.28 owner live-review navigation/public-language overlay.
cat \
  deploy/overlay28xz.groupA.b64 \
  deploy/overlay28xz.groupB.b64 \
  deploy/overlay28xz.groupC.b64 \
  deploy/overlay28xz.groupD.b64 \
  | tr -d '\n' | base64 -d > /tmp/franklin-helps-0.1.28-overlay.tar.xz

python3 - <<'PY'
from pathlib import Path
import hashlib, tarfile

overlay=Path('/tmp/franklin-helps-0.1.28-overlay.tar.xz')
actual=hashlib.sha256(overlay.read_bytes()).hexdigest()
expected='370580ce69b636cd4981cbe04dfd8e584c8efbf1fe3c999f56b27d2b33a59d17'
print(f'Franklin Helps 0.1.28 overlay xz SHA-256: {actual}')
assert actual==expected,(actual,expected)

with tarfile.open(overlay,'r:xz') as tf:
    tf.extractall('public')

for rel in [
    'assets/franklin-helps-logo-approved-site.webp',
    'assets/logo-franklin-helps.svg',
    'es/status/index.html',
    'status/index.html',
]:
    p=Path('public')/rel
    if p.exists():
        p.unlink()
for rel in ['es/status','status']:
    p=Path('public')/rel
    if p.exists() and p.is_dir():
        try: p.rmdir()
        except OSError: pass

rows=[]
for p in sorted(x for x in Path('public').rglob('*') if x.is_file()):
    rel=p.relative_to('public').as_posix()
    rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n')
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected_tree='f458b104f74339f9c6047f34130d0aecb3356bc8f8c947fbf50af731092375d1'
print(f'Franklin Helps FH-MAIN-0.1.28 public tree SHA-256: {tree}')
assert len(rows)==82,len(rows)
assert tree==expected_tree,(tree,expected_tree)
assert Path('public/index.html').is_file()
print('Franklin Helps FH-MAIN-0.1.28 exact public tree verified.')
PY


# Apply exact FH-MAIN-0.1.29 logo, resource-finder and public-copy clarity overlay.
cat \
  deploy/overlay29xz.groupA.b64 \
  deploy/overlay29xz.groupB.b64 \
  deploy/overlay29xz.groupC.b64 \
  deploy/overlay29xz.groupD.b64 \
  | tr -d '\n' | base64 -d > /tmp/franklin-helps-0.1.29-overlay.tar.xz

python3 - <<'PY'
from pathlib import Path
import hashlib, tarfile

overlay=Path('/tmp/franklin-helps-0.1.29-overlay.tar.xz')
actual=hashlib.sha256(overlay.read_bytes()).hexdigest()
expected='5126447d3e2b319d29ee7efe900f62937b410403285323b079e2f451faaf7f12'
print(f'Franklin Helps 0.1.29 overlay xz SHA-256: {actual}')
assert actual==expected,(actual,expected)

with tarfile.open(overlay,'r:xz') as tf:
    tf.extractall('public')

rows=[]
for p in sorted(x for x in Path('public').rglob('*') if x.is_file()):
    rel=p.relative_to('public').as_posix()
    rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n')
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected_tree='27aa0f90075b645245568dac68c2bb48804699606e463a2e86edb5d081c53858'
print(f'Franklin Helps FH-MAIN-0.1.29 public tree SHA-256: {tree}')
assert len(rows)==82,len(rows)
assert tree==expected_tree,(tree,expected_tree)
assert Path('public/index.html').is_file()
print('Franklin Helps FH-MAIN-0.1.29 exact public tree verified.')
PY

# Apply exact FH-MAIN-0.1.30 medication-resource currentness transform.
python3 deploy/transform_public_030.py

python3 - <<'PY'
from pathlib import Path
import hashlib
rows=[]
for p in sorted(x for x in Path('public').rglob('*') if x.is_file()):
    rel=p.relative_to('public').as_posix()
    rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {rel}\n')
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected_tree='903031e30b9f8ab566f911351afe50be325c8e3bcdc689998905b0d65c8cf17c'
print(f'Franklin Helps FH-MAIN-0.1.30 public tree SHA-256: {tree}')
assert len(rows)==82,len(rows)
assert tree==expected_tree,(tree,expected_tree)
assert Path('public/index.html').is_file()
print('Franklin Helps FH-MAIN-0.1.30 exact public tree verified.')
PY
