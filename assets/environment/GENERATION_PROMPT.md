# Terrain atlas generation

Tool: built-in image_gen. Reference role: style only; original sprites unchanged.

Use case: stylized-concept, production pixel-art texture atlas for a top-down 2D Godot arena shooter.
Reference images are STYLE REFERENCES ONLY: small handmade low-resolution sprites, dark purple outlines, discrete compact clusters, restrained 4-6 tone ramps. Do not redraw or include the characters. Match their simple charming slightly rough pixel language, not polished high detail.
Create ONE square 1024x1024 PNG atlas, strict 4 rows x 4 columns of equal 256x256 cells, no gutters, no text, no labels, no lines between cells. Each cell is a game-ready texture/sprite. Exact coordinates mandatory:
Row 1 y0..255 MARS: dark muted rusty red/brown dusty ground, jagged ferruginous rocks, rust-red basalt.
Row 2 y256..511 NEPTUNE: dark muted deep blue glacial ground, chunky indigo stone with cyan ice caps and simple blue fissures. Fantastical ice-moon-like floating rocky region, not water surface.
Row 3 y512..767 JUPITER: dark muted umber/mauve mineral ground, charcoal and reddish-brown floating stone with restrained amber mineral seams. Jovian storm palette, no lava pools.
Row 4 y768..1023 ALIEN NEXUS: dark muted violet ground, deep purple angular alien stone with sparse lavender crystal flecks.
Within EACH row:
Column 1 x0..255: fully OPAQUE seamlessly repeatable flat ground tile filling entire cell. Quiet low-contrast soil texture, sparse tiny pebbles/cracks; no large rock, no craters, no border, no grid, no large motifs. Every edge same base color for seamless tiling. Keep ground much darker/lower contrast than rock sprites and characters.
Column 2 x256..511: ONE large solid chunky roughly square rock formation, centered, almost filling cell (about 236x236), with very small transparent margins. Continuous solid mass with irregular chipped edges, broad simple planar face and a couple of cracks, thick dark pixel outline, top-left highlights, subtle contact shadow at base. Viewed from above with a slight front face like the reference creatures.
Column 3 x512..767: ONE different compact nearly square pile of 3-4 stones, centered nearly filling cell, continuous solid footprint, transparent around silhouette, same style.
Column 4 x768..1023: ONE horizontal wall segment made from closely interlocked boulders, the stones continuously span the full cell width and central 192px height, transparent above and below. Left and right ends must join seamlessly to repeated copies. No bricks, crates, metal, buildings, plants, furniture or floor backing.
Genuine transparency outside rock silhouettes (except fully opaque ground cells). Crisp actual pixel art: draw on an implied 256x256 logical canvas upscaled exactly 4x with nearest-neighbor, mostly 1-2 logical pixel contour steps, no antialiasing, no blur, no smooth gradients, no photoreal texture or 3D render. Small palette, no glossy highlights, no UI. Keep forms very readable at 64x64 logical pixels per cell.
