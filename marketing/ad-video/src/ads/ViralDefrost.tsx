import React from "react";
import { AbsoluteFill, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { Audio, Video } from "@remotion/media";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { GameFrame, L, Snd, XmasEndCard } from "./vShared";
import { FC, Seg } from "./vShared2";

/** "Defrosting" meme: Snuglo buzdan çözülür, 1 Aralık'ta şapkayı takıp Noel köyüne gider. */
const A = 132 + 135, B = 195, C1 = 90, C2 = 78, C3 = 78, END = 96;
const T1 = A, T2 = T1 + B, T3 = T2 + C1, T4 = T3 + C2, T5 = T4 + C3;
export const VIRAL_DEFROST_DUR = T5 + END;

/** Kar silkeleme: Flow frames-to-video klibi (vf_shake). İlk karesi 4.4 sn karesiyle aynı; kesintisiz çapraz geçiş, ses akışı sürekli. */
const PAPER_BG = "#f9edde";
const HOLD0 = 132, SH_LEN = 135, SH_RATE = 1.2;
const zAt = (f: number) => 1 + 0.05 * f / A;
const ShakeClip: React.FC = () => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 8], [0, 1], { extrapolateRight: "clamp" });
  // klibin ilk 1.2 sn'si sessiz, sonra ani kar gürültüsü başlıyor: sesi yavaşça yükselt
  const vol = (fr: number) => interpolate(fr, [0, 10, 22, 70], [0, 0.3, 0.3, 1], { extrapolateRight: "clamp" }) * interpolate(fr, [SH_LEN - 4, SH_LEN + 10], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return <AbsoluteFill style={{ opacity: o, transform: `scale(${zAt(HOLD0 + f)})`, background: PAPER_BG }}><Video src={staticFile("clips/vf_shake.mp4")} playbackRate={SH_RATE} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover" }} /></AbsoluteFill>;
};
const OrigClip: React.FC = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill style={{ transform: `scale(${zAt(f)})` }}><Video src={staticFile("clips/vf_defrost.mp4")} volume={(fr) => interpolate(fr, [0, HOLD0 - 4, HOLD0 + 10], [1, 1, 0], { extrapolateRight: "clamp" })} style={{ width: "100%", height: "100%", objectFit: "cover" }} /></AbsoluteFill>;
};

export const ViralDefrost: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* 1 · Buz bloğu: kanca + takvim 30 Kasım → 1 Aralık */}
    <Sequence durationInFrames={A + 12}>
      <Sequence durationInFrames={HOLD0 + 12}><OrigClip /></Sequence>
      <Sequence from={HOLD0} durationInFrames={SH_LEN + 12}><ShakeClip /></Sequence>
      <FabricWord text={L(lang, "POV: Snuglo defrosting for December", "POV: Snuglo Aralık için çözülüyor")} at={0} y={130} size={L(lang, 82, 78)} seed={4} x={90} width={840} />
      <FabricWord text={L(lang, "Nov 30", "30 Kasım")} at={14} out={46} y={560} size={130} seed={2} x={90} width={840} />
      <FabricWord text={L(lang, "Dec 1", "1 Aralık")} at={52} y={560} size={150} seed={6} x={90} width={840} />
      <FabricWord text={L(lang, "Ten more minutes.", "On dakika daha.")} at={190} y={1010} size={92} seed={9} x={90} width={840} />
    </Sequence>
    <Sequence from={90} durationInFrames={VIRAL_DEFROST_DUR - 90}>
      <Audio src={staticFile("bgm_xmas.wav")} volume={(fr) => interpolate(fr, [0, 90, T1 - 90, T1 - 60, VIRAL_DEFROST_DUR - 105, VIRAL_DEFROST_DUR - 90], [0, 0.12, 0.12, 0.3, 0.3, 0], { extrapolateRight: "clamp" })} />
    </Sequence>
    <Snd at={46} src="paper_fold" vol={0.9} />
    <Snd at={58} src="crackle" vol={0.7} />
    <Snd at={76} src="felt_pop" vol={0.7} />

    {/* 2 · Şapka düşer, köye doğru süzülür */}
    <Seg from={T1} dur={B} fade={10}>
      <FC clip="vf_hat" vol={1} dur={B} ain={10} />
      <FabricWord text={L(lang, "The hat is mandatory.", "Şapka zorunlu.")} at={24} out={120} y={150} size={L(lang, 104, 112)} seed={3} x={90} width={840} />
      <FabricWord text={L(lang, "Off we go.", "Hadi bakalım.")} at={130} y={150} size={120} seed={8} x={90} width={840} />
    </Seg>
    <Snd at={T1 + 12} src="felt_pop" vol={0.9} />

    {/* 3 · Noel köyü */}
    <Seg from={T2} dur={C1} fade={10}>
      <GameFrame clip={`xm_village_${lang}`} trim={20}>
        <FabricWord text={L(lang, "Christmas village: open.", "Noel köyü açıldı.")} at={4} y={130} size={L(lang, 98, 108)} seed={5} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T3} dur={C2} fade={10}>
      <GameFrame clip={`xm_treelit_${lang}`} trim={40}>
        <FabricWord text={L(lang, "Felt tree.", "Keçe ağaç.")} at={2} y={130} size={130} seed={7} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T4} dur={C3} fade={10}>
      <GameFrame clip={`xm_cbake_${lang}`} trim={100}>
        <FabricWord text={L(lang, "Cookies.", "Kurabiyeler.")} at={2} y={130} size={130} seed={10} x={90} width={840} />
      </GameFrame>
    </Seg>

    <Seg from={T5} dur={END} fade={10}><XmasEndCard lang={lang} line={["Thaw with us.", "Bizimle çözül."]} /></Seg>
    <Sequence from={T5 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T5} src="reward" vol={0.5} />
  </AbsoluteFill>
);
