import React from "react";
import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio, Video } from "@remotion/media";
import { AdProps, FONT, Sfx } from "./common";
import { FabricWord } from "./FabricWord";

const L = <T,>(lang: string, en: T, tr: T) => (lang === "tr" ? tr : en);

/** Aynı odanın karesi: çok yavaş yaklaşan kamera. */
const Night: React.FC<{ src: string; from?: number; to?: number }> = ({ src, from = 1, to = 1.05 }) => {
  const f = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const z = interpolate(f, [0, durationInFrames], [from, to]);
  return (
    <AbsoluteFill style={{ background: "#05080F" }}>
      <Img src={staticFile(`art/viral/${src}.jpg`)} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${z})`, transformOrigin: "50% 55%" }} />
    </AbsoluteFill>
  );
};

/* Olay örgüsü: tek şaka. Yanlış hamle → Snuglo üç yılda yatağa varır. */
const HOOK = 72, DAY1 = HOOK + 72, DAY2 = DAY1 + 66, REST = DAY2 + 90, DAY3 = REST + 234;
export const VIRAL_NIGHT_DUR = DAY3 + 54;

export const ViralNight: React.FC<AdProps> = ({ lang }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = spring({ frame: f - DAY3, fps, config: { damping: 11, stiffness: 180 } });
  return (
    <AbsoluteFill style={{ background: "#05080F" }}>
      <Sequence durationInFrames={HOOK}>
        <Video src={staticFile(`clips/viral_story_${lang}.mp4`)} trimBefore={36} volume={0.8} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        <FabricWord text={L(lang, "you put it in the wrong spot.", "parçayı yanlış yere koydun.")} at={0} y={300} size={L(lang, 84, 96)} seed={1} />
      </Sequence>

      <Sequence from={HOOK} durationInFrames={DAY1 - HOOK}>
        <Night src="night1" />
        <FabricWord text={L(lang, "Day 1", "Gün 1")} at={2} y={120} size={150} seed={4} />
        <FabricWord text={L(lang, "Snuglo set off.", "Snuglo yola çıktı.")} at={22} y={1430} size={84} seed={6} />
      </Sequence>

      <Sequence from={DAY1} durationInFrames={DAY2 - DAY1}>
        <Night src="night2" />
        <FabricWord text={L(lang, "Day 212", "Gün 212")} at={2} y={120} size={150} seed={8} />
        <FabricWord text={L(lang, "Still coming.", "Hâlâ yolda.")} at={22} y={1430} size={92} seed={3} />
      </Sequence>

      <Sequence from={DAY2} durationInFrames={REST - DAY2}>
        <Night src="night_rest" />
        <FabricWord text={L(lang, "Day 640", "Gün 640")} at={2} y={120} size={150} seed={7} />
        <FabricWord text={L(lang, "Taking a break.", "Mola verdi.")} at={26} y={1430} size={92} seed={2} />
      </Sequence>

      <Sequence from={REST} durationInFrames={DAY3 - REST}>
        <AbsoluteFill>
          <Video src={staticFile("clips/flow_bedside.mp4")} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        </AbsoluteFill>
        <FabricWord text={L(lang, "Day 1095", "Gün 1095")} at={2} out={56} y={110} size={150} seed={9} />
        <FabricWord text={L(lang, "You shouldn't have put it there.", "Oraya koymayacaktın.")} at={70} out={165} y={110} size={L(lang, 92, 112)} seed={2} />
        <FabricWord text={L(lang, "Don't let it happen again.", "Bir daha olmasın.")} at={176} y={110} size={L(lang, 92, 116)} seed={5} />
      </Sequence>

      <Sequence from={DAY3}>
        <AbsoluteFill>
          <Img src={staticFile("art/viral/bedside_end.jpg")} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          <AbsoluteFill style={{ background: "rgba(5,8,15,0.45)" }} />
        </AbsoluteFill>
        <Img src={staticFile("art/logo.png")} style={{ position: "absolute", left: 140, top: 180, width: 800, transform: `scale(${logo})` }} />
        <div style={{ position: "absolute", left: 0, right: 0, top: 560, textAlign: "center", fontFamily: FONT, fontWeight: 700, fontSize: 62, color: "#fff", WebkitTextStroke: "8px #3A241A", paintOrder: "stroke fill", opacity: logo }}>
          {L(lang, "Free on the App Store", "App Store'da ücretsiz")}
        </div>
      </Sequence>

      {/* Ses: neşeli başlangıç, hatada kesilir, sonra müzik kutusu. */}
      <Sequence durationInFrames={43}>
        <Audio src={staticFile("snuglo_jingle.wav")} volume={0.38} />
      </Sequence>
      <Sequence from={43} durationInFrames={30}><Sfx src="error" vol={1} /></Sequence>
      <Sequence from={HOOK}>
        <Audio src={staticFile("night_box.wav")} volume={0.7} />
      </Sequence>
    </AbsoluteFill>
  );
};
