"""Encode native game captures as looping GIFs and validate the delivered bundle."""
from pathlib import Path
import hashlib,json,zipfile
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/media/gifs'
manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
for clip in manifest['clips']:
    files=sorted((ROOT/'tmp/mechanics-frames'/Path(clip['file']).stem).glob('*.png'))
    assert len(files)==clip['frames'],clip['file']
    # Shared palette prevents frame-to-frame color flicker; no dithering on pixel art.
    samples=files[::max(1,len(files)//16)]
    swatch=Image.new('RGB',(160*len(samples),90))
    for i,path in enumerate(samples):
        with Image.open(path) as im: swatch.paste(im.convert('RGB').resize((160,90),Image.Resampling.NEAREST),(i*160,0))
    palette=swatch.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
    frames=[]
    for path in files:
        with Image.open(path) as im:
            assert im.size==(640,360)
            frames.append(im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE))
    target=OUT/clip['file']
    frames[0].save(target,save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=True,disposal=1)
    with Image.open(target) as check:
        assert check.size==(640,360) and check.info['loop']==0
        duration=0
        for i in range(check.n_frames):
            check.seek(i);check.load()
            expected=frames[duration//50].convert("RGB")
            assert ImageChops.difference(check.convert("RGB"),expected).getbbox() is None,(clip["file"],i,"compositing mismatch")
            duration+=check.info["duration"]
        assert duration==clip['frames']*50,(clip['file'],duration)
    clip['bytes']=target.stat().st_size
    clip['sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
    print(f"Verified {clip['file']}: {duration/1000:g}s, {clip['bytes']:,} bytes")
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
archive=ROOT/'docs/media/one-more-orbit-gifs.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as bundle:
    for clip in manifest['clips']:bundle.write(OUT/clip['file'],'one-more-orbit-gifs/'+clip['file'])
    bundle.write(OUT/'manifest.json','one-more-orbit-gifs/manifest.json')
    bundle.writestr('one-more-orbit-gifs/LEIA-ME.md',(OUT/'README.md').read_text(encoding='utf-8').replace('(../../../README.md)','(https://github.com/Honorato1337/Noctir)').replace('(../one-more-orbit-gifs.zip)','(https://github.com/Honorato1337/Noctir/raw/refs/heads/main/docs/media/one-more-orbit-gifs.zip)'))
with zipfile.ZipFile(archive) as check:
    assert check.testzip() is None and len(check.namelist())==10
print(f"ZIP verified: {archive} ({archive.stat().st_size:,} bytes)")
