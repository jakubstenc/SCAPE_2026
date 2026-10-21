"""Split node images for the pollen-transfer concept: left half = plant photo, right half = Succisa stigma."""
from PIL import Image, ImageDraw

S = 1200  # output size (px)
plants = {
    "centaurea": "images/Centaurea_jaceae.png", "succisa": "images/Succisa_pratensis.png",
    "achillea": "images/Achillea_ptarmica.png", "selinum": "images/Selinum_carvifolia.png",
    "ranunculus": "images/Ranunculus_acris.png", "pimpinella": "images/Pimpinella_saxifraga.png",
}

# Stigma: place the stigma head centre in the middle of the right half, on a white canvas
stigma = Image.open("images/Blizna_Suc_pra_2.jpg").convert("RGB")
# Paint out the air bubbles of the microscope slide (centre x, y, radius in the original photo)
bubbles = [(476, 570, 185), (124, 1811, 175), (2712, 3892, 400), (3096, 1140, 160)]
draw = ImageDraw.Draw(stigma)
bg = stigma.getpixel((1500, 300))
for bx, by, br in bubbles:
    draw.ellipse((bx - br, by - br, bx + br, by + br), fill=bg)
head_x, head_y, head_span = 1560, 2100, 2650          # head centre and width in the original photo
scale = (S / 2 * 0.95) / head_span
st = stigma.resize((round(stigma.width * scale), round(stigma.height * scale)), Image.LANCZOS)
st_canvas = Image.new("RGB", (S, S), "white")
st_canvas.paste(st, (round(S * 0.75 - head_x * scale), round(S / 2 - head_y * scale)))

circle = Image.new("L", (S, S), 0)
ImageDraw.Draw(circle).ellipse((0, 0, S - 1, S - 1), fill=255)
left = Image.new("L", (S, S), 0)
ImageDraw.Draw(left).rectangle((0, 0, S // 2 - 1, S), fill=255)

for name, path in plants.items():
    plant = Image.open(path).convert("RGBA").resize((S, S), Image.LANCZOS)
    out = Image.composite(plant.convert("RGB"), st_canvas, left).convert("RGBA")
    ImageDraw.Draw(out).line((S // 2, 0, S // 2, S), fill="white", width=14)
    out.putalpha(circle)
    out.save(f"images/pollen_node_{name}.png")
print("Saved 6 split node images.")
