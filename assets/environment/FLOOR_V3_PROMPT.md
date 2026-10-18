# Floor texture atlas

Tool: built-in image_gen. Original team sprites were style references. Source: floor_tiles-v3.png. The game imports each floor into a native 32px tile with its dark planet palette.

ONE production pixel-art ground TEXTURE atlas, fully OPAQUE square, strict equal 2x2 quadrants, all artwork filling every quadrant edge to edge, NO margins, NO borders, NO frames, NO objects isolated on backgrounds. Each quadrant is a seamless repeating 32x32 logical-pixel ground texture, enlarged16x into a1024x1024 image. Use only low-contrast pixel clusters and a few sparse tiny cracks/grains, simple handmade pixel style matching the supplied original32px astronaut and aliens. Never polished realistic illustration. No lighting gradients, no antialiasing, no big rocks, no crystal objects, no grid, no text, no arena layouts.
Top-left MARS: dark dusty rusty soil; palette base#2b1829 with muted#351c2a,#3b202c,#46232d and small#532936 grain accents. Fine irregular dirt mottling with a few angular short fissures, rusty but sufficiently dark for red enemies to stand out.
Top-right NEPTUNE: dark blue frozen ground; base#18263b with#1c2d43,#20384b,#244356 and small#2c4e60. Slight icy grain and a few short thin frost seams, no bright snow or white patches.
Bottom-left JUPITER: dark plum/brown mineral crust; base#272031 with#312434,#3d2938,#4a303c and small#573b43. Subtle curved dusty bands mixed with small granular marks.
Bottom-right ALIEN NEXUS: dark violet alien stone; base#241d3b with#2c2246,#342950,#40315e and small#4c396c. A few tiny geometric mineral fissures and muted speckles.
Every quadrant must be visibly textured across the entire surface, but restrained enough to read enemy projectiles. No large repeated decorative motif. Keep each edge same base color as its opposite edge, seamless repeating. Transparent background is NOT wanted; fill all pixels of the whole image. References are palette/simple pixel-language only; do not include characters.
