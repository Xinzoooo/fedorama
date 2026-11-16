// Nebel – Linux Wallpaper Engine, MIT
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; mat2 r = mat2(0.8, 0.6, -0.6, 0.8); for (int i = 0; i < 6; i++) { v += a * noise(p); p = r * p * 2.0; a *= 0.5; } return v; }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv += (iMouseUV - 0.5) * 0.06;
    float t = iTime * 0.02;
    vec2 q = vec2(fbm(uv * 2.0 + t), fbm(uv * 2.0 + vec2(5.2, 1.3) - t));
    vec2 r = vec2(fbm(uv * 2.0 + 4.0 * q + vec2(1.7, 9.2) + t * 2.0), fbm(uv * 2.0 + 4.0 * q + vec2(8.3, 2.8)));
    float f = fbm(uv * 2.0 + 4.0 * r);
    vec3 col = mix(vec3(0.05, 0.02, 0.15), vec3(0.6, 0.1, 0.5), clamp(f * f * 2.0, 0.0, 1.0));
    col = mix(col, vec3(0.1, 0.5, 0.9), clamp(length(q) * 0.6, 0.0, 1.0) * 0.6);
    col = mix(col, vec3(1.0, 0.7, 0.4), clamp(r.x * r.x * 0.8, 0.0, 1.0) * 0.5);
    col *= f * 1.5;
    col += pow(f, 6.0) * vec3(1.0, 0.8, 0.9) * 0.8;
    vec2 g = floor(fragCoord / 2.0);
    float s = h21(g);
    col += step(0.997, s) * (0.6 + 0.4 * sin(iTime * 2.0 + s * 70.0)) * vec3(0.9, 0.95, 1.0);
    col = 1.0 - exp(-col * 1.6);
    fragColor = vec4(col, 1.0);
}
