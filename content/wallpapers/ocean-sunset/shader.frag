// Ozean bei Sonnenuntergang – Fedorama, MIT
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.1; a *= 0.5; } return v; }

vec3 sky(vec2 uv, vec2 sun) {
    float y = uv.y;
    vec3 c = mix(vec3(1.0, 0.55, 0.25), vec3(0.25, 0.2, 0.5), smoothstep(0.0, 0.45, y));
    c = mix(c, vec3(0.06, 0.07, 0.2), smoothstep(0.35, 0.7, y));
    float d = length(uv - sun);
    c += vec3(1.0, 0.6, 0.3) * exp(-d * 5.0) * 0.6;
    c = mix(c, vec3(1.0, 0.92, 0.7), smoothstep(0.06, 0.055, d));
    // clouds
    float cl = fbm(vec2(uv.x * 3.0 + iTime * 0.01, uv.y * 12.0));
    c = mix(c, mix(vec3(0.95, 0.45, 0.4), vec3(0.3, 0.15, 0.3), smoothstep(0.1, 0.4, y)), smoothstep(0.55, 0.8, cl) * smoothstep(0.05, 0.15, y) * 0.8);
    return c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5);
    uv.x += m.x * 0.04;
    float hor = -0.08 + m.y * 0.02;
    vec2 sun = vec2(0.1, hor + 0.09);
    vec3 col;
    if (uv.y > hor) {
        col = sky(uv - vec2(0.0, hor), sun - vec2(0.0, hor));
    } else {
        float y = hor - uv.y;
        float z = 0.25 / y;
        vec2 wp = vec2(uv.x * z, z + iTime * 0.6);
        float w1 = fbm(wp * vec2(0.6, 1.2));
        float w2 = fbm(wp * vec2(1.5, 3.0) + iTime * 0.2);
        float h = w1 * 0.7 + w2 * 0.3;
        vec2 n = vec2(dFdx(h), dFdy(h)) * 60.0;
        // reflection of sky with normal perturbation
        vec2 r = vec2(uv.x + n.x * 0.05, y * 0.8 + n.y * 0.04);
        col = sky(r, sun - vec2(0.0, hor)) * 0.55;
        col = mix(col, vec3(0.03, 0.05, 0.12), smoothstep(0.0, 0.35, y));
        // sun glitter path
        float path = exp(-abs(uv.x - sun.x) * (6.0 + y * 20.0));
        float glit = smoothstep(0.6, 0.9, w2 + 0.2 * noise(wp * 9.0));
        col += vec3(1.0, 0.75, 0.45) * path * glit * 1.6 * (1.0 - smoothstep(0.0, 0.4, y) * 0.6);
        col += vec3(1.0, 0.6, 0.35) * exp(-y * 40.0) * 0.3;
    }
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.7 + 0.3 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);
    fragColor = vec4(col, 1.0);
}
