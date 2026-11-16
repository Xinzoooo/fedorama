// Warp – Linux Wallpaper Engine, MIT
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv -= (iMouseUV - 0.5) * 0.3;
    vec3 col = vec3(0.0, 0.0, 0.02);
    float speed = 0.4 + iAudio.x * 0.8;
    for (int l = 0; l < 4; l++) {
        float fl = float(l);
        float z = fract(iTime * speed * 0.25 + fl * 0.25);
        float scale = mix(18.0, 0.6, z);
        vec2 p = uv * scale;
        vec2 id = floor(p), f = fract(p) - 0.5;
        float n = h21(id + fl * 31.0);
        vec2 o = vec2(h21(id + 3.0), h21(id + 7.0)) - 0.5;
        vec2 d = f - o * 0.8;
        // streak along radial direction
        vec2 dir = normalize(uv + 1e-4);
        float along = dot(d, dir), across = dot(d, vec2(-dir.y, dir.x));
        float len = 0.02 + z * z * 0.6 * length(uv) * 3.0;
        float s = smoothstep(0.03, 0.0, abs(across)) * smoothstep(len, 0.0, abs(along));
        float fade = smoothstep(0.0, 0.3, z) * smoothstep(1.0, 0.85, z);
        vec3 tint = mix(vec3(0.6, 0.8, 1.0), vec3(1.0, 0.6, 0.9), n);
        col += tint * s * fade * step(0.6, n) * 1.5;
    }
    col += vec3(0.2, 0.3, 0.8) * 0.15 * exp(-length(uv) * 3.0);
    fragColor = vec4(col, 1.0);
}
