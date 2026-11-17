// Schneenacht – Fedorama, MIT
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float h11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
float n1(float x) { float i = floor(x), f = fract(x); return mix(h11(i), h11(i + 1.0), f * f * (3.0 - 2.0 * f)); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float mx = iMouseUV.x - 0.5;
    vec3 col = mix(vec3(0.12, 0.16, 0.30), vec3(0.02, 0.03, 0.09), smoothstep(-0.5, 0.5, uv.y));
    // moon glow
    col += vec3(0.6, 0.7, 1.0) * 0.25 * exp(-length(uv - vec2(-0.5, 0.3)) * 4.0);
    col = mix(col, vec3(0.9, 0.93, 1.0), smoothstep(0.052, 0.048, length(uv - vec2(-0.5, 0.3))));
    // hills + pine silhouettes
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float x = uv.x + mx * (0.02 + fi * 0.04) + fi * 3.7;
        float h = -0.18 - fi * 0.1 + 0.08 * n1(x * 2.0 + fi) ;
        float tx = fract(x * (9.0 + fi * 4.0)) - 0.5;
        float tid = floor(x * (9.0 + fi * 4.0));
        float th = 0.06 + 0.07 * h11(tid + fi * 9.0);
        float tree = step(0.4, h11(tid * 3.1 + fi)) * step(abs(tx) * (0.12 / (9.0 + fi * 4.0)) * 9.0, (h + th - uv.y) * 0.35) * step(h - 0.01, uv.y);
        vec3 lc = mix(vec3(0.55, 0.62, 0.8), vec3(0.85, 0.9, 1.0), fi / 2.0) * (0.5 + fi * 0.25);
        if (uv.y < h) col = lc;
        if (tree > 0.5 && uv.y >= h) col = mix(vec3(0.04, 0.06, 0.12), vec3(0.1, 0.13, 0.22), fi / 3.0 * 0.0) * (1.0 - fi * 0.2);
    }
    // snow layers
    for (int l = 0; l < 4; l++) {
        float fl = float(l);
        float sc = 5.0 + fl * 6.0;
        vec2 p = uv * sc;
        p.y += iTime * (0.6 + fl * 0.25);
        p.x += sin(p.y * 0.3 + fl + iTime * 0.5) * 0.6 + mx * (fl + 1.0) * 0.6;
        vec2 id = floor(p), f = fract(p) - 0.5;
        float n = h21(id + fl * 17.0);
        vec2 o = vec2(h21(id + 1.3), h21(id + 2.9)) - 0.5;
        float d = length(f - o * 0.7);
        float size = (0.04 + 0.06 * n) * (1.0 + (3.0 - fl) * 0.25);
        col += vec3(0.95, 0.97, 1.0) * smoothstep(size, size * 0.3, d) * step(0.35, n) * (0.5 + fl * 0.12);
    }
    fragColor = vec4(col, 1.0);
}
