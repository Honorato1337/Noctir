"""Validate and package the current gallery without generated imports or old shots."""
from pathlib import Path
import hashlib
import json
import zipfile
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "docs/media/gallery"
manifest = json.loads((GALLERY / "manifest.json").read_text(encoding="utf-8"))
shots = manifest["screenshots"]
assert len(shots) == 10 and len({s["file"] for s in shots}) == 10
captions = ["One More Orbit — capturas da branch main", "", "10 PNGs em 1920×1080, renderizados no Godot.", "Cenários de demonstração montados por script; sem montagem externa dos PNGs.", ""]
checksums = []
for shot in shots:
    path = GALLERY / shot["file"]
    with Image.open(path) as im:
        assert im.size == (1920, 1080) and im.format == "PNG", path
        im.verify()
    captions.append(shot["file"] + " — " + shot["caption"])
    checksums.append(hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name)
target = ROOT / "docs/media/one-more-orbit-prints.zip"
with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for shot in shots:
        archive.write(GALLERY / shot["file"], "one-more-orbit-prints/" + shot["file"])
    archive.writestr("one-more-orbit-prints/LEIA-ME.txt", "\n".join(captions))
    archive.writestr("one-more-orbit-prints/SHA256.txt", "\n".join(checksums))
    archive.write(GALLERY / "manifest.json", "one-more-orbit-prints/manifest.json")
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist()) == 13
print(f"Verified {len(shots)} Full HD PNGs; ZIP: {target} ({target.stat().st_size:,} bytes)")
