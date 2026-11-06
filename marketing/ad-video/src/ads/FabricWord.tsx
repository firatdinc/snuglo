import React from "react";
import { interpolate, staticFile, useCurrentFrame, useVideoConfig, Easing } from "remotion";
import { C } from "../kit";

/**
 * Oyunun FabricWord'ünün (godot/scripts/fx/fabric_word.gd) Remotion karşılığı:
 * her harf ayrı kumaş, krem keçe kontür, koyu kenar + kabartma gölgesi, harf harf yaylanarak geliş.
 */
const FONT = "Fredoka, sans-serif";
const DARK = "#3B2114";
const RIM = "#FAEDD9";
const FABRICS = [0, 1, 2, 3, 4, 6, 7, 8, 10, 11]; // çok açık kumaşlar (f05, f09) okunmuyor

// Fredoka'da olmayan Türkçe harfler: temel harf + aynı katmanlarda çizilen işaret.
const COMPOSE: Record<string, { base: string; mark: "cedilla" | "breve" | "dot" }> = {
  "ş": { base: "s", mark: "cedilla" }, "Ş": { base: "S", mark: "cedilla" },
  "ğ": { base: "g", mark: "breve" }, "Ğ": { base: "G", mark: "breve" },
  "İ": { base: "I", mark: "dot" },
};

const seeded = (n: number) => {
  const x = Math.sin(n * 91.17) * 43758.5453;
  return x - Math.floor(x);
};

const markStyle = (mark: string, size: number): React.CSSProperties => {
  if (mark === "cedilla") return { left: "50%", top: size * 1.06, width: size * 0.11, height: size * 0.13, marginLeft: -size * 0.055, borderRadius: `${size * 0.03}px ${size * 0.03}px ${size * 0.12}px ${size * 0.12}px` };
  if (mark === "breve") return { left: "50%", top: size * 0.2, width: size * 0.26, height: size * 0.08, marginLeft: -size * 0.13, borderRadius: `0 0 ${size * 0.2}px ${size * 0.2}px` };
  return { left: "50%", top: size * 0.04, width: size * 0.14, height: size * 0.14, marginLeft: -size * 0.07, borderRadius: "50%" };
};

const Letter: React.FC<{ ch: string; size: number; fabric: string; offset: [number, number] }> = ({ ch, size, fabric, offset }) => {
  const comp = COMPOSE[ch];
  const glyph = comp ? comp.base : ch;
  const outline = Math.max(5, size * 0.075);
  const common: React.CSSProperties = {
    fontFamily: FONT, fontSize: size, fontWeight: 700, lineHeight: 1.35, whiteSpace: "pre",
    fontVariationSettings: "'wght' 700",
  };
  const shade = "linear-gradient(180deg, rgba(255,255,255,0.28) 12%, rgba(255,255,255,0.05) 42%, rgba(30,12,4,0.28) 88%)";
  const fill: React.CSSProperties = {
    backgroundImage: `${shade}, url(${fabric})`,
    backgroundSize: `100% 100%, ${size * 2.4}px`,
    backgroundPosition: `0 0, ${offset[0] * size * 2.4}px ${offset[1] * size * 2.4}px`,
  };
  const stroked = (w: number, color: string, extra?: React.CSSProperties) => (
    <span style={{ ...common, position: "absolute", inset: 0, color, WebkitTextStroke: `${w * 2}px ${color}`, ...extra }}>{glyph}</span>
  );
  const mark = (w: number, color: string, extra?: React.CSSProperties, useFill?: boolean) =>
    comp && (
      <span style={{ position: "absolute", ...markStyle(comp.mark, size), background: useFill ? undefined : color, boxShadow: useFill ? undefined : `0 0 0 ${w}px ${color}`, ...(useFill ? fill : null), ...extra }} />
    );
  return (
    <span style={{ position: "relative", display: "inline-block" }}>
      <span style={{ ...common, visibility: "hidden" }}>{glyph}</span>
      {stroked(outline + size * 0.03, "rgba(59,33,20,0.5)", { transform: `translateY(${size * 0.075}px)` })}
      {mark(outline + size * 0.03, "rgba(59,33,20,0.5)", { transform: `translateY(${size * 0.075}px)` })}
      {stroked(outline + size * 0.022, DARK)}
      {mark(outline + size * 0.022, DARK)}
      {stroked(outline, RIM)}
      {mark(outline, RIM)}
      {mark(0, "", undefined, true)}
      <span style={{ ...common, ...fill, position: "absolute", inset: 0, color: "transparent", WebkitBackgroundClip: "text", backgroundClip: "text" }}>{glyph}</span>
    </span>
  );
};

/** Kumaş yazı. at: giriş karesi, out: çıkış karesi; maxWidth'e sığmazsa satıra böler. */
export const FabricWord: React.FC<{
  text: string; at?: number; out?: number; y: number; size?: number; seed?: number; x?: number; width?: number;
}> = ({ text, at = 0, out, y, size = 120, seed = 3, x = 70, width = 940 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (f < at || (out !== undefined && f >= out + 10)) return null;
  const leave = out === undefined ? 0 : interpolate(f, [out, out + 10], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  let k = 0;
  return (
    <div style={{
      position: "absolute", left: x, top: y, width, display: "flex", flexWrap: "wrap", justifyContent: "center", rowGap: size * 0.02,
      opacity: 1 - leave, transform: `translateY(${-leave * 70}px)`,
    }}>
      {text.split(" ").map((word, wi) => (
        <span key={wi} style={{ display: "inline-flex", marginRight: size * 0.28 }}>
          {[...word].map((ch, li) => {
            const i = k++;
            const t = (f - at - i * 0.045 * fps) / fps; // saniye
            const up = interpolate(t, [0, 0.13], [0, 1.22], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.quad) });
            const settle = interpolate(t, [0.13, 0.35], [1.22, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.back(2)) });
            const scale = t < 0.13 ? up : settle;
            const r0 = (seeded(i + seed) - 0.5) * 0.7;
            const r1 = (seeded(i + seed + 40) - 0.5) * 0.14;
            const rot = interpolate(t, [0, 0.22], [r0, r1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) + Math.sin((f + i * 9) / 22) * 0.012;
            const fab = staticFile(`art/fabric/f${String(FABRICS[(seed + i * 3) % FABRICS.length]).padStart(2, "0")}.png`);
            return (
              <span key={li} style={{ display: "inline-block", marginRight: size * 0.035, transform: `scale(${scale}) rotate(${rot}rad)`, transformOrigin: "50% 75%" }}>
                <Letter ch={ch} size={size} fabric={fab} offset={[seeded(i + seed + 7), seeded(i + seed + 13)]} />
              </span>
            );
          })}
        </span>
      ))}
    </div>
  );
};

/** Oyundaki kumaş kurdele + küçük yazı (bağlam satırları). */
export const FabricLabel: React.FC<{ text: string; at?: number; out?: number; y: number; size?: number }> = ({ text, at = 0, out, y, size = 58 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (f < at || (out !== undefined && f >= out)) return null;
  const s = interpolate(f - at, [0, 0.12 * fps, 0.26 * fps], [0, 1.08, 1], { extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: y, display: "flex", justifyContent: "center", transform: `scale(${s})` }}>
      <div style={{
        padding: `${size * 0.32}px ${size * 0.75}px`, borderRadius: size, background: C.terracotta,
        boxShadow: `inset 0 0 0 ${size * 0.08}px #A9472D, 0 ${size * 0.12}px 0 rgba(58,36,26,0.4)`, position: "relative",
      }}>
        <div style={{ position: "absolute", inset: size * 0.14, borderRadius: size, border: `${size * 0.05}px dashed ${C.cream}` }} />
        <span style={{ position: "relative", fontFamily: FONT, fontWeight: 700, fontSize: size, color: "#fff", fontVariationSettings: "'wght' 640", fontFeatureSettings: "'kern'" }}>{text}</span>
      </div>
    </div>
  );
};
