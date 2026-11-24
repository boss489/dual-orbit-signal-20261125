from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from pathlib import Path

source = Path('NotoSansKR.ttf')
target = Path('NotoSansKR-Medium.ttf')
font = TTFont(source)
instantiateVariableFont(font, {'wght': 600}, inplace=True)
font.save(target)
print(f'Baked Noto Sans KR 600: {target.stat().st_size} bytes')
