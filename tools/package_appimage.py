"""Package the existing Linux export as a type-2 AppImage on Windows.

Tools: official AppImage/type2-runtime runtime-x86_64 and the upstream
squashfs-tools-ng 1.3.2 Windows package (see docs/EXPORTACAO.md).
No signing credentials or development tools are included in the image.
"""
import hashlib
import json
import shutil
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.godot/export-tools/appimage'
OUT = ROOT / 'builds/linux'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    runtime = TOOLS / 'runtime-x86_64'
    provenance = json.loads((TOOLS/'runtime-source.json').read_text(encoding='utf-8-sig'))
    assert 'sha256:'+sha(runtime) == provenance['digest']
    runtime_bytes = runtime.read_bytes()
    assert runtime_bytes[:4] == b'\x7fELF' and runtime_bytes[8:11] == b'AI\x02'
    assert struct.unpack_from('<H', runtime_bytes, 18)[0] == 62
    generator = next((TOOLS/'squashfs').rglob('gensquashfs.exe'))
    reader = next((TOOLS/'squashfs').rglob('rdsquashfs.exe'))
    appdir = TOOLS / 'OneMoreOrbit.AppDir'
    appdir.mkdir(exist_ok=True)
    binary = OUT / 'OneMoreOrbit.x86_64'
    shutil.copy2(binary, appdir/binary.name)
    icon = ROOT/'assets/branding/icon-384.png'
    for name in ['one-more-orbit.png', '.DirIcon']:
        shutil.copy2(icon, appdir/name)
    (appdir/'AppRun').write_bytes(b'#!/bin/sh\nHERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"\nexec "$HERE/OneMoreOrbit.x86_64" "$@"\n')
    (appdir/'one-more-orbit.desktop').write_text('[Desktop Entry]\nType=Application\nName=One More Orbit\nComment=Space horde survival with temporal echoes\nExec=OneMoreOrbit.x86_64\nIcon=one-more-orbit\nTerminal=false\nCategories=Game;ActionGame;\nX-AppImage-Version=0.3.3\n', encoding='utf-8')
    files = ['AppRun', binary.name, 'one-more-orbit.desktop', 'one-more-orbit.png', '.DirIcon']
    listing = TOOLS / 'appdir.list'
    listing.write_text('\n'.join(f'file /{name} {"0755" if name in files[:2] else "0644"} 0 0 {name}' for name in files)+'\n', encoding='utf-8')
    squash = TOOLS/'OneMoreOrbit.squashfs'
    subprocess.run([str(generator), '-f', '-q', '-j', '2', '-c', 'gzip', '-D', str(appdir), '-F', str(listing), str(squash)], check=True)
    assert squash.read_bytes()[:4] == b'hsqs'
    description = subprocess.check_output([str(reader), '--stat', '/AppRun', str(squash)], text=True)
    assert '0755' in description or 'rwxr-xr-x' in description, description
    verification = TOOLS/'verify-game.x86_64'
    with verification.open('wb') as output:
        subprocess.run([str(reader), '--cat', '/'+binary.name, str(squash)], stdout=output, check=True)
    assert sha(verification) == sha(binary)
    image = OUT/'OneMoreOrbit-x86_64.AppImage'
    with image.open('wb') as output:
        output.write(runtime_bytes)
        with squash.open('rb') as payload:
            shutil.copyfileobj(payload, output)
    with image.open('rb') as output:
        output.seek(len(runtime_bytes))
        assert output.read(4) == b'hsqs'
    report = {'version':'0.3.3', 'file':image.name, 'bytes':image.stat().st_size,
              'sha256':sha(image), 'runtime':provenance, 'squashfs_offset':len(runtime_bytes),
              'payload_binary_sha256':sha(binary), 'checks':['ELF x86_64 runtime', 'AI type-2 marker', 'runtime SHA256', 'SquashFS v4 gzip', 'AppRun executable mode', 'extracted game SHA256 matches Linux export'],
              'native_linux_execution_tested':False}
    (OUT/'appimage-report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(description)
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()
