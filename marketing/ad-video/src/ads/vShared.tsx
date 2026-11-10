import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio, Video } from "@remotion/media";
import { AdProps, C, FONT } from "./common";
import { FabricWord } from "./FabricWord";

export const L = <T,>(lang: string, en: T, tr: T) => (lang === "tr" ? tr : en);
export const PAPER = "#f9edde";

/** Tam ekran Flow (Veo) klibi. Kendi ortam sesi korunur. */
export const FlowClip: React.FC<{ clip: string; trim?: number; rate?: number; vol?: number; zoom?: [number, number]; dur?: number }> = ({ clip, trim = 0, rate = 1, vol = 0.9, zoom = [1, 1], dur = 240 }) => {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, dur], zoom, { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ background: PAPER, overflow: "hidden" }}>
      <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={trim} playbackRate={rate} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${z})` }} />
    </AbsoluteFill>
  );
};

/** Oyun kaydı: kâğıt zeminde çerçeveli, üstte yazıya yer bırakır (UI yazısı ile çakışmaz). */
export const GameFrame: React.FC<{ clip: string; trim?: number; rate?: number; vol?: number; children?: React.ReactNode }> = ({ clip, trim = 0, rate = 1, vol = 0, children }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame: f, fps, config: { damping: 14, stiffness: 150 } });
  return (
    <AbsoluteFill style={{ background: PAPER }}>
      <Img src={staticFile("art/scene/snow.jpg")} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity: 0.35 }} />
      <div style={{ position: "absolute", left: 213, top: 410, width: 654, height: 1417, borderRadius: 38, overflow: "hidden", border: `10px solid ${C.terracotta}`, boxShadow: "0 18px 40px rgba(60,30,10,.35)", transform: `scale(${0.9 + 0.1 * pop})`, background: "#000" }}>
        <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={trim} playbackRate={rate} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
      {children}
    </AbsoluteFill>
  );
};

/** Ken Burns still (ChatGPT / sanat görseli). */
export const Kb: React.FC<{ src: string; from?: [number, number]; dur?: number; contain?: boolean }> = ({ src, from = [1, 1.12], dur = 70, contain }) => {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, dur], from, { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ background: PAPER, overflow: "hidden" }}>
      <Img src={staticFile(src)} style={{ width: "100%", height: "100%", objectFit: contain ? "contain" : "cover", transform: `scale(${z})` }} />
    </AbsoluteFill>
  );
};

export const XmasEndCard: React.FC<AdProps & { line: [string, string] }> = ({ lang, line }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = spring({ frame: f, fps, config: { damping: 10, stiffness: 170 } });
  const btn = spring({ frame: f - 14, fps, config: { damping: 9, stiffness: 200 } });
  const mas = spring({ frame: f - 6, fps, config: { damping: 8, stiffness: 140 } });
  return (
    <AbsoluteFill>
      <Img src={staticFile("art/scene/snow.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: 140, top: 150, width: 800, transform: `scale(${logo})` }} />
      <FabricWord text={L(lang, line[0], line[1])} at={8} y={500} size={L(lang, 96, 92)} seed={2} x={90} width={840} />
      <Img src={staticFile("art/xmas/mascot/idle.png")} style={{ position: "absolute", left: 360, top: 830, width: 360, transform: `scale(${mas}) rotate(${Math.sin(f / 9) * 1.5}deg)` }} />
      <div style={{ position: "absolute", left: 140, top: 1180, width: 800, height: 230, transform: `scale(${btn * (1 + Math.sin(f / 7) * 0.025)})`, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Img src={staticFile("art/btn_terracotta.png")} style={{ position: "absolute", width: "100%", height: "100%" }} />
        <span style={{ position: "relative", fontFamily: FONT, fontWeight: 700, fontSize: L(lang, 84, 74), color: "#fff", WebkitTextStroke: "6px #6E2A17", paintOrder: "stroke fill" }}>
          {L(lang, "PLAY FREE", "ÜCRETSİZ OYNA")}
        </span>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1430, textAlign: "center", fontFamily: FONT, fontWeight: 700, fontSize: 50, color: "#fff", WebkitTextStroke: `7px ${C.ink}`, paintOrder: "stroke fill" }}>
        {L(lang, "Christmas opens Dec 1", "Noel 1 Aralık'ta")}
      </div>
    </AbsoluteFill>
  );
};

/** Müzik: bgm_xmas, girişte yumuşak, çıkışta kısılır. */
export const Bgm: React.FC<{ at: number; dur: number; from?: number; vol?: number }> = ({ at, dur, from = 0, vol = 0.3 }) => (
  <Sequence from={at} durationInFrames={dur}>
    <Audio src={staticFile("bgm_xmas.wav")} trimBefore={from} volume={(fr) => vol * interpolate(fr, [0, 20, dur - 15, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
  </Sequence>
);

export const Snd: React.FC<{ at: number; src: string; vol?: number; dur?: number }> = ({ at, src, vol = 0.8, dur = 60 }) => (
  <Sequence from={at} durationInFrames={dur}>
    <Audio src={staticFile(`sfx/${src}.wav`)} volume={vol} />
  </Sequence>
);
