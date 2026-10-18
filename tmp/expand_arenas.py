from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
def coordinate(value,axis):
    origin=64 if axis=='x' else 104
    factor=1.5 if axis=='x' else 1.6
    return round((origin+(float(value)-origin)*factor)/4)*4
for path in (root/'scenes/world').glob('*.tscn'):
    s=path.read_text(encoding='utf-8')
    s=re.sub(r'offset_(left|right|top|bottom) = (-?[\d.]+)',lambda m:f'offset_{m[1]} = {coordinate(m[2],"x" if m[1] in ["left","right"] else "y")}.0',s)
    s=re.sub(r'position = Vector2\(([-\d.]+),\s*([-\d.]+)\)',lambda m:f'position = Vector2({coordinate(m[1],"x")}, {coordinate(m[2],"y")})',s)
    s=s.replace('PackedVector2Array(64,104,1088,104,1088,664,64,664,64,104)','PackedVector2Array(64,104,1600,104,1600,1000,64,1000,64,104)')
    path.write_text(s,encoding='utf-8')
print('Expanded twelve authored arenas to 1536 x 896 without scaling sprites.')
