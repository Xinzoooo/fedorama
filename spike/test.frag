#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix; float qt_Opacity; float iTime; vec2 iResolution; vec2 iMouse;
};
void main() {
    vec2 uv = qt_TexCoord0;
    vec3 c = 0.5 + 0.5*cos(iTime + uv.xyx*3.0 + vec3(0,2,4));
    float d = length((uv - iMouse) * vec2(iResolution.x/iResolution.y, 1.0));
    c += vec3(1.0) * smoothstep(0.05, 0.0, d);
    fragColor = vec4(c, 1.0) * qt_Opacity;
}
