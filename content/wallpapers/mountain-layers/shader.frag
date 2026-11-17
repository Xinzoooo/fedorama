// Bergdämmerung – Fedorama, MIT
float h11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
float n1(float x) { float i = floor(x), f = fract(x); return mix(h11(i), h11(i + 1.0), f * f * (3.0 - 2.0 * f)); }
float ridge(float x, float s) { float v = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { v += a * n1(x * s + float(i) * 7.0); s *= 2.1; a *= 0.5; } return v; }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    float mx = iMouseUV.x - 0.5;
    vec3 top = vec3(0.12, 0.10, 0.30), bot = vec3(1.0, 0.55, 0.45);
    vec3 col = mix(bot, top, pow(uv.y, 0.8));
    vec2 sun = vec2(0.62, 0.66);
    float sd = length((uv - sun) * vec2(aspect, 1.0));
    col = mix(col, vec3(1.0, 0.9, 0.75), smoothstep(0.07, 0.065, sd));
    col += vec3(1.0, 0.6, 0.4) * exp(-sd * 5.0) * 0.4;
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float depth = fi / 5.0;
        float x = uv.x * aspect + mx * (0.05 + depth * 0.3) + iTime * 0.004 * (depth + 0.2) + fi * 13.0;
        float h = 0.55 - depth * 0.09 + (ridge(x, 1.2 + depth * 0.6) - 0.5) * (0.25 + depth * 0.05);
        vec3 lc = mix(vec3(0.75, 0.45, 0.55), vec3(0.06, 0.04, 0.12), depth);
        float haze = exp(-(h - uv.y) * 6.0) * (1.0 - depth) * 0.25;
        if (uv.y < h) col = lc + vec3(1.0, 0.6, 0.5) * haze;
    }
    // birds-free calm; tiny drifting mist
    col += vec3(1.0, 0.8, 0.8) * 0.04 * n1(uv.x * 6.0 + iTime * 0.1) * smoothstep(0.5, 0.2, uv.y);
    fragColor = vec4(col, 1.0);
}
