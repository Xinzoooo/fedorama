// Lava – Linux Wallpaper Engine, MIT
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float aspect = iResolution.x / iResolution.y;
    float t = iTime * 0.25;
    float field = 0.0;
    for (int i = 0; i < 11; i++) {
        float fi = float(i);
        float x = (fract(sin(fi * 12.9898) * 43758.5) - 0.5) * aspect * 0.9;
        x += 0.12 * sin(t * (0.7 + fi * 0.13) + fi);
        float y = sin(t * (0.35 + fract(fi * 0.37) * 0.5) + fi * 1.7) * 0.55;
        float r = 0.055 + 0.05 * fract(sin(fi * 78.233) * 1234.5);
        r *= 1.0 + iAudio.x * 0.25;
        vec2 p = uv - vec2(x, y);
        field += r * r / dot(p, p);
    }
    // cursor blob
    vec2 mp = (iMouseUV - 0.5) * vec2(aspect, 1.0);
    field += 0.006 / dot(uv - mp, uv - mp);
    // floor and ceiling pools
    field += 0.004 / pow(max(0.56 + uv.y, 0.02), 2.0) + 0.003 / pow(max(0.56 - uv.y, 0.02), 2.0);

    vec3 bg = mix(vec3(0.06, 0.0, 0.08), vec3(0.18, 0.02, 0.10), smoothstep(-0.5, 0.5, uv.y));
    float edge = smoothstep(0.95, 1.05, field);
    vec3 lava = mix(vec3(1.0, 0.25, 0.05), vec3(1.0, 0.8, 0.2), smoothstep(1.0, 3.5, field));
    lava = mix(lava, vec3(0.9, 0.05, 0.25), smoothstep(0.4, -0.5, uv.y) * 0.5);
    vec3 col = bg + vec3(1.0, 0.3, 0.1) * 0.25 * smoothstep(0.3, 1.0, field);
    col = mix(col, lava, edge);
    // rim light
    col += vec3(1.0, 0.6, 0.3) * 0.4 * smoothstep(1.0, 1.08, field) * smoothstep(1.4, 1.08, field);
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);
    fragColor = vec4(col, 1.0);
}
