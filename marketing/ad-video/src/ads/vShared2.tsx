import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { Audio, Video } from "@remotion/media";
import { PAPER } from "./vShared";

const FadeIn: React.FC<{ fade: number; first?: boolean; children: React.ReactNode }> = ({ fade, first, children }) => {
  const f = useCurrentFrame();
  const o = first ? 1 : interpolate(f, [0, fade], [0, 1], { extrapolateRight: "clamp" });
  return <AbsoluteFill style={{ opacity: o }}>{children}</AbsoluteFill>;
};
/** Çapraz geçiş: dilim önceki dilimin üstüne `fade` karede belirir; kuyruğu `fade` kare uzar ki altındaki kesilmesin. */
export const Seg: React.FC<{ from: number; dur: number; fade?: number; first?: boolean; children: React.ReactNode }> = ({ from, dur, fade = 10, first, children }) => (
  <Sequence from={from} durationInFrames={dur + fade}><FadeIn fade={fade} first={first}>{children}</FadeIn></Sequence>
);

/** Flow klibi: sesi yumuşak girer/çıkar (dur içinde). */
export const FC: React.FC<{ clip: string; trim?: number; rate?: number; vol?: number; zoom?: [number, number]; dur: number; ain?: number; aout?: number }> = ({ clip, trim = 0, rate = 1, vol = 0.9, zoom = [1, 1], dur, ain = 8, aout = 14 }) => {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, dur], zoom, { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ background: PAPER, overflow: "hidden" }}>
      <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={trim} playbackRate={rate} volume={(fr) => vol * interpolate(fr, [0, ain, dur - aout, dur + aout], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${z})` }} />
    </AbsoluteFill>
  );
};

/** Ken Burns still. */
export const KbS: React.FC<{ src: string; from?: [number, number]; dur: number; origin?: string }> = ({ src, from = [1, 1.08], dur, origin = "50% 50%" }) => {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, dur], from, { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ background: PAPER, overflow: "hidden" }}>
      <Img src={staticFile(src)} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${z})`, transformOrigin: origin }} />
    </AbsoluteFill>
  );
};

/** Müzik: uzun, yumuşak giriş (ani patlama yok). */
export const Music: React.FC<{ at: number; dur: number; vol?: number; fadeIn?: number; fadeOut?: number }> = ({ at, dur, vol = 0.26, fadeIn = 75, fadeOut = 40 }) => (
  <Sequence from={at} durationInFrames={dur}>
    <Audio src={staticFile("bgm_xmas.wav")} volume={(fr) => vol * interpolate(fr, [0, fadeIn, dur - fadeOut, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
  </Sequence>
);
