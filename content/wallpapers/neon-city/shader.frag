// Neon-Stadt – Fedorama, MIT
float h11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }

// one row of buildings. returns rgb + coverage in a
vec4 skyline(vec2 uv, float layer, float t) {
    float w = 0.06 + layer * 0.03;
    float x = uv.x / w;
    float id = floor(x);
    float fx = fract(x);
    float h = 0.12 + h11(id * 1.7 + layer * 31.0) * (0.35 - layer * 0.08);
    if (h11(id + layer * 9.0) > 0.8) h += 0.15;               // occasional tower
    float base = -0.5 + layer * 0.12;
    float top = base + h;
    float gap = step(0.06, fx) * step(fx, 0.94);
    if (uv.y > top || gap < 0.5) return vec4(0.0);
    vec3 c = mix(vec3(0.03, 0.02, 0.08), vec3(0.09, 0.05, 0.16), layer / 3.0);
    // windows
    vec2 wg = vec2(fx * (5.0 + layer * 2.0), (uv.y - base) * (60.0 - layer * 10.0));
    vec2 wid = floor(wg);
    vec2 wf = fract(wg);
    float lit = step(0.55, h21(wid + id * 17.0 + layer * 3.0 + floor(t * 0.1 + h21(wid + id) * 4.0) * 0.0));
    float flick = step(0.02, fract(h21(wid * 1.3 + id) * 13.0 + t * 0.05 * h21(wid)));
    float win = step(0.25, wf.x) * step(wf.x, 0.75) * step(0.3, wf.y) * step(wf.y, 0.75) * lit * flick;
    vec3 wc = mix(vec3(1.0, 0.75, 0.4), vec3(0.4, 0.9, 1.0), step(0.7, h21(wid + id)));
    c += win * wc * (0.6 - layer * 0.12);
    // neon sign
    float signId = h11(id * 3.3 + layer);
    if (signId > 0.72 && layer > 0.5) {
        float sy = top - 0.05 - signId * 0.08;
        float sgn = smoothstep(0.012, 0.0, abs(uv.y - sy)) * step(0.2, fx) * step(fx, 0.8);
        vec3 nc = signId > 0.86 ? vec3(1.0, 0.1, 0.6) : vec3(0.1, 0.9, 1.0);
        c += nc * sgn * (0.8 + 0.2 * sin(t * 7.0 + id)) * 1.5;
    }
    // roof light
    c += vec3(1.0, 0.1, 0.2) * smoothstep(0.004, 0.0, length(vec2((fx - 0.5) * w, uv.y - top - 0.004))) * step(0.5, sin(t * 3.0 + id));
    return vec4(c, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5);
    float t = iTime;
    vec3 col = mix(vec3(0.55, 0.1, 0.45), vec3(0.04, 0.02, 0.12), smoothstep(-0.35, 0.45, uv.y));
    col += vec3(0.2, 0.05, 0.3) * exp(-abs(uv.y + 0.2) * 3.0);
    // moon
    vec2 mp = uv - vec2(0.45, 0.28);
    col += vec3(1.0, 0.8, 0.9) * smoothstep(0.075, 0.07, length(mp)) * 0.9;
    col += vec3(1.0, 0.4, 0.7) * 0.2 * exp(-length(mp) * 6.0);
    col += step(0.998, h21(floor(fragCoord / 2.0))) * smoothstep(0.0, 0.3, uv.y) * 0.8;

    for (int i = 0; i < 4; i++) {
        float l = float(i);
        vec2 p = uv;
        p.x += m.x * (0.02 + l * 0.03) + t * 0.004 * (l + 1.0);
        vec4 b = skyline(p, l, t);
        float haze = 1.0 - l * 0.2;
        col = mix(col, b.rgb + vec3(0.25, 0.05, 0.3) * 0.25 * (1.0 - haze), b.a);
        col += vec3(0.6, 0.15, 0.6) * 0.04 * exp(-abs(uv.y + 0.5 - l * 0.12) * 20.0);
    }
    // street with moving car lights
    float road = smoothstep(-0.44, -0.46, uv.y);
    if (uv.y < -0.44) {
        float lane = step(-0.47, uv.y);
        float cx = fract(uv.x * 1.5 + t * (lane > 0.5 ? 0.15 : -0.2));
        float car = smoothstep(0.02, 0.0, abs(cx - 0.5) * 0.3) * smoothstep(0.006, 0.0, abs(uv.y - (lane > 0.5 ? -0.455 : -0.48)));
        col = mix(col, vec3(0.02, 0.01, 0.04), road * 0.8);
        col += car * (lane > 0.5 ? vec3(1.0, 0.2, 0.1) : vec3(1.0, 0.95, 0.8)) * 2.0;
        col += vec3(0.5, 0.1, 0.4) * 0.15 * smoothstep(-0.6, -0.44, uv.y);
    }
    col += iAudio.x * vec3(0.3, 0.05, 0.3) * 0.3;
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.65 + 0.35 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);
    fragColor = vec4(col, 1.0);
}
