// Platine – Linux Wallpaper Engine, MIT
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.y;
    uv += (iMouseUV - 0.5) * 0.05;
    float sc = 14.0;
    vec2 p = uv * sc;
    vec2 id = floor(p), f = fract(p);
    float n = h21(id);
    // each cell: a trace that is either horizontal, vertical or a corner
    float w = 0.06;
    float line = 0.0;
    float along = 0.0;
    if (n < 0.33) { line = smoothstep(w, w * 0.5, abs(f.y - 0.5)); along = f.x + id.x; }
    else if (n < 0.66) { line = smoothstep(w, w * 0.5, abs(f.x - 0.5)); along = f.y + id.y; }
    else {
        float d = abs(length(f - vec2(0.0, 0.0)) - 0.5);
        line = smoothstep(w, w * 0.5, d); along = atan(f.y, f.x) / 1.5708 + id.x + id.y;
    }
    float via = smoothstep(0.14, 0.1, length(f - 0.5)) * step(0.85, h21(id + 4.0));
    float viaRing = smoothstep(0.16, 0.13, length(f - 0.5)) - smoothstep(0.1, 0.07, length(f - 0.5));
    viaRing *= step(0.85, h21(id + 4.0));
    // pulses travelling along the traces
    float pulse = pow(fract(along * 0.08 - iTime * 0.25 + h21(floor(id / 6.0)) ), 12.0);
    vec3 base = vec3(0.01, 0.04, 0.05);
    vec3 trace = vec3(0.05, 0.25, 0.25);
    vec3 glow = mix(vec3(0.1, 1.0, 0.8), vec3(0.2, 0.6, 1.0), h21(floor(id / 4.0)));
    vec3 col = base + trace * line * 0.6 + trace * viaRing;
    col += glow * line * pulse * (2.0 + iAudio.x * 2.0);
    col += glow * via * (0.3 + 0.7 * pow(0.5 + 0.5 * sin(iTime * 2.0 + n * 30.0), 4.0));
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.6 + 0.4 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);
    fragColor = vec4(col, 1.0);
}
