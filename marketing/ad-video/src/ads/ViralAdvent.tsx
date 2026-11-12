import React from "react";
import { AbsoluteFill, Img, Sequence, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { Bgm, FlowClip, GameFrame, L, PAPER, Snd, XmasEndCard } from "./vShared";

/** "Pahalı advent takvimi, minik içerik" şikayeti: Snuglo bir düğme bulur, sonra 24 kapılık Advent Yorgan. */
const A = 237, S1 = 72, S2 = 66, S3 = 70, S4 = 80, END = 96;
const T1 = A, T2 = T1 + S1, T3 = T2 + S2, T4 = T3 + S3, T5 = T4 + S4;
export const VIRAL_ADVENT_DUR = T5 + END;

const FRIENDS = ["fox", "gingerbread", "penguin", "owl"];
const Friends: React.FC<{ lang: string }> = ({ lang }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return (
    <AbsoluteFill style={{ background: PAPER }}>
      <Img src={staticFile("art/scene/snow.jpg")} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity: 0.4 }} />
      {FRIENDS.map((n, i) => {
        const p = spring({ frame: f - 4 - i * 9, fps, config: { damping: 8, stiffness: 150 } });
        const x = [60, 520, 90, 500][i], y = [440, 520, 960, 1010][i];
        return <Img key={n} src={staticFile(`art/xmas/friends/${n}.png`)} style={{ position: "absolute", left: x, top: y, width: 440, transform: `scale(${p}) rotate(${(i % 2 ? 1 : -1) * 4 * (1 - p) + Math.sin((f + i * 8) / 10) * 2}deg)` }} />;
      })}
      <FabricWord text={L(lang, "A friend.", "Bir dost.")} at={2} y={130} size={140} seed={6} x={90} width={840} />
    </AbsoluteFill>
  );
};

export const ViralAdvent: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* 1 · Kanca: kapı 22, tek düğme, ölü bakış */}
    <Sequence durationInFrames={A}>
      <FlowClip clip="va_button" vol={1} dur={A} zoom={[1, 1.06]} />
      <FabricWord text={L(lang, "Opened door 22.", "22. kapıyı açtım.")} at={0} out={74} y={130} size={L(lang, 108, 100)} seed={2} x={90} width={840} />
      <FabricWord text={L(lang, "Got this.", "Bunu buldum.")} at={80} out={160} y={130} size={130} seed={9} x={90} width={840} />
      <FabricWord text={L(lang, "Incredible.", "Muhteşem.")} at={166} y={130} size={140} seed={4} x={90} width={840} />
    </Sequence>
    <Snd at={2} src="paper_fold" vol={0.8} />
    <Snd at={84} src="felt_pop" vol={0.6} />

    {/* 2 · Oysa Snuglo'da */}
    <Sequence from={T1} durationInFrames={S1}>
      <GameFrame clip={`xm_advent_${lang}`} trim={10}>
        <FabricWord text={L(lang, "Snuglo's Advent Quilt: 24 doors", "Snuglo Advent Yorganı: 24 kapı")} at={2} y={110} size={L(lang, 86, 80)} seed={5} x={90} width={840} />
      </GameFrame>
    </Sequence>
    <Sequence from={T2} durationInFrames={S2}>
      <GameFrame clip={`xm_quilt_${lang}`} trim={30}>
        <FabricWord text={L(lang, "A new patch.", "Yeni bir yama.")} at={2} y={130} size={L(lang, 126, 116)} seed={7} x={90} width={840} />
      </GameFrame>
    </Sequence>
    <Sequence from={T3} durationInFrames={S3}><Friends lang={lang} /></Sequence>
    <Sequence from={T4} durationInFrames={S4}>
      <GameFrame clip={`xm_solve_${lang}`} trim={45}>
        <FabricWord text={L(lang, "A puzzle.", "Bir bulmaca.")} at={2} y={130} size={140} seed={3} x={90} width={840} />
      </GameFrame>
    </Sequence>

    <Sequence from={T5}><XmasEndCard lang={lang} line={["Better doors.", "Daha iyi kapılar."]} /></Sequence>
    <Sequence from={T5 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T2} src="chime" vol={0.6} />
    <Snd at={T3} src="chime" vol={0.6} />
    <Snd at={T4} src="chime" vol={0.6} />
    <Snd at={T5} src="reward" vol={0.5} />
    <Bgm at={T1 - 4} dur={VIRAL_ADVENT_DUR - T1 + 4} from={0} vol={0.32} />
  </AbsoluteFill>
);
