import math, random, sys, os
out = sys.argv[1]
os.makedirs(out, exist_ok=True)

PINE_LIGHT, PINE_DARK = "#EBCB92", "#D4AA6C"
GRAIN = "#93612F"
INK = "#4A2A12"
RED = "#C0301A"

def grain_paths(rng, x0, y0, w, h, spacing=(10, 22), amp=(2, 9)):
    paths, y = [], y0 - 10
    while y < y0 + h + 10:
        late = rng.random() < 0.28
        a = rng.uniform(*amp); wl = rng.uniform(260, 700); ph = rng.uniform(0, 6.283)
        pts = []
        x = x0 - 20
        while x <= x0 + w + 20:
            pts.append(f"{x:.1f},{y + a*math.sin(x/wl*6.283+ph):.1f}")
            x += 16
        op = rng.uniform(0.2, 0.32) if late else rng.uniform(0.07, 0.13)
        sw = rng.uniform(3, 7) if late else rng.uniform(1, 2)
        paths.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{GRAIN}" stroke-opacity="{op:.2f}" stroke-width="{sw:.1f}"/>')
        y += rng.uniform(*spacing)
    return "\n".join(paths)

def knot(cx, cy, w):
    rings = []
    for i in range(6):
        k = 1 - i * 0.15
        rings.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{w*k:.1f}" ry="{w*0.42*k:.1f}" fill="none" stroke="{GRAIN}" stroke-opacity="0.3" stroke-width="3"/>')
    rings.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{w*0.22:.1f}" ry="{w*0.1:.1f}" fill="#5A3414" fill-opacity="0.55"/>')
    return "\n".join(rings)

def pt(cx, cy, r, deg):
    t = math.radians(deg)
    return cx + r*math.cos(t), cy - r*math.sin(t)

def vu(cx, cy, r, sw):
    """Simple VU glyph: scale arc with a red top end, five ticks, needle, pivot."""
    a0, a1, ared = 150, 30, 55
    s = pt(cx, cy, r, a0); m = pt(cx, cy, r, ared); e = pt(cx, cy, r, a1)
    parts = [
        f'<path d="M{s[0]:.1f} {s[1]:.1f} A{r} {r} 0 0 1 {m[0]:.1f} {m[1]:.1f}" fill="none" stroke="{INK}" stroke-width="{sw}" stroke-linecap="round"/>',
        f'<path d="M{m[0]:.1f} {m[1]:.1f} A{r} {r} 0 0 1 {e[0]:.1f} {e[1]:.1f}" fill="none" stroke="{RED}" stroke-width="{sw}" stroke-linecap="round"/>',
    ]
    for deg in (140, 115, 90, 65, 40):
        p1 = pt(cx, cy, r + sw*0.9, deg); p2 = pt(cx, cy, r + sw*1.9, deg)
        col = RED if deg < ared else INK
        parts.append(f'<line x1="{p1[0]:.1f}" y1="{p1[1]:.1f}" x2="{p2[0]:.1f}" y2="{p2[1]:.1f}" stroke="{col}" stroke-width="{sw*0.45:.1f}" stroke-linecap="round"/>')
    n = pt(cx, cy, r * 0.9, 62)
    parts.append(f'<line x1="{cx}" y1="{cy}" x2="{n[0]:.1f}" y2="{n[1]:.1f}" stroke="{INK}" stroke-width="{sw*0.8:.1f}" stroke-linecap="round"/>')
    parts.append(f'<circle cx="{cx}" cy="{cy}" r="{sw*0.95:.1f}" fill="{INK}"/>')
    return "\n".join(parts)

def icon_body(rng, size=1024):
    # macOS icon grid: 824pt rounded square inset 100pt, with a soft shadow.
    return f'''<defs>
  <linearGradient id="pine" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{PINE_LIGHT}"/><stop offset="1" stop-color="{PINE_DARK}"/>
  </linearGradient>
  <clipPath id="tile"><rect x="100" y="100" width="824" height="824" rx="185"/></clipPath>
  <filter id="shadow" x="-10%" y="-10%" width="120%" height="125%">
    <feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#000" flood-opacity="0.28"/>
  </filter>
</defs>
<g filter="url(#shadow)"><rect x="100" y="100" width="824" height="824" rx="185" fill="url(#pine)"/></g>
<g clip-path="url(#tile)">
{grain_paths(rng, 100, 100, 824, 824)}
{knot(250, 820, 70)}
</g>
<rect x="104" y="104" width="816" height="816" rx="181" fill="none" stroke="#6B4320" stroke-opacity="0.35" stroke-width="8"/>
<g transform="translate(0,70)">{vu(512, 600, 255, 38)}</g>'''

def write(name, w, h, body):
    with open(os.path.join(out, name), "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n')

# App icon (also the favicon source).
write("icon.svg", 1024, 1024, icon_body(random.Random(1907)))

# Horizontal logo: icon + wordmark.
icon_group = f'<g transform="translate(0,0) scale(0.390625)">{icon_body(random.Random(1907))}</g>'
write("logo.svg", 1040, 400, f'''{icon_group}
<text x="410" y="258" font-family="Georgia, 'New York', 'Times New Roman', serif" font-size="190" font-weight="700" fill="{INK}" letter-spacing="2">Plug</text>''')

# Social / web banner 1200x630 on a full pine board.
rng = random.Random(42)
write("og-image.svg", 1200, 630, f'''<defs>
  <linearGradient id="board" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{PINE_LIGHT}"/><stop offset="1" stop-color="{PINE_DARK}"/>
  </linearGradient>
</defs>
<rect width="1200" height="630" fill="url(#board)"/>
{grain_paths(rng, 0, 0, 1200, 630, spacing=(9, 20))}
{knot(1030, 120, 80)}
<rect x="6" y="6" width="1188" height="618" fill="none" stroke="#6B4320" stroke-opacity="0.35" stroke-width="12"/>
<g transform="translate(70,103) scale(0.41)">{icon_body(random.Random(1907))}</g>
<text x="520" y="300" font-family="Georgia, 'New York', 'Times New Roman', serif" font-size="150" font-weight="700" fill="{INK}">Plug</text>
<text font-family="Georgia, 'New York', 'Times New Roman', serif" font-size="38" fill="{INK}" fill-opacity="0.85"><tspan x="524" y="378">Audio Unit effects for</tspan><tspan x="524" y="428">everything your Mac plays</tspan></text>''')
print("ok")
