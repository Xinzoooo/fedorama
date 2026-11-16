// Audio-Balken (Visualizer) – Linux Wallpaper Engine, MIT
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 q = fragCoord / iResolution.xy;
    float n = 48.0;
    float id = floor(q.x * n);
    float f = fract(q.x * n);
    float x = (id + 0.5) / n;
    float idle = 0.08 + 0.06 * sin(iTime * 2.0 + id * 0.5);
    float h = max(lweSpectrum(abs(x - 0.5) * 2.0), idle * (1.0 - iAudio.w)) * 0.55;
    float base = 0.32;
    float y = q.y - base;
    vec3 c = mix(vec3(0.1, 0.9, 1.0), vec3(1.0, 0.15, 0.7), smoothstep(0.0, 0.5, y));
    float gap = smoothstep(0.08, 0.15, f) * smoothstep(0.92, 0.85, f);
    vec3 col = mix(vec3(0.02, 0.0, 0.06), vec3(0.08, 0.02, 0.15), q.y);
    float bar = step(0.0, y) * step(y, h) * gap;
    col += c * bar * (0.7 + 0.5 * y / max(h, 0.01));
    // reflection
    float ry = -y;
    float refl = step(0.0, ry) * step(ry, h * 0.6) * gap;
    col += mix(vec3(0.1, 0.9, 1.0), vec3(1.0, 0.15, 0.7), 0.2) * refl * 0.25 * (1.0 - ry / max(h * 0.6, 0.01));
    col += vec3(0.6, 0.2, 1.0) * 0.4 * exp(-abs(y) * 80.0);
    // peak caps
    col += c * smoothstep(0.006, 0.0, abs(y - h - 0.01)) * gap;
    fragColor = vec4(col, 1.0);
}
