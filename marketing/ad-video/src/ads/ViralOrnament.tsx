import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { AdProps, Confetti } from "./common";
import { FabricWord } from "./FabricWord";
import { GameFrame, L, Snd, XmasEndCard } from "./vShared";
import { FC, KbS, Music, Seg } from "./vShared2";

/** "Süs puanlama": Snuglo keçe süsleri puanlar, yıldızı en tepeye koyar. */
const S = 58, G = 110, F1 = 190, G2 = 70, END = 96;
const T1 = 3 * S, T2 = T1 + G, T3 = T2 + F1, T4 = T3 + G2;
export const VIRAL_ORN_DUR = T4 + END;

export const ViralOrnament: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={S}><KbS src="art/viral2/o_star.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "Rating ornaments", "Süsleri puanlıyorum")} at={0} y={140} size={L(lang, 100, 96)} seed={4} x={90} width={840} />
      <FabricWord text={L(lang, "10/10 star", "10/10 yıldız")} at={16} y={1080} size={110} seed={2} x={90} width={840} />
    </Seg>
    <Seg from={S} dur={S}><KbS src="art/viral2/o_man.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "7/10 gingerbread man", "7/10 kurabiye adam")} at={6} y={1080} size={L(lang, 88, 92)} seed={6} x={90} width={840} />
    </Seg>
    <Seg from={2 * S} dur={S}><KbS src="art/viral2/o_shiny.jpg" dur={S + 20} />
      <FabricWord text={L(lang, "3/10 too shiny", "3/10 fazla parlak")} at={6} y={1080} size={L(lang, 100, 100)} seed={9} x={90} width={840} />
    </Seg>
    <Seg from={T1} dur={G}>
      <GameFrame clip={`xm_treeslow_${lang}`} trim={60}>
        <FabricWord text={L(lang, "Tree: pending…", "Ağaç: inceleniyor…")} at={4} y={130} size={L(lang, 104, 100)} seed={5} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T2} dur={F1}><KbS src="art/viral2/o_top_start.jpg" dur={60} from={[1, 1.03]} />
      <Seg first={false} from={30} dur={F1 - 30} fade={14}><FC clip="vo_star" trim={18} vol={0} dur={F1 - 30} /></Seg>
      <FabricWord text={L(lang, "The star goes on top.", "Yıldız en tepeye.")} at={10} out={F1 - 60} y={150} size={L(lang, 100, 104)} seed={3} x={90} width={840} />
      <FabricWord text={L(lang, "10/10", "10/10")} at={F1 - 50} y={150} size={170} seed={8} x={90} width={840} />
    </Seg>
    <Seg from={T3} dur={G2}>
      <GameFrame clip={`xm_treelit_${lang}`} trim={40}>
        <FabricWord text={L(lang, "Approved.", "Onaylandı.")} at={2} y={130} size={130} seed={7} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={T4} dur={END}><XmasEndCard lang={lang} line={["Decorate with us.", "Bizimle süsle."]} /></Seg>
    <Sequence from={T4 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={T4 + 10} src="reward" vol={0.45} />
    <Snd at={T1 - 6} src="felt_pop" vol={0.5} />
    <Snd at={T2 + F1 - 46} src="ding" vol={0.6} />
    <Music at={0} dur={VIRAL_ORN_DUR} />
  </AbsoluteFill>
);
