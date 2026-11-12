import React from "react";
import { AbsoluteFill, Img, OffthreadVideo, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig, Easing } from "remotion";
import { Audio, Video } from "@remotion/media";
import { AdProps, C, Confetti, FONT } from "./common";
import { FabricWord } from "./FabricWord";
import { L, Snd } from "./vShared";
import { FC, Music, Seg } from "./vShared2";
import { YP_BOX } from "./ypBox";

/**
 * 15) "Çekim 47" setinin oyunlu kurgusu: molada Snuglo telefonda Snuglo oynuyor,
 * kamera telefona dalıp oynanışa geçiyor, geri çıkınca ekip de izliyor ve uyukluyor,
 * Çekim 48'de herkes uyuyor. Oynanış yeşil ekrana per-kare kutu ile oturtulur.
 */

// ---- zaman çizelgesi (30 fps) ----
const A = 214;                 // Çekim 47 (xf_take1)
const P1 = A;                  // telefon sahnesi başı
const ZIN0 = P1 + 46, ZIN1 = P1 + 68;     // telefona dalış
const FULL1 = P1 + 248;                   // tam ekran oynanış sonu
const ZOUT1 = FULL1 + 24;                 // geri çıkış sonu
const P2_TRIM = 80;                       // yp_phone'da (comp karesi) geri dönüş noktası
const P2_LEN = 238 - P2_TRIM;             // klibin geri kalanı
const B = FULL1 + P2_LEN;                 // Çekim 48 başı
const BL = 236;
const END = B + BL;
export const VIRAL_PLAY_END = END;
export const VIRAL_PLAY_DUR = END + 126;

const ZMAX = 3.32;
const S = 1.5; // 720 -> 1080

// telefon klibinin wall-kare -> klip comp karesi eşlemesi (null: görünmez/donuk)
const clipFrame = (f: number): number => {
  if (f < FULL1) return Math.min(f - P1, ZIN1 - P1);
  return P2_TRIM + (f - FULL1);
};
const box = (cf: number) => {
  const i = Math.max(0, Math.min(YP_BOX.length - 1, Math.floor((cf * 24) / 30)));
  const [x0, y0, x1, y1] = YP_BOX[i];
  return { x0: x0 * S - 5, y0: y0 * S - 5, x1: x1 * S + 5, y1: y1 * S + 5 };
};
const zoomAt = (f: number) => {
  const e = Easing.inOut(Easing.cubic);
  if (f < ZIN0) return 1;
  if (f < ZIN1) return 1 + (ZMAX - 1) * e((f - ZIN0) / (ZIN1 - ZIN0));
  if (f < FULL1) return ZMAX;
  if (f < ZOUT1) return ZMAX - (ZMAX - 1) * e((f - FULL1) / (ZOUT1 - FULL1));
  return 1;
};

/** Ekrandaki oynanış (wall kare -> hangi klip). */
type Beat = { from: number; to: number; clip: string; trim: number; vol: number };
const beats = (): Beat[] => [
  { from: P1, to: P1 + 116, clip: "xm_solve", trim: 18, vol: 0.5 },
  { from: P1 + 108, to: P1 + 186, clip: "xm_treeslow", trim: 60, vol: 0.5 },
  { from: P1 + 178, to: FULL1 + 12, clip: "xm_cbake", trim: 40, vol: 0.5 },
  { from: FULL1 + 4, to: B + 12, clip: "xm_quilt", trim: 70, vol: 0.18 },
];

const ScreenGame: React.FC<{ lang: AdProps["lang"] }> = ({ lang }) => {
  const f = useCurrentFrame() + P1; // Sequence P1'den başlar
  const z = zoomAt(f);
  const cf = clipFrame(f);
  const b = box(cf);
  const cx = (b.x0 + b.x1) / 2, cy = (b.y0 + b.y1) / 2;
  const t = (z - 1) / (ZMAX - 1);
  const tx = cx + (540 - cx) * t, ty = cy + (960 - cy) * t;
  const L0 = tx + z * (b.x0 - cx), T0 = ty + z * (b.y0 - cy);
  const W = z * (b.x1 - b.x0), H = z * (b.y1 - b.y0);
  const glare = interpolate(t, [0, 1], [0.1, 0]);
  return (
    <AbsoluteFill>
      <div style={{ position: "absolute", left: L0, top: T0, width: W, height: H, overflow: "hidden", borderRadius: 26 * z, background: "#120a05" }}>
        {beats().map((bt, i) => (
          <Sequence key={i} from={bt.from - P1} durationInFrames={bt.to - bt.from}>
            <BeatVid bt={bt} lang={lang} full={i > 0 && i < 3} />
          </Sequence>
        ))}
        <AbsoluteFill style={{ background: `linear-gradient(160deg, rgba(255,255,255,${glare}) 0%, rgba(255,255,255,0) 45%)` }} />
      </div>
    </AbsoluteFill>
  );
};
const BeatVid: React.FC<{ bt: Beat; lang: AdProps["lang"]; full: boolean }> = ({ bt, lang }) => {
  const f = useCurrentFrame();
  const d = bt.to - bt.from;
  // ekranlar arası telefon içi kaydırma geçişi
  const inX = interpolate(f, [0, 8], [100, 0], { extrapolateRight: "clamp", easing: Easing.out(Easing.cubic) });
  const first = bt.clip === "xm_solve" || bt.clip === "xm_quilt";
  return (
    <AbsoluteFill style={{ transform: first ? undefined : `translateX(${inX}%)` }}>
      <Video src={staticFile(`clips/${bt.clip}_${lang}.mp4`)} trimBefore={bt.trim} volume={(fr) => bt.vol * interpolate(fr, [0, 6, d - 8, d], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </AbsoluteFill>
  );
};

/** Anahtarlanmış (şeffaf ekranlı) telefon çekimi + aynı yakınlaştırma. */
const PhoneShot: React.FC = () => {
  const f = useCurrentFrame() + P1;
  const z = zoomAt(f);
  const cf = clipFrame(f);
  const b = box(cf);
  const cx = (b.x0 + b.x1) / 2, cy = (b.y0 + b.y1) / 2;
  const t = (z - 1) / (ZMAX - 1);
  const tx = cx + (540 - cx) * t, ty = cy + (960 - cy) * t;
  // dış dünya: dalışın sonunda kaybolur, çıkışın başında geri gelir
  const op = f < FULL1 ? interpolate(f, [ZIN1 - 8, ZIN1], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })
                       : interpolate(f, [FULL1, FULL1 + 8], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const blur = interpolate(t, [0, 0.4, 1], [0, 1.5, 6]);
  return (
    <AbsoluteFill style={{ opacity: op, filter: blur > 0.05 ? `blur(${blur}px)` : undefined }}>
      <div style={{ position: "absolute", left: 0, top: 0, width: 1080, height: 1920, transformOrigin: "0 0", transform: `translate(${tx - z * cx}px, ${ty - z * cy}px) scale(${z})` }}>
        <Sequence durationInFrames={ZIN1 - P1 + 1}>
          <OffthreadVideo src={staticFile("clips/yp_phone_key.mov")} transparent muted style={{ width: 1080, height: 1920 }} />
        </Sequence>
        <Sequence from={FULL1 - P1} durationInFrames={P2_LEN + 12}>
          <OffthreadVideo src={staticFile("clips/yp_phone_key.mov")} trimBefore={P2_TRIM} transparent muted style={{ width: 1080, height: 1920 }} />
        </Sequence>
      </div>
    </AbsoluteFill>
  );
};

/** Telefon sahnesinin ortam sesi (klipten), görünmezken kısılır. */
const PhoneAudio: React.FC = () => (
  <>
    <Sequence from={P1} durationInFrames={ZIN1 - P1 + 8}>
      <Audio src={staticFile("clips/yp_phone.mp4")} volume={(fr) => 0.8 * interpolate(fr, [0, 10, ZIN1 - P1 - 6, ZIN1 - P1 + 8], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
    </Sequence>
    <Sequence from={FULL1} durationInFrames={P2_LEN + 10}>
      <Audio src={staticFile("clips/yp_phone.mp4")} trimBefore={P2_TRIM} volume={(fr) => 0.8 * interpolate(fr, [0, 12, P2_LEN - 6, P2_LEN + 10], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })} />
    </Sequence>
  </>
);

/** Altyazı (ViralX ile aynı dil). */
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

/** Oynanış özellik etiketi (tam ekranda). */
const Tag: React.FC<{ at: number; dur: number; text: string }> = ({ at, dur, text }) => (
  <Sequence from={at} durationInFrames={dur}>
    <FabricWord text={text} at={0} out={dur - 10} y={300} size={88} seed={4} x={90} width={840} />
  </Sequence>
);

/* ---------- App Store rozeti (Apple resmi rozetinin birebir taklidi; resmisi ile değiştirilebilir) ---------- */
const APPLE = "M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701";
export const StoreBadge: React.FC<{ lang: AdProps["lang"]; width?: number }> = ({ lang, width = 520 }) => {
  const h = width * 0.3;
  const small = L(lang, "Download on the", "App Store'dan");
  const big = L(lang, "App Store", "İndirin");
  return (
    <div style={{ width, height: h, background: "#000", borderRadius: h * 0.2, border: `${Math.max(2, h * 0.018)}px solid #A6A6A6`, display: "flex", alignItems: "center", justifyContent: "center", gap: h * 0.12, boxSizing: "border-box" }}>
      <svg viewBox="0 0 24 24" width={h * 0.5} height={h * 0.5}><path d={APPLE} fill="#fff" /></svg>
      <div style={{ display: "flex", flexDirection: "column", color: "#fff", fontFamily: "-apple-system, 'SF Pro Display', 'Helvetica Neue', Arial, sans-serif", lineHeight: 1 }}>
        <span style={{ fontSize: h * 0.2, fontWeight: 500, letterSpacing: 0.3 }}>{small}</span>
        <span style={{ fontSize: h * 0.42, fontWeight: 600, letterSpacing: -0.5, marginTop: h * 0.03 }}>{big}</span>
      </div>
    </div>
  );
};

/** Bitiş kartı: logo, maskot, rozet ve link çıkartması için ayrılmış güvenli alan. */
export const LinkEndCard: React.FC<AdProps & { line: [string, string]; linkText: boolean }> = ({ lang, line, linkText }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = spring({ frame: f, fps, config: { damping: 11, stiffness: 160 } });
  const mas = spring({ frame: f - 6, fps, config: { damping: 9, stiffness: 140 } });
  const bad = spring({ frame: f - 14, fps, config: { damping: 12, stiffness: 180 } });
  const boxO = interpolate(f, [22, 34], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const pulse = 1 + Math.sin(f / 8) * 0.012;
  return (
    <AbsoluteFill>
      <Img src={staticFile("art/scene/snow.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(40,20,10,.15), rgba(40,20,10,.35))" }} />
      {/* güvenli alan: üst 250, alt 350, sağ 150 px boş */}
      <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: 175, top: 280, width: 640, transform: `scale(${logo})` }} />
      <FabricWord text={L(lang, line[0], line[1])} at={8} y={600} size={L(lang, 74, 64)} seed={2} x={80} width={830} />
      <Img src={staticFile("art/xmas/mascot/idle.png")} style={{ position: "absolute", left: 375, top: 815, width: 240, transform: `scale(${mas}) rotate(${Math.sin(f / 9) * 1.5}deg)` }} />
      <div style={{ position: "absolute", left: 495 - 260, top: 1105, transform: `scale(${bad})` }}>
        <StoreBadge lang={lang} width={520} />
      </div>
      <div style={{ position: "absolute", left: 175, top: 1330, width: 640, height: 200, borderRadius: 34, border: "6px dashed rgba(255,255,255,.95)", background: "rgba(255,255,255,.16)", opacity: boxO, transform: `scale(${pulse})`, display: "flex", alignItems: "center", justifyContent: "center", boxSizing: "border-box" }}>
        {linkText && (
          <span style={{ fontFamily: FONT, fontWeight: 700, fontSize: L(lang, 52, 46), color: "#fff", textAlign: "center", lineHeight: 1.1, WebkitTextStroke: `7px ${C.ink}`, paintOrder: "stroke fill" }}>
            {L(lang, "Tap the link to play ↓", "Linke dokun, hemen oyna ↓")}
          </span>
        )}
      </div>
    </AbsoluteFill>
  );
};

const Play15: React.FC<AdProps & { linkText: boolean }> = ({ lang, linkText }) => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* Çekim 47 */}
    <Seg first from={0} dur={A}><FC clip="yt_take1" dur={A + 10} vol={1} ain={2} aout={10} /></Seg>
    <Cap at={2} dur={66} y={150} size={L(lang, 74, 74)} text={L(lang, "Our Christmas ad. Take 47.", "Noel reklamımız. Çekim 47.")} />
    <Cap at={74} dur={80} y={1520} size={L(lang, 68, 66)} text={L(lang, "“Okay. Look EXCITED!”", "“Tamam. Şimdi HEYECANLI ol!”")} />
    <Cap at={172} dur={40} y={1520} size={L(lang, 68, 66)} text={L(lang, "“…5 minute break.”", "“…5 dakika mola.”")} />

    {/* Mola: telefon + oynanış (dalış/çıkış) */}
    <Seg from={P1} dur={B - P1} fade={10}>
      <AbsoluteFill style={{ background: "#2a160c" }}>
        <Sequence from={0}><ScreenGame lang={lang} /></Sequence>
        <PhoneShot />
      </AbsoluteFill>
    </Seg>
    <PhoneAudio />
    <Tag at={ZIN1 - 4} dur={P1 + 112 - ZIN1 + 4} text={L(lang, "Advent Quilt", "Advent Yorganı")} />
    <Tag at={P1 + 110} dur={78} text={L(lang, "Christmas Village", "Noel Köyü")} />
    <Tag at={P1 + 182} dur={FULL1 - P1 - 182 + 4} text={L(lang, "Bake cookies", "Kurabiye pişir")} />
    <Cap at={ZOUT1 + 4} dur={70} y={150} size={L(lang, 70, 70)} text={L(lang, "The break… ran long.", "Mola… biraz uzadı.")} />
    <Snd at={ZIN0 - 2} src="rustle" vol={0.3} />
    <Snd at={FULL1 - 2} src="rustle" vol={0.25} />

    {/* Çekim 48 */}
    <Seg from={B} dur={BL} fade={12}><FC clip="xf_take2" dur={BL + 10} vol={1} ain={8} /></Seg>
    <Cap at={B + 100} dur={100} y={150} size={140} pop text={L(lang, "Take 48.", "Çekim 48.")} />
    <Cap at={B + 150} dur={80} y={1500} size={L(lang, 64, 62)} text={L(lang, "Turns out it's too cozy to film.", "Meğer çekilemeyecek kadar rahatlatıcıymış.")} />

    <Music at={P1 + 30} dur={VIRAL_PLAY_DUR - P1 - 30} vol={0.22} fadeIn={90} fadeOut={30} />

    {/* Bitiş */}
    <Seg from={END} dur={126} fade={14}><LinkEndCard lang={lang} line={["Christmas is here. Cozy up.", "Noel geldi. Keyfine bak."]} linkText={linkText} /></Seg>
    <Sequence from={END + 10}><Confetti at={0} x={495} y={1000} n={50} /></Sequence>
    <Snd at={END + 12} src="reward" vol={0.35} />
  </AbsoluteFill>
);

export const ViralPlay: React.FC<AdProps> = ({ lang }) => <Play15 lang={lang} linkText />;
export const ViralPlayLink: React.FC<AdProps> = ({ lang }) => <Play15 lang={lang} linkText={false} />;
