import React from "react";
import { AbsoluteFill, Easing, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio, Video } from "@remotion/media";
import { C, FONT } from "../kit";

// App Store önizlemeleri (886×1920, 30 fps). Görüntü tamamen oyundan; üstüne kumaş temalı hareketli yazılar.
export type PLang = "en" | "tr" | "es";
export type PProps = { lang: PLang };
const FABRICS = ["f00", "f03", "f05", "f07", "f09", "f02", "f06", "f04", "f08", "f01"];

const AppClip: React.FC<{ src: string; trim?: number; vol?: number; zoom?: [number, number] }> = ({ src, trim = 0, vol = 0.8, zoom = [1, 1.03] }) => {
  const f = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill style={{ scale: String(interpolate(f, [0, durationInFrames], zoom)) }}>
      <Video src={staticFile(`clips/${src}.mp4`)} trimBefore={trim} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </AbsoluteFill>
  );
};

/** Yavaş kayan kumaş yama zemin (oyunun yorgan dokusu). */
const Patchwork: React.FC = () => {
  const f = useCurrentFrame();
  const S = 180;
  const off = (f * 0.6) % S;
  return (
    <AbsoluteFill style={{ overflow: "hidden", background: C.ink }}>
      <div style={{ position: "absolute", left: -S, top: -S + off, width: 886 + 2 * S, height: 1920 + 2 * S, display: "flex", flexWrap: "wrap" }}>
        {Array.from({ length: 7 * 14 }).map((_, i) => (
          <div key={i} style={{ width: S, height: S, backgroundImage: `url(${staticFile(`art/fabric/${FABRICS[(i * 7 + Math.floor(i / 7)) % FABRICS.length]}.png`)})`,
            backgroundSize: "260px", outline: `3px dashed rgba(251,241,225,0.35)`, outlineOffset: -10 }} />
        ))}
      </div>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse at 50% 60%, rgba(58,36,26,0.25), rgba(58,36,26,0.7))" }} />
      <AbsoluteFill style={{ background: "linear-gradient(rgba(40,22,14,0.75), rgba(40,22,14,0.35) 18%, transparent 24%)" }} />
    </AbsoluteFill>
  );
};

/** Oyun klibi dikişli krem çerçevede; sahne başında yay ile oturur, hafifçe salınır. */
const FramedClip: React.FC<{ src: string; trim: number; top?: number }> = ({ src, trim, top = 400 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const h = 1920 - top - 70; const w = (h * 886) / 1920;
  const s = spring({ frame: f, fps, config: { damping: 13, stiffness: 170 } });
  return (
    <div style={{ position: "absolute", left: (886 - w) / 2 - 14, top: top - 14, width: w + 28, height: h + 28, borderRadius: 64, background: C.cream, padding: 14,
      boxShadow: "0 30px 60px rgba(0,0,0,0.45)", scale: String(interpolate(s, [0, 1], [0.9, 1])), rotate: `${Math.sin(f / 20) * 0.8}deg` }}>
      <div style={{ position: "absolute", inset: 6, borderRadius: 58, border: `5px dashed ${C.terracotta}`, opacity: 0.85 }} />
      <div style={{ width: "100%", height: "100%", borderRadius: 50, overflow: "hidden", position: "relative" }}>
        <Video src={staticFile(`clips/${src}.mp4`)} trimBefore={trim} volume={0.7} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
    </div>
  );
};

/** Oyundaki FabricWord gibi: her harf ayrı kumaş dolgulu, krem kenarlı, yayla zıplayarak gelir. */
export const FabricText: React.FC<{ text: string; size?: number; y: number; at?: number; seed?: number }> = ({ text, size = 104, y, at = 0, seed = 0 }) => {
  const f = useCurrentFrame() - at;
  const { fps, durationInFrames } = useVideoConfig();
  if (f < 0) return null;
  const out = interpolate(f, [durationInFrames - at - 8, durationInFrames - at], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const lines = text.split("\n");
  let k = 0;
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: y, display: "flex", flexDirection: "column", alignItems: "center", gap: size * 0.02, opacity: out }}>
      {lines.map((line, li) => (
        <div key={li} style={{ display: "flex", justifyContent: "center", flexWrap: "nowrap" }}>
          {[...line].map((ch, i) => {
            const idx = k++;
            const s = spring({ frame: f - idx * 0.9, fps, config: { damping: 9, stiffness: 240, mass: 0.55 } });
            const fab = FABRICS[(idx + seed) % FABRICS.length];
            const rot = Math.sin((idx + seed) * 2.3) * 6;
            const bob = Math.sin((f + idx * 5) / 9) * 3;
            const st: React.CSSProperties = { fontFamily: FONT, fontWeight: 700, fontSize: size, lineHeight: 1.05, whiteSpace: "pre" };
            return (
              <span key={i} style={{ position: "relative", display: "inline-block", scale: String(s), rotate: `${rot * s}deg`, translate: `0px ${(1 - s) * 60 + bob}px` }}>
                <span style={{ ...st, color: C.cream, WebkitTextStroke: `${size * 0.2}px ${C.cream}`, paintOrder: "stroke fill",
                  filter: `drop-shadow(0 ${size * 0.07}px 0 ${C.ink}) drop-shadow(0 ${size * 0.1}px ${size * 0.12}px rgba(58,36,26,0.45))` }}>{ch}</span>
                <span style={{ ...st, position: "absolute", left: 0, top: 0, color: "transparent", backgroundImage: `url(${staticFile(`art/fabric/${fab}.png`)})`,
                  backgroundSize: `${size * 2.2}px`, backgroundPosition: `${idx * 37}px ${idx * 23}px`, WebkitBackgroundClip: "text", backgroundClip: "text",
                  WebkitTextStroke: `${size * 0.035}px rgba(58,36,26,0.55)` }}>{ch}</span>
              </span>
            );
          })}
        </div>
      ))}
    </div>
  );
};

/** Dikişli krem kurdele etiket (önizleme turu için sade başlık). */
const Ribbon: React.FC<{ text: string; y?: number }> = ({ text, y = 130 }) => {
  const f = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const s = spring({ frame: f, fps, config: { damping: 11, stiffness: 200 } });
  const out = interpolate(f, [durationInFrames - 6, durationInFrames], [1, 0], { extrapolateLeft: "clamp" });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: y, display: "flex", justifyContent: "center", scale: String(s), opacity: out, rotate: "-2deg" }}>
      <div style={{ position: "relative", background: C.cream, borderRadius: 26, padding: "22px 48px", fontFamily: FONT, fontWeight: 700, fontSize: 60,
        color: C.ink, boxShadow: `0 10px 0 ${C.terracotta}, 0 22px 30px rgba(58,36,26,0.35)`, textAlign: "center", lineHeight: 1.1, whiteSpace: "pre" }}>
        <div style={{ position: "absolute", inset: 9, borderRadius: 18, border: `4px dashed ${C.terracotta}`, opacity: 0.75 }} />
        {text}
      </div>
    </div>
  );
};

/** Kesme geçişi: çapraz kumaş şeritleri ekranı kaplayıp açılır (kesme noktası 'mid'). */
const FabricWipe: React.FC<{ at: number; len?: number }> = ({ at, len = 16 }) => {
  const f = useCurrentFrame() - at;
  if (f < 0 || f > len) return null;
  const strips = 6;
  return (
    <AbsoluteFill style={{ pointerEvents: "none", overflow: "hidden" }}>
      {Array.from({ length: strips }).map((_, i) => {
        const d = i * 1.2;
        const t = interpolate(f - d, [0, len - strips * 1.2], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.inOut(Easing.cubic) });
        const x = interpolate(t, [0, 0.5, 1], [-1.6, 0, 1.6]) * 1400;
        const h = 2600 / strips;
        return (
          <div key={i} style={{ position: "absolute", left: -260 + x, top: -340 + i * h, width: 1400, height: h + 4, rotate: "-18deg",
            backgroundImage: `url(${staticFile(`art/fabric/${FABRICS[i]}.png`)})`, backgroundSize: "300px", boxShadow: "0 0 0 3px rgba(251,241,225,0.9)",
            borderTop: `5px dashed ${C.cream}`, borderBottom: `5px dashed ${C.cream}` }} />
        );
      })}
    </AbsoluteFill>
  );
};

const Music: React.FC<{ from?: number; vol?: number }> = ({ from = 0, vol = 0.6 }) => {
  const { durationInFrames, fps } = useVideoConfig();
  return (
    <Audio src={staticFile("snuglo_jingle.wav")} trimBefore={from * fps}
      volume={(fr) => vol * interpolate(fr, [0, 6, durationInFrames - 30, durationInFrames], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
  );
};

const TX = {
  h1: { en: "Cozy patchwork\npuzzles", tr: "Sıcacık yama\nbulmacaları", es: "Puzles de\nretales" },
  h2: { en: "Snug every\npatch in!", tr: "Her yamayı\nyerine oturt!", es: "¡Encaja cada\nretal!" },
  h3: { en: "Legendary\nchests!", tr: "Efsanevi\nsandıklar!", es: "¡Cofres\nlegendarios!" },
  h4: { en: "1,000+ levels\n17 worlds", tr: "1000+ bölüm\n17 dünya", es: "1000+ niveles\n17 mundos" },
  p1: { en: "Fit every patch", tr: "Her parçayı yerleştir", es: "Encaja cada pieza" },
  p2: { en: "Combos & cheers", tr: "Seriler ve tezahüratlar", es: "Combos y ánimos" },
  p3: { en: "Stuck? Take a Peek", tr: "Takıldın mı? Göz At", es: "¿Atascado? Vistazo" },
  p4: { en: "Open lucky chests", tr: "Şanslı sandıklar aç", es: "Abre cofres de suerte" },
  p5: { en: "1,000+ levels, 17 worlds", tr: "1000+ bölüm, 17 dünya", es: "1000+ niveles, 17 mundos" },
  p6: { en: "Cozy & calm", tr: "Sıcacık ve sakin", es: "Acogedor y relajante" },
};

// [klip, başlangıç karesi, süre, yazı]
type Shot = [string, number, number, keyof typeof TX];
export const HEADER_PLAN: Shot[] = [["menu", 30, 75, "h1"], ["solve", 150, 150, "h2"], ["chest", 80, 150, "h3"], ["map", 10, 105, "h4"]];
export const TOUR_PLAN: Shot[] = [["hook", 0, 120, "p1"], ["solve", 330, 270, "p2"], ["peek", 0, 81, "p3"], ["chest", 30, 180, "p4"], ["map", 0, 90, "p5"], ["menu", 30, 105, "p6"]];
const total = (p: Shot[]) => p.reduce((a, s) => a + s[2], 0);
export const HEADER_DUR = total(HEADER_PLAN);
export const TOUR_DUR = total(TOUR_PLAN);

/** 1. önizleme (sayfada otomatik oynayan "header"): hızlı, kumaş yazılı, geçişli. */
export const AppHeader: React.FC<PProps> = ({ lang }) => {
  let at = 0;
  const cuts: number[] = [];
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      {HEADER_PLAN.map(([src, trim, d, cap], i) => {
        const from = at; at += d; if (i > 0) cuts.push(from);
        return (
          <Sequence key={i} from={from} durationInFrames={d}>
            <Patchwork />
            <FramedClip src={`ap_${src}_${lang}`} trim={trim} />
            <FabricText text={TX[cap][lang]} y={70} at={4} seed={i * 3} size={lang === "en" ? 104 : 96} />
          </Sequence>
        );
      })}
      {cuts.map((c) => <FabricWipe key={c} at={c - 8} />)}
      <Music from={0} vol={0.55} />
    </AbsoluteFill>
  );
};

/** 2. önizleme: özellik turu, sade kurdele başlıklar. */
export const AppTour: React.FC<PProps> = ({ lang }) => {
  let at = 0;
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      {TOUR_PLAN.map(([src, trim, d, cap], i) => {
        const from = at; at += d;
        return (
          <Sequence key={i} from={from} durationInFrames={d}>
            <AppClip src={`ap_${src}_${lang}`} trim={trim} vol={0.8} />
            <Ribbon text={TX[cap][lang]} />
          </Sequence>
        );
      })}
      <Music from={4} vol={0.45} />
    </AbsoluteFill>
  );
};


/* ------------------------------------------------------------------ Ürün sayfası başlığı (21:9, 3840×1646)
   Sessiz başlar, sürekli döner: tüm hareketler HDR_DUR periyotlu, böylece döngü dikişsiz. */
export const HDR_DUR = 360;
const HW = 3840, HH = 1646;
const cyc = (f: number, k = 1) => (2 * Math.PI * k * f) / HDR_DUR;

const HeaderCard: React.FC<{ src: string; trim: number; x: number; y: number; rot: number; ph: number; h?: number }> = ({ src, trim, x, y, rot, ph, h = 1240 }) => {
  const f = useCurrentFrame();
  const w = (h * 886) / 1920;
  const bob = Math.sin(cyc(f, 2) + ph) * 18;
  const r = rot + Math.sin(cyc(f, 1) + ph) * 1.5;
  return (
    <div style={{ position: "absolute", left: x, top: y + bob, width: w + 36, height: h + 36, borderRadius: 80, background: C.cream, padding: 18, rotate: `${r}deg`,
      boxShadow: "0 40px 80px rgba(30,15,8,0.55)" }}>
      <div style={{ position: "absolute", inset: 8, borderRadius: 72, border: `7px dashed ${C.terracotta}`, opacity: 0.85 }} />
      <div style={{ width: "100%", height: "100%", borderRadius: 64, overflow: "hidden" }}>
        <Video src={staticFile(`clips/${src}.mp4`)} trimBefore={trim} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
    </div>
  );
};

const Plush: React.FC<{ src: string; x: number; y: number; w: number; ph: number; flip?: boolean }> = ({ src, x, y, w, ph, flip }) => {
  const f = useCurrentFrame();
  return <Img src={staticFile(`art/${src}.png`)} style={{ position: "absolute", left: x, top: y + Math.sin(cyc(f, 2) + ph) * 14, width: w,
    rotate: `${Math.sin(cyc(f, 1) + ph) * 5}deg`, scale: flip ? "-1 1" : undefined, filter: "drop-shadow(0 24px 30px rgba(30,15,8,0.45))" }} />;
};

export const ProductHeader: React.FC<PProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const S = 330;
  const drift = (f / HDR_DUR) * S * 2;
  const logoBob = Math.sin(cyc(f, 2)) * 16;
  return (
    <AbsoluteFill style={{ background: C.ink, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: -2 * S + drift * 0.5, top: -2 * S + drift * 0.25, width: HW + 4 * S, height: HH + 4 * S, display: "flex", flexWrap: "wrap" }}>
        {Array.from({ length: Math.ceil((HW + 4 * S) / S) * Math.ceil((HH + 4 * S) / S) }).map((_, i) => (
          <div key={i} style={{ width: S, height: S, backgroundImage: `url(${staticFile(`art/fabric/${FABRICS[(i * 7 + Math.floor(i / 13)) % FABRICS.length]}.png`)})`,
            backgroundSize: "480px", outline: "5px dashed rgba(251,241,225,0.4)", outlineOffset: -16 }} />
        ))}
      </div>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 45% 70% at 50% 45%, rgba(251,241,225,0.55), rgba(251,241,225,0.08) 60%, rgba(40,22,14,0.55))" }} />
      {/* Işık hüzmeleri */}
      <AbsoluteFill style={{ opacity: 0.18, background: `repeating-conic-gradient(from ${(f / HDR_DUR) * 30}deg at 50% 40%, #fff 0deg 6deg, transparent 6deg 18deg)` }} />
      <HeaderCard src={`ap_solve_${lang}`} trim={150} x={150} y={250} rot={-7} ph={0} />
      <HeaderCard src={`ap_hook_${lang}`} trim={0} x={760} y={430} rot={5} ph={1.7} h={1120} />
      <HeaderCard src={`ap_chest_${lang}`} trim={40} x={2470} y={430} rot={-5} ph={2.9} h={1120} />
      <HeaderCard src={`ap_peek_${lang}`} trim={0} x={3080} y={250} rot={7} ph={4.2} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: HW / 2 - 820, top: 150 + logoBob, width: 1640,
        rotate: `${Math.sin(cyc(f, 1)) * 1.5}deg`, filter: "drop-shadow(0 30px 40px rgba(30,15,8,0.45))" }} />
      <Plush src="cheer" x={HW / 2 - 330} y={850} w={660} ph={0.5} />
      <Plush src="friends/fox" x={HW / 2 - 760} y={1150} w={400} ph={2.1} />
      <Plush src="friends/bunny" x={HW / 2 + 380} y={1140} w={400} ph={3.3} flip />
    </AbsoluteFill>
  );
};

/* ------------------------------------------------------------------ Arama sonuçları videosu (3:2, 2880×1920)
   Arama listesinde küçük oynar → az yazı, büyük oynanış kartları; HDR_DUR periyotlu dikişsiz döngü. */
export const SEARCH_W = 2880, SEARCH_H = 1920;
export const SearchAsset: React.FC<PProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const S = 300;
  const drift = (f / HDR_DUR) * S * 2;
  return (
    <AbsoluteFill style={{ background: C.ink, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: -2 * S + drift * 0.5, top: -2 * S + drift * 0.25, width: SEARCH_W + 4 * S, height: SEARCH_H + 4 * S, display: "flex", flexWrap: "wrap" }}>
        {Array.from({ length: Math.ceil((SEARCH_W + 4 * S) / S) * Math.ceil((SEARCH_H + 4 * S) / S) }).map((_, i) => (
          <div key={i} style={{ width: S, height: S, backgroundImage: `url(${staticFile(`art/fabric/${FABRICS[(i * 7 + Math.floor(i / 11)) % FABRICS.length]}.png`)})`,
            backgroundSize: "440px", outline: "5px dashed rgba(251,241,225,0.4)", outlineOffset: -14 }} />
        ))}
      </div>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 60% 60% at 50% 55%, rgba(251,241,225,0.45), rgba(40,22,14,0.55))" }} />
      <AbsoluteFill style={{ opacity: 0.16, background: `repeating-conic-gradient(from ${(f / HDR_DUR) * 30}deg at 50% 55%, #fff 0deg 6deg, transparent 6deg 18deg)` }} />
      <HeaderCard src={`ap_solve_${lang}`} trim={150} x={260} y={330} rot={-6} ph={0} h={1440} />
      <HeaderCard src={`ap_chest_${lang}`} trim={80} x={1080} y={240} rot={0} ph={1.9} h={1560} />
      <HeaderCard src={`ap_hook_${lang}`} trim={0} x={1900} y={330} rot={6} ph={3.6} h={1440} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: SEARCH_W / 2 - 560, top: 40 + Math.sin(cyc(f, 2)) * 12, width: 1120,
        filter: "drop-shadow(0 24px 30px rgba(30,15,8,0.5))" }} />
      <Plush src="cheer" x={60} y={1380} w={520} ph={0.5} />
      <Plush src="friends/bunny" x={2420} y={1440} w={420} ph={2.7} flip />
    </AbsoluteFill>
  );
};
