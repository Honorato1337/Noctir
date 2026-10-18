"""Build local standalone Windows EXE and signed Android APK with Godot 4.7.2."""
import hashlib, json, os, re, secrets, shutil, subprocess
from pathlib import Path
import prepare_exports
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.godot'/'export-tools'
def replace_values(text, section, values):
 pattern=r'(\['+re.escape(section)+r'\]\n)(.*?)(?=\n\[|\Z)'
 match=re.search(pattern,text,re.S)
 if not match:
  text+='\n['+section+']\n';match=re.search(pattern,text,re.S)
 body=match.group(2)
 for key,value in values.items():
  line=key+'='+value
  if re.search(r'^'+re.escape(key)+r'\s*=',body,re.M):body=re.sub(r'^'+re.escape(key)+r'\s*=.*$',lambda _:line,body,flags=re.M)
  else:body+='\n'+line+'\n'
 return text[:match.start(2)]+body+text[match.end(2):]
def quote(value):return '"'+str(value).replace('\\','/').replace('"','\\"')+'"'
def main():
 for fn in [prepare_exports.templates,prepare_exports.java,prepare_exports.android]:fn()
 java=next(BASE.glob('jdk*/bin/java.exe')).parent.parent
 engine=BASE/'godot'/'Godot.exe';engine.parent.mkdir(exist_ok=True)
 source=Path('C:/Users/heads/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe')
 if not engine.exists():shutil.copy2(source,engine)
 (engine.parent/'_sc_').touch()
 settings=engine.parent/'editor_data';settings.mkdir(exist_ok=True)
 sdk=BASE/'android-sdk'
 private=ROOT/'.export-signing';private.mkdir(exist_ok=True)
 key=private/'noctir-release.keystore'
 stored=private/'credentials.json'
 credentials=ROOT/'.godot'/'export_credentials.cfg'
 text=credentials.read_text(encoding='utf-8') if credentials.exists() else ''
 match=re.search(r'^keystore/release_password="(.+)"$',text,re.M)
 password=json.loads(stored.read_text(encoding='utf-8'))['password'] if stored.exists() else (match.group(1) if key.exists() and match else secrets.token_urlsafe(32))
 env=os.environ.copy();env['JAVA_HOME']=str(java);env['ANDROID_HOME']=str(sdk);env['NOCTIR_KEYSTORE_PASSWORD']=password
 env['PATH']=str(java/'bin')+os.pathsep+env['PATH']
 if not key.exists():
  subprocess.run([str(java/'bin'/'keytool.exe'),'-genkeypair','-keystore',str(key),'-alias','noctir','-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=NOCTIR, OU=Game Development','-storepass:env','NOCTIR_KEYSTORE_PASSWORD','-keypass:env','NOCTIR_KEYSTORE_PASSWORD'],env=env,check=True)
 stored.write_text(json.dumps({'alias':'noctir','password':password},indent=2),encoding='utf-8')
 # Only ignored local files contain signing credentials. Preserve this key for updates.
 text=replace_values(text,'preset.0.options',{'keystore/release':quote(key),'keystore/release_user':quote('noctir'),'keystore/release_password':quote(password)})
 credentials.write_text(text,encoding='utf-8')
 (settings/'editor_settings-4.7.tres').write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/java_sdk_path = '+quote(java)+'\nexport/android/android_sdk_path = '+quote(sdk)+'\nexport/android/debug_keystore = '+quote(key)+'\nexport/android/debug_keystore_user = "noctir"\nexport/android/debug_keystore_pass = '+quote(password)+'\n',encoding='utf-8')
 presets=ROOT/'export_presets.cfg';text=presets.read_text(encoding='utf-8')
 text=replace_values(text,'preset.0.options',{'custom_template/debug':quote(BASE/'templates'/'android_debug.apk'),'custom_template/release':quote(BASE/'templates'/'android_release.apk')})
 text=replace_values(text,'preset.1.options',{'custom_template/release':quote(BASE/'templates'/'windows_release_x86_64.exe')})
 presets.write_text(text,encoding='utf-8')
 for preset,output in [('Windows Desktop',ROOT/'builds'/'windows'/'NOCTIR.exe'),('Android',ROOT/'builds'/'android'/'NOCTIR.apk')]:
  output.parent.mkdir(parents=True,exist_ok=True)
  log=ROOT/'builds'/('export-windows.log' if preset=='Windows Desktop' else 'export-android.log')
  print('Exporting '+preset,flush=True)
  with log.open('w',encoding='utf-8') as stream:
   result=subprocess.run([str(engine),'--headless','--path',str(ROOT),'--export-release',preset,str(output)],env=env,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT)
  if result.returncode or not output.exists():
   print(log.read_text(encoding='utf-8'),flush=True);raise RuntimeError('Export failed: '+preset)
  print(f'Built {output.name}: {output.stat().st_size:,} bytes',flush=True)
 print('Both export files ready',flush=True)
if __name__=='__main__':main()
