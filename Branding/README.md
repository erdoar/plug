# Plug branding

Original artwork, drawn for Plug: a pale pine tile with a simple VU-meter glyph (dark brown scale and needle, red top end). No third-party assets or fonts are embedded.

| File | Use |
|---|---|
| `icon.svg` | App icon source, 1024×1024 on Apple's icon grid (824 pt tile, 185 pt corners, soft shadow). |
| `logo.svg` | Horizontal logo: icon plus "Plug" wordmark. |
| `og-image.svg` | 1200×630 social/web banner on a full pine board. |
| `png/` | Renders of the above, plus `favicon-32.png` and `apple-touch-icon.png` (180×180). |
| `../Bundle/AppIcon.iconset/` | The app icon at every macOS size; `scripts/bundle.sh` turns it into `AppIcon.icns`. |
| `make.py` | Generates the three SVGs (the wood grain is seeded, so it comes out the same each time). |

Colours: pine `#EBCB92` → `#D4AA6C`, grain `#93612F`, ink `#4A2A12`, red `#C0301A`.

The wordmark and banner text use the system serif (Georgia / New York); the PNGs here were rendered on Linux with its serif, so the letterforms differ slightly from a Mac render.

To regenerate: `python3 Branding/make.py Branding`, then render each SVG to PNG at its own size (any browser or `rsvg-convert` works) and resize `png/icon-1024.png` into the iconset sizes.
