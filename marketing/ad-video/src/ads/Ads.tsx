import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { AdProps, C, Clip, Confetti, EndCard, FONT, FullClip, Music, Native, Pop, Sfx, usePulse } from "./common";
import { Sticker } from "../kit";

const L = <T,>(lang: string, en: T, tr: T) => (lang === "tr" ? tr : en);

/* ---------------------------------------------------------------- A · Son parça (merak) */
export const AD_LAST_DUR = 105 + 90 + 96 + 90;
export const AdLastPiece: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const q = L(lang, ["WHERE DOES THE", "LAST PIECE GO?"], ["SON PARÇA", "NEREYE GİDER?"]);
  const frz = f - 105;
  const n = frz >= 0 && frz < 90 ? 3 - Math.floor(frz / 30) : 0;
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Sequence durationInFrames={105}><FullClip src={`lp_a_${lang}`} vol={0.7} /></Sequence>
      <Sequence from={105} durationInFrames={90}>
        <AbsoluteFill style={{ scale: String(interpolate(frz, [0, 90], [1, 1.18])), transformOrigin: "50% 30%" }}>
          <Img src={staticFile(`clips/lp_still_${lang}.png`)} style={{ width: "100%", height: "100%" }} />
        </AbsoluteFill>
        <AbsoluteFill style={{ background: "rgba(40,20,10,0.25)" }} />
        {[0, 30, 60].map((t) => <Sequence key={t} from={t} durationInFrames={30}><Sfx src="click" vol={0.9} /></Sequence>)}
      </Sequence>
      <Sequence from={195} durationInFrames={96}><FullClip src={`lp_b_${lang}`} vol={0.9} /></Sequence>
      {f < 195 && <><Pop text={q[0]} at={0} y={150} size={L(lang, 100, 112)} /><Pop text={q[1]} at={8} y={265} size={L(lang, 112, 112)} color={C.mustard} /></>}
      {n > 0 && <Pop key={n} text={String(n)} at={105 + (3 - n) * 30} y={820} size={360} color="#fff" stroke={C.terracotta} />}
      {f >= 205 && f < 291 && <Pop text={L(lang, "NAILED IT! ✓", "TAM İSABET! ✓")} at={205} y={200} size={120} color={C.sage} stroke={C.ink} />}
      <Confetti at={215} x={540} y={700} n={90} />
      <Sequence from={291}><EndCard lang={lang} /></Sequence>
      <Music from={4} vol={0.55} />
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- B · Yanlış hamle (yorum tuzağı) */
export const AD_WRONG_DUR = 168 + 90;
export const AdWrongMove: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Sequence durationInFrames={168}><FullClip src={`wm_${lang}`} vol={0.9} /></Sequence>
      {f < 168 && (
        <>
          <Native text={L(lang, "I wouldn't put it there…", "Ben olsam oraya koymazdım…")} at={0} out={80} y={300} size={70} />
          <Sticker text="❌" at={40} out={85} bg={C.plum} x={720} y={1150} rot={8} size={90} />
          <Native text={L(lang, "ok THAT was satisfying", "tamam, bu çok tatmin ediciydi")} at={95} out={130} y={300} size={70} />
          <Native text={L(lang, "where would YOU put the next one? 👇", "sen sıradakini nereye koyardın? 👇")} at={130} y={300} size={70} />
        </>
      )}
      <Sequence from={168}><EndCard lang={lang} pose="think" /></Sequence>
      <Music from={0} vol={0.4} />
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- C · ASMR (sessiz tatmin) */
export const AD_ASMR_DUR = 441 + 75;
export const AdAsmr: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Sequence durationInFrames={441}><FullClip src={`asmr_${lang}`} vol={1.0} zoom={[1.0, 1.08]} /></Sequence>
      {f < 75 && <Native text={L(lang, "🔊 sound on", "🔊 sesi aç")} y={300} size={60} />}
      {f >= 380 && f < 441 && <Native text={L(lang, "*chef's kiss*", "*mükemmel*")} y={300} size={60} />}
      <Sequence from={441}>
        <AbsoluteFill style={{ background: C.cream, alignItems: "center", justifyContent: "center" }}>
          <Img src={staticFile("art/logo.png")} style={{ width: 760, scale: String(interpolate(f - 441, [0, 20], [0.9, 1], { extrapolateRight: "clamp" })) }} />
          <div style={{ marginTop: 40, fontFamily: FONT, fontWeight: 700, fontSize: 60, color: C.ink }}>{L(lang, "Free on the App Store", "App Store'da ücretsiz")}</div>
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- D · Meydan okuma (30 saniye) */
export const AD_CH_DUR = 482 + 90;
export const AdChallenge: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const SPEED = 1.25;
  const left = Math.max(0, 30 - (f / fps) * SPEED);
  const done = f >= 452;
  const shown = done ? 30 - (452 / fps) * SPEED : left;
  const urgent = shown < 15;
  const pulse = usePulse();
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Sequence durationInFrames={482}><FullClip src={`ch_${lang}`} vol={0.8} /></Sequence>
      {f < 482 && (
        <>
          {f < 75 && <><Pop text={L(lang, "SOLVE IT IN", "30 SANİYEDE")} at={0} y={150} size={110} /><Pop text={L(lang, "30 SECONDS?", "ÇÖZEBİLİR MİSİN?")} at={8} y={260} size={L(lang, 120, 98)} color={C.mustard} /></>}
          <div style={{ position: "absolute", right: 70, top: 380, width: 250, height: 120, borderRadius: 60, background: urgent ? C.terracotta : C.cream,
            border: `8px solid ${C.ink}`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: FONT, fontWeight: 700,
            fontSize: 72, color: urgent ? "#fff" : C.ink, scale: String(1 + (urgent && !done ? pulse * 0.1 : 0)), rotate: "4deg" }}>
            0:{String(Math.ceil(shown)).padStart(2, "0")}
          </div>
          {done && <Pop text={L(lang, `SOLVED WITH ${Math.ceil(shown)}s LEFT!`, `${Math.ceil(shown)} SN KALA ÇÖZÜLDÜ!`)} at={452} y={170} size={L(lang, 78, 84)} color={C.sage} />}
          {done && <Pop text={L(lang, "YOUR TURN 👇", "SIRA SENDE 👇")} at={462} y={280} size={110} color={C.mustard} />}
        </>
      )}
      <Confetti at={452} x={540} y={760} n={90} />
      <Sequence from={482}><EndCard lang={lang} /></Sequence>
      <Music from={4} vol={0.5} />
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- E · UGC / yerli */
export const AD_UGC_DUR = 120 + 188 + 60;
export const AdUgc: React.FC<AdProps> = ({ lang }) => {
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Sequence durationInFrames={120}><FullClip src={`ugc1_${lang}`} vol={0.8} /></Sequence>
      <Sequence from={120} durationInFrames={248}><FullClip src={`ugc2_${lang}`} vol={0.8} /></Sequence>
      <Native text={L(lang, "pov: you said “just one level” 45 minutes ago", "pov: “bir bölüm daha” dedin, 45 dakika oldu")} out={150} y={250} size={66} />
      <Native text={L(lang, "the little snap sound is so addictive 😭", "o küçük “tık” sesi bağımlılık yapıyor 😭")} at={150} out={300} y={250} size={66} />
      <Native text={L(lang, "it's called Snuglo, free on the App Store", "adı Snuglo, App Store'da ücretsiz")} at={300} y={250} size={66} />
      <Music from={4} vol={0.3} />
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- G · App Store önizleme (886×1920) */
const CapPill: React.FC<{ text: string }> = ({ text }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: f, fps, config: { damping: 11, stiffness: 200 } });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 150, display: "flex", justifyContent: "center", scale: String(s) }}>
      <div style={{ background: C.cream, border: `6px solid ${C.terracotta}`, borderRadius: 999, padding: "16px 44px", fontFamily: FONT, fontWeight: 700,
        fontSize: 58, color: C.ink, boxShadow: "0 10px 0 rgba(58,36,26,0.35)" }}>{text}</div>
    </div>
  );
};
export const AP_PLAN: [string, number, string][] = [
  ["ap_hook", 132, "Fit every patch"], ["ap_solve", 180, "Snap, combo, solve!"], ["ap_peek", 81, "Stuck? Take a Peek"],
  ["ap_chest", 150, "Open lucky chests"], ["ap_map", 90, "1,000+ levels, 17 worlds"], ["ap_menu", 105, "Cozy, calm, free"],
];
export const AP_DUR = AP_PLAN.reduce((a, [, d]) => a + d, 0);
export const AppPreview: React.FC = () => {
  let at = 0;
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {AP_PLAN.map(([src, d, cap]) => {
        const from = at; at += d;
        return (
          <Sequence key={src} from={from} durationInFrames={d}>
            <Clip src={src} vol={0.8} />
            <CapPill text={cap} />
          </Sequence>
        );
      })}
      <Music from={4} vol={0.5} />
    </AbsoluteFill>
  );
};
