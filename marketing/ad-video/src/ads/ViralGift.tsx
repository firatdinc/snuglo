import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { GameFrame, L, Snd, XmasEndCard } from "./vShared";
import { FC, KbS, Music, Seg } from "./vShared2";

/** "Hediye paketleyen ben": Snuglo hediyeyi değil kendini paketler. */
const S = 54, F1 = 192, C = 54, END = 96;
const T1 = 3 * S, T2 = T1 + F1, T3 = T2 + C, T4 = T3 + C, T5 = T4 + C;
export const VIRAL_GIFT_DUR = T5 + END;

export const ViralGift: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={S}><KbS src="art/viral2/g_paper.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "Me wrapping gifts", "Hediye paketleyen ben")} at={0} y={140} size={L(lang, 96, 88)} seed={4} x={90} width={840} />
    </Seg>
    <Seg from={S} dur={S}><KbS src="art/viral2/g_tape.jpg" dur={S + 20} /></Seg>
    <Seg from={2 * S} dur={S}><KbS src="art/viral2/g_ribbon.jpg" dur={S + 20} /></Seg>
    <Seg from={T1} dur={F1}><FC clip="vg_wrap" dur={F1} />
      <FabricWord text={L(lang, "…wrapped myself.", "…kendimi paketledim.")} at={F1 - 56} y={150} size={L(lang, 104, 94)} seed={3} x={90} width={840} />
    </Seg>
    <Seg from={T2} dur={C}>
      <GameFrame clip={`xm_village_${lang}`} trim={20}>
        <FabricWord text={L(lang, "Christmas village.", "Noel köyü.")} at={2} y={130} size={L(lang, 104, 120)} seed={5} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T3} dur={C}>
      <GameFrame clip={`xm_treelit_${lang}`} trim={40}>
        <FabricWord text={L(lang, "Felt tree.", "Keçe ağaç.")} at={2} y={130} size={130} seed={7} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T4} dur={C}>
      <GameFrame clip={`xm_cbake_${lang}`} trim={100}>
        <FabricWord text={L(lang, "Cookies.", "Kurabiyeler.")} at={2} y={130} size={130} seed={10} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T5} dur={END}><XmasEndCard lang={lang} line={["Gift yourself a game.", "Kendine oyun hediye et."]} /></Seg>
    <Sequence from={T5 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T5 + 10} src="reward" vol={0.45} />
    <Snd at={S - 6} src="paper_fold" vol={0.6} />
    <Snd at={2 * S - 6} src="rustle" vol={0.6} />
    <Snd at={T1 + 90} src="ribbon" vol={0.7} />
    <Snd at={T1 + F1 - 58} src="felt_pop" vol={0.7} />
    <Music at={0} dur={VIRAL_GIFT_DUR} />
  </AbsoluteFill>
);
