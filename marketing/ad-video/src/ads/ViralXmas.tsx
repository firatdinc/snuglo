import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio, Video } from "@remotion/media";
import { AdProps, C, Confetti, FONT, Sfx } from "./common";
import { FabricWord } from "./FabricWord";

const L = <T,>(lang: string, en: T, tr: T) => (lang === "tr" ? tr : en);
// Güvenli alan: sağdan 150 px, alttan 350 px boş. Metin x=70..930, y<=1500.
const TX = { x: 70, width: 860 };

/** Karla kaplı kış köyü zemini (oyunun kendi sanatı) + hafif karartma + kar. */
const Snow: React.FC<{ dim?: number }> = ({ dim = 0.18 }) => {
  const f = useCurrentFrame();
  const z = 1 + f * 0.0003;
  return (
    <AbsoluteFill style={{ background: "#2c3a52" }}>
      <Img src={staticFile("art/scene/snow.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${z})` }} />
      <AbsoluteFill style={{ background: `rgba(20,24,44,${dim})` }} />
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
        const x = (i * 137) % 1000 + 30;
        const y = ((f * (1.4 + (i % 3) * 0.5) + i * 260) % 2000) - 60;
        return <Img key={i} src={staticFile(`art/xmas/misc/flake_${i % 6}.png`)} style={{ position: "absolute", left: x + Math.sin((f + i * 20) / 30) * 20, top: y, width: 70 + (i % 3) * 20, opacity: 0.85, transform: `rotate(${f * 0.6 + i * 40}deg)` }} />;
      })}
    </AbsoluteFill>
  );
};

/** Noel şapkalı Snuglo kuklası: nefes, çok yavaş eğim. tilt: sona doğru derece. */
const Puppet: React.FC<{ pose: "idle" | "sleep" | "think" | "cheer" | "wave"; top?: number; width?: number; tilt?: number; pop?: boolean }> = ({ pose, top = 720, width = 700, tilt = 0, pop = true }) => {
  const f = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const enter = pop ? spring({ frame: f, fps, config: { damping: 12, stiffness: 150 } }) : 1;
  const breath = Math.sin(f / 16) * 0.012;
  const rot = interpolate(f, [0, durationInFrames], [0, tilt]);
  return (
    <>
      <div style={{ position: "absolute", left: 540 - width * 0.42, top: top + width * 0.9, width: width * 0.84, height: width * 0.12, borderRadius: "50%", background: "rgba(30,18,10,0.35)", filter: "blur(18px)" }} />
      <Img src={staticFile(`art/xmas/mascot/${pose}.png`)} style={{ position: "absolute", left: 540 - width / 2, top, width, transformOrigin: "50% 92%", transform: `translateY(${(1 - enter) * 260}px) scale(${enter * (1 + breath)}, ${enter * (1 - breath * 1.4)}) rotate(${rot}deg)` }} />
    </>
  );
};

const Game: React.FC<{ clip: string; trim?: number; rate?: number; vol?: number }> = ({ clip, trim = 0, rate = 1, vol = 0.6 }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    <Video src={staticFile(`clips/${clip}.mp4`)} trimBefore={trim} playbackRate={rate} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
  </AbsoluteFill>
);

/** Oyunun kendi süsü (ball_red): tepsiden çok yavaşça yükselir, dala asılır, sallanır. */
const Orn: React.FC<{ from: number; land: number }> = ({ from, land }) => {
  const f = useCurrentFrame();
  if (f < from) return null;
  const t = interpolate(f, [from, land], [0, 1], { extrapolateRight: "clamp", easing: (x) => x * x * (3 - 2 * x) });
  const x = interpolate(t, [0, 1], [230, 452]);
  const y = interpolate(t, [0, 1], [1690, 905]) - Math.sin(t * Math.PI) * 60;
  const hit = f >= land ? f - land : 0;
  const sw = f >= land ? Math.sin(hit / 5) * 14 * Math.exp(-hit / 22) : 0;
  const sc = interpolate(t, [0, 1], [1.5, 1]) * (f >= land ? 1 + Math.exp(-hit / 6) * 0.18 * Math.cos(hit / 2) : 1);
  return <Img src={staticFile("art/xmas/tree/ball_red.png")} style={{ position: "absolute", left: x - 70, top: y - 14, width: 140, transformOrigin: "50% 0%", transform: `rotate(${sw}deg) scale(${sc})` }} />;
};

const EndCard: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = spring({ frame: f, fps, config: { damping: 10, stiffness: 170 } });
  const btn = spring({ frame: f - 16, fps, config: { damping: 9, stiffness: 200 } });
  return (
    <AbsoluteFill>
      <Snow dim={0.25} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: 140, top: 130, width: 800, transform: `scale(${logo})` }} />
      <FabricWord text={L(lang, "Christmas opens Dec 1", "Noel 1 Aralık'ta açılıyor")} at={8} y={470} size={L(lang, 96, 84)} seed={4} {...TX} />
      <Puppet pose="wave" top={760} width={520} />
      <div style={{ position: "absolute", left: 140, top: 1290, width: 800, height: 200, transform: `scale(${btn * (1 + Math.sin(f / 7) * 0.025)})`, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Img src={staticFile("art/btn_terracotta.png")} style={{ position: "absolute", width: "100%", height: "100%" }} />
        <span style={{ position: "relative", fontFamily: FONT, fontWeight: 700, fontSize: L(lang, 78, 66), color: "#fff", WebkitTextStroke: "6px #6E2A17", paintOrder: "stroke fill" }}>
          {L(lang, "FREE ON APP STORE", "APP STORE'DA ÜCRETSİZ")}
        </span>
      </div>
    </AbsoluteFill>
  );
};

/* Olay örgüsü (kare @30fps). Tek şaka: Snuglo süslemez, sonra sessizce bir süs asar. */
const A = 75, B = A + 96, Cc = B + 105, D = Cc + 105, E = D + 165, F = E + 96, G = F + 100;
export const VIRAL_XMAS_DUR = G;
const DROP = 106; // E içinde süsün asıldığı kare

export const ViralXmas: React.FC<AdProps> = ({ lang }) => {
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {/* 1 · Kanca: boş ağaç */}
      <Sequence durationInFrames={A}>
        <Game clip={`vx_tree_bare_${lang}`} trim={6} vol={0} />
        <FabricWord text={L(lang, "Asking Snuglo to decorate the tree", "Snuglo'dan ağacı süslemesini istemek")} at={0} y={250} size={L(lang, 80, 74)} seed={1} {...TX} />
      </Sequence>

      {/* 2 · Yanıt */}
      <Sequence from={A} durationInFrames={B - A}>
        <Snow />
        <FabricWord text={L(lang, "No.", "Hayır.")} at={22} y={200} size={190} seed={4} {...TX} />
        <Puppet pose="think" tilt={-5} />
        <FabricWord text={L(lang, "I'm festive from here.", "Ben buradan Noel'im.")} at={52} y={1220} size={L(lang, 84, 84)} seed={6} {...TX} />
      </Sequence>

      {/* 3 · Herkes süsler */}
      <Sequence from={B} durationInFrames={Cc - B}>
        <Game clip={`vx_tree_full_${lang}`} trim={10} vol={0.5} />
        <FabricWord text={L(lang, "Everyone else:", "Diğer herkes:")} at={0} out={44} y={250} size={110} seed={2} {...TX} />
        <FabricWord text={L(lang, "15 ornaments. 3 seconds.", "15 süs. 3 saniye.")} at={50} y={250} size={L(lang, 84, 92)} seed={7} {...TX} />
      </Sequence>

      {/* 4 · Snuglo: gözetliyorum */}
      <Sequence from={Cc} durationInFrames={D - Cc}>
        <Snow />
        <FabricWord text={L(lang, "I don't decorate.", "Ben süslemem.")} at={6} out={58} y={200} size={L(lang, 112, 130)} seed={3} {...TX} />
        <FabricWord text={L(lang, "I supervise.", "Ben denetlerim.")} at={64} y={200} size={L(lang, 130, 120)} seed={8} {...TX} />
        <Puppet pose="sleep" top={800} width={720} tilt={4} />
      </Sequence>

      {/* 5 · Kimse bakmazken tek süs */}
      <Sequence from={D} durationInFrames={E - D}>
        <Game clip={`vx_tree_bare_${lang}`} trim={0} rate={0.5} vol={0} />
        <Orn from={34} land={DROP} />
        <FabricWord text={L(lang, "…", "…")} at={0} out={30} y={250} size={170} seed={5} {...TX} />
        <FabricWord text={L(lang, "(nobody is looking)", "(kimse bakmıyor)")} at={32} out={DROP - 4} y={250} size={L(lang, 80, 84)} seed={9} {...TX} />
        <FabricWord text={L(lang, "One.", "Bir tane.")} at={DROP} y={250} size={L(lang, 170, 150)} seed={2} {...TX} />
      </Sequence>

      {/* 6 · Konu kapanır */}
      <Sequence from={E} durationInFrames={F - E}>
        <Snow />
        <FabricWord text={L(lang, "We don't talk about it.", "Bunu konuşmuyoruz.")} at={14} y={200} size={L(lang, 104, 104)} seed={6} {...TX} />
        <Puppet pose="idle" top={790} width={700} tilt={-3} />
      </Sequence>

      <Sequence from={F}><EndCard lang={lang} /></Sequence>
      <Sequence from={F + 10}><Confetti at={0} x={540} y={1380} n={50} /></Sequence>

      {/* Ses: şenlikli müzik, süs anında kesilir; yalnız tık, sonra geri gelir. */}
      <Sequence durationInFrames={D + 26}>
        <Audio src={staticFile("bgm_xmas.wav")} volume={(fr) => 0.5 * interpolate(fr, [D + 14, D + 26], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
      </Sequence>
      <Sequence from={D + DROP + 4} durationInFrames={VIRAL_XMAS_DUR - (D + DROP + 4)}>
        <Audio src={staticFile("bgm_xmas.wav")} trimBefore={30 * 20} volume={(fr) => 0.5 * interpolate(fr, [0, 20], [0, 1], { extrapolateRight: "clamp" })} />
      </Sequence>
      <Sequence from={B - 1} durationInFrames={20}><Sfx src="click" vol={0.6} /></Sequence>
      <Sequence from={A + 22} durationInFrames={24}><Sfx src="error" vol={0.8} /></Sequence>
      <Sequence from={D + DROP} durationInFrames={20}><Sfx src="place" vol={1} /></Sequence>
      <Sequence from={F}><Sfx src="reward" vol={0.55} /></Sequence>
    </AbsoluteFill>
  );
};
