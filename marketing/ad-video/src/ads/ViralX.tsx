import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { AdProps, C, Confetti, FONT } from "./common";
import { FabricWord } from "./FabricWord";
import { GameFrame, L, Snd, XmasEndCard } from "./vShared";
import { FC, Music, Seg } from "./vShared2";

/** Daha akıcı seri: az kesme, uzun Flow çekimleri, tek oyun vuruşu. */

/** Altyazı / punchline: yumuşak giriş-çıkış, hafif büyüme. */
const Cap: React.FC<{ at: number; dur: number; text: string; y?: number; size?: number; pop?: boolean }> = ({ at, dur, text, y = 1540, size = 66, pop }) => (
  <Sequence from={at} durationInFrames={dur}>
    <CapIn dur={dur} text={text} y={y} size={size} pop={pop} />
  </Sequence>
);
const CapIn: React.FC<{ dur: number; text: string; y: number; size: number; pop?: boolean }> = ({ dur, text, y, size, pop }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 5, dur - 6, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const s = pop ? interpolate(f, [0, 6, 12], [0.6, 1.08, 1], { extrapolateRight: "clamp" }) : 1;
  return (
    <div style={{ position: "absolute", left: 50, right: 50, top: y, textAlign: "center", opacity: o, transform: `scale(${s})`, fontFamily: FONT, fontWeight: 700, fontSize: size, lineHeight: 1.12, color: "#fff", WebkitTextStroke: `10px ${C.ink}`, paintOrder: "stroke fill" }}>
      {text}
    </div>
  );
};

/** Fragman yazısı: siyah zemin üstüne değil, klibin üstüne büyük, harf aralıklı. */
const Trailer: React.FC<{ at: number; dur: number; text: string; y?: number }> = ({ at, dur, text, y = 780 }) => (
  <Sequence from={at} durationInFrames={dur}>
    <TrailerIn dur={dur} text={text} y={y} />
  </Sequence>
);
const TrailerIn: React.FC<{ dur: number; text: string; y: number }> = ({ dur, text, y }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 4, dur - 5, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const s = interpolate(f, [0, dur], [1.0, 1.08]);
  return (
    <AbsoluteFill style={{ background: `rgba(0,0,0,${0.35 * o})` }}>
      <div style={{ position: "absolute", left: 40, right: 40, top: y, textAlign: "center", opacity: o, transform: `scale(${s})`, fontFamily: FONT, fontWeight: 700, fontSize: 92, letterSpacing: 6, lineHeight: 1.1, color: "#FFE7B0", WebkitTextStroke: `6px #3A1E0E`, paintOrder: "stroke fill" }}>
        {text}
      </div>
    </AbsoluteFill>
  );
};

/** Tek oyun vuruşu (akış bozulmasın diye bir tane). */
const Play: React.FC<{ lang: AdProps["lang"]; clip: string; trim?: number; from: number; d: number; en: string; tr: string }> = ({ lang, clip, trim = 20, from, d, en, tr }) => (
  <Seg from={from} dur={d} fade={12}>
    <GameFrame clip={`${clip}_${lang}`} trim={trim}>
      <FabricWord text={L(lang, en, tr)} at={2} y={130} size={L(lang, 100, 100)} seed={5} x={80} width={920} />
    </GameFrame>
  </Seg>
);

const End: React.FC<{ lang: AdProps["lang"]; at: number; line: [string, string] }> = ({ lang, at, line }) => (
  <>
    <Seg from={at} dur={96} fade={12}><XmasEndCard lang={lang} line={line} /></Seg>
    <Sequence from={at + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>
    <Snd at={at + 10} src="reward" vol={0.4} />
  </>
);

/* ---------- 11) Geç kalan duygusal Noel reklamı ---------- */
const E1 = 236, E2 = 236, EG = 66;
const ET1 = E1, ET2 = ET1 + E2, ET3 = ET2 + EG;
export const VIRAL_LATE_DUR = ET3 + 96;
export const ViralLate: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={E1}><FC clip="xe_walk" dur={E1 + 10} vol={1} ain={2} aout={6} /></Seg>
    <Cap at={6} dur={110} y={150} size={L(lang, 70, 72)} text={L(lang, "He set off to be home for Christmas.", "Noel'e yetişmek için yola çıktı.")} />
    <Seg from={ET1} dur={E2} fade={8}><FC clip="xe_door" dur={E2 + 10} vol={1} ain={2} /></Seg>
    <Cap at={ET1 + 70} dur={80} y={150} size={150} pop text={L(lang, "April.", "Nisan.")} />
    <Cap at={ET1 + 158} dur={84} y={1520} size={L(lang, 70, 72)} text={L(lang, "Made it. Ish.", "Yetiştim. Sayılır.")} />
    <Play lang={lang} clip="xm_village" from={ET2} d={EG} en="Christmas is already here." tr="Noel çoktan geldi." />
    <Music at={ET2 - 30} dur={VIRAL_LATE_DUR - ET2 + 30} vol={0.26} fadeIn={40} />
    <End lang={lang} at={ET3} line={["Don't be late this year.", "Bu sefer geç kalma."]} />
  </AbsoluteFill>
);

/* ---------- 12) Noel reklamı çekimi: "Çekim 47" ---------- */
const F1 = 236, F2 = 236, FG = 66;
const FT1 = F1, FT2 = FT1 + F2, FT3 = FT2 + FG;
export const VIRAL_TAKE_DUR = FT3 + 96;
export const ViralTake: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={F1}><FC clip="xf_take1" dur={F1 + 10} vol={1} ain={2} aout={6} /></Seg>
    <Cap at={2} dur={70} y={150} size={L(lang, 74, 74)} text={L(lang, "Our Christmas ad. Take 47.", "Noel reklamımız. Çekim 47.")} />
    <Cap at={78} dur={84} y={1520} size={L(lang, 68, 66)} text={L(lang, "“Okay. Look EXCITED!”", "“Tamam. Şimdi HEYECANLI ol!”")} />
    <Seg from={FT1} dur={F2} fade={8}><FC clip="xf_take2" dur={F2 + 10} vol={1} ain={2} /></Seg>
    <Cap at={FT1 + 110} dur={110} y={150} size={140} pop text={L(lang, "Take 48.", "Çekim 48.")} />
    <Play lang={lang} clip="xm_treelit" trim={40} from={FT2} d={FG} en="We do cozy. Slowly." tr="Biz sadece rahatlarız." />
    <Music at={FT2 - 30} dur={VIRAL_TAKE_DUR - FT2 + 30} vol={0.26} fadeIn={40} />
    <End lang={lang} at={FT3} line={["Excitement, at your pace.", "Heyecan, kendi hızında."]} />
  </AbsoluteFill>
);

/* ---------- 13) Fragman: "Tek bir kahraman" ---------- */
const G1 = 236, G2 = 236, GG = 66;
const GT1 = G1, GT2 = GT1 + G2, GT3 = GT2 + GG;
export const VIRAL_HERO_DUR = GT3 + 96;
export const ViralHero: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={G1}><FC clip="xg_fall1" dur={G1 + 10} vol={1} ain={2} aout={6} /></Seg>
    <Trailer at={4} dur={56} text={L(lang, "THIS CHRISTMAS…", "BU NOEL…")} />
    <Trailer at={74} dur={60} text={L(lang, "ONE HERO…", "TEK BİR KAHRAMAN…")} />
    <Trailer at={148} dur={70} text={L(lang, "WILL SAVE THE STAR.", "YILDIZI KURTARACAK.")} />
    <Seg from={GT1} dur={G2} fade={8}><FC clip="xg_fall2" dur={G2 + 10} vol={1} ain={2} /></Seg>
    <Cap at={GT1 + 120} dur={110} y={150} size={120} pop text={L(lang, "…eventually.", "…bir ara.")} />
    <Play lang={lang} clip="xm_treeslow" trim={30} from={GT2} d={GG} en="Save Christmas. Slowly." tr="Noel'i kurtar. Yavaş yavaş." />
    <Music at={GT2 - 30} dur={VIRAL_HERO_DUR - GT2 + 30} vol={0.26} fadeIn={40} />
    <End lang={lang} at={GT3} line={["Heroes take their time.", "Kahramanlar acele etmez."]} />
  </AbsoluteFill>
);

/* ---------- 14) Blok bulmaca refleksi: hediyeler "satır temizlendi" ---------- */
const H1 = 236, H2 = 236, HG = 66;
const HT1 = H1, HT2 = HT1 + H2, HT3 = HT2 + HG;
export const VIRAL_FIT_DUR = HT3 + 96;
export const ViralFit: React.FC<AdProps> = ({ lang }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={H1}><FC clip="xh_fit1" dur={H1 + 10} vol={1} ain={2} aout={6} /></Seg>
    <Cap at={2} dur={120} y={150} size={L(lang, 66, 68)} text={L(lang, "Me wrapping gifts after 300 block puzzle levels:", "300 blok bulmacadan sonra hediye dizen ben:")} />
    <Seg from={HT1} dur={H2} fade={8}><FC clip="xh_fit2" dur={H2 + 10} vol={1} ain={2} /></Seg>
    <Cap at={134} dur={70} y={150} size={140} pop text={L(lang, "LINE CLEAR.", "SATIR TAMAM.")} />
    <Cap at={170} dur={74} y={1520} size={L(lang, 68, 68)} text={L(lang, "Your gifts are… gone.", "Hediyeleriniz… gitti.")} />
    <Cap at={HT1 + 30} dur={120} y={150} size={L(lang, 86, 86)} pop text={L(lang, "…one more line?", "…bir satır daha?")} />
    <Play lang={lang} clip="xm_solve" trim={20} from={HT2} d={HG} en="Clear lines. Not gifts." tr="Satırları temizle. Hediyeleri değil." />
    <Music at={HT2 - 30} dur={VIRAL_FIT_DUR - HT2 + 30} vol={0.26} fadeIn={40} />
    <End lang={lang} at={HT3} line={["Satisfying. Every time.", "Her seferinde tatmin edici."]} />
  </AbsoluteFill>
);
