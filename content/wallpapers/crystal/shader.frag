// Kristall – Linux Wallpaper Engine, MIT
vec2 h22(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.xx + p3.yz) * p3.zy); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    vec2 p = uv * 5.0;
    vec2 i = floor(p), f = fract(p);
    float d1 = 8.0, d2 = 8.0; vec2 cid = vec2(0.0);
    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
        vec2 o = vec2(x, y);
        vec2 r = h22(i + o);
        vec2 pt = o + 0.5 + 0.4 * sin(iTime * 0.3 + 6.2831 * r);
        float d = length(pt - f);
        if (d < d1) { d2 = d1; d1 = d; cid = i + o; } else if (d < d2) { d2 = d; }
    }
    float edge = d2 - d1;
    vec2 rc = h22(cid);
    vec3 base = 0.5 + 0.5 * cos(6.2831 * (rc.x * 0.3 + vec3(0.6, 0.7, 0.85) + iTime * 0.02));
    float shade = 0.3 + 0.7 * rc.y;
    float light = exp(-length(uv - m) * 2.0);
    vec3 col = base * shade * (0.15 + 0.35 * light);
    col += base * smoothstep(0.05, 0.0, edge) * (0.6 + light);
    col += vec3(1.0) * smoothstep(0.015, 0.0, edge) * 0.4 * light;
    col += base * 0.25 * (1.0 - smoothstep(0.0, 0.5, d1)) * rc.x;
    col *= 1.0 + iAudio.x * 0.5;
    fragColor = vec4(col, 1.0);
}
