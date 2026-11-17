// Wolkenhimmel – Fedorama, MIT
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; mat2 r = mat2(1.6, 1.2, -1.2, 1.6); for (int i = 0; i < 6; i++) { v += a * noise(p); p = r * p; a *= 0.5; } return v; }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.y;
    vec2 m = (iMouseUV - 0.5) * 0.1;
    float y = fragCoord.y / iResolution.y;
    vec3 sky = mix(vec3(0.55, 0.75, 0.98), vec3(0.18, 0.42, 0.85), y);
    vec2 sun = vec2(0.25 * iResolution.x / iResolution.y, 0.8);
    float sd = length(uv - sun);
    sky += vec3(1.0, 0.9, 0.7) * exp(-sd * 6.0) * 0.5;
    vec3 col = sky;
    for (int l = 0; l < 3; l++) {
        float fl = float(l);
        vec2 p = uv * (1.6 + fl * 0.8) + vec2(iTime * (0.012 + fl * 0.01), fl * 3.1) + m * (fl + 1.0);
        float d = fbm(p);
        float cover = smoothstep(0.48 - fl * 0.03, 0.75, d);
        float shade = fbm(p + vec2(0.04, 0.04));
        vec3 cc = mix(vec3(1.0, 0.98, 0.96), vec3(0.62, 0.68, 0.8), smoothstep(0.4, 0.8, shade) * 0.8);
        cc += vec3(1.0, 0.9, 0.7) * exp(-sd * 3.0) * 0.25;
        col = mix(col, cc, cover * (0.75 + fl * 0.1));
    }
    fragColor = vec4(col, 1.0);
}
