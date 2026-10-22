"""Build the files to send: one self-contained HTML (primary) and a PDF backup.

Originals are never modified. Steps:
  1. every image/video referenced in index.qmd is copied into images_web/ at slide resolution
  2. index.qmd is copied to SCAPE_2026_Stenc.qmd with paths pointing to images_web/ and embed-resources on
  3. Quarto renders it into export/SCAPE_2026_Stenc.html (single file)
  4. headless Chrome prints the HTML to export/SCAPE_2026_Stenc.pdf (one page per build step)

Run from the project folder:  python3 make_export.py
"""
import base64
import re
import shutil
import subprocess
from pathlib import Path
from urllib.parse import unquote

from PIL import Image

ROOT = Path(__file__).resolve().parent
SRC_QMD = ROOT / "index.qmd"
WEB = ROOT / "images_web"
EXPORT = ROOT / "export"
NAME = "SCAPE_2026_Stenc"

MAX_SIDE = 1600        # px; the slide is ~1050 px wide, this leaves room for a full-HD projector
MAX_SIDE_ALPHA = 1000  # transparent PNGs (round photos, plots) are shown smaller and compress poorly
JPEG_QUALITY = 85

WEB.mkdir(exist_ok=True)
EXPORT.mkdir(exist_ok=True)

qmd = SRC_QMD.read_text(encoding="utf-8")
refs = sorted(set(re.findall(r'images/[^"\')\s}]+', qmd)))


def has_alpha(im):
    if im.mode not in ("RGBA", "LA", "P"):
        return False
    return im.convert("RGBA").getchannel("A").getextrema()[0] < 255


total_in = total_out = 0
for ref in refs:
    src = ROOT / unquote(ref)
    if not src.exists():
        print("missing:", ref)
        continue
    dst = WEB / src.name
    total_in += src.stat().st_size
    ext = src.suffix.lower()
    if ext == ".mp4":
        if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime:
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-an",
                            "-vf", "scale=1280:-2", "-c:v", "libx264", "-crf", "30", "-preset", "slow",
                            "-movflags", "+faststart", str(dst)], check=True)
    elif ext in (".png", ".jpg", ".jpeg", ".gif", ".webp"):
        im = Image.open(src)
        im.load()
        limit = MAX_SIDE_ALPHA if ext == ".png" and has_alpha(im) else MAX_SIDE
        if max(im.size) > limit:
            im.thumbnail((limit, limit), Image.LANCZOS)
        if ext == ".png":
            if not has_alpha(im) and im.mode != "P":
                # opaque photos stored as PNG compress far better as JPEG, but keep the name
                # so the HTML reference stays valid; browsers sniff the real format
                im.convert("RGB").save(dst, "JPEG", quality=JPEG_QUALITY, optimize=True)
            else:
                im.save(dst, "PNG", optimize=True)
        elif ext in (".jpg", ".jpeg"):
            im.convert("RGB").save(dst, "JPEG", quality=JPEG_QUALITY, optimize=True)
        else:
            shutil.copy2(src, dst)
    else:
        shutil.copy2(src, dst)
    total_out += dst.stat().st_size

print(f"{len(refs)} files: {total_in / 1e6:.0f} MB -> {total_out / 1e6:.0f} MB")

# Export copy of the slides: point at images_web/ and embed everything into one file
out = qmd.replace("images/", "images_web/")
out = out.replace("embed-resources: false", "embed-resources: true")
export_qmd = ROOT / f"{NAME}.qmd"
export_qmd.write_text(out, encoding="utf-8")

subprocess.run(["quarto", "render", export_qmd.name, "--output-dir", "export"], cwd=ROOT, check=True)
export_qmd.unlink()
# the website project also copies site files into export/; keep only what is sent
for extra in EXPORT.iterdir():
    if extra.name not in (f"{NAME}.html", f"{NAME}.pdf"):
        shutil.rmtree(extra) if extra.is_dir() else extra.unlink()
html = EXPORT / f"{NAME}.html"

# PDF backup via reveal.js print mode (fragments become separate pages: pdf-separate-fragments);
# printed before the video is embedded, a PDF cannot show it anyway and Chrome stalls on it
pdf = EXPORT / f"{NAME}.pdf"
chrome = shutil.which("google-chrome") or shutil.which("chromium")
subprocess.run([chrome, "--headless=new", "--disable-gpu", "--no-sandbox", "--no-pdf-header-footer",
                "--virtual-time-budget=60000", f"--print-to-pdf={pdf}",
                html.as_uri() + "?print-pdf"], check=True, capture_output=True, timeout=600)
print(f"PDF:  {pdf} ({pdf.stat().st_size / 1e6:.1f} MB)")

# embed-resources does not inline slide background videos, and reveal.js splits
# data-background-video at commas, so a data: URI breaks it. Store the video as base64 text
# and turn it into a (comma-free) blob: URL just before Reveal starts.
page = html.read_text(encoding="utf-8")
store = []
for i, vid in enumerate(sorted(set(re.findall(r'data-background-video="(images_web/[^"]+)"', page)))):
    data = base64.b64encode((ROOT / vid).read_bytes()).decode("ascii")
    page = page.replace(f'data-background-video="{vid}"', f'data-embedded-video="bgvid{i}"')
    store.append(f'<script type="application/octet-stream" id="bgvid{i}">{data}</script>')
if store:
    loader = """
document.querySelectorAll('section[data-embedded-video]').forEach(function (sec) {
  var b64 = document.getElementById(sec.getAttribute('data-embedded-video')).textContent;
  var bin = atob(b64), bytes = new Uint8Array(bin.length);
  for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  sec.setAttribute('data-background-video', URL.createObjectURL(new Blob([bytes], {type: 'video/mp4'})));
});
"""
    # use the last occurrence: earlier ones sit inside embedded plugin code; the stored video
    # must come before the <script> that runs the loader, or it does not exist yet
    init = page.rindex("Reveal.initialize(")
    page = page[:init] + loader + page[init:]
    tag = page.rindex("<script>", 0, init)
    page = page[:tag] + "\n".join(store) + "\n" + page[tag:]
html.write_text(page, encoding="utf-8")
print(f"HTML: {html} ({html.stat().st_size / 1e6:.1f} MB)")
