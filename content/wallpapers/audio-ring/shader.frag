// Audio-Ring (Visualizer) – Linux Wallpaper Engine, MIT
// Reagiert auf Musik, wenn "Auf Musik reagieren" aktiv ist.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    float x = abs(a) / 3.14159265;                  // mirrored 0..1
    float idle = 0.15 + 0.1 * sin(iTime * 1.5 + x * 12.0);
    float s = max(lweSpectrum(x), idle * (1.0 - iAudio.w));
    float bars = 64.0;
    float seg = fract(a / 6.2831853 * bars);
    float barMask = smoothstep(0.0, 0.08, seg) * smoothstep(1.0, 0.92, seg);
    float base = 0.22 + iAudio.x * 0.03;
    float len = s * 0.22;
    float bar = step(base, r) * step(r, base + len) * barMask;
    vec3 c = mix(vec3(0.0, 0.9, 1.0), vec3(1.0, 0.2, 0.8), x);
    vec3 col = vec3(0.01, 0.0, 0.03) + vec3(0.05, 0.02, 0.1) * (1.0 - r);
    col += c * bar * 1.3;
    col += c * 0.5 * exp(-abs(r - base - len) * 40.0) * barMask * s;
    col += c * 0.35 * smoothstep(0.005, 0.0, abs(r - base + 0.015));
    // inner core
    col += vec3(0.6, 0.3, 1.0) * exp(-r * (10.0 - iAudio.x * 5.0)) * (0.4 + iAudio.x);
    // background rings
    col += vec3(0.2, 0.1, 0.4) * 0.15 * smoothstep(0.004, 0.0, abs(fract(r * 6.0 - iTime * 0.2) - 0.5) - 0.48);
    fragColor = vec4(col, 1.0);
}
