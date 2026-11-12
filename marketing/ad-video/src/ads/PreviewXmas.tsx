import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Video } from "@remotion/media";
import { C, FONT } from "../kit";
import { AppClip, FabCtx, FabricText, FabricWipe, HDR_DUR, HW, HH, Music, Patchwork, PProps, SEARCH_H, SEARCH_W, cyc } from "./Preview";

/* Noel sürümü (2.0.6) mağaza videoları. Eski kompozisyonlarla aynı biçim/ölçü/süre; yalnızca tema Noel.
   Görsellerin hepsi oyundaki ChatGPT çizimleri (art/xmas, mascot_xmas, friends_xmas, klasik kumaş seti); kar/çerçeve CSS. */
const XC = { red: "#B8382F", green: "#4C7A4F", gold: "#E2A93B" };
const XFAB = { dir: "xmas/fabric", ids: ["f00", "f06", "f04", "f08", "f02", "f10", "f01", "f05", "f07", "f03"] };
const xa = (p: string) => staticFile(`art/xmas/${p}.png`);
const MUSIC = "bgm_xmas.wav";

const rnd = (i: number, k: number) => { const x = Math.sin(i * 127.1 + k * 311.7) * 43758.5453; return x - Math.floor(x); };

/** Düşen kar: oyunun keçe kar topu/kar tanesi çizimleri + CSS noktalar. Tüm hareket `period` karede tam turlu → dikişsiz döngü. */
export const Snow: React.FC<{ w: number; h: number; n?: number; period: number; size?: number; laps?: number[]; seed?: number }> = ({ w, h, n = 46, period, size = 44, laps = [1, 2], seed = 0 }) => {
  const f = useCurrentFrame();
  const m = 90, hh = h + 2 * m;
  return (
    <AbsoluteFill style={{ pointerEvents: "none", overflow: "hidden" }}>
      {Array.from({ length: n }).map((_, i) => {
        const r = (k: number) => rnd(i + seed * 100, k);
        const s = size * (0.35 + r(1) * 0.9);
        const lap = laps[Math.floor(r(2) * laps.length)];
        const y = ((r(3) * hh + (lap * hh * f) / period) % hh) - m;
        const sw = 1 + Math.floor(r(4) * 2);
        const x = r(5) * w + Math.sin((2 * Math.PI * sw * f) / period + r(6) * 6.28) * s * 0.9;
        const kind = r(7);
        const op = 0.55 + r(8) * 0.45;
        if (kind < 0.45) return <div key={i} style={{ position: "absolute", left: x, top: y, width: s * 0.4, height: s * 0.4, borderRadius: "50%", background: "#fff", opacity: op * 0.9, filter: `blur(${s * 0.02}px)` }} />;
        const flake = kind < 0.75 ? "misc/flake_0" : `misc/flake_${3 + Math.floor(r(9) * 3)}`;
        return <Img key={i} src={xa(flake)} style={{ position: "absolute", left: x, top: y, width: s, opacity: op, rotate: `${(360 * (1 + (i % 2)) * f) / period * (r(10) > 0.5 ? 1 : -1) * (kind < 0.75 ? 0 : 1)}deg`, filter: "drop-shadow(0 2px 3px rgba(30,15,8,0.25))" }} />;
      })}
    </AbsoluteFill>
  );
};

/** Dikişli krem çerçeve: kırmızı/yeşil dikiş, üstte karlı kenar (oyunun snow_cap çizimi). */
const XFrame: React.FC<{ pad: number; radius: number; dash: number; alt?: boolean; cap?: number; children: React.ReactNode; style?: React.CSSProperties }> = ({ pad, radius, dash, alt, cap = 1, children, style }) => (
  <div style={{ position: "absolute", borderRadius: radius, background: C.cream, padding: pad, ...style }}>
    <div style={{ position: "absolute", inset: pad * 0.45, borderRadius: radius * 0.9, border: `${dash}px dashed ${alt ? XC.green : XC.red}`, opacity: 0.9 }} />
    <div style={{ width: "100%", height: "100%", borderRadius: radius * 0.8, overflow: "hidden", position: "relative" }}>{children}</div>
    <Img src={xa("misc/snow_cap_mid")} style={{ position: "absolute", left: "50%", top: -pad * 1.5 * cap, width: "104%", translate: "-50% 0", pointerEvents: "none", filter: "drop-shadow(0 6px 6px rgba(30,15,8,0.3))" }} />
  </div>
);

const XFramedClip: React.FC<{ src: string; trim: number; top?: number }> = ({ src, trim, top = 400 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const h = 1920 - top - 70; const w = (h * 886) / 1920;
  const s = spring({ frame: f, fps, config: { damping: 13, stiffness: 170 } });
  return (
    <XFrame pad={14} radius={64} dash={5} alt={Math.floor(trim / 7) % 2 === 1}
      style={{ left: (886 - w) / 2 - 14, top: top - 14, width: w + 28, height: h + 28, boxShadow: "0 30px 60px rgba(0,0,0,0.45)", scale: String(interpolate(s, [0, 1], [0.9, 1])), rotate: `${Math.sin(f / 20) * 0.8}deg` }}>
      <Video src={staticFile(`clips/${src}.mp4`)} trimBefore={trim} volume={0.7} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </XFrame>
  );
};

const XRibbon: React.FC<{ text: string; y?: number; alt?: boolean }> = ({ text, y = 130, alt }) => {
  const f = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const s = spring({ frame: f, fps, config: { damping: 11, stiffness: 200 } });
  const out = interpolate(f, [durationInFrames - 6, durationInFrames], [1, 0], { extrapolateLeft: "clamp" });
  const col = alt ? XC.green : XC.red;
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: y, display: "flex", justifyContent: "center", scale: String(s), opacity: out, rotate: "-2deg" }}>
      <div style={{ position: "relative", background: C.cream, borderRadius: 26, padding: "22px 48px", fontFamily: FONT, fontWeight: 700, fontSize: 60,
        color: C.ink, boxShadow: `0 10px 0 ${col}, 0 22px 30px rgba(58,36,26,0.35)`, textAlign: "center", lineHeight: 1.1, whiteSpace: "pre" }}>
        <div style={{ position: "absolute", inset: 9, borderRadius: 18, border: `4px dashed ${col}`, opacity: 0.75 }} />
        {text}
        <Img src={xa("misc/snow_cap_mid")} style={{ position: "absolute", left: "50%", top: -34, width: "92%", translate: "-50% 0", pointerEvents: "none" }} />
      </div>
    </div>
  );
};

const TX = {
  x1: { en: "Cozy Christmas\nvillage", tr: "Sıcacık Noel\nköyü", es: "Pueblo navideño\nacogedor" },
  x2: { en: "Decorate\nyour tree!", tr: "Ağacını\nsüsle!", es: "¡Decora tu\nárbol!" },
  x3: { en: "Bake\ncookies!", tr: "Kurabiye\npişir!", es: "¡Hornea\ngalletas!" },
  x4: { en: "Festive patch\npuzzles", tr: "Şenlikli yama\nbulmacaları", es: "Puzles de retales\nfestivos" },
  t0: { en: "Snowy & cozy", tr: "Karlı ve sıcacık", es: "Nevado y acogedor" },
  t1: { en: "Cozy Christmas\nvillage", tr: "Sıcacık Noel\nköyü", es: "Pueblo navideño\nacogedor" },
  t2: { en: "Decorate your tree", tr: "Ağacını süsle", es: "Decora tu árbol" },
  t3: { en: "Bake cookies", tr: "Kurabiye pişir", es: "Hornea galletas" },
  t4: { en: "Cut festive shapes", tr: "Şenlikli kalıplar kes", es: "Corta formas\nfestivas" },
  t5: { en: "Festive patch puzzles", tr: "Şenlikli yama\nbulmacaları", es: "Puzles de retales\nfestivos" },
  t6: { en: "Sew your own quilt", tr: "Kendi yorganını dik", es: "Cose tu propia\ncolcha" },
  t7: { en: "24-day advent quilt", tr: "24 günlük\nadvent yorganı", es: "Colcha de adviento\nde 24 días" },
  hd: { en: "Cozy Christmas is here", tr: "Sıcacık Noel geldi", es: "La Navidad ha llegado" },
};
export const XMAS_TX = TX;

type Shot = [string, number, number, keyof typeof TX];
export const XHERO_PLAN: Shot[] = [["menu", 30, 75, "x1"], ["tree", 150, 150, "x2"], ["cbake", 30, 150, "x3"], ["solve", 90, 105, "x4"]];
export const XTOUR_PLAN: Shot[] = [["menu", 30, 60, "t0"], ["village", 0, 105, "t1"], ["tree", 150, 135, "t2"], ["cmix", 30, 105, "t3"], ["ccut", 30, 75, "t4"],
  ["solve", 60, 150, "t5"], ["quilt", 0, 135, "t6"], ["advent", 0, 81, "t7"]];
const total = (p: Shot[]) => p.reduce((a, s) => a + s[2], 0);
export const XHERO_DUR = total(XHERO_PLAN);
export const XTOUR_DUR = total(XTOUR_PLAN);

const XSnowSeq: React.FC = () => <Snow w={886} h={1920} n={38} period={300} size={46} laps={[1, 2]} />;

/** Noel Hero: ilk önizleme (kumaş yazılı, geçişli). */
export const XmasHero: React.FC<PProps> = ({ lang }) => {
  let at = 0;
  const cuts: number[] = [];
  return (
    <FabCtx.Provider value={XFAB}>
      <AbsoluteFill style={{ background: C.ink }}>
        {XHERO_PLAN.map(([src, trim, d, cap], i) => {
          const from = at; at += d; if (i > 0) cuts.push(from);
          return (
            <Sequence key={i} from={from} durationInFrames={d}>
              <Patchwork />
              <XFramedClip src={`xm_${src}_${lang}`} trim={trim} />
              <FabricText text={TX[cap][lang]} y={70} at={4} seed={i * 3} size={lang === "en" ? 104 : lang === "tr" ? 92 : 80} />
            </Sequence>
          );
        })}
        <XSnowSeq />
        {cuts.map((c) => <FabricWipe key={c} at={c - 8} />)}
        <Music from={0} vol={0.62} file={MUSIC} />
      </AbsoluteFill>
    </FabCtx.Provider>
  );
};

/** Noel Tour: ikinci önizleme (kurdele başlıklar). */
export const XmasTour: React.FC<PProps> = ({ lang }) => {
  let at = 0;
  return (
    <FabCtx.Provider value={XFAB}>
      <AbsoluteFill style={{ background: C.ink }}>
        {XTOUR_PLAN.map(([src, trim, d, cap], i) => {
          const from = at; at += d;
          return (
            <Sequence key={i} from={from} durationInFrames={d}>
              <AppClip src={`xm_${src}_${lang}`} trim={trim} vol={0.8} />
              <XRibbon text={TX[cap][lang]} alt={i % 2 === 1} />
            </Sequence>
          );
        })}
        <XSnowSeq />
        <Music from={4} vol={0.5} file={MUSIC} />
      </AbsoluteFill>
    </FabCtx.Provider>
  );
};

/* ------------------------------------------------------------------ Noel ürün sayfası başlığı + arama videosu
   Hareketin tamamı HDR_DUR periyotlu: kumaş zemin köşegen kayar (desen yalnız (sütun−satır)'a bağlı → tam bir karo kaymasında kendine denk),
   kar/yüzen çizimler tam turlu. Fiyat / "Free" yazısı yok. */
const XTiles: React.FC<{ w: number; h: number; S: number; bg: number; dash: number }> = ({ w, h, S, bg, dash }) => {
  const f = useCurrentFrame();
  const drift = (f / HDR_DUR) * S;
  const cols = Math.ceil(w / S) + 4, rows = Math.ceil(h / S) + 4;
  const n = XFAB.ids.length;
  return (
    <div style={{ position: "absolute", left: -2 * S + drift, top: -2 * S + drift, width: cols * S, height: rows * S, display: "flex", flexWrap: "wrap" }}>
      {Array.from({ length: cols * rows }).map((_, i) => {
        const c = i % cols, r = Math.floor(i / cols);
        const id = XFAB.ids[(((c - r) % n) + n) % n];
        return <div key={i} style={{ width: S, height: S, backgroundImage: `url(${staticFile(`art/xmas/fabric/${id}.png`)})`, backgroundSize: `${bg}px`,
          outline: `${dash}px dashed rgba(251,241,225,0.4)`, outlineOffset: -16 }} />;
      })}
    </div>
  );
};

const XCard: React.FC<{ src: string; x: number; y: number; rot: number; ph: number; h?: number; alt?: boolean; trim?: number }> = ({ src, x, y, rot, ph, h = 1240, alt, trim = 0 }) => {
  const f = useCurrentFrame();
  const w = (h * 886) / 1920;
  const bob = Math.sin(cyc(f, 2) + ph) * 18;
  const r = rot + Math.sin(cyc(f, 1) + ph) * 1.5;
  return (
    <XFrame pad={18} radius={80} dash={7} alt={alt} style={{ left: x, top: y + bob, width: w + 36, height: h + 36, rotate: `${r}deg`, boxShadow: "0 40px 80px rgba(30,15,8,0.55)" }}>
      <Video src={staticFile(`clips/${src}.mp4`)} trimBefore={trim} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </XFrame>
  );
};

const XBanner: React.FC<{ text: string; x: number; y: number; size: number }> = ({ text, x, y, size }) => {
  const f = useCurrentFrame();
  return (
    <div style={{ position: "absolute", left: x, top: y + Math.sin(cyc(f, 2) + 1) * 10, translate: "-50% 0", rotate: `${-2 + Math.sin(cyc(f, 1)) * 1}deg`, background: C.cream, borderRadius: size * 0.45,
      padding: `${size * 0.3}px ${size * 0.8}px`, fontFamily: FONT, fontWeight: 700, fontSize: size, color: C.ink, whiteSpace: "pre", textAlign: "center",
      boxShadow: `0 ${size * 0.17}px 0 ${XC.red}, 0 ${size * 0.4}px ${size * 0.5}px rgba(30,15,8,0.4)` }}>
      <div style={{ position: "absolute", inset: size * 0.14, borderRadius: size * 0.34, border: `${size * 0.07}px dashed ${XC.green}`, opacity: 0.8 }} />
      {text}
      <Img src={xa("misc/snow_cap_mid")} style={{ position: "absolute", left: "50%", top: -size * 0.62, width: "90%", translate: "-50% 0" }} />
    </div>
  );
};

const XPlush: React.FC<{ src: string; x: number; y: number; w: number; ph: number; flip?: boolean }> = ({ src, x, y, w, ph, flip }) => {
  const f = useCurrentFrame();
  return <Img src={xa(src)} style={{ position: "absolute", left: x, top: y + Math.sin(cyc(f, 2) + ph) * 14, width: w, rotate: `${Math.sin(cyc(f, 1) + ph) * 5}deg`,
    scale: flip ? "-1 1" : undefined, filter: "drop-shadow(0 24px 30px rgba(30,15,8,0.45))" }} />;
};

export const XmasPageHeader: React.FC<PProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const logoBob = Math.sin(cyc(f, 2)) * 16;
  return (
    <AbsoluteFill style={{ background: C.ink, overflow: "hidden" }}>
      <XTiles w={HW} h={HH} S={330} bg={480} dash={5} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 45% 70% at 50% 45%, rgba(251,241,225,0.55), rgba(251,241,225,0.08) 60%, rgba(40,22,14,0.55))" }} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 80% 90% at 50% 50%, transparent 55%, rgba(150,35,30,0.28))" }} />
      <AbsoluteFill style={{ opacity: 0.18, background: `repeating-conic-gradient(from ${(f / HDR_DUR) * 30}deg at 50% 40%, #fff 0deg 6deg, transparent 6deg 18deg)` }} />
      <XCard src={`xm_solve_${lang}`} x={150} y={250} rot={-7} ph={0} />
      <XCard src={`xm_tree_${lang}`} trim={140} x={760} y={430} rot={5} ph={1.7} h={1120} alt />
      <XCard src={`xm_cbake_${lang}`} x={2470} y={430} rot={-5} ph={2.9} h={1120} alt />
      <XCard src={`xm_village_${lang}`} x={3080} y={250} rot={7} ph={4.2} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: HW / 2 - 820, top: 150 + logoBob, width: 1640,
        rotate: `${Math.sin(cyc(f, 1)) * 1.5}deg`, filter: "drop-shadow(0 30px 40px rgba(30,15,8,0.45))" }} />
      <XPlush src="mascot/cheer" x={HW / 2 - 330} y={850} w={660} ph={0.5} />
      <XPlush src="friends/fox" x={HW / 2 - 760} y={1150} w={400} ph={2.1} />
      <XPlush src="friends/bunny" x={HW / 2 + 380} y={1140} w={400} ph={3.3} flip />
      <XPlush src="friends/gingerbread" x={HW / 2 - 1130} y={1210} w={300} ph={1.1} />
      <XPlush src="friends/reindeer" x={HW / 2 + 830} y={1200} w={320} ph={4.4} flip />
      <XBanner text={TX.hd[lang]} x={HW / 2} y={1470} size={92} />
      <Snow w={HW} h={HH} n={90} period={HDR_DUR} size={70} laps={[2, 3, 4]} />
    </AbsoluteFill>
  );
};

export const XmasSearch: React.FC<PProps> = ({ lang }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: C.ink, overflow: "hidden" }}>
      <XTiles w={SEARCH_W} h={SEARCH_H} S={300} bg={440} dash={5} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 60% 60% at 50% 55%, rgba(251,241,225,0.45), rgba(40,22,14,0.55))" }} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 80% 90% at 50% 50%, transparent 55%, rgba(150,35,30,0.28))" }} />
      <AbsoluteFill style={{ opacity: 0.16, background: `repeating-conic-gradient(from ${(f / HDR_DUR) * 30}deg at 50% 55%, #fff 0deg 6deg, transparent 6deg 18deg)` }} />
      <XCard src={`xm_solve_${lang}`} x={260} y={330} rot={-6} ph={0} h={1440} />
      <XCard src={`xm_treeslow_${lang}`} trim={10} x={1080} y={240} rot={0} ph={1.9} h={1560} alt />
      <XCard src={`xm_cbake_${lang}`} x={1900} y={330} rot={6} ph={3.6} h={1440} />
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: SEARCH_W / 2 - 560, top: 40 + Math.sin(cyc(f, 2)) * 12, width: 1120,
        filter: "drop-shadow(0 24px 30px rgba(30,15,8,0.5))" }} />
      <XPlush src="mascot/cheer" x={60} y={1380} w={520} ph={0.5} />
      <XPlush src="friends/fox" x={2420} y={1440} w={420} ph={2.7} flip />
      <Snow w={SEARCH_W} h={SEARCH_H} n={70} period={HDR_DUR} size={64} laps={[2, 3, 4]} />
    </AbsoluteFill>
  );
};
