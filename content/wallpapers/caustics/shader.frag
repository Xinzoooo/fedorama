// Unterwasser – Linux Wallpaper Engine, MIT
// Caustics: edge distance of two animated Voronoi layers.
vec2 h22(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.xx + p3.yz) * p3.zy); }

float voronoiEdge(vec2 p, float t) {
    vec2 i = floor(p), f = fract(p);
    float d1 = 8.0, d2 = 8.0;
    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
        vec2 o = vec2(x, y);
        vec2 r = h22(i + o);
        vec2 pt = o + 0.5 + 0.45 * sin(t + 6.2831 * r);
        float d = length(pt - f);
        if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
    }
    return d2 - d1;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.y;
    vec2 m = (iMouseUV - 0.5) * 0.3;
    float t = iTime * 0.6;
    vec2 p = uv * 5.0 + m;
    p += 0.15 * vec2(sin(p.y * 1.3 + t), cos(p.x * 1.1 + t * 0.8));
    float e1 = voronoiEdge(p, t);
    float e2 = voronoiEdge(p * 1.6 + 4.0, t * 1.2);
    float c = pow(1.0 - smoothstep(0.0, 0.18, e1), 3.0) + 0.6 * pow(1.0 - smoothstep(0.0, 0.14, e2), 3.0);
    float y = fragCoord.y / iResolution.y;
    vec3 deep = mix(vec3(0.0, 0.04, 0.12), vec3(0.0, 0.28, 0.42), y);
    vec3 col = deep + vec3(0.3, 0.8, 0.9) * c * (0.25 + 0.35 * y);
    vec2 q = fragCoord / iResolution.xy;
    float rays = 0.0;
    for (int k = 0; k < 4; k++) {
        float fk = float(k);
        rays += smoothstep(0.08, 0.0, abs(fract(q.x * (1.3 + fk * 0.4) - q.y * 0.35 + sin(iTime * 0.2 + fk) * 0.1) - 0.5) - 0.04) * (0.25 - fk * 0.04);
    }
    col += vec3(0.4, 0.8, 0.9) * rays * q.y * 0.5;
    vec2 g = floor((fragCoord + vec2(0.0, iTime * 12.0)) / 6.0);
    float s = fract(sin(dot(g, vec2(12.9898, 78.233))) * 43758.5453);
    col += step(0.997, s) * vec3(0.6, 0.9, 1.0) * 0.5;
    fragColor = vec4(col, 1.0);
}
