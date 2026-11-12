import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { GameFrame, L, Snd, XmasEndCard } from "./vShared";
import { FC, KbS, Music, Seg } from "./vShared2";

/** "Rafta Tembel Hayvan": Elf on the Shelf ama Snuglo gecede 1 cm ilerliyor. */
const S = 54, F1 = 150, G = 66, F2 = 160, END = 96;
const T1 = 3 * S, T2 = T1 + F1, T3 = T2 + G, T4 = T3 + F2;
export const VIRAL_ELF_DUR = T4 + END;

/** Uyku anı: Flow kredisi yetmedi, ChatGPT karelerinden yumuşak çapraz geçiş + nefes hareketi. */
const SleepStill: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [34, 70], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const breathe = 1 + 0.012 * Math.sin(f / 9) * interpolate(f, [60, 90], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <AbsoluteFill>
      <KbS src="art/viral2/e_cookie.jpg" dur={dur} from={[1, 1.1]} origin="62% 55%" />
      <AbsoluteFill style={{ opacity: o, transform: `scale(${breathe})`, transformOrigin: "62% 60%" }}><KbS src="art/viral2/e_asleep.jpg" dur={dur} from={[1.1, 1.14]} origin="62% 55%" /></AbsoluteFill>
    </AbsoluteFill>
  );
};

export const ViralElf: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={S}><KbS src="art/viral2/e_shelf.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "Elf on the Shelf, Snuglo edition", "Rafta Elf, Snuglo versiyonu")} at={0} y={140} size={L(lang, 80, 84)} seed={4} x={90} width={840} />
      <FabricWord text={L(lang, "Night 1: 1 cm", "Gece 1: 1 cm")} at={16} y={1080} size={110} seed={2} x={90} width={840} />
    </Seg>
    <Seg from={S} dur={S}><KbS src="art/viral2/e_lower.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "Night 3: 1 cm", "Gece 3: 1 cm")} at={6} y={1080} size={110} seed={6} x={90} width={840} />
    </Seg>
    <Seg from={2 * S} dur={S}><KbS src="art/viral2/e_scarf.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "Night 6: 1 cm + tiny scarf", "Gece 6: 1 cm + minik atkı")} at={6} y={1080} size={L(lang, 84, 80)} seed={9} x={90} width={840} />
    </Seg>
    <Seg from={T1} dur={F1}><FC clip="ve_creep" dur={F1} />
      <FabricWord text={L(lang, "Still on my way.", "Hâlâ yoldayım.")} at={30} y={150} size={L(lang, 110, 110)} seed={3} x={90} width={840} />
    </Seg>
    <Seg from={T2} dur={G}>
      <GameFrame clip={`xm_cbake_${lang}`} trim={100}>
        <FabricWord text={L(lang, "Cookies open Dec 1.", "Kurabiyeler 1 Aralık'ta.")} at={4} y={130} size={L(lang, 96, 92)} seed={5} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T3} dur={F2}><SleepStill dur={F2} />
      <FabricWord text={L(lang, "Dec 25: still on my way", "25 Aralık: hâlâ yolda")} at={F2 - 62} y={150} size={L(lang, 88, 92)} seed={8} x={90} width={840} />
    </Seg>
    <Seg from={T4} dur={END}><XmasEndCard lang={lang} line={["Move in with us.", "Bizimle yola çık."]} /></Seg>
    <Sequence from={T4 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T4 + 10} src="reward" vol={0.45} />
    <Snd at={S - 6} src="felt_pop" vol={0.5} />
    <Snd at={2 * S - 6} src="felt_pop" vol={0.5} />
    <Snd at={T2 - 4} src="rustle" vol={0.5} />
    <Snd at={T3 + 52} src="felt_pop" vol={0.5} />
    <Music at={0} dur={VIRAL_ELF_DUR} />
  </AbsoluteFill>
);
