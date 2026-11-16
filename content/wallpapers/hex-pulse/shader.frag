// Hexagon-Puls – Linux Wallpaper Engine, MIT
vec4 hexCoords(vec2 uv) {
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    vec2 id = uv - gv;
    float x = atan(gv.x, gv.y);
    vec2 p = abs(gv);
    float y = 0.5 - max(dot(p, normalize(r)), p.x);
    return vec4(x, y, id);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 m = (iMouseUV - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    vec4 h = hexCoords(uv * 9.0);
    vec2 cid = h.zw / 9.0;
    float d = length(cid - m);
    float wave = sin(length(cid) * 9.0 - iTime * 2.0) * 0.5 + 0.5;
    float pulse = wave * 0.6 + exp(-d * 6.0) * 1.2 + iAudio.x * 0.8 * (0.5 + 0.5 * sin(h.z * 3.0 + h.w));
    float edge = smoothstep(0.06, 0.0, h.y);
    float fill = smoothstep(0.0, 0.25, h.y);
    vec3 c1 = vec3(0.0, 0.9, 1.0), c2 = vec3(0.8, 0.1, 1.0);
    vec3 lc = mix(c1, c2, 0.5 + 0.5 * sin(cid.x * 2.0 + iTime * 0.3));
    vec3 col = vec3(0.01, 0.01, 0.03);
    col += lc * edge * (0.25 + pulse * 0.9);
    col += lc * fill * pulse * 0.12;
    col *= 1.0 - 0.5 * length(uv);
    fragColor = vec4(col, 1.0);
}
