// Galaxie – Fedorama, MIT
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; for (int i = 0; i < 6; i++) { v += a * noise(p); p *= 2.02; a *= 0.5; } return v; }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv += (iMouseUV - 0.5) * 0.08;
    // tilt the disc
    vec2 p = uv * mat2(0.94, -0.34, 0.34, 0.94);
    p.y *= 1.9;
    float r = length(p);
    float a = atan(p.y, p.x);
    float rot = iTime * 0.03;
    // two logarithmic spiral arms
    float arms = 2.0;
    float sp = a * arms - log(r + 1e-3) * 4.2 + rot * 6.0;
    float armMask = pow(0.5 + 0.5 * cos(sp), 3.0);
    vec2 q = vec2(cos(a + rot), sin(a + rot)) * r;
    float dust = fbm(q * 7.0 + 3.0);
    float density = armMask * exp(-r * 2.6) * (0.4 + dust);
    float core = exp(-r * 14.0);
    vec3 col = vec3(0.005, 0.005, 0.02);
    col += vec3(0.35, 0.45, 1.0) * density * 1.6;
    col += vec3(1.0, 0.45, 0.75) * pow(armMask, 4.0) * exp(-r * 3.0) * fbm(q * 18.0) * 0.9;
    col -= vec3(0.15, 0.12, 0.1) * smoothstep(0.55, 0.75, fbm(q * 12.0 + 7.0)) * exp(-r * 3.0) * armMask;
    col += vec3(1.0, 0.85, 0.6) * (core * 2.2 + exp(-r * 5.0) * 0.35);
    // stars in arms
    vec2 g = floor(fragCoord / 2.0);
    float s = h21(g);
    col += step(0.9975 - armMask * exp(-r * 2.0) * 0.02, s) * vec3(0.9, 0.95, 1.0) * (0.5 + 0.5 * sin(iTime * 3.0 + s * 90.0));
    col += step(0.9993, h21(g + 7.0)) * 0.7;
    col = max(col, 0.0);
    col = 1.0 - exp(-col * 1.4);
    fragColor = vec4(col, 1.0);
}
