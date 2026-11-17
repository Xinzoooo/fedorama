// Bokeh-Lichter – Fedorama, MIT
float h11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float aspect = iResolution.x / iResolution.y;
    vec3 col = mix(vec3(0.05, 0.02, 0.1), vec3(0.01, 0.03, 0.08), fragCoord.y / iResolution.y);
    vec2 m = (iMouseUV - 0.5);
    for (int i = 0; i < 48; i++) {
        float fi = float(i);
        float depth = 0.3 + h11(fi * 3.7) * 0.7;
        float t = iTime * (0.015 + 0.02 * h11(fi)) ;
        vec2 p = vec2(h11(fi * 1.3) * aspect * 1.4 - aspect * 0.7 + sin(t * 3.0 + fi) * 0.2,
                      fract(h11(fi * 7.9) + t) * 1.4 - 0.7);
        p += m * 0.1 * depth;
        float size = (0.03 + 0.09 * h11(fi * 2.1)) * (1.4 - depth);
        float d = length(uv - p);
        float blur = 0.02 + (1.0 - depth) * 0.05;
        float disc = smoothstep(size, size - blur, d);
        float ringE = smoothstep(size, size - 0.01, d) - smoothstep(size - 0.01, size - 0.03, d);
        vec3 c = 0.5 + 0.5 * cos(6.28 * (h11(fi * 5.1) * 0.35 + vec3(0.55, 0.75, 0.95)));
        col += c * (disc * 0.32 + ringE * 0.12) * (0.6 + 0.4 * sin(iTime + fi));
    }
    col += iAudio.x * vec3(0.05, 0.02, 0.08);
    col = 1.0 - exp(-col * 1.5);
    fragColor = vec4(col, 1.0);
}
