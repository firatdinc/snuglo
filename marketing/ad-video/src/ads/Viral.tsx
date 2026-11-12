import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio, Video } from "@remotion/media";
import { AdProps, C, Confetti, FONT, Sfx } from "./common";
import { FabricWord } from "./FabricWord";

const L = <T,>(lang: string, en: T, tr: T) => (lang === "tr" ? tr : en);
const PAPER = "#f9edde"; // Flow kliplerinin zemini

/** Üstte oyun, altta Snuglo'nun yüzü. */
const ReactionCam: React.FC<{ clip: string; trim: number; rate?: number; still: string; vol?: number; children?: React.ReactNode }> = ({ clip, trim, rate = 1, still, vol = 0.7, children }) => (
  <AbsoluteFill style={{ background: PAPER }}>
    <Img src={staticFile(`art/viral/${still}.png`)} style={{ position: "absolute", left: 220, top: 880, width: 640, WebkitMaskImage: "linear-gradient(90deg, transparent 0, #000 7%, #000 93%, transparent 100%)", maskImage: "linear-gradient(90deg, transparent 0, #000 7%, #000 93%, transparent 100%)" }} />
    <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: 1020, overflow: "hidden", borderBottom: `12px dashed ${C.terracotta}`, boxSizing: "border-box", background: "#000" }}>
      <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={trim} playbackRate={rate} volume={vol} style={{ position: "absolute", left: 0, top: -150, width: 1080, height: 1920 }} />
    </div>
    {children}
  </AbsoluteFill>
);

/** Tam ekran Flow klibi: sessiz, sadece bakış. */
const Mascot: React.FC<{ clip: string; trim: number; rate?: number }> = ({ clip, trim, rate = 1 }) => (
  <AbsoluteFill style={{ background: PAPER }}>
    <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={trim} playbackRate={rate} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
  </AbsoluteFill>
);

const Still: React.FC<{ src: string }> = ({ src }) => (
  <AbsoluteFill style={{ background: PAPER }}>
    <Img src={staticFile(`art/viral/${src}.png`)} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
  </AbsoluteFill>
);

const EndCard: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = spring({ frame: f, fps, config: { damping: 10, stiffness: 170 } });
  const btn = spring({ frame: f - 14, fps, config: { damping: 9, stiffness: 200 } });
  return (
    <AbsoluteFill>
      <Img src={staticFile("art/scene/flower.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: 140, top: 170, width: 800, transform: `scale(${logo})` }} />
      <FabricWord text={L(lang, "Your turn.", "Sıra sende.")} at={8} y={560} size={120} seed={2} />
      <Img src={staticFile("art/sleep.png")} style={{ position: "absolute", left: 300, top: 760, width: 480 }} />
      <div style={{ position: "absolute", left: 140, top: 1260, width: 800, height: 230, transform: `scale(${btn * (1 + Math.sin(f / 7) * 0.025)})`, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Img src={staticFile("art/btn_terracotta.png")} style={{ position: "absolute", width: "100%", height: "100%" }} />
        <span style={{ position: "relative", fontFamily: FONT, fontWeight: 700, fontSize: L(lang, 84, 74), color: "#fff", WebkitTextStroke: "6px #6E2A17", paintOrder: "stroke fill" }}>
          {L(lang, "PLAY FREE", "ÜCRETSİZ OYNA")}
        </span>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1500, textAlign: "center", fontFamily: FONT, fontWeight: 700, fontSize: 50, color: "#fff", WebkitTextStroke: `7px ${C.ink}`, paintOrder: "stroke fill" }}>
        {L(lang, "on the App Store", "App Store'da")}
      </div>
    </AbsoluteFill>
  );
};

/* Olay örgüsü (kare @30fps). Oyun klibi olayları: hata 2.62s, 6.36s, ~9.7s, bölüm sonu 15.6s. */
const S1 = 52, S2 = S1 + 150, S3 = S2 + 104, S4 = S3 + 108, S5 = S4 + 88, S6 = S5 + 118, S6B = S6 + 60, S7 = S6B + 112, S8 = S7 + 54, S9 = S8 + 190;
export const VIRAL_DISAPPOINTED_DUR = S9 + 84;
const MISS1 = 43, MISS2 = S2 + 92, MISS3 = S4 + 80;

export const ViralDisappointed: React.FC<AdProps> = ({ lang }) => {
  const clip = `viral_story_${lang}`;
  const music = (at: number, dur: number, from: number, vol = 0.32) => (
    <Sequence from={at} durationInFrames={dur}>
      <Audio src={staticFile("snuglo_jingle.wav")} trimBefore={from} volume={(fr) => vol * interpolate(fr, [0, 3], [0.5, 1], { extrapolateRight: "clamp" })} />
    </Sequence>
  );
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {/* 1 · Kanca: ilk yanlış hamle */}
      <Sequence durationInFrames={S1}>
        <ReactionCam clip={clip} trim={36} still="think">
          <FabricWord text={L(lang, "playing in front of Snuglo", "Snuglo'nun önünde oynamak")} at={0} y={1025} size={84} seed={1} x={80} width={920} />
        </ReactionCam>
      </Sequence>

      {/* 2 · Yavaşça döner, surat asar */}
      <Sequence from={S1} durationInFrames={S2 - S1}>
        <Mascot clip="flow_stare" trim={24} rate={1.3} />
        <FabricWord text={L(lang, "…there?", "…oraya mı?")} at={42} out={92} y={150} size={124} seed={4} />
        <FabricWord text={L(lang, "Bold.", "Cesurca.")} at={102} y={150} size={150} seed={6} />
      </Sequence>

      {/* 3 · Doğru hamle, ikinci hata */}
      <Sequence from={S2} durationInFrames={S3 - S2}>
        <ReactionCam clip={clip} trim={99} still="frown">
          <FabricWord text={L(lang, "I said nothing.", "Ben bir şey demedim.")} at={28} y={1030} size={L(lang, 88, 76)} seed={8} />
        </ReactionCam>
      </Sequence>

      {/* 4 · İç çeker */}
      <Sequence from={S3} durationInFrames={S4 - S3}>
        <Mascot clip="flow_facepalm" trim={36} />
        <FabricWord text={L(lang, "I sewed this quilt.", "Bu yorganı ben diktim.")} at={8} out={56} y={170} size={100} seed={3} />
        <FabricWord text={L(lang, "It took three years.", "Üç yılda.")} at={62} y={170} size={L(lang, 100, 140)} seed={9} />
      </Sequence>

      {/* 5 · Üçüncü hata */}
      <Sequence from={S4} durationInFrames={S5 - S4}>
        <ReactionCam clip={clip} trim={210} still="tired" />
      </Sequence>

      {/* 6 · Pes eder, yorgana gömülür */}
      <Sequence from={S5} durationInFrames={S6 - S5}>
        <Mascot clip="flow_flop" trim={30} rate={1.5} />
      </Sequence>
      <Sequence from={S6} durationInFrames={S6B - S6}>
        <Still src="lump" />
        <FabricWord text={L(lang, "Snuglo is closed.", "Snuglo kapalı.")} at={2} y={190} size={L(lang, 112, 130)} seed={5} />
      </Sequence>

      {/* 7 · Oyun boş odaya bağırır */}
      <Sequence from={S6B} durationInFrames={S7 - S6B}>
        <ReactionCam clip={clip} trim={300} rate={1.5} still="lump_small">
          <FabricWord text={L(lang, "Nobody's watching.", "Kimse izlemiyor.")} at={18} y={1030} size={L(lang, 84, 92)} seed={7} />
        </ReactionCam>
      </Sequence>

      {/* 8 · Bölüm tamam */}
      <Sequence from={S7} durationInFrames={S8 - S7}>
        <AbsoluteFill>
          <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={472} volume={0.7} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        </AbsoluteFill>
      </Sequence>

      {/* 9 · Tek göz */}
      <Sequence from={S8} durationInFrames={S9 - S8}>
        <Mascot clip="flow_eye" trim={30} />
        <FabricWord text={L(lang, "I always believed in you.", "Sana hep inandım.")} at={50} y={170} size={L(lang, 96, 124)} seed={2} />
      </Sequence>

      <Sequence from={S9}><EndCard lang={lang} /></Sequence>
      <Sequence from={S9 + 8}><Confetti at={0} x={540} y={1300} n={60} /></Sequence>

      {/* Ses: hatada müzik kesilir; Snuglo sahneleri sessizdir. */}
      {[MISS1, MISS2, MISS3].map((m) => <Sequence key={m} from={m} durationInFrames={24}><Sfx src="error" vol={1} /></Sequence>)}
      <Sequence from={S6 - 4} durationInFrames={20}><Sfx src="place" vol={0.8} /></Sequence>
      <Sequence from={S9}><Sfx src="reward" vol={0.55} /></Sequence>
      {music(0, MISS1, 0)}
      {music(S2, MISS2 - S2, MISS1)}
      {music(S4, MISS3 - S4, MISS1 + MISS2 - S2)}
      {music(S6B, S8 - S6B, MISS1 + MISS2 - S2 + MISS3 - S4)}
      {music(S9, VIRAL_DISAPPOINTED_DUR - S9, 60, 0.45)}
    </AbsoluteFill>
  );
};
