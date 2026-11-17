// Synthwave-Grid – Fedorama, MIT
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(float x) { float i = floor(x), f = fract(x); return mix(h21(vec2(i, 0.0)), h21(vec2(i + 1.0, 0.0)), f * f * (3.0 - 2.0 * f)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5);
    uv.x += m.x * 0.05;
    float hor = -0.05 + m.y * 0.03;
    float bass = iAudio.x;
    vec3 col;

    if (uv.y > hor) {
        float y = uv.y - hor;
        col = mix(vec3(0.95, 0.25, 0.55), vec3(0.06, 0.02, 0.18), smoothstep(0.0, 0.55, y));
        col = mix(col, vec3(0.02, 0.0, 0.06), smoothstep(0.35, 0.6, y));
        // stars
        float s = h21(floor(fragCoord / 2.0));
        col += step(0.998, s) * smoothstep(0.1, 0.4, y) * vec3(1.0);
        // sun
        vec2 sp = uv - vec2(0.0, hor + 0.2);
        float r = 0.24 * (1.0 + bass * 0.06);
        float d = length(sp);
        vec3 sun = mix(vec3(1.0, 0.85, 0.2), vec3(1.0, 0.15, 0.55), smoothstep(0.2, -0.2, sp.y));
        float stripes = step(0.0, sin((sp.y + iTime * 0.02) * 90.0) + (sp.y + 0.05) * 18.0);
        if (sp.y > 0.02) stripes = 1.0;
        col = mix(col, sun, smoothstep(r, r - 0.004, d) * stripes);
        col += vec3(1.0, 0.3, 0.6) * 0.35 * exp(-max(d - r, 0.0) * 8.0);
        // mountains
        float mx = uv.x * 3.0;
        float mh = 0.12 * abs(noise(mx * 1.5) - 0.3) + 0.08 * noise(mx * 4.0) * smoothstep(0.1, 0.9, abs(uv.x));
        mh *= smoothstep(0.05, 0.6, abs(uv.x)) * 1.8;
        if (y < mh) {
            col = mix(vec3(0.05, 0.0, 0.12), vec3(0.25, 0.0, 0.35), y / max(mh, 1e-3));
            float edge = smoothstep(0.004, 0.0, mh - y);
            col += edge * vec3(0.0, 0.9, 1.0) * 0.8;
        }
    } else {
        // perspective grid floor
        float y = hor - uv.y;
        float z = 0.35 / y;
        float x = uv.x * z;
        float zz = z + iTime * 1.6;
        vec2 g = abs(fract(vec2(x, zz)) - 0.5);
        float lw = 0.02 * z;
        float line = smoothstep(lw + 0.015 * z, lw, min(g.x, g.y) * 1.0) ;
        float fade = exp(-z * 0.12);
        col = mix(vec3(0.03, 0.0, 0.08), vec3(0.18, 0.0, 0.25), fade);
        vec3 lc = mix(vec3(1.0, 0.2, 0.8), vec3(0.2, 0.8, 1.0), 0.5 + 0.5 * sin(iTime * 0.3));
        col += line * lc * (fade * 1.5 + 0.1) * (1.0 + bass * 1.5);
        col += vec3(1.0, 0.3, 0.7) * 0.6 * exp(-y * 25.0);
    }
    col += vec3(1.0, 0.4, 0.8) * 0.25 * exp(-abs(uv.y - hor) * 50.0);
    // scanlines + vignette
    col *= 0.94 + 0.06 * sin(fragCoord.y * 3.14159);
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.6 + 0.4 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);
    fragColor = vec4(col, 1.0);
}
