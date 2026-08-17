from PIL import Image, ImageDraw, ImageFont
import os

path = os.path.join(os.getcwd(), 'assets', 'images', 'docmac_logo.png')
os.makedirs(os.path.dirname(path), exist_ok=True)

img = Image.new('RGBA', (512, 512), (255, 255, 255, 0))
d = ImageDraw.Draw(img)
d.ellipse((56, 56, 456, 456), fill=(67, 97, 238, 255))
d.ellipse((160, 160, 352, 352), fill=(255, 255, 255, 255))

font_path = 'C:/Windows/Fonts/arial.ttf'
try:
    font = ImageFont.truetype(font_path, 180)
except Exception:
    font = ImageFont.load_default()

w, h = d.textsize('D', font=font)
d.text(((512 - w) / 2, (512 - h) / 2 - 20), 'D', font=font, fill=(67, 97, 238, 255))
img.save(path)
print('saved', path, os.path.getsize(path))
