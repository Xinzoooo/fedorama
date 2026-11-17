// Sanfter Verlauf (sehr sparsam) – Fedorama, MIT
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float t = iTime * 0.05;
    vec2 p1 = vec2(0.3 + 0.2 * sin(t * 1.1), 0.3 + 0.2 * cos(t * 0.9));
    vec2 p2 = vec2(0.75 + 0.15 * cos(t * 0.7), 0.7 + 0.2 * sin(t * 1.3));
    vec2 p3 = vec2(0.6 + 0.25 * sin(t * 0.5 + 2.0), 0.2 + 0.15 * cos(t * 0.8));
    vec2 p4 = iMouseUV;
    float a = iResolution.x / iResolution.y;
    vec2 s = vec2(a, 1.0);
    float w1 = 1.0 / (0.02 + pow(length((uv - p1) * s), 2.0));
    float w2 = 1.0 / (0.02 + pow(length((uv - p2) * s), 2.0));
    float w3 = 1.0 / (0.02 + pow(length((uv - p3) * s), 2.0));
    float w4 = 0.4 / (0.05 + pow(length((uv - p4) * s), 2.0));
    vec3 c1 = vec3(0.36, 0.18, 0.85), c2 = vec3(0.05, 0.65, 0.85), c3 = vec3(0.92, 0.3, 0.55), c4 = vec3(0.4, 0.9, 0.8);
    vec3 col = (c1 * w1 + c2 * w2 + c3 * w3 + c4 * w4) / (w1 + w2 + w3 + w4);
    col *= 0.75;
    // subtle grain against banding
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
