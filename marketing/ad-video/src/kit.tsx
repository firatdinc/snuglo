import React from "react";
import { AbsoluteFill, Easing, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont } from "@remotion/fonts";

loadFont({ family: "Fredoka", url: staticFile("fonts/Fredoka.ttf"), weight: "700" });

export const C = {
  cream: "#FBF1E1", ink: "#3A241A", terracotta: "#C95C3E", mustard: "#E2A93B",
  sage: "#8FA77A", blue: "#5F86B8", plum: "#8E3B5B", pink: "#F2A7A0",
};
export const BEAT = 15; // 120 BPM @ 30 fps
export const FONT = "Fredoka, sans-serif";

/** Kayan pötikare (gingham) kumaş arka plan. */
export const Gingham: React.FC<{ a: string; b: string; size?: number }> = ({ a, b, size = 90 }) => {
  const f = useCurrentFrame();
  const o = (f * 1.2) % (size * 2);
  return (
    <AbsoluteFill
      style={{
        backgroundColor: a,
        backgroundImage: `repeating-linear-gradient(0deg, ${b}66 0 ${size}px, transparent ${size}px ${size * 2}px), repeating-linear-gradient(90deg, ${b}66 0 ${size}px, transparent ${size}px ${size * 2}px)`,
        backgroundPosition: `${o}px ${o}px`,
      }}
    />
  );
};

/** Ritim nabzı: her vuruşta küçük ölçek zıplaması (0..1). */
export const usePulse = (offset = 0) => {
  const f = useCurrentFrame() - offset;
  const p = ((f % BEAT) + BEAT) % BEAT;
  return interpolate(p, [0, 3, BEAT], [1, 0.4, 0], { extrapolateRight: "clamp" });
};

/** Yay ile beliren büyük kontürlü yazı. */
export const Pop: React.FC<{
  text: string; at: number; size?: number; color?: string; stroke?: string; y?: number; rot?: number; out?: number;
}> = ({ text, at, size = 130, color = "#fff", stroke = C.ink, y = 0, rot = 0, out }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (f < at || (out !== undefined && f >= out)) return null;
  const s = spring({ frame: f - at, fps, config: { damping: 9, stiffness: 220, mass: 0.6 } });
  return (
    <div
      style={{
        position: "absolute", left: 0, right: 0, top: y, textAlign: "center", fontFamily: FONT, fontWeight: 700,
        fontSize: size, lineHeight: 1.0, color, WebkitTextStroke: `${size * 0.12}px ${stroke}`, paintOrder: "stroke fill",
        textShadow: `0 ${size * 0.08}px 0 ${stroke}`, scale: String(s), rotate: `${rot * (1 - s) + rot * 0.15}deg`,
        letterSpacing: 1,
      }}
    >
      {text}
    </div>
  );
};

/** Dikişli krem çerçeveli telefon; içinde oyun klibi. */
export const Phone: React.FC<{ children: React.ReactNode; w?: number; tilt?: number; at?: number }> = ({ children, w = 780, tilt = 0, at = 0 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: f - at, fps, config: { damping: 12, stiffness: 160 } });
  const h = (w * 1920) / 1080;
  return (
    <div
      style={{
        position: "absolute", left: (1080 - w) / 2, top: 1920 / 2 - h / 2 + 140, width: w, height: h,
        borderRadius: 72, background: C.cream, padding: 18, boxShadow: "0 30px 60px rgba(58,36,26,0.45)",
        scale: String(interpolate(s, [0, 1], [0.6, 1])), translate: `0px ${interpolate(s, [0, 1], [500, 0])}px`,
        rotate: `${tilt + Math.sin(f / 18) * 1.2}deg`,
      }}
    >
      <div style={{ position: "absolute", inset: 8, borderRadius: 64, border: `5px dashed ${C.terracotta}`, opacity: 0.8 }} />
      <div style={{ width: "100%", height: "100%", borderRadius: 56, overflow: "hidden", position: "relative" }}>{children}</div>
    </div>
  );
};

/** Çıkartma (sticker) rozet. */
export const Sticker: React.FC<{ text: string; at: number; bg: string; x: number; y: number; rot?: number; size?: number; out?: number }> = ({ text, at, bg, x, y, rot = -8, size = 76, out }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (f < at || (out !== undefined && f >= out)) return null;
  const s = spring({ frame: f - at, fps, config: { damping: 8, stiffness: 260, mass: 0.5 } });
  return (
    <div style={{ position: "absolute", left: x, top: y, scale: String(s), rotate: `${rot}deg`, background: bg, color: "#fff",
      fontFamily: FONT, fontWeight: 700, fontSize: size, padding: "18px 40px", borderRadius: 999, border: "8px solid #fff",
      boxShadow: "0 14px 0 rgba(58,36,26,0.35)", WebkitTextStroke: `4px ${C.ink}`, paintOrder: "stroke fill" }}>
      {text}
    </div>
  );
};

/** Konfeti patlaması (deterministik). */
export const Confetti: React.FC<{ at: number; x?: number; y?: number; n?: number }> = ({ at, x = 540, y = 900, n = 70 }) => {
  const f = useCurrentFrame() - at;
  if (f < 0 || f > 70) return null;
  const cols = [C.terracotta, C.mustard, C.sage, C.blue, C.plum, C.pink, "#fff"];
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {Array.from({ length: n }).map((_, i) => {
        const r = (k: number) => { const v = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return v - Math.floor(v); };
        const ang = r(1) * Math.PI * 2; const sp = 18 + r(2) * 30;
        const px = x + Math.cos(ang) * sp * f; const py = y + Math.sin(ang) * sp * f * 0.8 + 0.9 * f * f;
        return <div key={i} style={{ position: "absolute", left: px, top: py, width: 22, height: 34, background: cols[i % cols.length],
          borderRadius: 6, rotate: `${f * (r(3) * 30 - 15)}deg`, opacity: interpolate(f, [50, 70], [1, 0], { extrapolateLeft: "clamp" }) }} />;
      })}
    </AbsoluteFill>
  );
};

/** Sahne girişi: zoom-punch + beyaz flaş. */
export const Punch: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ scale: String(interpolate(f, [0, 8], [1.14, 1], { extrapolateRight: "clamp", easing: Easing.out(Easing.cubic) })) }}>
      {children}
      <AbsoluteFill style={{ background: "#fff", opacity: interpolate(f, [0, 4], [0.85, 0], { extrapolateRight: "clamp" }) }} />
    </AbsoluteFill>
  );
};

export const Art: React.FC<{ src: string; style?: React.CSSProperties }> = ({ src, style }) => (
  <Img src={staticFile(src)} style={{ position: "absolute", ...style }} />
);
