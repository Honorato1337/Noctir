"""Structural and signing checks; does not replace testing on either target OS."""
import hashlib
import json
import struct
import subprocess
import tarfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / '.godot/export-tools'

def main():
    linux = ROOT / 'builds/linux/OneMoreOrbit.x86_64'
    header = linux.read_bytes()[:64]
    assert header[:4] == b'\x7fELF' and header[4] == 2
    assert struct.unpack_from('<H', header, 18)[0] == 62, 'Expected Linux x86_64'
    bundle = linux.with_name('OneMoreOrbit-Linux-x86_64.tar.gz')
    with tarfile.open(bundle) as archive:
        entry = archive.getmember(linux.name)
        assert entry.mode & 0o111
        assert hashlib.sha256(archive.extractfile(entry).read()).digest() == hashlib.sha256(linux.read_bytes()).digest()
    print('Linux: ELF x86_64, archive integrity and executable permissions PASS')
    apk = ROOT / 'builds/android/OneMoreOrbit.apk'
    java = next(BASE.glob('jdk*/bin/java.exe'))
    sdk = BASE / 'android-sdk/build-tools/35.0.1'
    logs = []
    commands = [
        ('signature', [str(java), '-jar', str(sdk/'lib/apksigner.jar'), 'verify', '--verbose', '--print-certs', str(apk)]),
        ('alignment', [str(sdk/'zipalign.exe'), '-c', '-P', '16', '4', str(apk)]),
        ('manifest', [str(sdk/'aapt.exe'), 'dump', 'badging', str(apk)]),
    ]
    for name, command in commands:
        result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace')
        logs.append(name+'\n'+result.stdout+result.stderr)
        assert result.returncode == 0, logs[-1]
        if name == 'manifest':
            assert "versionCode='22'" in result.stdout and "versionName='0.3.3'" in result.stdout
            print('\n'.join(line for line in result.stdout.splitlines() if line.startswith(('package:', 'sdkVersion:', 'targetSdkVersion:', 'native-code:'))))
        print('Android '+name+': PASS')
    with zipfile.ZipFile(apk) as archive:
        assert archive.testzip() is None
        assert any(n.startswith('lib/arm64-v8a/') for n in archive.namelist())
        assert any(n.startswith('lib/armeabi-v7a/') for n in archive.namelist())
        assert not any('.export-signing' in n or 'credentials.json' in n for n in archive.namelist())
    (ROOT/'builds/verify-ports.log').write_text('\n\n'.join(logs), encoding='utf-8')
    files = [linux, bundle, apk]
    hashes = {str(p.relative_to(ROOT/'builds')): {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in files}
    (ROOT/'builds/checksums-ports.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    print('Archive checks and checksums saved; target-device execution not tested.')

if __name__ == '__main__':
    main()
