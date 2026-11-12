import React from "react";
import { AbsoluteFill, Img, OffthreadVideo, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { StoreBadge } from "./ViralPlay";
import { FabricWord } from "./FabricWord";
import { Snd } from "./vShared";
import { AdProps, C, FONT } from "./common";
import { FC, Seg } from "./vShared2";

/**
 * 18) "Bu tiple mi yeni yıla girecek": TR haber meme'i, Kling video-edit ile tüm kişiler
 * Noel şapkalı farklı Snuglo tembel hayvanlarına çevrildi; orijinal ses korunur.
 * Başlık parodisi: "YORGANDA 45 SAAT MAHSUR KALDILAR".
 */
const CLIP = 300;
const END = 296;
const C0 = END;           // Snuglo tanıtımı (müziksiz)
const CDUR = 186;
export const VIRAL_MEME_DUR = C0 + CDUR;
const S = 30;

const SubIn: React.FC<{ dur: number; text: string }> = ({ dur, text }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 3, dur - 3, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 50, right: 50, top: 1200, textAlign: "center", opacity: o, fontFamily: FONT, fontWeight: 700, fontSize: 58, lineHeight: 1.15, color: "#fff", WebkitTextStroke: `10px ${C.ink}`, paintOrder: "stroke fill" }}>
      {text}
    </div>
  );
};
const Sub: React.FC<{ a: number; b: number; text: string }> = ({ a, b, text }) => (
  <Sequence from={Math.round(a * S)} durationInFrames={Math.round((b - a) * S)}><SubIn dur={Math.round((b - a) * S)} text={text} /></Sequence>
);

const NewsFrame: React.FC<{ en: boolean }> = ({ en }) => {
  const f = useCurrentFrame();
  const blink = Math.floor(f / 15) % 2 === 0 ? 1 : 0.35;
  const tick = (f * 3) % 1400;
  return (
    <>
      <div style={{ position: "absolute", top: 440, left: 50, display: "flex", alignItems: "center", gap: 14, background: "#c62828", color: "#fff", fontFamily: FONT, fontWeight: 800, fontSize: 40, padding: "10px 24px", borderRadius: 10 }}>
        <span style={{ width: 20, height: 20, borderRadius: 10, background: "#fff", opacity: blink }} /> {en ? "BREAKING NEWS" : "SON DAKİKA"}
      </div>
      <div style={{ position: "absolute", top: 1400, left: 0, right: 0 }}>
        <div style={{ background: "#c62828", color: "#fff", fontFamily: FONT, fontWeight: 800, fontSize: 64, padding: "18px 40px", lineHeight: 1.05 }}>{en ? <>STUCK UNDER A QUILT<br />FOR 45 HOURS</> : <>YORGANDA 45 SAAT<br />MAHSUR KALDILAR</>}</div>
        <div style={{ background: "rgba(255,255,255,0.95)", color: C.ink, fontFamily: FONT, fontWeight: 700, fontSize: 36, padding: "12px 0", whiteSpace: "nowrap", overflow: "hidden" }}>
          <span style={{ display: "inline-block", transform: `translateX(${1080 - tick}px)` }}>{en ? "Heavy snow continues in Christmas Village • Residents refuse to leave their quilts • Snuglo Christmas update out now" : "Noel Köyü'nde kar yağışı sürüyor • Vatandaşlar yorgandan çıkmayı reddediyor • Snuglo'da Noel güncellemesi yayında"}</span>
        </div>
      </div>
    </>
  );
};

const SHOTS: [string, string, string][] = [
  ["xm_tree", "Noel Köyü'nü süsle", "Decorate the Christmas Village"],
  ["xm_cbake", "Kurabiye pişir", "Bake cozy cookies"],
  ["xm_solve", "Rahatlatıcı bulmacalar", "Relaxing puzzles"],
];
const SHOT = 30;

export const Promo: React.FC<{ lang: AdProps["lang"] }> = ({ lang }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const en = lang !== "tr";
  const ph = spring({ frame: f - 2, fps, config: { damping: 13, stiffness: 150 } });
  const P2 = SHOT * SHOTS.length;          // 90: kapanış
  const out1 = interpolate(f, [P2 - 6, P2 + 4], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const logo = spring({ frame: f - P2, fps, config: { damping: 11, stiffness: 160 } });
  const bad = spring({ frame: f - P2 - 10, fps, config: { damping: 12, stiffness: 180 } });
  const word = "Snuglo";
  const n = Math.max(0, Math.min(word.length, Math.floor((f - P2 - 22) / 4)));
  const sb = interpolate(f, [P2 + 14, P2 + 22], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const caret = Math.floor(f / 8) % 2 === 0 ? 1 : 0;
  return (
    <AbsoluteFill>
      <Img src={staticFile("art/scene/snow.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(40,20,10,.25), rgba(40,20,10,.45))" }} />
      {/* 1) telefonda oyun montajı */}
      <AbsoluteFill style={{ opacity: out1 }}>
        <FabricWord text={en ? "Christmas is here in Snuglo" : "Snuglo'da Noel başladı"} at={0} y={150} size={en ? 70 : 74} seed={5} x={60} width={960} />
        <div style={{ position: "absolute", left: 540 - 270, top: 360, width: 540, height: 1170, borderRadius: 70, background: "#111", padding: 16, boxSizing: "border-box", transform: `scale(${ph})`, boxShadow: "0 30px 80px rgba(0,0,0,.5)" }}>
          <div style={{ width: "100%", height: "100%", borderRadius: 56, overflow: "hidden", background: "#000", position: "relative" }}>
            {SHOTS.map(([c], i) => (
              <Sequence key={c} from={i * SHOT} durationInFrames={SHOT + (i === SHOTS.length - 1 ? 10 : 0)}>
                <OffthreadVideo src={staticFile(`clips/${c}_${lang === "tr" ? "tr" : "en"}.mp4`)} muted trimBefore={60} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
              </Sequence>
            ))}
          </div>
        </div>
        {SHOTS.map(([c, tr, enT], i) => (
          <Sequence key={c + "t"} from={i * SHOT} durationInFrames={SHOT}>
            <Chip text={en ? enT : tr} />
            <Snd at={0} src="felt_pop" vol={0.5} />
          </Sequence>
        ))}
      </AbsoluteFill>
      {/* 2) kapanış: logo + rozet + arama */}
      <Sequence from={P2}>
        <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: 190, top: 330, width: 700, transform: `scale(${logo})` }} />
        <Img src={staticFile("art/xmas/mascot/idle.png")} style={{ position: "absolute", left: 400, top: 700, width: 280, transform: `scale(${logo}) rotate(${Math.sin(f / 9) * 1.5}deg)` }} />
        <div style={{ position: "absolute", left: 540 - 280, top: 1040, transform: `scale(${bad})` }}><StoreBadge lang={lang} width={560} /></div>
        <div style={{ position: "absolute", left: 90, right: 90, top: 1300, opacity: sb, textAlign: "center", fontFamily: FONT }}>
          <div style={{ color: "#fff", fontWeight: 800, fontSize: 48, marginBottom: 16, WebkitTextStroke: `9px ${C.ink}`, paintOrder: "stroke fill" }}>{en ? "Search the App Store:" : "App Store'da ara:"}</div>
          <div style={{ display: "flex", alignItems: "center", gap: 22, background: "#fff", borderRadius: 60, padding: "20px 40px", boxShadow: "0 10px 40px rgba(0,0,0,0.45)" }}>
            <svg width="50" height="50" viewBox="0 0 24 24"><circle cx="10" cy="10" r="7" stroke="#8a8a8e" strokeWidth="2.6" fill="none" /><line x1="15.5" y1="15.5" x2="21" y2="21" stroke="#8a8a8e" strokeWidth="2.6" strokeLinecap="round" /></svg>
            <div style={{ fontSize: 62, fontWeight: 800, color: "#1c1c1e", textAlign: "left" }}>{word.slice(0, n)}<span style={{ opacity: caret, color: "#0a84ff" }}>|</span></div>
          </div>
        </div>
        <Snd at={0} src="reward" vol={0.45} />
      </Sequence>
    </AbsoluteFill>
  );
};

const Chip: React.FC<{ text: string }> = ({ text }) => {
  const f = useCurrentFrame();
  const s = interpolate(f, [0, 5, 9], [0.7, 1.06, 1], { extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 1600, display: "flex", justifyContent: "center" }}>
      <div style={{ transform: `scale(${s})`, background: "#fff8ec", color: C.ink, fontFamily: FONT, fontWeight: 800, fontSize: 54, padding: "16px 40px", borderRadius: 40, border: `5px solid ${C.ink}` }}>{text}</div>
    </div>
  );
};

type L = [number, number, string][];
const TR: L = [[0, 0.65, "Kim gelecek?"], [0.65, 1.8, "Yeni yıla gireceğiz abi."], [1.8, 3.2, "Yalan söylüyorlar abi."], [3.2, 6.5, "Abi, yeni yıla gireceğiz de bu millet neye girecek yeni yıla?"], [6.5, 7.8, "Bu adamın tipine baksana abi,"], [7.8, 9.8, "nereye girecek bu adam?"]];
const EN: L = [[0, 0.65, "Who's coming?"], [0.65, 1.8, "We'll make it to New Year, bro."], [1.8, 3.2, "They're lying, bro."], [3.2, 6.5, "Sure, WE'LL make it to New Year... but how's this lot gonna make it?"], [6.5, 7.8, "Just look at this guy's face, bro,"], [7.8, 9.8, "where's HE gonna go looking like that?"]];

const Meme: React.FC<AdProps & { linkText: boolean }> = ({ lang, linkText }) => (
  <AbsoluteFill style={{ background: "#1b1410" }}>
    <Seg first from={0} dur={END}>
      <AbsoluteFill style={{ background: "#1b1410" }}>
        <div style={{ position: "absolute", top: 560, left: 0, width: 1080, height: 778, overflow: "hidden" }}>
          <FC clip="ws_meme_sq" dur={CLIP} vol={1} ain={1} aout={4} />
        </div>
      </AbsoluteFill>
    </Seg>
    <Sequence from={0} durationInFrames={END}><NewsFrame en={lang !== "tr"} /></Sequence>
    {(lang === "tr" ? TR : EN).map(([a, b, t]) => <Sub key={a} a={a} b={b} text={t} />)}
    <Seg from={C0} dur={CDUR} fade={8}><Promo lang={lang} /></Seg>
  </AbsoluteFill>
);

export const ViralMeme: React.FC<AdProps> = ({ lang }) => <Meme lang={lang} linkText />;
export const ViralMemeLink: React.FC<AdProps> = ({ lang }) => <Meme lang={lang} linkText={false} />;
