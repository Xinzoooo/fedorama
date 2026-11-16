"""Shadertoy-style GLSL -> Qt Shader Baker (.qsb) compiler.

Wallpaper shaders are written like on shadertoy.com:

    void mainImage(out vec4 fragColor, in vec2 fragCoord) { ... }

Available inputs (same names as Shadertoy where possible):
    iTime, iTimeDelta, iFrame, iResolution, iMouse, iDate, iChannel0 (noise),
    iChannelResolution[0]
Linux-Wallpaper-Engine extras:
    iAudio      vec4(bass, mid, treble, level), 0..1
    lweSpectrum(x)  -> float, 16-band spectrum sampled at x in 0..1
    iMouseUV    vec2 cursor position in 0..1 (y up), smoothed
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HEADER = r"""#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 lwe_outColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float iTime;
    float iTimeDelta;
    float lweFrame;
    vec3 iResolution;
    vec4 iMouse;
    vec2 iMouseUV;
    vec4 iDate;
    vec4 iAudio;
    vec4 iSpectrumA;
    vec4 iSpectrumB;
    vec4 iSpectrumC;
    vec4 iSpectrumD;
    float uBrightness;
    float uHue;
    float uSaturation;
};
layout(binding = 1) uniform sampler2D iChannel0;
#define iFrame int(lweFrame)
#define iChannelResolution (vec3[1](vec3(256.0, 256.0, 1.0)))
#define texture2D texture
float lweSpectrum(float x) {
    float f = clamp(x, 0.0, 1.0) * 15.0;
    int i = int(floor(f));
    float a[16] = float[16](iSpectrumA.x, iSpectrumA.y, iSpectrumA.z, iSpectrumA.w,
                            iSpectrumB.x, iSpectrumB.y, iSpectrumB.z, iSpectrumB.w,
                            iSpectrumC.x, iSpectrumC.y, iSpectrumC.z, iSpectrumC.w,
                            iSpectrumD.x, iSpectrumD.y, iSpectrumD.z, iSpectrumD.w);
    int j = min(i + 1, 15);
    return mix(a[i], a[j], fract(f));
}
#line 1
"""

FOOTER = r"""
vec3 lwe_hue(vec3 c, float h) {
    const vec3 k = vec3(0.57735);
    float ca = cos(h);
    return c * ca + cross(k, c) * sin(h) + k * dot(k, c) * (1.0 - ca);
}
void main() {
    vec2 fc = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution.xy;
    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
    mainImage(col, fc);
    vec3 c = col.rgb;
    if (uHue != 0.0) c = lwe_hue(c, uHue);
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, uSaturation) * uBrightness;
    lwe_outColor = vec4(clamp(c, 0.0, 1.0), 1.0) * qt_Opacity;
}
"""

QSB_CANDIDATES = ["/usr/lib64/qt6/bin/qsb", "/usr/lib/qt6/bin/qsb", "qsb-qt6", "qsb"]


def find_qsb() -> str | None:
    for c in QSB_CANDIDATES:
        p = shutil.which(c) if not c.startswith("/") else (c if os.access(c, os.X_OK) else None)
        if p:
            return p
    return None


def wrap(user_code: str) -> str:
    code = user_code.replace("#version", "// #version")
    # strip things that collide with the wrapper
    lines = []
    for ln in code.splitlines():
        s = ln.strip()
        if s.startswith("precision ") or s.startswith("uniform "):
            lines.append("// " + ln)
        else:
            lines.append(ln)
    return HEADER + "\n".join(lines) + "\n" + FOOTER


def compile_shader(src: Path, out: Path) -> tuple[bool, str]:
    """Compile a shadertoy-style .frag file into a .qsb. Returns (ok, log)."""
    qsb = find_qsb()
    if not qsb:
        return False, "qsb (Qt Shader Tools) nicht gefunden. Paket: qt6-qtshadertools"
    code = Path(src).read_text(encoding="utf-8", errors="replace")
    if "mainImage" not in code:
        return False, "Kein mainImage() gefunden – ist das ein Shadertoy-Shader?"
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td) / "wrapped.frag"
        tmp.write_text(wrap(code), encoding="utf-8")
        out.parent.mkdir(parents=True, exist_ok=True)
        r = subprocess.run([qsb, "--glsl", "330,300 es", "-o", str(out), str(tmp)],
                           capture_output=True, text=True, timeout=60)
        log = (r.stdout + r.stderr).replace(str(tmp), src.name)
        return r.returncode == 0 and out.exists(), log.strip()


def build_tree(root: Path, force: bool = False) -> int:
    """Compile every <wallpaper>/shader.frag below root. Returns number of failures."""
    fails = 0
    for frag in sorted(Path(root).glob("*/shader.frag")):
        out = frag.with_name("shader.qsb")
        if not force and out.exists() and out.stat().st_mtime >= frag.stat().st_mtime:
            continue
        ok, log = compile_shader(frag, out)
        print(("  ok   " if ok else "  FAIL ") + frag.parent.name)
        if not ok:
            fails += 1
            print("       " + log.replace("\n", "\n       "))
    return fails


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "build":
        sys.exit(1 if build_tree(Path(sys.argv[2]), "--force" in sys.argv) else 0)
    if len(sys.argv) == 4 and sys.argv[1] == "compile":
        ok, log = compile_shader(Path(sys.argv[2]), Path(sys.argv[3]))
        print(log)
        sys.exit(0 if ok else 1)
    print("usage: shaders.py build <dir> [--force] | compile <in.frag> <out.qsb>")
    sys.exit(2)
