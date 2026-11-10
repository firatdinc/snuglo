import React from "react";
import { Composition, Folder, Sequence, staticFile, AbsoluteFill } from "remotion";
import { Audio } from "@remotion/media";
import { LangCtx, SChest, SEnd, SFriends, SHook, SPeek, SSolve, SWorlds, Sfx } from "./scenes/Scenes";
import { AppHeader, AppTour, HDR_DUR, HEADER_DUR, ProductHeader, SEARCH_H, SEARCH_W, SearchAsset, TOUR_DUR } from "./ads/Preview";
import { XmasHero, XmasPageHeader, XmasSearch, XmasTour, XHERO_DUR, XTOUR_DUR } from "./ads/PreviewXmas";
import { AdAsmr, AdChallenge, AdLastPiece, AdUgc, AdWrongMove, AppPreview, AD_ASMR_DUR, AD_CH_DUR, AD_LAST_DUR, AD_UGC_DUR, AD_WRONG_DUR, AP_DUR } from "./ads/Ads";
import { ViralNight, VIRAL_NIGHT_DUR } from "./ads/ViralNight";
import { ViralDisappointed, VIRAL_DISAPPOINTED_DUR } from "./ads/Viral";
import { ViralXmas, VIRAL_XMAS_DUR } from "./ads/ViralXmas";
import { ViralDefrost, VIRAL_DEFROST_DUR } from "./ads/ViralDefrost";
import { ViralAdvent, VIRAL_ADVENT_DUR } from "./ads/ViralAdvent";
import { ViralHibernate, VIRAL_HIBERNATE_DUR } from "./ads/ViralHibernate";

// 120 BPM: ölçü = 60 kare. Sahne kesmeleri ölçü/yarım ölçü çizgisinde.
const PLAN: [React.FC, number][] = [
  [SHook, 120], [SSolve, 120], [SPeek, 60], [SChest, 60], [SWorlds, 120], [SFriends, 120], [SEnd, 150],
];
const TOTAL = PLAN.reduce((a, [, d]) => a + d, 0);

export const SnugloAd: React.FC<{ lang: "en" | "tr" }> = ({ lang }) => {
  let at = 0;
  return (
    <LangCtx.Provider value={lang}>
      <AbsoluteFill style={{ background: "#000" }}>
        {PLAN.map(([S, d], i) => {
          const from = at; at += d;
          return (
            <Sequence key={i} from={from} durationInFrames={d} name={S.name}>
              <S />
              {i > 0 && <Sfx src={i % 2 ? "snap" : "click"} vol={0.6} />}
            </Sequence>
          );
        })}
        <Audio src={staticFile("snuglo_jingle.wav")} volume={0.9} />
        <Sequence from={630}><Sfx src="reward" vol={0.7} /></Sequence>
      </AbsoluteFill>
    </LangCtx.Provider>
  );
};

const V = { fps: 30, width: 1080, height: 1920 };
const ADS: [string, React.FC<{ lang: "en" | "tr" }>, number][] = [
  ["Showcase", SnugloAd, TOTAL], ["LastPiece", AdLastPiece, AD_LAST_DUR], ["WrongMove", AdWrongMove, AD_WRONG_DUR],
  ["Asmr", AdAsmr, AD_ASMR_DUR], ["Challenge", AdChallenge, AD_CH_DUR], ["Ugc", AdUgc, AD_UGC_DUR],
  ["ViralDisappointed", ViralDisappointed, VIRAL_DISAPPOINTED_DUR],
  ["ViralNight", ViralNight, VIRAL_NIGHT_DUR],
  ["ViralXmas", ViralXmas, VIRAL_XMAS_DUR],
  ["ViralDefrost", ViralDefrost, VIRAL_DEFROST_DUR],
  ["ViralAdvent", ViralAdvent, VIRAL_ADVENT_DUR],
  ["ViralHibernate", ViralHibernate, VIRAL_HIBERNATE_DUR],
];

export const MyComposition = () => (
  <>
    {(["en", "tr"] as const).map((lang) => (
      <Folder key={lang} name={lang.toUpperCase()}>
        {ADS.map(([id, C, d]) => (
          <Composition key={id} id={`${id}-${lang}`} component={C} durationInFrames={d} defaultProps={{ lang }} {...V} />
        ))}
      </Folder>
    ))}
    <Composition id="AppPreview" component={AppPreview} durationInFrames={AP_DUR} fps={30} width={886} height={1920} />
    <Folder name="StorePreviews">
      {(["en", "tr", "es"] as const).map((lang) => (
        <React.Fragment key={lang}>
          <Composition id={`Search-${lang}`} component={SearchAsset} durationInFrames={HDR_DUR} fps={30} width={SEARCH_W} height={SEARCH_H} defaultProps={{ lang }} />
          <Composition id={`PageHeader-${lang}`} component={ProductHeader} durationInFrames={HDR_DUR} fps={30} width={3840} height={1646} defaultProps={{ lang }} />
          <Composition id={`Hero-${lang}`} component={AppHeader} durationInFrames={HEADER_DUR} fps={30} width={886} height={1920} defaultProps={{ lang }} />
          <Composition id={`Tour-${lang}`} component={AppTour} durationInFrames={TOUR_DUR} fps={30} width={886} height={1920} defaultProps={{ lang }} />
        </React.Fragment>
      ))}
    </Folder>
    <Folder name="XmasStorePreviews">
      {(["en", "tr", "es"] as const).map((lang) => (
        <React.Fragment key={lang}>
          <Composition id={`XmasSearch-${lang}`} component={XmasSearch} durationInFrames={HDR_DUR} fps={30} width={SEARCH_W} height={SEARCH_H} defaultProps={{ lang }} />
          <Composition id={`XmasPageHeader-${lang}`} component={XmasPageHeader} durationInFrames={HDR_DUR} fps={30} width={3840} height={1646} defaultProps={{ lang }} />
          <Composition id={`XmasHero-${lang}`} component={XmasHero} durationInFrames={XHERO_DUR} fps={30} width={886} height={1920} defaultProps={{ lang }} />
          <Composition id={`XmasTour-${lang}`} component={XmasTour} durationInFrames={XTOUR_DUR} fps={30} width={886} height={1920} defaultProps={{ lang }} />
        </React.Fragment>
      ))}
    </Folder>
  </>
);
