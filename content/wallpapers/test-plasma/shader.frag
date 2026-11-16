void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 c = 0.5 + 0.5 * cos(iTime + uv.xyx * 3.0 + vec3(0, 2, 4));
    float d = length((uv - iMouseUV) * vec2(iResolution.x / iResolution.y, 1.0));
    c += smoothstep(0.06, 0.0, d) + texture(iChannel0, uv * 4.0).r * 0.05 + iAudio.x;
    fragColor = vec4(c, 1.0);
}
