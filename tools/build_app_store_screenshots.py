#!/usr/bin/env python3
"""Build the App Store screenshots from flat, deterministic illustrations."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "app_store_screenshots"
ART = OUT / "illustrations"
WORK = OUT / "_work"
W, H = 1242, 2688

BLACK = "#000000"
PANEL = "#17181B"
MID = "#2B2D31"
GRAY = "#66686D"
PAPER = "#F5F1E8"
ORANGE = "#FF6A00"
RED = "#F04A22"

ANTON = ROOT / "assets/fonts/Anton-Regular.ttf"
NUNITO = ROOT / "assets/fonts/NunitoSans-Bold.ttf"


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def centered(draw: ImageDraw.ImageDraw, text: str, y: int, face, fill: str) -> None:
    box = draw.textbbox((0, 0), text, font=face)
    draw.text(((W - box[2]) // 2, y), text, font=face, fill=fill)


def add_grain(image: Image.Image, seed: int) -> None:
    """Sparse screen-print texture; deterministic and clipped to the artwork."""
    rng = random.Random(seed)
    alpha = image.getchannel("A")
    texture = Image.new("RGBA", image.size)
    d = ImageDraw.Draw(texture)
    for _ in range(2600):
        x = rng.randrange(image.width)
        y = rng.randrange(image.height)
        shade = rng.choice(((0, 0, 0, 18), (255, 255, 255, 12)))
        d.line((x, y, x + rng.randrange(1, 6), y), fill=shade, width=1)
    texture.putalpha(Image.composite(texture.getchannel("A"), Image.new("L", image.size), alpha))
    image.alpha_composite(texture)


def header(lines: list[tuple[str, str]], support: list[str]) -> Image.Image:
    canvas = Image.new("RGB", (W, H), BLACK)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((542, 78, 700, 92), radius=7, fill=ORANGE)

    size = 154
    while True:
        face = font(ANTON, size)
        if max(d.textbbox((0, 0), line, font=face)[2] for line, _ in lines) <= 1120:
            break
        size -= 2

    y = 160
    for line, color in lines:
        centered(d, line, y, face, color)
        y += size + 8

    support_face = font(NUNITO, 45)
    y += 42
    for line in support:
        centered(d, line, y, support_face, PAPER)
        y += 62
    return canvas


def pressure_art() -> Image.Image:
    im = Image.new("RGBA", (1120, 1780))
    d = ImageDraw.Draw(im)

    # Oversized pressure dial.
    d.ellipse((120, 70, 1000, 950), fill=PANEL, outline=PAPER, width=20)
    d.ellipse((180, 130, 940, 890), outline=MID, width=38)
    center_xy = (560, 510)
    for i in range(25):
        angle = math.radians(205 + i * 130 / 24)
        long = i % 4 == 0
        r1, r2 = (305, 354) if long else (325, 354)
        p1 = (center_xy[0] + math.cos(angle) * r1, center_xy[1] + math.sin(angle) * r1)
        p2 = (center_xy[0] + math.cos(angle) * r2, center_xy[1] + math.sin(angle) * r2)
        d.line((*p1, *p2), fill=ORANGE if i > 17 else PAPER, width=12 if long else 6)
    needle = math.radians(322)
    d.line((560, 510, 560 + math.cos(needle) * 285, 510 + math.sin(needle) * 285), fill=ORANGE, width=28)
    d.ellipse((520, 470, 600, 550), fill=ORANGE, outline=PAPER, width=8)

    # Mechanical wheel and a person deliberately turning it.
    d.ellipse((95, 1000, 545, 1450), fill=PANEL, outline=PAPER, width=24)
    d.ellipse((195, 1100, 445, 1350), outline=ORANGE, width=34)
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        d.line((320, 1225, 320 + math.cos(rad) * 205, 1225 + math.sin(rad) * 205), fill=GRAY, width=20)
    d.ellipse((274, 1179, 366, 1271), fill=ORANGE)

    # Figure: head, torso, legs, and arms pushing the wheel.
    d.ellipse((730, 900, 842, 1012), fill=ORANGE, outline=PAPER, width=6)
    d.polygon(((690, 1010), (848, 1000), (900, 1250), (720, 1265)), fill=PAPER, outline=BLACK)
    d.polygon(((720, 1260), (812, 1250), (760, 1580), (650, 1580)), fill=MID)
    d.polygon(((815, 1245), (900, 1250), (1030, 1510), (930, 1565)), fill=MID)
    d.polygon(((705, 1050), (660, 1090), (465, 1160), (430, 1100)), fill=ORANGE)
    d.polygon(((840, 1030), (885, 1080), (520, 1245), (485, 1175)), fill=ORANGE)
    d.ellipse((410, 1080, 485, 1155), fill=PAPER)
    d.ellipse((480, 1170, 555, 1245), fill=PAPER)
    d.polygon(((630, 1570), (765, 1570), (760, 1635), (600, 1635)), fill=PAPER)
    d.polygon(((920, 1540), (1040, 1485), (1065, 1545), (935, 1610)), fill=PAPER)
    d.line((70, 1645, 1060, 1645), fill=GRAY, width=12)
    add_grain(im, 1)
    return im


def quote_art() -> Image.Image:
    im = Image.new("RGBA", (1120, 1780))
    d = ImageDraw.Draw(im)

    # A physical pair of quote marks used as a barbell.
    quote_face = font(ANTON, 620)
    d.text((92, 5), "“", font=quote_face, fill=PAPER, stroke_width=8, stroke_fill=BLACK)
    d.text((630, 5), "”", font=quote_face, fill=ORANGE, stroke_width=8, stroke_fill=BLACK)
    d.line((120, 590, 1000, 590), fill=PAPER, width=30)
    d.rectangle((75, 515, 145, 665), fill=ORANGE, outline=PAPER, width=8)
    d.rectangle((975, 515, 1045, 665), fill=ORANGE, outline=PAPER, width=8)

    # Athlete holding the weight overhead.
    d.ellipse((510, 710, 620, 820), fill=ORANGE, outline=PAPER, width=6)
    d.polygon(((440, 835), (690, 835), (650, 1170), (470, 1170)), fill=PAPER, outline=BLACK)
    d.polygon(((470, 855), (410, 900), (245, 645), (300, 610)), fill=ORANGE)
    d.polygon(((665, 855), (725, 900), (875, 645), (825, 610)), fill=ORANGE)
    d.ellipse((230, 575, 310, 655), fill=PAPER)
    d.ellipse((815, 575, 895, 655), fill=PAPER)
    d.polygon(((475, 1160), (555, 1160), (465, 1540), (330, 1540)), fill=MID)
    d.polygon(((565, 1160), (650, 1160), (795, 1535), (660, 1545)), fill=MID)
    d.polygon(((310, 1525), (470, 1525), (455, 1600), (285, 1600)), fill=PAPER)
    d.polygon(((660, 1525), (815, 1515), (845, 1585), (675, 1600)), fill=PAPER)

    # Impact marks keep it graphic instead of photographic.
    for x, y, angle in ((125, 820, -30), (945, 820, 25), (185, 1030, -15), (900, 1040, 20)):
        rad = math.radians(angle)
        d.line((x, y, x + math.cos(rad) * 110, y + math.sin(rad) * 110), fill=ORANGE, width=18)
    d.line((80, 1640, 1040, 1640), fill=GRAY, width=12)
    add_grain(im, 2)
    return im


def excuses_art() -> Image.Image:
    im = Image.new("RGBA", (1120, 1780))
    d = ImageDraw.Draw(im)

    # Person with a megaphone; the callout physically breaks the friction wall.
    d.ellipse((130, 950, 240, 1060), fill=ORANGE, outline=PAPER, width=6)
    d.polygon(((105, 1060), (275, 1060), (340, 1360), (120, 1370)), fill=PAPER, outline=BLACK)
    d.polygon(((125, 1350), (225, 1350), (160, 1640), (40, 1640)), fill=MID)
    d.polygon(((225, 1350), (330, 1350), (470, 1600), (350, 1650)), fill=MID)
    d.polygon(((250, 1120), (320, 1125), (450, 995), (410, 950)), fill=ORANGE)
    d.ellipse((395, 925, 465, 995), fill=PAPER)

    # Megaphone and visual sound beam.
    d.polygon(((420, 880), (560, 800), (560, 1110), (420, 1020)), fill=ORANGE, outline=PAPER)
    d.rounded_rectangle((370, 915, 440, 990), radius=24, fill=PAPER)
    d.polygon(((555, 825), (940, 590), (940, 1320), (555, 1085)), fill=(255, 106, 0, 70))
    for offset in (0, 95, 190):
        d.arc((560 + offset, 720 - offset // 2, 900 + offset, 1190 + offset // 2), -50, 50, fill=PAPER, width=14)

    # Wall of excuses, split down the middle.
    bricks = [
        (770, 160, 1080, 380), (650, 400, 910, 610), (920, 410, 1110, 650),
        (710, 650, 1000, 880), (940, 900, 1120, 1130), (730, 1120, 1030, 1360),
        (860, 1380, 1110, 1600),
    ]
    for i, box in enumerate(bricks):
        d.rectangle(box, fill=MID if i % 2 else PANEL, outline=GRAY, width=7)
    crack = [(815, 210), (760, 480), (845, 640), (755, 855), (835, 1040), (760, 1250), (850, 1510)]
    d.line(crack, fill=ORANGE, width=34, joint="curve")
    for poly in (
        ((680, 390), (590, 340), (630, 270), (720, 325)),
        ((920, 720), (1020, 690), (1040, 790), (955, 820)),
        ((690, 1000), (600, 1030), (575, 940), (650, 900)),
    ):
        d.polygon(poly, fill=PANEL, outline=ORANGE)
    d.line((35, 1655, 1080, 1655), fill=GRAY, width=12)
    add_grain(im, 4)
    return im


def goal_art() -> Image.Image:
    im = Image.new("RGBA", (1120, 1780))
    d = ImageDraw.Draw(im)

    # Concentric target behind a single, finite path.
    d.ellipse((390, 55, 730, 395), outline=GRAY, width=16)
    d.ellipse((450, 115, 670, 335), outline=PAPER, width=14)
    d.ellipse((510, 175, 610, 275), fill=ORANGE)
    d.line((560, 220, 560, 520), fill=PAPER, width=16)
    d.polygon(((560, 225), (760, 295), (560, 365)), fill=ORANGE, outline=PAPER)

    # Flat, impossible-to-misread staircase.
    steps = [
        ((30, 1630), (1090, 1630), (960, 1450), (160, 1450)),
        ((160, 1430), (960, 1430), (855, 1260), (265, 1260)),
        ((265, 1240), (855, 1240), (770, 1080), (350, 1080)),
        ((350, 1060), (770, 1060), (700, 910), (420, 910)),
        ((420, 890), (700, 890), (650, 750), (470, 750)),
        ((470, 730), (650, 730), (615, 610), (505, 610)),
        ((505, 590), (615, 590), (590, 500), (530, 500)),
    ]
    for i, poly in enumerate(steps):
        d.polygon(poly, fill=ORANGE if i % 2 == 0 else MID, outline=PAPER)

    # Small climber keeps the goal human and earned.
    d.ellipse((495, 870, 565, 940), fill=ORANGE, outline=PAPER, width=4)
    d.polygon(((470, 940), (565, 930), (595, 1100), (485, 1110)), fill=PAPER, outline=BLACK)
    d.polygon(((490, 1090), (540, 1090), (500, 1250), (430, 1245)), fill=MID)
    d.polygon(((540, 1090), (585, 1085), (680, 1195), (625, 1240)), fill=MID)
    d.polygon(((485, 965), (455, 1000), (385, 910), (420, 880)), fill=ORANGE)
    d.polygon(((560, 955), (600, 980), (665, 875), (625, 850)), fill=ORANGE)
    d.line((25, 1670, 1095, 1670), fill=GRAY, width=12)
    add_grain(im, 5)
    return im


SLIDES = {
    "01-hardcore-motivation.png": (
        [("HARDCORE MOTIVATION.", PAPER), ("ON YOUR TERMS.", ORANGE)],
        ["Choose the pressure.", "Control when it shows up."],
        "01-pressure.png",
        pressure_art,
    ),
    "02-quotes-that-hit-hard.png": (
        [("QUOTES THAT", PAPER), ("HIT HARD.", ORANGE)],
        ["No gentle affirmations. No empty hype.", "Get back to work."],
        "02-hard-quotes.png",
        quote_art,
    ),
    "04-excuses-called-out.png": (
        [("YOUR EXCUSES", PAPER), ("GET CALLED OUT.", ORANGE)],
        ["Direct prompts call out your friction", "and push you back to work."],
        "04-callout.png",
        excuses_art,
    ),
    "05-one-goal.png": (
        [("ONE GOAL.", PAPER), ("STOP THE DRIFT.", ORANGE)],
        ["Set your schedule. Protect your focus.", "Do the work."],
        "05-goal.png",
        goal_art,
    ),
}


def build() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    for name, (title, support, art_name, maker) in SLIDES.items():
        illustration = maker()
        illustration.save(ART / art_name)
        canvas = header(title, support)
        canvas.paste(illustration, (61, 850), illustration)
        canvas.save(OUT / name, icc_profile=None)

    names = [f"0{i}-" for i in range(1, 6)]
    files = [next(OUT.glob(prefix + "*.png")) for prefix in names]
    thumbs = [Image.open(path).convert("RGB").resize((310, 671), Image.Resampling.LANCZOS) for path in files]
    sheet = Image.new("RGB", (1710, 711), "#222222")
    for i, thumb in enumerate(thumbs):
        sheet.paste(thumb, (20 + i * 338, 20))
    sheet.save(WORK / "contact-sheet.png")

    for path in files:
        result = Image.open(path)
        assert result.size == (W, H) and result.mode == "RGB", path


if __name__ == "__main__":
    build()
