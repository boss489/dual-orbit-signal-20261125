from pathlib import Path
import re
from fontTools.ttLib import TTFont
root = Path(__file__).resolve().parent
script = (root / 'Main.gd').read_text()
strings = re.findall(r'"([^"\n]*)"', script)
chars = set(''.join(strings))
font = TTFont(root / 'NotoSansKR-Medium.ttf')
cmap = font.getBestCmap()
missing = sorted(c for c in chars if ord(c) >= 32 and ord(c) not in cmap)
print(f'Font: {font["name"].getDebugName(1)}; unique literal chars: {len(chars)}; missing: {missing}')
print('axes:', [(x.axisTag, x.minValue, x.defaultValue, x.maxValue) for x in font['fvar'].axes] if 'fvar' in font else 'static')
assert not missing
