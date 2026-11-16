// Matrix-Regen – Linux Wallpaper Engine, MIT
float h11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }

// procedural 5x7 glyph: random bit pattern, mirrored a bit to look like characters
float glyph(vec2 uv, float seed) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
    vec2 g = floor(uv * vec2(5.0, 7.0));
    vec2 cell = fract(uv * vec2(5.0, 7.0));
    float gx = g.x > 2.0 ? 4.0 - g.x : g.x;          // symmetry
    float on = step(0.5, h21(vec2(gx + seed * 13.0, g.y + seed * 7.0)));
    if (g.x == 2.0) on = step(0.35, h21(vec2(seed, g.y)));
    float px = smoothstep(0.5, 0.35, max(abs(cell.x - 0.5), abs(cell.y - 0.5)));
    return on * px;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float cellH = iResolution.y / 42.0;
    vec2 cs = vec2(cellH * 0.62, cellH);
    vec2 id = floor(fragCoord / cs);
    vec2 f = fract(fragCoord / cs);

    float col = id.x;
    float speed = 4.0 + h11(col * 3.1) * 10.0;
    float len = 8.0 + h11(col * 7.7) * 24.0;
    float rows = iResolution.y / cs.y;
    float head = mod(iTime * speed + h11(col) * 200.0, rows + len);
    float y = rows - id.y;                    // top -> bottom
    float d = head - y;
    float trail = (d >= 0.0 && d < len) ? 1.0 - d / len : 0.0;

    // second, dimmer stream in same column
    float head2 = mod(iTime * speed * 0.63 + h11(col * 1.9) * 400.0, rows + len * 1.6);
    float d2 = head2 - y;
    float trail2 = (d2 >= 0.0 && d2 < len * 1.6) ? (1.0 - d2 / (len * 1.6)) * 0.45 : 0.0;
    float b = max(trail, trail2);

    float change = floor(iTime * (2.0 + h21(id) * 6.0) + h21(id * 1.3) * 10.0);
    float seed = h21(id + change * 0.37);
    float gl = glyph((f - vec2(0.1, 0.08)) / vec2(0.8, 0.84), seed);

    vec3 green = vec3(0.1, 1.0, 0.35);
    vec3 c = green * gl * pow(b, 1.6) * 1.2;
    c += vec3(0.75, 1.0, 0.85) * gl * smoothstep(0.92, 1.0, b) * 1.3;   // bright head
    c += green * 0.03 * b;                                           // glow
    // mouse spotlight
    vec2 mp = iMouseUV * iResolution.xy;
    c *= 1.0 + 0.8 * exp(-length(fragCoord - mp) / (iResolution.y * 0.15));
    c += vec3(0.0, 0.02, 0.01);
    fragColor = vec4(c, 1.0);
}
