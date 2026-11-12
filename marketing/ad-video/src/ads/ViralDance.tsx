import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { AdProps, C, FONT } from "./common";
import { FC, Seg } from "./vShared2";
import { Promo } from "./ViralMeme";

/**
 * 19) Dans dönüşümü (yurt dışı): viral reels, Kling video-edit ile Snuglo; ayaktaki bot = app ikonu.
 * Orijinal ses korunur; sonda müziksiz Snuglo tanıtımı.
 */
const CLIP = 361; // 12.03 sn
const PDUR = 186;
export const VIRAL_DANCE_DUR = CLIP + PDUR;

const Cap: React.FC<{ text: string }> = ({ text }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 6], [0, 1], { extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 50, right: 50, top: 190, textAlign: "center", opacity: o, fontFamily: FONT, fontWeight: 800, fontSize: 64, lineHeight: 1.12, color: "#fff", WebkitTextStroke: `11px ${C.ink}`, paintOrder: "stroke fill" }}>{text}</div>
  );
};

const CUT = 160; // kıyafet değişimi (5.33 sn)
const Flash: React.FC = () => {
  const f = useCurrentFrame();
  const o = interpolate(f, [CUT - 3, CUT, CUT + 2, CUT + 10], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return <AbsoluteFill style={{ background: "#fff", opacity: o }} />;
};

const Dance: React.FC<AdProps> = ({ lang }) => {
  const en = lang !== "tr";
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Seg first from={0} dur={CLIP}><FC clip="ws_dance_butt" dur={CLIP} vol={1} ain={1} aout={6} /></Seg>
      <Sequence from={0} durationInFrames={CLIP - 4}>
        <Cap text={en ? "Me when the Snuglo Christmas update finally drops" : "Snuglo'ya Noel güncellemesi gelince ben:"} />
      </Sequence>
      <Flash />
      <Seg from={CLIP} dur={PDUR} fade={8}><Promo lang={lang} /></Seg>
    </AbsoluteFill>
  );
};

export const ViralDance: React.FC<AdProps> = ({ lang }) => <Dance lang={lang} />;
