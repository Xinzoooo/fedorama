// Regen am Fenster – Linux Wallpaper Engine, MIT
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
vec2 h22(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.xx + p3.yz) * p3.zy); }

// blurry night city seen through the glass; blur = 0 sharp .. 1 very soft
vec3 city(vec2 uv, float blur) {
    vec3 col = mix(vec3(0.02, 0.03, 0.07), vec3(0.10, 0.06, 0.12), smoothstep(-0.6, 0.6, uv.y));
    col += vec3(0.25, 0.12, 0.05) * exp(-abs(uv.y + 0.15) * 4.0) * 0.6;
    for (int layer = 0; layer < 3; layer++) {
        float sc = 6.0 + float(layer) * 5.0;
        vec2 g = uv * sc + vec2(float(layer) * 7.3, 0.0);
        vec2 id = floor(g), f = fract(g);
        for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(x, y);
            vec2 r = h22(id + o + float(layer) * 11.0);
            if (r.x < 0.62) continue;
            vec2 p = o + r - f;
            float size = (0.18 + 0.25 * r.y) * (0.6 + blur * 0.8);
            float d = length(p);
            float disc = smoothstep(size, size * (1.0 - 0.6 * blur) - 0.02, d);
            float rr = h21(id + o + 3.0);
            vec3 c = rr < 0.33 ? vec3(1.0, 0.55, 0.2) : (rr < 0.66 ? vec3(1.0, 0.2, 0.45) : vec3(0.25, 0.6, 1.0));
            float tw = 0.75 + 0.25 * sin(iTime * (0.5 + rr) + rr * 40.0);
            col += c * disc * 0.5 * tw * smoothstep(0.35, -0.45, uv.y + float(layer) * 0.08);
        }
    }
    return col;
}

// returns xy = refraction offset, z = drop mask
vec3 staticDrops(vec2 uv, float t) {
    vec2 g = uv * 22.0;
    vec2 id = floor(g);
    vec2 r = h22(id);
    vec2 p = fract(g) - 0.5 - (r - 0.5) * 0.7;
    float size = 0.06 + 0.16 * h21(id + 1.7) * step(0.35, r.y);
    float life = fract(t * 0.15 + r.x * 5.0);
    float fade = smoothstep(0.0, 0.05, life) * smoothstep(1.0, 0.6, life);
    float d = length(p);
    float m = smoothstep(size, size * 0.6, d) * fade;
    return vec3(p / size * m, m);
}

vec3 slidingDrops(vec2 uv, float t, float scale) {
    vec2 a = vec2(6.0, 1.0);
    vec2 g = uv * scale * a;
    float colId = floor(g.x);
    float sp = 0.35 + h21(vec2(colId, 4.0)) * 0.5;
    g.y += t * sp + h21(vec2(colId, 1.0)) * 10.0;
    vec2 id = floor(g);
    vec2 st = fract(g) - vec2(0.5, 0.0);
    float n = h21(id);
    float x = (n - 0.5) * 0.6;
    float wig = sin(st.y * 9.0 + sin(st.y * 7.0 + n * 6.0)) * 0.12;
    x += wig * (0.5 - abs(x));
    float y = 1.0 - fract(t * sp * 0.7 + n * 3.0);      // drop moves downward inside the cell
    y = smoothstep(0.0, 1.0, y) * 0.8 + 0.1;
    vec2 p = (st - vec2(x, y)) / a;
    float d = length(p * vec2(1.0, 0.75));
    float drop = smoothstep(0.06, 0.04, d);
    // trail of tiny droplets above the drop
    vec2 tp = (st - vec2(x, fract(st.y * 8.0) / 8.0 - 0.0)) / a;
    tp.y = (fract(st.y * 8.0) - 0.5) / 8.0;
    float td = length(tp);
    float trail = smoothstep(0.018, 0.008, td) * smoothstep(y, y + 0.4, st.y) * smoothstep(1.0, y + 0.1, st.y);
    float alive = step(0.25, n);
    float m = (drop + trail * 0.8) * alive;
    vec2 off = drop > 0.0 ? p / 0.06 : tp / 0.018;
    return vec3(off * m, m);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;
    vec3 s = staticDrops(uv, t);
    vec3 d1 = slidingDrops(uv, t, 2.0);
    vec3 d2 = slidingDrops(uv * 1.7 + 3.1, t * 1.1, 2.0);
    float mask = clamp(s.z + d1.z + d2.z, 0.0, 1.0);
    vec2 off = s.xy + d1.xy + d2.xy;

    vec2 par = (iMouseUV - 0.5) * 0.04;
    // fogged glass: very blurry, drops: sharper & refracted (inverted view)
    vec3 bgFog = city(uv + par, 1.0) * 0.55;
    vec3 bgDrop = city(uv + par - off * 0.15, 0.15) * 1.5 + vec3(0.03, 0.035, 0.05);
    vec3 col = mix(bgFog, bgDrop, mask);
    // highlight on drop edge
    col += vec3(0.6, 0.7, 0.9) * 0.35 * mask * smoothstep(0.3, 1.0, length(off)) * step(0.0, off.y);
    col += vec3(0.8, 0.85, 1.0) * 0.02;                         // glass sheen
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.55 + 0.45 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);
    fragColor = vec4(col, 1.0);
}
