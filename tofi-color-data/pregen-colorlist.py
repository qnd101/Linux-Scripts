#!/bin/python3

import subprocess
from PIL import Image, ImageDraw, ImageFont

data = []
with open('pastel-colors-ansi.txt', 'r') as f:
    for line in f:
        name = line.split()[1]
        temp = line.split('m')[0].split(';')
        fore_rgb = tuple(map(int, temp[2:5]))
        back_rgb = tuple(map(int, temp[7:10]))
        data.append((name, back_rgb, fore_rgb))

# 139 elements; 20 x 7
cell_width = 150
cell_height = 25
col_len = 25

img = Image.new('RGBA', (cell_width * ((len(data)-1)//col_len+1), cell_height * col_len), (0,0,0,0))
draw = ImageDraw.Draw(img)

font = ImageFont.truetype('/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Bold.ttf', 15)

for i, (name, back_rgb, fore_rgb) in enumerate(data):
    y = (i%col_len) * cell_height
    x = i//col_len * cell_width
    draw.rectangle([x, y, x+cell_width, y+cell_height], fill=back_rgb)
    draw.text((x+5, y+2), name, fill=fore_rgb, font=font)

img.save('pastel-colors.png')

# Save data into file
with open('pastel-colors.txt', 'w', newline='') as f:
    for name, rgb, _ in data:
        hex_color = f'#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}'
        f.write(name+' '+hex_color+'\n')
