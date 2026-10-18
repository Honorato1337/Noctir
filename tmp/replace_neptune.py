from pathlib import Path
root=Path(__file__).resolve().parents[1]
mapping={
 'venus_refinery':'neptune_outpost',
 'venus_gardens':'neptune_frostfields',
 'venus_channels':'neptune_windways',
 'venus_core':'neptune_storm_core',
}
names={
 'VENUS / REFINARIA':'NETUNO / POSTO BOREAL',
 'VENUS / JARDINS SULFURICOS':'NETUNO / CAMPOS DE GEADA',
 'VENUS / CANAIS':'NETUNO / CORREDORES DE VENTO',
 'VENUS / CAMARA DE PRESSAO':'NETUNO / NUCLEO DA TEMPESTADE',
 'Vênus / Refinaria':'Netuno / Posto Boreal',
 'Vênus / Jardins Sulfúricos':'Netuno / Campos de Geada',
 'Vênus / Canais':'Netuno / Corredores de Vento',
 'Vênus / Câmara de Pressão':'Netuno / Núcleo da Tempestade',
}
for old,new in mapping.items():
    src=root/f'scenes/world/{old}.tscn'
    dst=root/f'scenes/world/{new}.tscn'
    assert src.resolve().is_relative_to(root) and dst.resolve().is_relative_to(root)
    src.rename(dst)
    uid=src.with_suffix('.tscn.uid')
    if uid.exists(): uid.rename(dst.with_suffix('.tscn.uid'))
paths=list((root/'scripts').glob('*.gd'))+list((root/'scenes').rglob('*.tscn'))+list((root/'tests').glob('*.gd'))+list((root/'docs').glob('*.md'))+[root/'README.md']
for path in paths:
    original=path.read_text(encoding='utf-8')
    text=original
    for old,new in mapping.items(): text=text.replace(old,new)
    for old,new in names.items(): text=text.replace(old,new)
    text=text.replace('VÊNUS','NETUNO').replace('Vênus','Netuno').replace('preview-venus','preview-neptune')
    if path.name=='main_menu.tscn':
        text=text.replace('name="Venus"','name="Neptune"').replace('/Route/Venus','/Route/Neptune')
        # Retain the hidden route's layout while updating its planet accent.
        text=text.replace('Color(1, 0.82, 0.45, 1)\ntheme_override_font_sizes/font_size = 22\ntext = "05—08   NETUNO"','Color(0.47, 0.81, 0.96, 1)\ntheme_override_font_sizes/font_size = 22\ntext = "05—08   NETUNO"')
    if path.parent.name=='world':
        text=text.replace('name="Acid1"','name="Hazard1"').replace('name="Acid2"','name="Hazard2"')
        if path.stem.startswith('neptune_'):
            text=text.replace('Color(0.12, 0.10, 0.15, 1)','Color(0.07, 0.16, 0.24, 1)')
            text=text.replace('Color(0.25, 0.28, 0.32, 1)','Color(0.18, 0.38, 0.5, 1)')
    if path.suffix=='.md':
        text=text.replace('cristais de enxofre que mantêm distância e disparam','sentinelas de gelo que mantêm distância e disparam estilhaços duplos')
        text=text.replace('ácido periódico em Netuno','geadas periódicas e rajadas em Netuno')
        text=text.replace('nuvens ácidas de Netuno','zonas de geada de Netuno')
        text=text.replace('e ácido','e geada').replace('e duas nuvens centrais','e duas zonas de geada centrais').replace('ácido nas extremidades','geada nas extremidades').replace('da nuvem central','da zona de geada central')
        text=text.replace('Altamente ácido','Congelante')
    if text!=original: path.write_text(text,encoding='utf-8')
print('Replaced sector files and their references with Neptune arenas.')
