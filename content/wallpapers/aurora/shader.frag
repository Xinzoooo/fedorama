// Nordlicht – Fedorama, MIT
float h21(vec2 p) { p = fract(p * vec2(233.34, 851.73)); p += dot(p, p + 23.45); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; mat2 r = mat2(0.8, 0.6, -0.6, 0.8); for (int i = 0; i < 5; i++) { v += a * noise(p); p = r * p * 2.0; a *= 0.5; } return v; }

vec3 aurora(vec2 uv, float t) {
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 24; i++) {
        float fi = float(i);
        float depth = 1.0 + fi * 0.06;
        vec2 p = uv * depth;
        float wave = fbm(vec2(p.x * 1.2 + t * 0.05 + fi * 0.03, t * 0.03)) * 0.6;
        float curtain = p.y - 0.02 - wave + fi * 0.012;
        float band = exp(-max(curtain, 0.0) * 5.0) * smoothstep(-0.03, 0.04, curtain);
        float rays = 0.5 + 0.5 * fbm(vec2(p.x * 14.0 + t * 0.2, fi));
        vec3 c = mix(vec3(0.1, 1.0, 0.55), vec3(0.6, 0.25, 1.0), smoothstep(0.0, 1.0, fi / 24.0 + curtain * 2.0));
        acc += c * band * rays * (1.0 - fi / 26.0) * 0.22;
    }
    return acc;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv += (iMouseUV - 0.5) * vec2(0.05, 0.02);
    float t = iTime;
    vec3 col = mix(vec3(0.01, 0.02, 0.05), vec3(0.02, 0.07, 0.12), smoothstep(0.5, -0.4, uv.y));
    // stars
    vec2 sg = floor(fragCoord / 2.5);
    float s = h21(sg);
    col += step(0.9975, s) * (0.5 + 0.5 * sin(t * 2.0 + s * 100.0)) * vec3(0.8, 0.9, 1.0);

    float horizon = -0.22;
    if (uv.y > horizon) {
        col += aurora(uv, t);
    } else {
        // lake reflection
        vec2 ruv = vec2(uv.x + 0.004 * sin(uv.y * 160.0 + t * 2.0), 2.0 * horizon - uv.y);
        col = mix(col, aurora(ruv, t) * 0.5 + vec3(0.01, 0.03, 0.05), 0.85);
    }
    // mountains
    float x = uv.x;
    float m1 = horizon + 0.10 + 0.07 * fbm(vec2(x * 2.5, 3.0)) - 0.02 * abs(sin(x * 3.0));
    float shape = smoothstep(0.003, -0.003, uv.y - m1) * step(horizon, uv.y);
    col = mix(col, vec3(0.01, 0.02, 0.035) + vec3(0.02, 0.06, 0.05) * smoothstep(m1 - 0.12, m1, uv.y), shape);
    // reflection of mountains
    float rshape = smoothstep(0.003, -0.003, (2.0 * horizon - uv.y) - m1) * step(uv.y, horizon);
    col = mix(col, vec3(0.01, 0.02, 0.03), rshape * 0.9);
    col += vec3(0.1, 0.4, 0.3) * 0.05 * exp(-abs(uv.y - horizon) * 60.0);
    fragColor = vec4(col, 1.0);
}
