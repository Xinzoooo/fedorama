// Plasma-Fluss – Fedorama, MIT
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime * 0.35;
    vec2 p = uv * 2.2;
    for (int i = 1; i < 6; i++) {
        float fi = float(i);
        p += vec2(0.55 / fi * sin(fi * p.y + t + 0.3 * fi) + 0.8,
                  0.45 / fi * sin(fi * p.x + t * 1.3 + 0.3 * fi) - 0.6);
    }
    float v = 0.5 + 0.5 * sin(p.x + p.y);
    float w = 0.5 + 0.5 * cos(p.x * 0.7 - p.y * 1.2 + t);
    vec3 a = vec3(0.10, 0.05, 0.35), b = vec3(0.0, 0.85, 0.95), c = vec3(0.95, 0.15, 0.75);
    vec3 col = mix(a, b, smoothstep(0.2, 0.9, v));
    col = mix(col, c, smoothstep(0.5, 1.0, w) * 0.7);
    col *= 0.55 + 0.45 * smoothstep(0.0, 1.0, v * w + 0.3);
    col += vec3(0.6, 0.4, 1.0) * 0.25 * exp(-length(uv - m) * 4.0);
    col *= 1.0 + iAudio.x * 0.4;
    fragColor = vec4(col, 1.0);
}
