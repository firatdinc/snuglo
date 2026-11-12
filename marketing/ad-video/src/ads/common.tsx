import React from "react";
import { AbsoluteFill, Easing, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio, Video } from "@remotion/media";
import { Art, BEAT, C, Confetti, FONT, Gingham, Pop, usePulse } from "../kit";

export type Lang = "en" | "tr";
export type AdProps = { lang: Lang };

export const T = {
  play: { en: "PLAY FREE", tr: "ÜCRETSİZ OYNA" },
  store: { en: "on the App Store", tr: "App Store'da" },
};

export const Clip: React.FC<{ src: string; vol?: number; style?: React.CSSProperties }> = ({ src, vol = 0.8, style }) => (
  <Video src={staticFile(`clips/${src}.mp4`)} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover", ...style }} />
);

/** Tam ekran oyun klibi + yavaş Ken Burns. */
export const FullClip: React.FC<{ src: string; vol?: number; zoom?: [number, number] }> = ({ src, vol, zoom = [1, 1.04] }) => {
  const f = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill style={{ scale: String(interpolate(f, [0, durationInFrames], zoom)) }}>
      <Clip src={src} vol={vol} />
    </AbsoluteFill>
  );
};

/** TikTok yerli altyazı: beyaz dolgu, siyah kontür, arka plan yok. */
export const Native: React.FC<{ text: string; at?: number; out?: number; y?: number; size?: number }> = ({ text, at = 0, out, y = 260, size = 64 }) => {
  const f = useCurrentFrame();
  if (f < at || (out !== undefined && f >= out)) return null;
  return (
    <div style={{ position: "absolute", left: 120, right: 120, top: y, textAlign: "center", fontFamily: "-apple-system, 'SF Pro Display', Helvetica, sans-serif",
      fontWeight: 800, fontSize: size, lineHeight: 1.15, color: "#fff", WebkitTextStroke: `${size * 0.14}px #000`, paintOrder: "stroke fill",
      textShadow: "0 3px 12px rgba(0,0,0,0.35)" }}>{text}</div>
  );
};

/** Ortak kapanış kartı (logo + maskot + ÜCRETSİZ OYNA). */
export const EndCard: React.FC<AdProps & { pose?: string }> = ({ lang, pose = "cheer" }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = usePulse();
  const logo = spring({ frame: f, fps, config: { damping: 8, stiffness: 160 } });
  const btn = spring({ frame: f - 10, fps, config: { damping: 9, stiffness: 200 } });
  return (
    <AbsoluteFill>
      <AbsoluteFill><img src={staticFile("art/scene/flower.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} /></AbsoluteFill>
      <Art src="art/logo.png" style={{ left: 90, top: 260, width: 900, scale: String(logo * (1 + p * 0.04)), translate: `0px ${(1 - logo) * -500}px` }} />
      <Art src={`art/${pose}.png`} style={{ left: 310, top: 720, width: 460, scale: String(spring({ frame: f - 5, fps, config: { damping: 10 } })), rotate: `${Math.sin(f / 7) * 5}deg` }} />
      <div style={{ position: "absolute", left: 140, top: 1240, width: 800, height: 170, borderRadius: 999, background: C.terracotta,
        border: `10px solid ${C.cream}`, boxShadow: "0 16px 0 rgba(58,36,26,0.4)", scale: String(btn * (1 + p * 0.07)),
        display: "flex", alignItems: "center", justifyContent: "center", fontFamily: FONT, fontWeight: 700, fontSize: lang === "tr" ? 84 : 96,
        color: "#fff", WebkitTextStroke: `8px ${C.ink}`, paintOrder: "stroke fill" }}>{T.play[lang]}</div>
      {f >= 18 && <Pop text={T.store[lang]} at={18} y={1440} size={70} />}
      <Confetti at={10} x={540} y={1320} n={70} />
    </AbsoluteFill>
  );
};

/** Müzik: neşeli jingle; trim (sn) ile drop'tan başlat, sonda kıs. */
export const Music: React.FC<{ from?: number; vol?: number }> = ({ from = 0, vol = 0.85 }) => {
  const { durationInFrames, fps } = useVideoConfig();
  return (
    <Audio src={staticFile("snuglo_jingle.wav")} trimBefore={from * fps}
      volume={(fr) => vol * interpolate(fr, [0, 6, durationInFrames - 24, durationInFrames], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
  );
};

export const Sfx: React.FC<{ src: string; vol?: number }> = ({ src, vol = 0.8 }) => <Audio src={staticFile(`sfx/${src}.wav`)} volume={vol} />;
export { BEAT, C, Confetti, FONT, Gingham, Pop, Art, usePulse, Easing };
