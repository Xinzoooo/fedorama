// Hyper-Tunnel – Fedorama, MIT
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv -= (iMouseUV - 0.5) * 0.25;
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    float z = 0.35 / max(r, 1e-3) + iTime * 1.2 * (1.0 + iAudio.x * 0.8);
    float u = a / 6.2831853 * 12.0 + iTime * 0.1;
    vec2 g = abs(fract(vec2(u, z)) - 0.5);
    float ring = smoothstep(0.06, 0.0, g.y);
    float rib = smoothstep(0.05, 0.0, g.x);
    vec3 c1 = vec3(0.1, 0.8, 1.0), c2 = vec3(1.0, 0.15, 0.7);
    vec3 lc = mix(c1, c2, 0.5 + 0.5 * sin(z * 0.5));
    float fog = smoothstep(0.0, 0.6, r);
    vec3 col = vec3(0.01, 0.0, 0.03);
    col += lc * (ring * 1.2 + rib * 0.5) * fog;
    col += lc * 0.12 * (1.0 - fog) ;
    col += vec3(1.0, 0.8, 1.0) * exp(-r * 18.0) * 0.6;
    col *= 0.85 + 0.15 * sin(z * 6.0);
    fragColor = vec4(col, 1.0);
}
