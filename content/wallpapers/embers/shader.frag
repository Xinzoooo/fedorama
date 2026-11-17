// Glut & Funken – Fedorama, MIT
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; } return v; }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;
    vec3 col = mix(vec3(0.02, 0.005, 0.0), vec3(0.0, 0.0, 0.02), fragCoord.y / iResolution.y);
    // heat glow from below
    float fl = fbm(vec2(uv.x * 3.0, uv.y * 2.0 - t * 0.8));
    float glow = smoothstep(0.1, -0.6, uv.y + fl * 0.35);
    col += vec3(1.0, 0.25, 0.02) * glow * 0.55 * (1.0 + iAudio.x);
    col += vec3(1.0, 0.6, 0.1) * smoothstep(-0.25, -0.65, uv.y + fl * 0.3) * 0.5;
    // sparks rising in 3 layers
    for (int l = 0; l < 3; l++) {
        float fl2 = float(l);
        float sc = 9.0 + fl2 * 7.0;
        vec2 p = uv * sc;
        p.y -= t * (1.5 + fl2 * 0.8);
        p.x += sin(p.y * 0.4 + t + fl2) * 0.6 + (iMouseUV.x - 0.5) * (fl2 + 1.0);
        vec2 id = floor(p), f = fract(p) - 0.5;
        float n = h21(id + fl2 * 13.0);
        if (n > 0.66) {
            vec2 o = vec2(h21(id + 1.0), h21(id + 2.0)) - 0.5;
            float d = length(f - o * 0.6);
            float life = smoothstep(0.7, -0.2, uv.y + h21(id + 3.0) * 0.4);
            float br = 0.02 / max(d, 0.002) * life * (0.5 + 0.5 * sin(t * 6.0 + n * 50.0));
            col += vec3(1.0, 0.45, 0.1) * br * (1.0 - fl2 * 0.25);
        }
    }
    col = 1.0 - exp(-col * 1.3);
    fragColor = vec4(col, 1.0);
}
