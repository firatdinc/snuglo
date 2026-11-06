import React from "react";
import { AbsoluteFill, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig, Easing } from "remotion";
import { Video, Audio } from "@remotion/media";
import { Art, BEAT, C, Confetti, FONT, Gingham, Phone, Pop, Punch, Sticker, usePulse } from "../kit";
export const LangCtx = React.createContext<"en" | "tr">("en");
const tx = (en: string, tr: string) => (React.useContext(LangCtx) === "tr" ? tr : en);

const Clip: React.FC<{ src: string; vol?: number }> = ({ src, vol = 0.55 }) => (
  <Video src={staticFile(`clips/${src}.mp4`)} volume={vol} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
);

/** 1 · Kanca: "Can you fit every patch?" — yanlış hamle, sonra ŞAK diye oturuyor. */
export const SHook: React.FC = () => (
  <Punch>
    <Gingham a={C.terracotta} b="#ffffff" />
    <Phone w={760} at={0}><Clip src={`hook_${React.useContext(LangCtx)}`} /></Phone>
    <Pop text={tx("CAN YOU FIT", "HER YAMAYI")} at={0} y={150} size={112} />
    <Pop text={tx("EVERY PATCH?", "SIĞDIRABİLİR MİSİN?")} at={BEAT} y={275} size={106} color={C.mustard} />
    <Sticker text={tx("NOPE!", "OLMADI!")} at={34} out={80} bg={C.plum} x={640} y={1180} rot={10} />
    <Sticker text={tx("SNAP! ✓", "TIK! ✓")} at={88} bg={C.sage} x={90} y={1020} rot={-9} size={84} />
    <Confetti at={88} x={540} y={980} />
  </Punch>
);

/** 2 · Drop: hızlı çözüm, kelimeler vuruşta değişir. */
export const SSolve: React.FC = () => {
  const words = [tx("DRAG", "SÜRÜKLE"), tx("DROP", "BIRAK"), tx("SNAP", "OTURT"), tx("SOLVE!", "ÇÖZ!")];
  const f = useCurrentFrame();
  const k = Math.min(words.length - 1, Math.floor(f / (BEAT * 2)));
  return (
    <Punch>
      <Gingham a={C.sage} b={C.cream} size={70} />
      <Phone w={780} tilt={-2}><Clip src={`solve_${React.useContext(LangCtx)}`} /></Phone>
      {words.map((w, i) => (
        <Pop key={w} text={w} at={i * BEAT * 2} out={i === k ? undefined : (i + 1) * BEAT * 2} y={170} size={170}
          color={[C.cream, C.mustard, "#fff", C.pink][i]} rot={i % 2 ? 6 : -6} />
      ))}
      <Confetti at={104} x={540} y={700} n={90} />
    </Punch>
  );
};

/** 3 · Göz At */
export const SPeek: React.FC = () => {
  const p = usePulse();
  return (
    <Punch>
      <Gingham a={C.blue} b={C.cream} size={80} />
      <Phone w={760} tilt={2}><Clip src={`peek_${React.useContext(LangCtx)}`} /></Phone>
      <Pop text={tx("STUCK?", "TAKILDIN MI?")} at={0} y={150} size={130} />
      <Pop text={tx("TAKE A PEEK!", "GÖZ AT!")} at={BEAT} y={285} size={108} color={C.mustard} />
      <Art src="art/ic_peek.png" style={{ left: 700, top: 1250, width: 300, scale: String(1 + p * 0.12), rotate: "-12deg" }} />
    </Punch>
  );
};

/** 4 · Şanslı sandık */
export const SChest: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <Punch>
      <Gingham a={C.mustard} b="#ffffff" size={80} />
      <AbsoluteFill style={{ background: `repeating-conic-gradient(from ${f * 2}deg at 50% 52%, #ffffff33 0 10deg, transparent 10deg 20deg)` }} />
      <Phone w={760} tilt={-2}><Clip src={`chest_${React.useContext(LangCtx)}`} /></Phone>
      <Pop text={tx("LUCKY", "ŞANSLI")} at={0} y={150} size={140} color={C.cream} />
      <Pop text={tx("CHESTS!", "SANDIKLAR!")} at={BEAT} y={290} size={140} color="#fff" stroke={C.terracotta} />
      {Array.from({ length: 14 }).map((_, i) => {
        const t = f - 20 - i * 2; if (t < 0) return null;
        const x = 540 + Math.cos(i * 1.7) * t * 22; const y = 1100 - t * 30 + t * t * 0.9;
        return <Art key={i} src={i % 3 ? "art/coin.png" : "art/ic_gem.png"} style={{ left: x, top: y, width: 110, rotate: `${t * 12}deg` }} />;
      })}
    </Punch>
  );
};

const SCENES = ["island", "forest", "flower", "snow", "autumn", "beach", "lake", "mushroom", "desert", "volcano", "waterfall", "island"];
/** 5 · 17 dünya / 1000+ bölüm: yorgan ızgarası */
export const SWorlds: React.FC = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const n = Math.round(interpolate(f, [62, 100], [0, 1020], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.cubic) }));
  return (
    <Punch>
      <Gingham a={C.plum} b={C.pink} size={60} />
      <div style={{ position: "absolute", left: 90, top: 470, width: 900, display: "flex", flexWrap: "wrap", gap: 20 }}>
        {SCENES.map((s, i) => {
          const sp = spring({ frame: f - i * 4, fps, config: { damping: 10, stiffness: 200 } });
          return (
            <div key={i} style={{ width: 210, height: 210, borderRadius: 30, overflow: "hidden", border: `10px solid ${C.cream}`,
              outline: `4px dashed ${C.terracotta}`, outlineOffset: -20, scale: String(sp), rotate: `${(i % 3 - 1) * 4 * (1 - sp)}deg`,
              boxShadow: "0 12px 0 rgba(0,0,0,0.25)" }}>
              <img src={staticFile(`art/scene/${s}.jpg`)} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            </div>
          );
        })}
      </div>
      <Art src="art/think.png" style={{ left: 330, top: 1430 + Math.sin(f / 7) * 12, width: 420 }} />
      <Pop text={tx("17 COZY WORLDS", "17 SICACIK DÜNYA")} at={0} y={170} size={118} color={C.cream} />
      {f >= 60 && <Pop text={tx(`${n.toLocaleString("en-US")}+ LEVELS`, `${n.toLocaleString("tr-TR")}+ BÖLÜM`)} at={60} y={1250} size={124} color={C.mustard} />}
    </Punch>
  );
};

const FRIENDS = ["bear", "bunny", "fox", "owl", "hedgehog", "koala", "penguin", "redpanda", "tiger", "frog", "lion", "sheep", "cow", "hippo", "turtle", "bee"];
/** 6 · Sevimli dostlar */
export const SFriends: React.FC = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = usePulse();
  return (
    <Punch>
      <Gingham a={C.sage} b={C.mustard} size={70} />
      {FRIENDS.map((n, i) => {
        const col = i % 4, row = Math.floor(i / 4);
        const sp = spring({ frame: f - i * 3, fps, config: { damping: 9, stiffness: 220 } });
        const hop = Math.abs(Math.sin((f + i * 4) / BEAT * Math.PI)) * 26;
        return <Art key={n} src={`art/friends/${n}.png`} style={{ left: 80 + col * 235, top: 440 + row * 225 - hop, width: 200, scale: String(sp) }} />;
      })}
      <Art src="art/cheer.png" style={{ left: 330, top: 1340, width: 420, scale: String(1 + p * 0.06), rotate: `${Math.sin(f / 6) * 4}deg` }} />
      <Pop text={tx("CUDDLY", "SEVİMLİ")} at={0} y={140} size={130} />
      <Pop text={tx("FRIENDS!", "DOSTLAR!")} at={BEAT} y={280} size={140} color={C.mustard} />
    </Punch>
  );
};

/** 7 · Kapanış */
export const SEnd: React.FC = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = usePulse();
  const logo = spring({ frame: f, fps, config: { damping: 8, stiffness: 160 } });
  const btn = spring({ frame: f - 2 * BEAT, fps, config: { damping: 9, stiffness: 200 } });
  return (
    <Punch>
      <AbsoluteFill><img src={staticFile("art/scene/flower.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} /></AbsoluteFill>
      <Art src="art/logo.png" style={{ left: 90, top: 240, width: 900, scale: String(logo * (1 + p * 0.04)), translate: `0px ${(1 - logo) * -500}px` }} />
      <Art src="art/wave.png" style={{ left: 300, top: 720, width: 480, scale: String(spring({ frame: f - BEAT, fps, config: { damping: 10 } })), rotate: `${Math.sin(f / 7) * 5}deg` }} />
      <div style={{ position: "absolute", left: 170, top: 1330, width: 740, height: 170, borderRadius: 999, background: C.terracotta,
        border: `10px solid ${C.cream}`, boxShadow: "0 16px 0 rgba(58,36,26,0.4)", scale: String(btn * (1 + p * 0.07)),
        display: "flex", alignItems: "center", justifyContent: "center", fontFamily: FONT, fontWeight: 700, fontSize: tx("x","y") === "y" ? 84 : 96, color: "#fff",
        WebkitTextStroke: `8px ${C.ink}`, paintOrder: "stroke fill" }}>{tx("PLAY FREE", "ÜCRETSİZ OYNA")}</div>
      {f >= 3 * BEAT && <Pop text={tx("on the App Store", "App Store'da")} at={3 * BEAT} y={1535} size={70} />}
      <Confetti at={2 * BEAT} x={540} y={1400} n={80} />
      <Confetti at={8 * BEAT} x={300} y={500} n={60} />
      <Confetti at={8 * BEAT} x={800} y={500} n={60} />
    </Punch>
  );
};

/** Sahne geçişlerinde pop/snap efekt sesleri. */
export const Sfx: React.FC<{ src: string; vol?: number }> = ({ src, vol = 0.8 }) => <Audio src={staticFile(`sfx/${src}.wav`)} volume={vol} />;
