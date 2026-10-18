import concurrent.futures, hashlib, io, json, os, re, urllib.request, xml.etree.ElementTree as ET, zipfile
from pathlib import Path
BASE=Path(__file__).resolve().parents[1]/'.godot'/'export-tools'
BASE.mkdir(parents=True,exist_ok=True)
HEADERS={'User-Agent':'NOCTIR-local-export'}
def request(url,headers=None):
 return urllib.request.urlopen(urllib.request.Request(url,headers={**HEADERS,**(headers or {})}),timeout=45)
def read_range(url,start,end):
 data=bytearray();failures=0
 while len(data)<end-start+1:
  before=len(data)
  try:
   with request(url,{'Range':f'bytes={start+len(data)}-{end}'}) as r:
    if r.status!=206:raise RuntimeError('Range unavailable')
    while len(data)<end-start+1:
     chunk=r.read(min(65536,end-start+1-len(data)))
     if not chunk:break
     data.extend(chunk)
  except Exception:
   pass
  failures=failures+1 if len(data)==before else 0
  if failures>=10:raise RuntimeError(f'Unable to resume bytes {start+len(data)}-{end}')
 return bytes(data)

def range_data(url,start,length):
 blocks=[(offset,min(start+length-1,offset+1048575)) for offset in range(start,start+length,1048576)]
 with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
  return b''.join(pool.map(lambda pair:read_range(url,*pair),blocks))

def download(url,path,sha=None):
 with request(url,{'Range':'bytes=0-0'}) as r:
  resolved=url
  total=int(r.headers.get('Content-Range','0/0').split('/')[-1])
  if not total:raise RuntimeError('Missing range length '+path.name)
 if not path.exists() or path.stat().st_size!=total:
  print('Downloading in blocks '+path.name+f' ({total//1048576} MB)',flush=True)
  existing=path.stat().st_size if path.exists() else 0
  if existing>total:existing=0
  blocks=[(offset,min(total-1,offset+1048575)) for offset in range(existing,total,1048576)]
  with path.open('ab' if existing else 'wb') as dst,concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
   done=existing
   for chunk in pool.map(lambda pair:read_range(resolved,*pair),blocks):
    dst.write(chunk);done+=len(chunk)
    if done//16777216 != (done-len(chunk))//16777216:print(path.name+f' {done//1048576}/{total//1048576} MB',flush=True)
 if sha and hashlib.sha256(path.read_bytes()).hexdigest().lower()!=sha.lower(): raise RuntimeError('Checksum: '+path.name)
 return path
class RemoteZip(io.RawIOBase):
 def __init__(self,url,size):
  self.url=url;self.size=size;self.pos=0
  with request(url,{'Range':f'bytes={size-65536}-{size-1}'}) as r:
   self.url=r.geturl()
   if r.status!=206: raise RuntimeError('Server requires full template download')
   self.tail=r.read();self.tail_start=size-len(self.tail)
 def seekable(self): return True
 def readable(self): return True
 def tell(self): return self.pos
 def seek(self,offset,whence=0):
  self.pos=offset if whence==0 else (self.pos+offset if whence==1 else self.size+offset)
  return self.pos
 def read(self,n=-1):
  n=self.size-self.pos if n<0 else min(n,self.size-self.pos)
  if n<=0:return b''
  if self.pos>=self.tail_start:
   data=self.tail[self.pos-self.tail_start:self.pos-self.tail_start+n]
  else:
   data=range_data(self.url,self.pos,n)
  self.pos+=len(data)
  return data
def templates():
 required=BASE/'templates'
 if all((required/n).is_file() for n in ['windows_release_x86_64.exe','android_debug.apk','android_release.apk','version.txt']):return
 meta=json.load(request('https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable'))
 asset=next(a for a in meta['assets'] if a['name']=='Godot_v4.7.2-stable_export_templates.tpz')
 wanted={'windows_release_x86_64.exe','android_debug.apk','android_release.apk','version.txt'}
 target=BASE/'templates';target.mkdir(exist_ok=True)
 if all((target/n).is_file() for n in wanted):return
 try:stream=RemoteZip(asset['browser_download_url'],asset['size'])
 except RuntimeError:stream=download(asset['browser_download_url'],BASE/'templates.tpz')
 with zipfile.ZipFile(stream) as z:
  for name in z.namelist():
   if Path(name).name in wanted:
    print('Extracting template '+Path(name).name,flush=True)
    (target/Path(name).name).write_bytes(z.read(name))
 if not all((target/n).is_file() for n in wanted):raise RuntimeError('Missing selected template')
 print('Templates ready',flush=True)
def java():
 if list(BASE.glob('jdk*/bin/java.exe')):return
 meta=json.load(request('https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows'))
 pkg=meta[0]['binary']['package']
 archive=download(pkg['link'],BASE/'jdk.zip',pkg['checksum'])
 with zipfile.ZipFile(archive) as z:z.extractall(BASE)
 print('Java ready',flush=True)
def android():
 if (BASE/'android-sdk/build-tools/35.0.1/apksigner.bat').exists() and (BASE/'android-sdk/platform-tools/adb.exe').exists():return
 root=ET.parse(request('https://dl.google.com/android/repository/repository2-3.xml')).getroot()
 packages=root.findall('remotePackage')
 def get_package(path):
  pkg=next(p for p in packages if p.attrib['path']==path)
  archives=pkg.find('archives').findall('archive')
  archive=next(a for a in archives if a.findtext('host-os','windows')=='windows')
  info=archive.find('complete')
  relative=info.findtext('url')
  url=relative if relative.startswith('https://') else 'https://dl.google.com/android/repository/'+relative
  print('Official SDK source: '+url,flush=True)
  return pkg,info,url
 # Prebuilt APK export needs only Android packaging/signing tools and adb.
 target=BASE/'android-sdk';target.mkdir(exist_ok=True)
 for path in ['build-tools;35.0.1','platform-tools']:
  pkg,info,url=get_package(path)
  out=target/('build-tools/35.0.1' if path.startswith('build-tools') else 'platform-tools')
  if (out/('apksigner.bat' if path.startswith('build-tools') else 'adb.exe')).exists():continue
  archive=download(url,BASE/(path.replace(';','-')+'.zip'))
  checksum=info.find('checksum')
  if checksum is not None:
   algorithm=checksum.attrib.get('type','sha1')
   if hashlib.new(algorithm,archive.read_bytes()).hexdigest()!=checksum.text:raise RuntimeError('SDK checksum mismatch')
  with zipfile.ZipFile(archive) as z:
   for entry in z.infolist():
    parts=Path(entry.filename).parts
    if len(parts)<2:continue
    dest=out.joinpath(*parts[1:])
    if entry.is_dir():dest.mkdir(parents=True,exist_ok=True)
    else:
     dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(z.read(entry))
 print('Android build tools ready',flush=True)
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
  jobs={pool.submit(fn):fn.__name__ for fn in [templates,java,android]}
  for job in concurrent.futures.as_completed(jobs):
   try:job.result()
   except Exception as exc:print('FAILED '+jobs[job]+': '+str(exc),flush=True);raise
 print('EXPORT TOOLCHAIN READY',flush=True)
