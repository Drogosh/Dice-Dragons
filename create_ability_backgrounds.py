#!/usr/bin/env python3
import os
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Установка Pillow...")
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw, ImageFont

# Размеры карточки
width, height = 59, 162

# Цвета для каждой характеристики
abilities = [
    ('STR', (200, 50, 50)),      # Красный для Силы
    ('DEX', (50, 150, 200)),     # Синий для Ловкости
    ('CON', (100, 150, 100)),    # Зеленый для Телосложения
    ('INT', (150, 100, 200)),    # Фиолетовый для Интеллекта
    ('WIS', (200, 150, 50)),     # Оранжевый для Мудрости
    ('CHA', (200, 100, 150)),    # Розовый для Харизмы
]

filenames = ['ability_str', 'ability_dex', 'ability_con', 'ability_int', 'ability_wis', 'ability_cha']

os.makedirs('assets/images', exist_ok=True)

for (label, color), filename in zip(abilities, filenames):
    img = Image.new('RGB', (width, height), color=color)
    draw = ImageDraw.Draw(img)

    try:
        font = ImageFont.truetype('arial.ttf', 10)
    except:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), label, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (width - text_width) // 2
    draw.text((text_x, 8), label, fill=(255, 255, 255), font=font)

    img.save(f'assets/images/{filename}.png')
    print(f'✅ Создан {filename}.png')

print("\n✨ Все фоны созданы успешно!")

