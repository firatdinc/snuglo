import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { AdProps, C, Confetti, FONT } from "./common";
import { L, Snd } from "./vShared";
import { FC, Music, Seg } from "./vShared2";
import { LinkEndCard } from "./ViralPlay";

/**
 * 16) "Kaos Odası": Snuglo mutfaktan döner, oda kaos; 30 saniye önceye sarılır, tilki+ayı telefon için
 * çekişir (ağaç devrilir, un patlar); Snuglo sakince telefonunu alıp oynar.
 * Klipler: Flow zv_A..D; telefon yeşil ekranı Python ile gerçek oyun kaydıyla doldurulmuş (zg_*).
 */
const A_DUR = 138;
const RW = A_DUR;            // geri sarma
const RW_DUR = 30;
const B0 = RW + RW_DUR;      // 168
const B_DUR = 174;
const C0 = B0 + B_DUR;       // 342
const C_DUR = 165;
const D0 = C0 + C_DUR;       // 507
const D_DUR = 258;
const END = D0 + D_DUR;      // 765
export const VIRAL_CHAOS_END = END;
export const VIRAL_CHAOS_DUR = END + 126;

const Cap: React.FC<{ at: number; dur: number; text: string; y?: number; size?: number; pop?: boolean }> = ({ at, dur, text, y = 1540, size = 66, pop }) => (
  <Sequence from={at} durationInFrames={dur}><CapIn dur={dur} text={text} y={y} size={size} pop={pop} /></Sequence>
);
const CapIn: React.FC<{ dur: number; text: string; y: number; size: number; pop?: boolean }> = ({ dur, text, y, size, pop }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 5, dur - 6, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const s = pop ? interpolate(f, [0, 6, 12], [0.6, 1.08, 1], { extrapolateRight: "clamp" }) : 1;
  return (
    <div style={{ position: "absolute", left: 70, right: 70, top: y, textAlign: "center", opacity: o, transform: `scale(${s})`, fontFamily: FONT, fontWeight: 700, fontSize: size, lineHeight: 1.12, color: "#fff", WebkitTextStroke: `10px ${C.ink}`, paintOrder: "stroke fill" }}>
      {text}
    </div>
  );
};

/** Geri sarma: tersine hızlı klip + tarama çizgileri + hafif sararma. */
const Rewind: React.FC = () => {
  const f = useCurrentFrame();
  const flick = 0.1 + 0.06 * Math.sin(f * 2.3);
  const bar = (f * 90) % 1920;
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ background: "repeating-linear-gradient(0deg, rgba(0,0,0,0.14) 0px, rgba(0,0,0,0.14) 2px, rgba(0,0,0,0) 2px, rgba(0,0,0,0) 6px)" }} />
      <AbsoluteFill style={{ background: `rgba(255,236,190,${flick})`, mixBlendMode: "screen" }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: bar, height: 90, background: "linear-gradient(180deg, rgba(255,255,255,0), rgba(255,255,255,0.22), rgba(255,255,255,0))" }} />
    </AbsoluteFill>
  );
};

const Chaos16: React.FC<AdProps & { linkText: boolean }> = ({ lang, linkText }) => {
  const g = (k: string) => `zg_${k}_${lang}`;
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {/* 1) Hook */}
      <Seg first from={0} dur={A_DUR}><FC clip={g("A")} dur={A_DUR + 10} vol={0.8} ain={2} aout={6} zoom={[1, 1.07]} /></Seg>
      <Cap at={10} dur={96} y={150} size={L(lang, 70, 72)} text={L(lang, "I was in the kitchen for 30 seconds.", "Sadece 30 saniye mutfağa gittim.")} />

      {/* 2) 30 saniye önce */}
      <Seg from={RW} dur={RW_DUR} fade={4}>
        <AbsoluteFill><FC clip="zr_rewind" dur={RW_DUR + 6} vol={0} ain={1} aout={2} /><Rewind /></AbsoluteFill>
      </Seg>
      <Cap at={RW + 2} dur={RW_DUR + 24} y={820} size={L(lang, 104, 104)} pop text={L(lang, "30 seconds earlier", "30 saniye önce")} />
      <Snd at={RW} src="crackle" vol={0.5} dur={40} />
      <Snd at={RW + 4} src="rustle" vol={0.4} />

      {/* B: telefonu bırakıp çıkıyor, ikili görüyor */}
      <Seg from={B0} dur={B_DUR} fade={8}><FC clip={g("B")} trim={27} dur={B_DUR + 10} vol={0.6} ain={4} aout={8} /></Seg>
      <Cap at={B0 + 6} dur={84} y={150} size={L(lang, 66, 66)} text={L(lang, "I left my phone on the sofa.", "Telefonumu kanepeye bıraktım.")} />
      <Cap at={B0 + 104} dur={66} y={150} size={L(lang, 66, 66)} text={L(lang, "Two witnesses.", "İki şahit.")} />

      {/* C: çekişme -> kaos */}
      <Seg from={C0} dur={C_DUR} fade={6}><FC clip={g("C")} dur={C_DUR + 10} vol={0.7} ain={2} aout={10} /></Seg>
      <Cap at={C0 + 6} dur={74} y={150} size={L(lang, 66, 66)} text={L(lang, "Then the tug of war began.", "Sonra çekişme başladı.")} />
      <Cap at={C0 + 100} dur={60} y={150} size={L(lang, 66, 66)} text={L(lang, "The tree is gone. The flour is gone.", "Ağaç gitti. Un gitti.")} />
      <Snd at={C0 + 88} src="felt_pop" vol={0.8} />
      <Snd at={C0 + 94} src="ribbon" vol={0.6} />

      {/* D: sakin dönüş */}
      <Seg from={D0} dur={D_DUR} fade={8}><FC clip={g("D")} rate={0.92} dur={D_DUR + 10} vol={0.6} ain={4} aout={14} /></Seg>
      <Cap at={D0 + 14} dur={92} y={150} size={L(lang, 66, 66)} text={L(lang, "I just took my phone back.", "Ben telefonumu aldım.")} />
      <Cap at={D0 + 138} dur={D_DUR - 130} y={150} size={L(lang, 68, 68)} text={L(lang, "The only calm corner of Christmas.", "Noel'in tek huzurlu köşesi.")} />

      <Music at={20} dur={VIRAL_CHAOS_DUR - 20} vol={0.2} fadeIn={60} fadeOut={30} />

      {/* Bitiş */}
      <Seg from={END} dur={126} fade={14}><LinkEndCard lang={lang} line={["Calm Christmas. Cozy up.", "Sakin Noel. Keyfine bak."]} linkText={linkText} /></Seg>
      <Sequence from={END + 10}><Confetti at={0} x={495} y={1000} n={50} /></Sequence>
      <Snd at={END + 12} src="reward" vol={0.35} />
    </AbsoluteFill>
  );
};

export const ViralChaos: React.FC<AdProps> = ({ lang }) => <Chaos16 lang={lang} linkText />;
export const ViralChaosLink: React.FC<AdProps> = ({ lang }) => <Chaos16 lang={lang} linkText={false} />;
