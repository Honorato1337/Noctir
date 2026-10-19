"""Build Linux x86_64 and Android using the local, ignored export toolchain."""
import os
import subprocess
import tarfile
from pathlib import Path
import export_game as common
import prepare_exports as prep

ROOT = Path(__file__).resolve().parents[1]

def linux():
    target = prep.BASE / 'templates/linux_release.x86_64'
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        import json, zipfile
        meta = json.load(prep.request('https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable'))
        asset = next(a for a in meta['assets'] if a['name'].endswith('_export_templates.tpz'))
        with zipfile.ZipFile(prep.RemoteZip(asset['browser_download_url'], asset['size'])) as archive:
            name = next(n for n in archive.namelist() if n.endswith('/linux_release.x86_64'))
            target.write_bytes(archive.read(name))
    presets = ROOT / 'export_presets.cfg'
    text = presets.read_text(encoding='utf-8')
    if 'name="Linux"' not in text:
        text += '\n[preset.2]\nname="Linux"\nplatform="Linux"\nrunnable=true\nexport_filter="all_resources"\nexclude_filter=".export-signing/*,docs/*,tests/*,tools/*,tmp/*,builds/*,export_templates/*,*.md"\nexport_path="builds/linux/OneMoreOrbit.x86_64"\nscript_export_mode=2\n\n[preset.2.options]\ncustom_template/release=""\nbinary_format/architecture="x86_64"\nbinary_format/embed_pck=true\ntexture_format/s3tc_bptc=true\ntexture_format/etc2_astc=false\n'
    presets.write_text(text, encoding='utf-8')
    configured = common.replace_values(text, 'preset.2.options', {'custom_template/release': common.quote(target)})
    output = ROOT / 'builds/linux/OneMoreOrbit.x86_64'
    output.parent.mkdir(parents=True, exist_ok=True)
    try:
        presets.write_text(configured, encoding='utf-8')
        with (ROOT/'builds/export-linux.log').open('w', encoding='utf-8') as log:
            subprocess.run([os.environ['GODOT_BIN'], '--headless', '--path', str(ROOT), '--export-release', 'Linux', str(output)], stdout=log, stderr=subprocess.STDOUT, check=True)
    finally:
        presets.write_text(text, encoding='utf-8')
    assert output.read_bytes()[:4] == b'\x7fELF'
    instructions = output.parent / 'LEIA-ME.txt'
    instructions.write_text('One More Orbit 0.3.3 - Linux x86_64\nExtraia o arquivo .tar.gz. Abra um terminal na pasta e execute:\nchmod +x OneMoreOrbit.x86_64\n./OneMoreOrbit.x86_64\nRequer driver com OpenGL 3.3.\n', encoding='utf-8')
    with tarfile.open(output.parent/'OneMoreOrbit-Linux-x86_64.tar.gz', 'w:gz') as archive:
        for file in [output, instructions]:
            info = archive.gettarinfo(str(file), arcname=file.name)
            info.mode = 0o755 if file == output else 0o644
            with file.open('rb') as data:
                archive.addfile(info, data)
    print('Linux export ready', flush=True)

if __name__ == '__main__':
    linux()
