import React from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import { AdProps, C, FONT } from "./common";
import { FC, Music, Seg } from "./vShared2";
import { LinkEndCard } from "./ViralPlay";

/**
 * 17) "Sokak Röportajı": TR viral yapay zekâ röportaj formatı. Tilki muhabir Snuglo'ya
 * "Yılbaşında ne yapacaksınız?" diye sorar; cevap: "Önce bir bölüm oynayacağım… Sonra bir bölüm daha."
 * Klip: WaveSpeed Veo 3.1 Fast (Türkçe sesli), telefon yeşil ekranı gerçek oyun kaydıyla dolduruldu.
 */
const CLIP = 240;
const END = CLIP - 8;
export const VIRAL_INTERVIEW_DUR = END + 126;

const Sub: React.FC<{ at: number; dur: number; who: string; text: string }> = ({ at, dur, who, text }) => (
  <Sequence from={at} durationInFrames={dur}><SubIn dur={dur} who={who} text={text} /></Sequence>
);
const SubIn: React.FC<{ dur: number; who: string; text: string }> = ({ dur, who, text }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 4, dur - 4, dur], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: 1390, textAlign: "center", opacity: o, fontFamily: FONT, fontWeight: 700, fontSize: 60, lineHeight: 1.15, color: "#fff", WebkitTextStroke: `10px ${C.ink}`, paintOrder: "stroke fill" }}>
      <span style={{ fontSize: 40, color: "#ffd76a" }}>{who}</span><br />{text}
    </div>
  );
};

/** Haber kuşağı: CANLI rozeti + başlık bandı. */
const NewsBar: React.FC = () => {
  const f = useCurrentFrame();
  const x = interpolate(f, [0, 10], [-1080, 0], { extrapolateRight: "clamp" });
  const blink = Math.floor(f / 15) % 2 === 0 ? 1 : 0.35;
  return (
    <>
      <div style={{ position: "absolute", top: 120, left: 60, display: "flex", alignItems: "center", gap: 14, background: "#c62828", color: "#fff", fontFamily: FONT, fontWeight: 800, fontSize: 40, padding: "10px 24px", borderRadius: 10 }}>
        <span style={{ width: 20, height: 20, borderRadius: 10, background: "#fff", opacity: blink }} /> CANLI
      </div>
      <div style={{ position: "absolute", top: 1640, left: 0, right: 0, transform: `translateX(${x}px)` }}>
        <div style={{ background: "#c62828", color: "#fff", fontFamily: FONT, fontWeight: 800, fontSize: 38, padding: "10px 40px", display: "inline-block" }}>NOEL KÖYÜ</div>
        <div style={{ background: "rgba(255,255,255,0.94)", color: C.ink, fontFamily: FONT, fontWeight: 700, fontSize: 44, padding: "16px 40px" }}>Vatandaşa sorduk: Yılbaşında ne yapacaksınız?</div>
      </div>
    </>
  );
};

const Interview: React.FC<AdProps & { linkText: boolean }> = ({ lang, linkText }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Seg first from={0} dur={END}><FC clip={`ws_interview1_g_${lang === "tr" ? "tr" : "tr"}`} dur={CLIP} vol={1} ain={1} aout={6} /></Seg>
    <Sequence from={0} durationInFrames={210}><NewsBar /></Sequence>
    <Sub at={4} dur={54} who="Muhabir" text="Yılbaşında ne yapacaksınız?" />
    <Sub at={60} dur={54} who="Snuglo" text="Önce… bir bölüm oynayacağım." />
    <Sub at={114} dur={24} who="Muhabir" text="Sonra?" />
    <Sub at={138} dur={62} who="Snuglo" text="Sonra… bir bölüm daha." />
    <Seg from={END} dur={126} fade={10}><LinkEndCard lang={lang} line={["Christmas is here. Cozy up.", "Noel geldi. Keyfine bak."]} linkText={linkText} /></Seg>
    <Music at={END - 4} dur={130} vol={0.3} fadeIn={12} fadeOut={20} />
  </AbsoluteFill>
);

export const ViralInterview: React.FC<AdProps> = ({ lang }) => <Interview lang={lang} linkText />;
export const ViralInterviewLink: React.FC<AdProps> = ({ lang }) => <Interview lang={lang} linkText={false} />;
