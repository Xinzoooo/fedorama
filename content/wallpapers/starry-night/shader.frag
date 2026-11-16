// Sternenhimmel – Linux Wallpaper Engine, MIT
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }

vec3 starLayer(vec2 uv, float scale, float seed) {
    vec2 g = uv * scale;
    vec2 id = floor(g), f = fract(g) - 0.5;
    vec3 col = vec3(0.0);
    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
        vec2 o = vec2(x, y);
        float n = h21(id + o + seed);
        if (n < 0.55) continue;
        vec2 p = o + vec2(h21(id + o + seed + 7.1), h21(id + o + seed + 3.7)) - 0.5;
        float d = length(f - p);
        float size = fract(n * 37.0);
        float tw = 0.6 + 0.4 * sin(iTime * (1.0 + size * 3.0) + n * 60.0);
        float s = 0.012 * (0.4 + size) / d;
        s *= smoothstep(0.6, 0.15, d);
        vec3 tint = mix(vec3(1.0, 0.75, 0.6), vec3(0.6, 0.8, 1.0), fract(n * 91.0));
        col += s * s * tw * tint;
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5) * 0.06;
    float hgt = fragCoord.y / iResolution.y;

    vec3 col = mix(vec3(0.02, 0.03, 0.09), vec3(0.08, 0.06, 0.20), smoothstep(0.9, 0.0, hgt));
    col += vec3(0.25, 0.12, 0.25) * pow(1.0 - hgt, 4.0) * 0.6;

    // milky way band
    vec2 r = uv + m * 0.5;
    float band = r.y - r.x * 0.35 - 0.05;
    float mw = exp(-band * band * 18.0) * fbm(r * 3.0 + vec2(iTime * 0.005, 0.0));
    col += mw * vec3(0.45, 0.4, 0.7) * 0.9;
    col += exp(-band * band * 60.0) * fbm(r * 9.0) * vec3(0.5, 0.45, 0.6) * 0.5;

    col += starLayer(uv + m * 0.3, 18.0, 1.0);
    col += starLayer(uv + m * 0.6, 34.0, 5.0) * 0.8;
    col += starLayer(uv + m * 1.0, 60.0, 9.0) * 0.6 * (0.6 + mw);

    // shooting star every few seconds
    float t = iTime * 0.23;
    float k = floor(t);
    float ph = fract(t);
    vec2 s0 = vec2(h21(vec2(k, 1.0)) * 1.6 - 0.5, 0.45 - h21(vec2(k, 2.0)) * 0.25);
    vec2 dir = normalize(vec2(-1.0, -0.45));
    vec2 head = s0 + dir * ph * 1.4;
    vec2 rel = uv - head;
    float along = dot(rel, -dir), across = abs(dot(rel, vec2(-dir.y, dir.x)));
    float trail = smoothstep(0.25, 0.0, along) * step(0.0, along) * smoothstep(0.003, 0.0, across);
    col += trail * vec3(0.9, 0.95, 1.0) * smoothstep(0.0, 0.1, ph) * smoothstep(0.6, 0.3, ph) * step(0.5, h21(vec2(k, 9.0)));

    // hills silhouette
    float x = uv.x + m.x * 2.0;
    float hill = -0.32 + 0.06 * sin(x * 2.1 + 1.0) + 0.03 * sin(x * 5.3) + 0.04 * fbm(vec2(x * 3.0, 0.0));
    float hill2 = -0.40 + 0.05 * sin(x * 1.3 + 4.0) + 0.05 * fbm(vec2(x * 2.0 + 9.0, 1.0));
    col = mix(col, vec3(0.03, 0.03, 0.08), smoothstep(0.004, -0.004, uv.y - hill));
    col = mix(col, vec3(0.01, 0.01, 0.03), smoothstep(0.004, -0.004, uv.y - hill2));
    col += vec3(0.4, 0.2, 0.5) * 0.08 * exp(-abs(uv.y - hill) * 30.0);

    fragColor = vec4(col, 1.0);
}
