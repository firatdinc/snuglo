# Asset generation (OpenAI gpt-image-1 → Xcode asset catalog)

Generates game illustrations with OpenAI's image API and writes each one
straight into `SnugloApp/Resources/Assets.xcassets` as an `.imageset`, so
SwiftUI can use it immediately via `Image("<name>")`.

## Setup
You need an OpenAI API key with image access + credit. **Do not paste the key
into chat or commit it.** Pass it as an env var.

## Run
```bash
# preview prompts + cost estimate, no API calls:
node tools/asset-gen/generate.mjs --dry-run

# generate everything in the manifest:
OPENAI_API_KEY=sk-... node tools/asset-gen/generate.mjs

# one asset only, higher quality:
OPENAI_API_KEY=sk-... node tools/asset-gen/generate.mjs --only mascot-hippo --quality high
```

Options: `--manifest <path>` · `--out <xcassets path>` · `--quality low|medium|high`
· `--size 1024x1024|1024x1536|1536x1024` · `--only <name>` · `--force` · `--dry-run`.

## Cost (rough, per 1024px image)
low ≈ $0.011 · medium ≈ $0.042 · high ≈ $0.167. The current 8-asset manifest at
medium ≈ $0.34. `--dry-run` prints an estimate before you spend anything.

## Adding assets
Edit `manifest.json` — add `{ "name": "...", "prompt": "..." }`. The `name` is
what you reference in Swift (`Image("name")`), so keep it stable. A shared house
style is prepended automatically (bright, soft-3D, transparent background) for
consistency; just describe the subject in `prompt`.
