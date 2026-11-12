import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { AdProps, C, Confetti, FONT } from "./common";
import { FabricWord } from "./FabricWord";
import { GameFrame, L, Snd, XmasEndCard } from "./vShared";
import { FC, Music, Seg } from "./vShared2";

/** Alt yazı (konuşma/şarkı sözü): yumuşak giriş-çıkış. */
const Sub: React.FC<{ at: number; dur: number; text: string; y?: number; size?: number }> = ({ at, dur, text, y = 1560, size = 64 }) => (
  <Sequence from={at} durationInFrames={dur}>
    <SubIn dur={dur} text={text} y={y} size={size} />
  </Sequence>
);
const SubIn: React.FC<{ dur: number; text: string; y: number; size: number }> = ({ dur, text, y, size }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 6, dur - 6, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: y, textAlign: "center", opacity: o, fontFamily: FONT, fontWeight: 700, fontSize: size, lineHeight: 1.15, color: "#fff", WebkitTextStroke: `9px ${C.ink}`, paintOrder: "stroke fill" }}>
      {text}
    </div>
  );
};

/** Oyun kısa vitrini: 2 hızlı oyun kaydı. */
const Gameplay: React.FC<{ lang: string; from: number; d: number }> = ({ lang, from, d }) => (
  <>
    <Seg from={from} dur={d}>
      <GameFrame clip={`xm_village_${lang}`} trim={20}>
        <FabricWord text={L(lang, "Christmas village.", "Noel köyü.")} at={2} y={130} size={L(lang, 104, 120)} seed={5} x={90} width={840} />
      </GameFrame>
    </Seg>
    <Seg from={from + d} dur={d}>
      <GameFrame clip={`xm_treelit_${lang}`} trim={40}>
        <FabricWord text={L(lang, "Cozy puzzles.", "Rahat bulmacalar.")} at={2} y={130} size={L(lang, 104, 104)} seed={7} x={90} width={840} />
      </GameFrame>
    </Seg>
  </>
);

/* ---------- A) Noel'i uyuyarak kaçırmak ---------- */
const A1 = 186, A2 = 186, A3 = 228, AG = 48, AE = 96;
const AT1 = A1, AT2 = AT1 + A2, AT3 = AT2 + A3, AT4 = AT3 + 2 * AG;
export const VIRAL_SLEEP_DUR = AT4 + AE;
export const ViralSleepThrough: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={A1}><FC clip="wa_clock" dur={A1 + 10} />
      <FabricWord text={L(lang, "Dec 24: “Wake me up for Christmas.”", "24 Aralık: “Noel'de uyandırın.”")} at={4} y={130} size={L(lang, 84, 84)} seed={4} x={80} width={920} />
    </Seg>
    <Seg from={AT1} dur={A2}><FC clip="wa_gifts" dur={A2 + 10} />
      <FabricWord text={L(lang, "Dec 25", "25 Aralık")} at={4} y={130} size={130} seed={6} x={90} width={840} />
    </Seg>
    <Seg from={AT2} dur={A3}><FC clip="wa_wake" dur={A3 + 10} />
      <FabricWord text={L(lang, "Dec 26", "26 Aralık")} at={4} y={130} size={130} seed={8} x={90} width={840} />
      <FabricWord text={L(lang, "Don't sleep through Christmas.", "Bu Noel'i kaçırma.")} at={A3 - 70} y={1500} size={L(lang, 88, 96)} seed={3} x={80} width={920} />
    </Seg>
    <Gameplay lang={lang} from={AT3} d={AG} />
    <Seg from={AT4} dur={AE}><XmasEndCard lang={lang} line={["Christmas is waiting.", "Noel seni bekliyor."]} /></Seg>
    <Sequence from={AT4 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={AT4 + 10} src="reward" vol={0.45} />
    <Music at={AT3 - 30} dur={VIRAL_SLEEP_DUR - AT3 + 30} vol={0.28} fadeIn={40} />
  </AbsoluteFill>
);

/* ---------- B) Noel şarkısı (yavaş) ---------- */
const B1 = 236, B2 = 236, BG = 48, BE = 96;
const BT1 = B1, BT2 = BT1 + B2, BT3 = BT2 + 2 * BG;
export const VIRAL_SONG_DUR = BT3 + BE;
const SONG: [number, number, string, string][] = [
  [6, 96, "♪ La… la… laaa…", "♪ La… la… laaa…"],
  [112, 110, "(day 1 of decorating)", "(süslemenin 1. günü)"],
  [BT1 + 14, 100, "♪ Almost… done…", "♪ Bitti… sayılır…"],
  [BT1 + 130, 96, "(one ball. just one.)", "(bir top. tek bir top.)"],
];
export const ViralSong: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={B1}><FC clip="wb_sing1" dur={B1 + 10} vol={1} />
      <FabricWord text={L(lang, "My Christmas song:", "Noel şarkım:")} at={0} y={120} size={L(lang, 100, 110)} seed={2} x={90} width={840} />
    </Seg>
    <Seg from={BT1} dur={B2}><FC clip="wb_sing2" dur={B2 + 10} vol={1} /></Seg>
    {SONG.map(([at, d, en, tr], i) => <Sub key={i} at={at} dur={d} text={L(lang, en, tr)} />)}
    <Gameplay lang={lang} from={BT2} d={BG} />
    <Seg from={BT3} dur={BE}><XmasEndCard lang={lang} line={["Decorate at your own pace.", "Kendi hızında süsle."]} /></Seg>
    <Sequence from={BT3 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={BT3 + 10} src="reward" vol={0.45} />
    <Music at={BT2 - 20} dur={VIRAL_SONG_DUR - BT2 + 20} vol={0.28} fadeIn={40} />
  </AbsoluteFill>
);

/* ---------- C) "Gerçekmiş!" (Noel Baba ile karşılaşma) ---------- */
const C1 = 236, CG = 48, CE = 96;
const CT1 = C1, CT2 = CT1 + 2 * CG;
export const VIRAL_SANTA_DUR = CT2 + CE;
export const ViralSanta: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={C1}><FC clip="wc_meet" dur={C1 + 10} vol={1} />
      <FabricWord text={L(lang, "Me sneaking down for cookies:", "Gece kurabiyeye inen ben:")} at={0} y={110} size={L(lang, 82, 86)} seed={9} x={80} width={920} />
    </Seg>
    <Sub at={2} dur={46} text={L(lang, "“He exists!”", "“O gerçekmiş!”")} />
    <Sub at={64} dur={44} text={L(lang, "“…he exists.”", "“…o da gerçekmiş.”")} />
    <Gameplay lang={lang} from={CT1} d={CG} />
    <Seg from={CT2} dur={CE}><XmasEndCard lang={lang} line={["Some things are real.", "Bazı şeyler gerçek."]} /></Seg>
    <Sequence from={CT2 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={CT2 + 10} src="reward" vol={0.45} />
    <Music at={CT1 - 20} dur={VIRAL_SANTA_DUR - CT1 + 20} vol={0.28} fadeIn={40} />
  </AbsoluteFill>
);

/* ---------- D) "Pardon, kendime aldım" ---------- */
const D1 = 210, D2 = 210, DG = 48, DE = 96;
const DT1 = D1, DT2 = DT1 + D2, DT3 = DT2 + 2 * DG;
export const VIRAL_SELF_DUR = DT3 + DE;
export const ViralSelfGift: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={D1}><FC clip="wd_tiny" dur={D1 + 10} />
      <FabricWord text={L(lang, "Gifts for my friends:", "Arkadaşlarıma hediyeler:")} at={0} y={120} size={L(lang, 92, 88)} seed={4} x={80} width={920} />
    </Seg>
    <Seg from={DT1} dur={D2}><FC clip="wd_self" dur={D2 + 10} />
      <FabricWord text={L(lang, "Gift for me:", "Kendime hediye:")} at={4} y={120} size={L(lang, 110, 110)} seed={6} x={90} width={840} />
      <FabricWord text={L(lang, "Sorry. I gifted myself.", "Pardon. Kendime aldım.")} at={D2 - 80} y={1500} size={L(lang, 88, 92)} seed={3} x={80} width={920} />
    </Seg>
    <Gameplay lang={lang} from={DT2} d={DG} />
    <Seg from={DT3} dur={DE}><XmasEndCard lang={lang} line={["Gift yourself a game.", "Kendine oyun hediye et."]} /></Seg>
    <Sequence from={DT3 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={DT3 + 10} src="reward" vol={0.45} />
    <Music at={0} dur={VIRAL_SELF_DUR} vol={0.22} />
  </AbsoluteFill>
);
