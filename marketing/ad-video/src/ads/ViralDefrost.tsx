import React from "react";
import { AbsoluteFill, Audio, Img, Sequence, interpolate, random, staticFile, useCurrentFrame } from "remotion";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { FlowClip, GameFrame, L, Snd, XmasEndCard } from "./vShared";

/** "Defrosting" meme: Snuglo buzdan çözülür, 1 Aralık'ta şapkayı takıp Noel köyüne gider. */
const A = 237, B = 195, C1 = 90, C2 = 78, C3 = 78, END = 96;
const T1 = A, T2 = T1 + B, T3 = T2 + C1, T4 = T3 + C2, T5 = T4 + C3;
export const VIRAL_DEFROST_DUR = T5 + END;

/** Kar silkeleme: Flow'un bozulan 4.5–6 sn kısmı yerine 4.4 sn karesi kurgu ile sallanır, ChatGPT keçe kar taneleri savrulur. */
const HOLD0 = 132, HOLD1 = 178, TAIL_TRIM = 183;
const zAt = (f: number) => 1 + 0.05 * f / A;
const TAIL_FROM = HOLD1 - 8;
const ShakeOff: React.FC = () => {
  const f = useCurrentFrame();
  const g = HOLD0 + f;
  const t = Math.max(0, f - 6);
  const amp = f < 6 ? 0 : interpolate(t, [0, 6, 34], [2, 7, 0], { extrapolateRight: "clamp" });
  const rot = Math.sin(t * 1.55) * amp;
  const tx = Math.sin(t * 1.55 + 0.6) * amp * 3;
  const sq = f < 6 ? 1 - 0.04 * Math.sin((f / 6) * Math.PI) : 1 + Math.sin(t * 3.1) * amp * 0.004;
  const fade = interpolate(f, [HOLD1 - HOLD0 - 8, HOLD1 - HOLD0 + 8], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const flakes = Array.from({ length: 46 }, (_, i) => {
    const born = 6 + Math.floor(random(`b${i}`) * 26);
    const a = f - born;
    if (a < 0 || a > 40) return null;
    const side = random(`s${i}`) < 0.5 ? -1 : 1;
    const x0 = 540 + side * (60 + random(`x${i}`) * 250);
    const y0 = 520 + random(`y${i}`) * 420;
    const vx = side * (6 + random(`vx${i}`) * 14), vy = -(8 + random(`vy${i}`) * 14);
    const x = x0 + vx * a, y = y0 + vy * a + 0.9 * a * a;
    const sz = 44 + random(`z${i}`) * 50;
    const op = interpolate(a, [0, 3, 28, 40], [0, 1, 1, 0]);
    return <Img key={i} src={staticFile(`art/xmas/misc/flake_${i % 6}.png`)} style={{ position: "absolute", left: x - sz / 2, top: y - sz / 2, width: sz, height: sz, opacity: op, transform: `rotate(${(a * (8 + i % 5) * side)}deg)` }} />;
  });
  const cut = HOLD1 - HOLD0;
  const puff = Array.from({ length: 40 }, (_, i) => {
    const a = f - (cut - 10) - Math.floor(random(`pb${i}`) * 4);
    if (a < 0 || a > 30) return null;
    const ang = random(`pa${i}`) * Math.PI * 2;
    const sp = 18 + random(`ps${i}`) * 26;
    const x = 540 + Math.cos(ang) * sp * a, y = 900 + Math.sin(ang) * sp * a * 0.9 + 0.5 * a * a;
    const sz = 70 + random(`pz${i}`) * 90;
    const op = interpolate(a, [0, 2, 18, 30], [0, 1, 1, 0]);
    return <Img key={`p${i}`} src={staticFile(`art/xmas/misc/flake_${i % 6}.png`)} style={{ position: "absolute", left: x - sz / 2, top: y - sz / 2, width: sz, height: sz, opacity: op, transform: `rotate(${a * 12 * (i % 2 ? 1 : -1)}deg)` }} />;
  });
  const glow = interpolate(f, [cut - 10, cut, cut + 10], [0, 0.55, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <>
    <AbsoluteFill style={{ opacity: fade, overflow: "hidden" }}>
      <AbsoluteFill style={{ transform: `scale(${zAt(g)})` }}>
        <Img src={staticFile("art/viral/vf_defrost_hold.png")} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", transformOrigin: "50% 78%", transform: `translateX(${tx}px) rotate(${rot}deg) scale(${1 / sq}, ${sq})` }} />
      </AbsoluteFill>
      {flakes}
    </AbsoluteFill>
    <AbsoluteFill style={{ background: "radial-gradient(circle at 50% 50%, rgba(255,250,240,1), rgba(255,250,240,0) 70%)", opacity: glow }} />
    {puff}
    </>
  );
};
const TailClip: React.FC = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill style={{ transform: `scale(${zAt(TAIL_FROM + f)})` }}><FlowClip clip="vf_defrost" trim={TAIL_TRIM} rate={0.9} vol={0} /></AbsoluteFill>;
};

export const ViralDefrost: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* 1 · Buz bloğu: kanca + takvim 30 Kasım → 1 Aralık */}
    <Sequence durationInFrames={A}>
      <Sequence durationInFrames={HOLD0 + 2}><FlowClip clip="vf_defrost" vol={0} zoom={[1, 1.05]} dur={A} /></Sequence>
      <Sequence from={HOLD1 - 8}><TailClip /></Sequence>
      <Sequence from={HOLD0} durationInFrames={HOLD1 - HOLD0 + 30}><ShakeOff /></Sequence>
      <FabricWord text={L(lang, "POV: Snuglo defrosting for December", "POV: Snuglo Aralık için çözülüyor")} at={0} y={130} size={L(lang, 82, 78)} seed={4} x={90} width={840} />
      <FabricWord text={L(lang, "Nov 30", "30 Kasım")} at={14} out={46} y={560} size={130} seed={2} x={90} width={840} />
      <FabricWord text={L(lang, "Dec 1", "1 Aralık")} at={52} y={560} size={150} seed={6} x={90} width={840} />
      <FabricWord text={L(lang, "Ten more minutes.", "On dakika daha.")} at={168} y={1010} size={92} seed={9} x={90} width={840} />
    </Sequence>
    <Sequence durationInFrames={A + 12}>
      <Audio src={staticFile("clips/vf_defrost.mp4")} volume={(fr) => interpolate(fr, [0, A - 10, A + 12], [1, 1, 0], { extrapolateRight: "clamp" })} />
    </Sequence>
    <Sequence from={90} durationInFrames={VIRAL_DEFROST_DUR - 90}>
      <Audio src={staticFile("bgm_xmas.wav")} volume={(fr) => interpolate(fr, [0, 90, T1 - 90, T1 - 60, VIRAL_DEFROST_DUR - 105, VIRAL_DEFROST_DUR - 90], [0, 0.12, 0.12, 0.3, 0.3, 0], { extrapolateRight: "clamp" })} />
    </Sequence>
    <Snd at={46} src="paper_fold" vol={0.9} />
    <Snd at={58} src="crackle" vol={0.7} />
    <Snd at={76} src="felt_pop" vol={0.7} />
    <Snd at={HOLD0 + 6} src="rustle" vol={0.9} />
    <Snd at={HOLD0 + 12} src="snow_pack" vol={0.8} />
    <Snd at={HOLD0 + 24} src="snow_pack" vol={0.6} />

    {/* 2 · Şapka düşer, köye doğru süzülür */}
    <Sequence from={T1} durationInFrames={B}>
      <FlowClip clip="vf_hat" vol={1} dur={B} />
      <FabricWord text={L(lang, "The hat is mandatory.", "Şapka zorunlu.")} at={24} out={120} y={150} size={L(lang, 104, 112)} seed={3} x={90} width={840} />
      <FabricWord text={L(lang, "Off we go.", "Hadi bakalım.")} at={130} y={150} size={120} seed={8} x={90} width={840} />
    </Sequence>
    <Snd at={T1 + 12} src="felt_pop" vol={0.9} />

    {/* 3 · Noel köyü */}
    <Sequence from={T2} durationInFrames={C1}>
      <GameFrame clip={`xm_village_${lang}`} trim={20}>
        <FabricWord text={L(lang, "Christmas village: open.", "Noel köyü açıldı.")} at={4} y={130} size={L(lang, 98, 108)} seed={5} x={90} width={840} />
      </GameFrame>
    </Sequence>
    <Sequence from={T3} durationInFrames={C2}>
      <GameFrame clip={`xm_treelit_${lang}`} trim={40}>
        <FabricWord text={L(lang, "Felt tree.", "Keçe ağaç.")} at={2} y={130} size={130} seed={7} x={90} width={840} />
      </GameFrame>
    </Sequence>
    <Sequence from={T4} durationInFrames={C3}>
      <GameFrame clip={`xm_cbake_${lang}`} trim={100}>
        <FabricWord text={L(lang, "Cookies.", "Kurabiyeler.")} at={2} y={130} size={130} seed={10} x={90} width={840} />
      </GameFrame>
    </Sequence>

    <Sequence from={T5}><XmasEndCard lang={lang} line={["Thaw with us.", "Bizimle çözül."]} /></Sequence>
    <Sequence from={T5 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T5} src="reward" vol={0.5} />
  </AbsoluteFill>
);
