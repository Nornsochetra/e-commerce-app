"""Regenerates the APM launcher icons from branding/app_icon.svg.

Run from frontend-app/ after changing the logo:
    python tool/generate_icons.py

Needs Google Chrome (renders the SVG) and Pillow (`pip install pillow`).
Writes the iOS AppIcon set, the Android ic_launcher mipmaps and the web favicon/icons.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'branding' / 'app_icon.svg'
MASTER = 1024

CHROME_PATHS = [
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    'google-chrome',
    'chromium',
]


def find_chrome():
    for path in CHROME_PATHS:
        if os.path.isfile(path) or shutil.which(path):
            return path
    sys.exit('Google Chrome not found; it is used to render the SVG.')


def render_master(work: Path) -> Image.Image:
    """Renders the SVG at 1024x1024 with headless Chrome."""
    page = work / 'icon.html'
    page.write_text(
        '<!doctype html><html><body style="margin:0;overflow:hidden">'
        f'<img src="{SOURCE.as_uri()}" width="{MASTER}" height="{MASTER}" style="display:block">'
        '</body></html>',
        encoding='utf-8',
    )
    shot = work / 'master.png'
    subprocess.run(
        [find_chrome(), '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
         '--force-device-scale-factor=1', f'--window-size={MASTER},{MASTER}', f'--screenshot={shot}', page.as_uri()],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    return Image.open(shot).convert('RGB').crop((0, 0, MASTER, MASTER))


def save(master: Image.Image, size: int, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    master.resize((size, size), Image.LANCZOS).save(path, optimize=True)  # RGB: iOS rejects icons with alpha
    print(f'{size:>5}px  {path.relative_to(ROOT)}')


def main():
    with tempfile.TemporaryDirectory() as tmp:
        master = render_master(Path(tmp))

    ios = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for image in json.loads((ios / 'Contents.json').read_text())['images']:
        points = float(image['size'].split('x')[0])
        scale = int(image['scale'].rstrip('x'))
        save(master, round(points * scale), ios / image['filename'])

    for folder, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        save(master, size, ROOT / f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png')

    save(master, 32, ROOT / 'web/favicon.png')
    for size in (192, 512):
        save(master, size, ROOT / f'web/icons/Icon-{size}.png')
        save(master, size, ROOT / f'web/icons/Icon-maskable-{size}.png')


if __name__ == '__main__':
    main()
