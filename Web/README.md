# Plug web pack

Everything needed to put Plug on the web. All artwork is original to Plug.

| File | Size | Use |
|---|---|---|
| `icon.svg` | vector | App icon, any size |
| `icon-1024.png`, `icon-512.png`, `icon-256.png` | square | App icon as PNG |
| `favicon.svg` | vector | Browser tab icon (modern browsers) |
| `favicon-32.png` | 32×32 | Browser tab icon (fallback) |
| `apple-touch-icon.png` | 180×180 | iPhone/iPad home-screen icon |
| `logo.svg`, `logo.png` | 1040×400 | Icon plus "Plug" wordmark, transparent background |
| `og-image.svg`, `og-image.png` | 1200×630 | Link preview for social posts and chats |
| `menubar-glyph.svg` | 20×18 | The menu bar VU meter; draws in the text colour (`currentColor`) |
| `plug.css` | | Brand colours as CSS variables, plus the manual's page style (light and dark) |
| `index.html` | | The Plug home page: download, a working master knob, what Plug does and how to install. Self-contained apart from Google Fonts and the images here |
| `manual.html` | | The user manual as a web page, built from `../MANUAL.md` |

## Colours

| Name | Hex |
|---|---|
| Pine, light | `#EBCB92` |
| Pine, dark | `#D4AA6C` |
| Grain | `#93612F` |
| Ink | `#4A2A12` |
| Meter red | `#C0301A` |
| Lamp green | `#21A83D` |
| Lamp red | `#D11F14` |
| Brass | `#EDCC80` |

## Page head snippet

```html
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="icon" href="favicon-32.png" sizes="32x32" type="image/png">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<meta property="og:image" content="https://YOUR-SITE/og-image.png">
```

Link previews need the full address of `og-image.png` on your site. `index.html` has the relative path; change it to the full address when you publish.

## Publishing the site

Upload the whole `Web/` folder to any static host. `index.html` is the home page and links to `manual.html`. Its Download buttons point to the latest GitHub release, so attach the DMG to a release and they will find it.

## Rebuilding the manual page

After editing `MANUAL.md`, from the repo root:

```
pandoc MANUAL.md -f gfm -t html5 -s --metadata pagetitle="Plug: user manual" -c plug.css -o Web/manual.html
```

That plain command leaves out the logo masthead and icon links that the shipped `manual.html` has. To keep them, pass the same head, before and after snippets (`-H`, `-B`, `-A`). Or edit `manual.html` directly.

The text in `logo.png` and `og-image.png` was rendered with a Linux serif. The SVGs ask for Georgia or New York, so they render a little differently on a Mac.
