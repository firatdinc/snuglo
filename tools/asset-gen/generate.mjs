#!/usr/bin/env node
// Generate game art with OpenAI gpt-image-1 and drop each result straight into
// the Xcode asset catalog as an .imageset, so SwiftUI can use Image("<name>").
//
// Usage:
//   OPENAI_API_KEY=sk-... node tools/asset-gen/generate.mjs [options]
// Options:
//   --manifest <path>   asset list (default: tools/asset-gen/manifest.json)
//   --out <path>        .xcassets dir (default: SnugloApp/Resources/Assets.xcassets)
//   --quality <q>       low | medium | high  (default: medium — cheaper)
//   --size <s>          1024x1024 | 1024x1536 | 1536x1024  (default: 1024x1024)
//   --only <name>       generate just one asset by name
//   --force             overwrite assets that already exist
//   --dry-run           print the prompts/cost estimate, call no API

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
import path from "path";

const args = process.argv.slice(2);
const opt = (flag, def) => {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};
const has = (flag) => args.includes(flag);

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const MANIFEST = path.resolve(ROOT, opt("--manifest", "tools/asset-gen/manifest.json"));
const OUT = path.resolve(ROOT, opt("--out", "SnugloApp/Resources/Assets.xcassets"));
const QUALITY = opt("--quality", "medium");
const SIZE = opt("--size", "1024x1024");
const ONLY = opt("--only", null);
const FORCE = has("--force");
const DRY = has("--dry-run");

// Consistent house style so every asset matches the "Vibrant Play" look.
const STYLE_PREFIX =
  "Bright, friendly mobile-game illustration in a soft 3D / cute vector style. " +
  "Vivid playful colors, clean rounded shapes, gentle soft shadows, centered single subject, " +
  "high detail, transparent background, no text, no UI, no border.";

// Rough gpt-image-1 cost per 1024px image (USD) — for the dry-run estimate only.
const COST = { low: 0.011, medium: 0.042, high: 0.167 };

function contentsJson(file) {
  return JSON.stringify(
    {
      images: [{ filename: file, idiom: "universal" }],
      info: { author: "asset-gen", version: 1 },
      properties: { "template-rendering-intent": "original" },
    },
    null,
    2
  );
}

async function genOne(asset, key) {
  const dir = path.join(OUT, `${asset.name}.imageset`);
  const png = path.join(dir, `${asset.name}.png`);
  if (existsSync(png) && !FORCE) {
    console.log(`• skip (exists): ${asset.name}`);
    return;
  }
  const prompt = `${STYLE_PREFIX}\n\nSubject: ${asset.prompt}`;
  if (DRY) {
    console.log(`• [dry] ${asset.name} (${asset.size || SIZE}) — ${asset.prompt.slice(0, 70)}`);
    return;
  }
  const res = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      model: "gpt-image-1",
      prompt,
      n: 1,
      size: asset.size || SIZE,
      quality: asset.quality || QUALITY,
      background: "transparent",
    }),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`API ${res.status} for "${asset.name}": ${txt.slice(0, 300)}`);
  }
  const data = await res.json();
  const b64 = data?.data?.[0]?.b64_json;
  if (!b64) throw new Error(`No image returned for "${asset.name}"`);
  mkdirSync(dir, { recursive: true });
  writeFileSync(png, Buffer.from(b64, "base64"));
  writeFileSync(path.join(dir, "Contents.json"), contentsJson(`${asset.name}.png`));
  console.log(`✓ ${asset.name} → ${path.relative(ROOT, png)}`);
}

async function main() {
  const key = process.env.OPENAI_API_KEY;
  if (!key && !DRY) {
    console.error("OPENAI_API_KEY env yok. Örn: OPENAI_API_KEY=sk-... node tools/asset-gen/generate.mjs");
    process.exit(1);
  }
  let manifest = JSON.parse(readFileSync(MANIFEST, "utf-8"));
  if (ONLY) manifest = manifest.filter((a) => a.name === ONLY);
  if (manifest.length === 0) {
    console.error("Manifest boş (veya --only eşleşmedi).");
    process.exit(1);
  }
  const est = manifest.length * (COST[QUALITY] ?? COST.medium);
  console.log(`${manifest.length} asset · kalite=${QUALITY} · ~$${est.toFixed(2)} tahmini · çıktı=${path.relative(ROOT, OUT)}`);
  for (const asset of manifest) {
    try {
      await genOne(asset, key);
    } catch (e) {
      console.error(`✗ ${asset.name}: ${e.message}`);
    }
  }
  console.log("bitti.");
}

main();
