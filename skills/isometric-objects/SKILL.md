---
name: isometric-objects
description: Draw polished isometric wireframe objects and seamless looping scenes as code (SVG, canvas, or WebGL). Use when asked for an isometric illustration, icon, hero visual, product render, or looping animation in the dark hairline "technical figure" style.
---

# Isometric Objects

You draw isometric objects by modeling them in 3D and projecting to 2D with code. You never eyeball angles. Every edge comes from a projected point, so everything lines up.

Style target: a technical figure. Near-black solids, hairline edges, nested insets, small mechanical details, one lit focal point. Quiet everywhere except the one place you want the eye to go.

## 1. Projection

Use true isometric. World axes: x goes right-down, y goes left-down, z goes up.

```js
const C = Math.cos(Math.PI / 6), S = 0.5;            // 30 degrees
const iso = (x, y, z, s = 1) => [(x - y) * C * s, ((x + y) * S - z) * s];
```

- Pick one unit (for example 1 unit = 8 px) and model in whole or half units.
- Center the object with a single translate on the root group. Do not offset individual parts.
- For pixel-art crispness use 2:1 dimetric instead (`C = 1, S = 0.5`). Do not mix the two.

## 2. Build from primitives

Write small helpers and compose them. Each returns SVG path strings for its visible faces.

- `box(x, y, z, w, d, h)`: three visible faces: top, left (+y side), right (+x side).
- `roundedBox(..., r)`: same, plus a second hairline on each vertical edge, offset by r, to read as a rounded corner.
- `inset(face, margin, depth)`: a recessed panel on a face: outer frame line, inner frame line, darker fill. Nest 2 or 3 for bezels (screen, drawer, port).
- `slots(face, n, gap)`: vents. Short parallel lines that run along one face axis.
- `cylinder(cx, cy, z, r, h)`: top ellipse, side band, bottom half ellipse. Ellipse ratio follows the projection (rx = r * C * 2^0.5, ry = rx / 3^0.5 on a top face).
- `helix(path3d, r, turns)`: coiled cables. Sample in 3D, project, draw as one polyline.
- `grid(face, cols, rows, keyFn)`: keyboards, solar panels, tiles, server bays.

A detail on a face is drawn in that face's plane: project its 3D corners. A vent on the right face slants with the right face.

## 3. Depth order

- Painter's algorithm. Sort solids by `x + y + z` of their far corner (larger draws later). Ties: draw the lower z first.
- Inside one solid: top, then left, then right, then details, then edge lines last.
- Tall or overlapping parts: split them into unit blocks before sorting.
- Wrap each face's details in a `clipPath` of that face. Details then cannot bleed onto a neighbor face. This is the main fix for "small parts overlap".
- Keep details at least 0.25 unit in from face edges.

## 4. Shading

Three tones per material, fixed light from the top-left:

| face  | dark theme (on #0f0f0f to #141414 page) | light theme (on #ececec page) |
|-------|------|------|
| top   | #1f1f1f | #ffffff |
| left  | #181818 | #f2f2f2 |
| right | #121212 | #e2e2e2 |
| stroke | rgba(255,255,255,0.18 to 0.32) | rgba(20,20,30,0.35 to 0.55) |
| silhouette stroke | rgba(255,255,255,0.45) | rgba(20,20,30,0.75) |

- Drive colors from CSS custom properties (`--iso-top`, `--iso-left`, `--iso-right`, `--iso-line`, `--iso-accent`) so one asset works in both themes.
- No gradients on solids. Gradients only for light: a screen glow, an LED halo, a soft contact shadow under the object.
- Contact shadow: one blurred ellipse or projected footprint at z = 0, 20 to 35 percent opacity.

## 5. Lines

- `vector-effect: non-scaling-stroke`, width 1 px at display size (0.75 for interior details).
- `stroke-linejoin: round; stroke-linecap: round`.
- Three line weights only: silhouette, edges, detail. Detail lines are dimmer, not thinner than 0.75.
- Use a hairline highlight (brighter, 1 px) on the top-front edge of key solids. That one line sells the material.

## 6. Composition

- Put the object on a plinth or base plate. A thin slab larger than the footprint, with a chamfer line and a couple of screws.
- One accent color, used on at most 5 percent of the pixels: a screen, an LED, a moving packet. Everything else is greyscale.
- Leave 15 to 25 percent padding. The object sits slightly above center.
- Optional figure frame: `Fig 2` top-left, a name like `DESK COMPUTER` top-right, a caption or live state bottom row. Monospace, uppercase, 0.12em tracking, 45 to 60 percent opacity.
- Detail density: three levels. Big forms, then insets, then micro details (screws, LEDs, vents, labels). Stop at three.

## 7. Motion

Everything moves as a function of one loop phase `p` in [0, 1). No accumulated state, no `Math.random()` at frame time.

```js
const TAU = Math.PI * 2;
const p = ((now - t0) / DURATION) % 1;
const wave = Math.sin(TAU * (p * k + offset));   // integer k only
const ease = t => t < .5 ? 4*t*t*t : 1 - (-2*t + 2) ** 3 / 2;
```

- Integer cycle counts (`k`) guarantee frame `p = 0` equals frame `p = 1`. Check it: render both and diff.
- Movement happens along iso axes. Things slide on x, y, or z, never in screen space.
- Prefer few large confident moves (lift, slide, assemble) over many small jitters. Hold for 15 to 30 percent of the loop so the eye can rest.
- Exploded views are the strongest move: parts separate along z with leader lines and labels, hold, then reassemble.
- Use seeded randomness (`mulberry32(seed)`) for layout, computed once.
- Expose `render(p)` so the same code drives live playback and frame-exact video capture.
- `prefers-reduced-motion: reduce`: render one well-composed still (usually `p` at the hold).
- Pause when off-screen (IntersectionObserver) and when the tab is hidden.

## 8. Output

- Default: one self-contained SVG or HTML file, no dependencies. `viewBox` set, no fixed width.
- Canvas2D when you draw more than ~1,500 shapes per frame. Same projection, same palette.
- WebGL only for light effects (glow, bloom, ignition) layered over the vector drawing.
- Keep site assets under 30 KB gzipped.

## 9. Process

1. Write down the object as a parts list with sizes in units. Sketch the footprint.
2. Model big forms with `box` / `cylinder`. Render. Check silhouette and proportions.
3. Add insets and bezels. Render.
4. Add micro details, one face at a time, clipped.
5. Add the focal light and the accent.
6. Add motion with `render(p)`. Verify the loop seam.
7. Screenshot at 1x and 2x, on dark and light. Fix any line that crosses a face it does not belong to.

## Checklist

- [ ] Every point comes from `iso()`. No hand-placed coordinates.
- [ ] Details clipped to their face, inset from edges.
- [ ] Three tones per material, one accent, glow only on the focal point.
- [ ] Hairlines stay 1 px at any size.
- [ ] Loop: frame 0 equals frame N. Integer cycles. Hold beats exist.
- [ ] Reduced motion gives a good still. Off-screen pauses.
- [ ] Works on dark and light backgrounds.

Credit: style and idea reverse-engineered from @wheresryan22's `/isometric-objects` demo on X (Oct 2026). This is an independent rewrite, not his file.
