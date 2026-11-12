import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { Bgm, FlowClip, GameFrame, L, Snd, XmasEndCard } from "./vShared";

/** "Snuglo bu kış uykuya yatacak": Noel sesleri tek gözünü açtırır, kurabiye kokusu kazanır. */
const A = 237, B = 237, C1 = 84, END = 96;
const T1 = A, T2 = T1 + B, T3 = T2 + C1;
export const VIRAL_HIBERNATE_DUR = T3 + END;

export const ViralHibernate: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* 1 · Uyku + üç Noel sesi */}
    <Sequence durationInFrames={A}>
      <FlowClip clip="vh_sleep" vol={0.7} dur={A} zoom={[1, 1.06]} />
      <FabricWord text={L(lang, "Snuglo will hibernate this winter.", "Snuglo bu kış uykuya yatacak.")} at={0} out={90} y={130} size={L(lang, 86, 80)} seed={4} x={90} width={840} />
      <FabricWord text={L(lang, "*sleigh bell*", "*kızak çanı*")} at={14} out={70} y={1010} size={88} seed={2} x={90} width={840} />
      <FabricWord text={L(lang, "*oven ding*", "*fırın ding*")} at={106} out={160} y={1010} size={88} seed={6} x={90} width={840} />
      <FabricWord text={L(lang, "*cookie crunch*", "*kurabiye çıtırtısı*")} at={172} y={1010} size={L(lang, 88, 78)} seed={9} x={90} width={840} />
    </Sequence>
    <Snd at={12} src="bell" vol={0.85} dur={50} />
    <Snd at={104} src="ding" vol={0.9} dur={45} />
    <Snd at={170} src="crackle" vol={1} dur={30} />

    {/* 2 · Koku kazanır */}
    <Sequence from={T1} durationInFrames={B}>
      <FlowClip clip="vh_wake" vol={0.9} dur={B} />
      <FabricWord text={L(lang, "…is that a cookie?", "…o bir kurabiye mi?")} at={10} out={120} y={130} size={L(lang, 100, 100)} seed={3} x={90} width={840} />
      <FabricWord text={L(lang, "Hibernation cancelled.", "Kış uykusu iptal.")} at={150} y={130} size={L(lang, 100, 104)} seed={8} x={90} width={840} />
    </Sequence>
    <Snd at={T1 + 160} src="felt_pop" vol={0.8} />

    {/* 3 · Noel mutfağı */}
    <Sequence from={T2} durationInFrames={C1}>
      <GameFrame clip={`xm_cbake_${lang}`} trim={100}>
        <FabricWord text={L(lang, "Cookies open Dec 1.", "Kurabiyeler 1 Aralık'ta.")} at={4} y={130} size={L(lang, 100, 94)} seed={5} x={90} width={840} />
      </GameFrame>
    </Sequence>

    <Sequence from={T3}><XmasEndCard lang={lang} line={["Wake up with us.", "Bizimle uyan."]} /></Sequence>
    <Sequence from={T3 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T3} src="reward" vol={0.5} />
    <Bgm at={T1 + 90} dur={VIRAL_HIBERNATE_DUR - T1 - 90} from={0} vol={0.3} />
  </AbsoluteFill>
);
