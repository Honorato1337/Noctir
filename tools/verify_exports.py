from pathlib import Path
import hashlib,json,re,subprocess
root=Path(__file__).resolve().parents[1]
base=root/'.godot/export-tools'
java=next(base.glob('jdk*/bin/java.exe'))
sdk=base/'android-sdk/build-tools/35.0.1'
apk=root/'builds/android/OneMoreOrbit.apk'
exe=root/'builds/windows/OneMoreOrbit.exe'
logs=[]
for name,cmd in [('signature',[str(java),'-jar',str(sdk/'lib/apksigner.jar'),'verify','--verbose',str(apk)]),('alignment',[str(sdk/'zipalign.exe'),'-c','-P','16','4',str(apk)]),('manifest',[str(sdk/'aapt.exe'),'dump','badging',str(apk)])]:
    r=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
    if r.returncode:raise RuntimeError(name+' '+r.stderr)
    logs.append(name+'\n'+r.stdout+r.stderr)
    print(name+': PASS',flush=True)
    if name=='manifest':
        package=next(line for line in r.stdout.splitlines() if line.startswith('package:'))
        presets=(root/'export_presets.cfg').read_text(encoding='utf-8')
        code=re.search(r'^version/code=(\d+)$',presets,re.M).group(1)
        version=re.search(r'^version/name="([^"]+)"$',presets,re.M).group(1)
        assert "versionCode='"+code+"'" in package and "versionName='"+version+"'" in package
        print(package,flush=True)
r=subprocess.run([str(exe),'--headless','--fixed-fps','60','--quit-after','180','--','--smoke'],cwd=exe.parent,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
text=r.stdout+r.stderr
(root/'builds/verify-windows.log').write_text(text,encoding='utf-8')
assert r.returncode==0 and not any(marker in text for marker in ['SCRIPT ERROR','Parse Error','Failed loading resource','Invalid access'])
print('Standalone EXE: PASS (180 gameplay frames)',flush=True)
(root/'builds/verify-android.log').write_text('\n\n'.join(logs),encoding='utf-8')
manifest={str(p.relative_to(root/'builds')):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [exe,apk]}
(root/'builds/checksums.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
