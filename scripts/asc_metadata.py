#!/usr/bin/env python3
"""Fill all App Store Connect metadata for Snuglo, in en-US / tr / es-ES.

Sets: version string, category, age rating, per-locale name/subtitle/privacy URL
(appInfoLocalizations) and description/keywords/promo/support URL
(appStoreVersionLocalizations). Idempotent (creates or patches). Screenshots are
handled by asc_screenshots.py.
"""
import sys
from asc_client import client_from_env, APIError

LOCALES = ["en-US", "tr", "es-ES"]

NAME = "Snuglo"

SUBTITLE = {
    "en-US": "Cozy block-logic puzzles",
    "tr":    "Sıcacık blok bulmacaları",
    "es-ES": "Puzles de bloques zen",
}

PRIVACY_URL = {
    "en-US": "https://felabs.app/apps/snuglo/en/privacy-policy.html",
    "tr":    "https://felabs.app/apps/snuglo/tr/privacy-policy.html",
    "es-ES": "https://felabs.app/apps/snuglo/es/privacy-policy.html",
}

SUPPORT_URL = {
    "en-US": "https://felabs.app/apps/snuglo/en/support.html",
    "tr":    "https://felabs.app/apps/snuglo/tr/support.html",
    "es-ES": "https://felabs.app/apps/snuglo/es/support.html",
}

KEYWORDS = {
    "en-US": "puzzle,block,blocks,logic,brain,relax,zen,cozy,jigsaw,tangram,grid,calm,offline,daily",
    "tr":    "bulmaca,blok,mantık,zeka,rahatla,zen,sıcacık,puzzle,oyun,günlük,sakin,çevrimdışı,beyin",
    "es-ES": "puzzle,bloques,lógica,cerebro,relajar,zen,rompecabezas,calma,diario,mente,fichas",
}

PROMO = {
    "en-US": "Fit the pieces, fill the board, and unwind. 1000+ cozy puzzles, a daily challenge, a relaxing Zen mode, and a Tower climb await.",
    "tr":    "Parçaları yerleştir, tahtayı doldur, rahatla. 1000+ sıcacık bulmaca, günlük meydan okuma, huzurlu Zen modu ve Kule tırmanışı seni bekliyor.",
    "es-ES": "Coloca las piezas, llena el tablero y relájate. Más de 1000 puzles acogedores, un reto diario, un modo Zen y la Torre te esperan.",
}

DESC = {
"en-US": """Snuglo is a cozy block-logic puzzle you can sink into. Drag the pieces onto the board and fit them together with no gaps or overlaps — simple to learn, soothing to play, and surprisingly clever as the grids grow.

Take your time. Snuglo is built to relax, not rush.

✦ 1000+ HANDCRAFTED LEVELS
Seventeen themed packs that grow from gentle 5×5 boards to brain-bending 8×8 challenges. Unlock the next pack as you play.

✦ ZEN MODE
No timer, no fail — just you and the pieces, in a calm, soothing palette to unwind any time.

✦ DAILY PUZZLE
A fresh, hand-picked puzzle every day, with streaks to keep the cozy habit going.

✦ TOWER CLIMB
Feeling bold? Spend a ticket and climb floor by floor against the clock — one slip ends the run.

✦ COLLECT & CUSTOMIZE
Earn coins, gems and keys as you play. Open treasure chests, unlock block skins and boards, and make Snuglo yours.

✦ PLAY YOUR WAY
Hints, undo and shuffle when you want a nudge. Game Center leaderboards and achievements when you want a challenge.

Snuglo is free to play, with optional purchases and a Premium upgrade (unlimited energy, no ads, and every pack and cosmetic unlocked).

Cozy up and start solving. 🧩""",

"tr": """Snuglo, içine huzurla dalabileceğin sıcacık bir blok-mantık bulmacası. Parçaları tahtaya sürükle ve boşluk ya da üst üste binme olmadan yerleştir — öğrenmesi kolay, oynaması huzur verici, ızgaralar büyüdükçe şaşırtıcı derecede zekice.

Acele yok. Snuglo rahatlatmak için tasarlandı.

✦ 1000+ EL YAPIMI BÖLÜM
Nazik 5×5 tahtalardan zorlu 8×8 meydan okumalarına uzanan on yedi temalı paket. Oynadıkça sonrakini aç.

✦ ZEN MODU
Süre yok, kaybetme yok — sadece sen ve parçalar; istediğin an rahatlatan sakin bir palet.

✦ GÜNÜN BULMACASI
Her gün özenle seçilmiş yeni bir bulmaca; sıcacık alışkanlığı sürdürmek için seriler.

✦ KULE TIRMANIŞI
Cesur musun? Bir bilet harca ve zamana karşı kat kat tırman — tek hata seni eler.

✦ TOPLA & ÖZELLEŞTİR
Oynarken altın, elmas ve anahtar kazan. Sandıkları aç, blok görünümleri ve tahtalar aç, Snuglo'yu kendine ait kıl.

✦ KENDİ TARZINDA OYNA
İstediğinde ipucu, geri al ve karıştır. Meydan okumak istediğinde Game Center liderlik tabloları ve başarımlar.

Snuglo ücretsizdir; isteğe bağlı satın almalar ve Premium yükseltme (sınırsız enerji, reklamsız, tüm paketler ve kozmetikler açık) içerir.

Rahatına bak ve çözmeye başla. 🧩""",

"es-ES": """Snuglo es un acogedor puzle de lógica de bloques en el que perderte. Arrastra las piezas al tablero y encájalas sin huecos ni solapamientos: fácil de aprender, relajante de jugar y sorprendentemente ingenioso a medida que crecen los tableros.

Tómate tu tiempo. Snuglo está hecho para relajar, no para correr.

✦ MÁS DE 1000 NIVELES HECHOS A MANO
Diecisiete paquetes temáticos que van de suaves tableros 5×5 a desafíos 8×8 para exprimir la mente. Desbloquea el siguiente jugando.

✦ MODO ZEN
Sin tiempo, sin perder: solo tú y las piezas, con una paleta serena para desconectar cuando quieras.

✦ PUZLE DIARIO
Un puzle nuevo y elegido a mano cada día, con rachas para mantener el hábito acogedor.

✦ TORRE
¿Te atreves? Gasta un ticket y sube piso a piso contra el reloj: un fallo termina la partida.

✦ COLECCIONA Y PERSONALIZA
Gana monedas, gemas y llaves jugando. Abre cofres, desbloquea aspectos y tableros, y haz tuyo Snuglo.

✦ JUEGA A TU MANERA
Pistas, deshacer y mezclar cuando quieras una ayuda. Clasificaciones y logros de Game Center cuando quieras un reto.

Snuglo es gratis, con compras opcionales y una mejora Premium (energía ilimitada, sin anuncios y todos los paquetes y cosméticos desbloqueados).

Ponte cómodo y empieza a resolver. 🧩""",
}


def main():
    apply = "--apply" in sys.argv
    c, app = client_from_env()
    print(f"App {app} | {'APPLY' if apply else 'DRY-RUN'}\n")

    # ── Editable version ──
    vers = c.request("GET", f"/v1/apps/{app}/appStoreVersions", params={"limit": "10"})
    ver = next((v for v in vers["data"]
                if v["attributes"]["appStoreState"] in
                ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")), None)
    if not ver:
        sys.exit("✗ Düzenlenebilir App Store sürümü yok.")
    vid = ver["id"]
    print(f"Version {vid} | {ver['attributes']['versionString']} → 1.1.0")

    # ── appInfo ──
    ai = c.request("GET", f"/v1/apps/{app}/appInfos")["data"][0]
    aid = ai["id"]

    if not apply:
        print("(dry-run) — değişiklik yazılmayacak. --apply ile çalıştır.")
        return

    # 1) version string
    c.request("PATCH", f"/v1/appStoreVersions/{vid}",
              body={"data": {"type": "appStoreVersions", "id": vid,
                             "attributes": {"versionString": "1.1.0"}}})
    print("✓ versionString = 1.1.0")

    # 2) category (Games → Puzzle)
    try:
        c.request("PATCH", f"/v1/appInfos/{aid}",
                  body={"data": {"type": "appInfos", "id": aid, "relationships": {
                      "primaryCategory": {"data": {"type": "appCategories", "id": "GAMES"}},
                      "primarySubcategoryOne": {"data": {"type": "appCategories", "id": "GAMES_PUZZLE"}},
                  }}})
        print("✓ category = Games / Puzzle")
    except APIError as e:
        print(f"  ⚠ category: {e}")

    # 3) appInfoLocalizations (name, subtitle, privacy URL)
    existing_il = {l["attributes"]["locale"]: l["id"]
                   for l in c.request("GET", f"/v1/appInfos/{aid}/appInfoLocalizations")["data"]}
    for loc in LOCALES:
        attrs = {"name": NAME, "subtitle": SUBTITLE[loc], "privacyPolicyUrl": PRIVACY_URL[loc]}
        if loc in existing_il:
            c.request("PATCH", f"/v1/appInfoLocalizations/{existing_il[loc]}",
                      body={"data": {"type": "appInfoLocalizations", "id": existing_il[loc], "attributes": attrs}})
            print(f"  ✓ appInfoLoc {loc} (patched)")
        else:
            attrs["locale"] = loc
            c.request("POST", "/v1/appInfoLocalizations",
                      body={"data": {"type": "appInfoLocalizations", "attributes": attrs,
                                     "relationships": {"appInfo": {"data": {"type": "appInfos", "id": aid}}}}})
            print(f"  + appInfoLoc {loc} (created)")

    # 4) appStoreVersionLocalizations (description, keywords, promo, support)
    existing_vl = {l["attributes"]["locale"]: l["id"]
                   for l in c.request("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]}
    def clean(s):  # App Store description rejects emoji / decorative glyphs
        for ch in ("✦ ", "✦", " 🧩", "🧩"):
            s = s.replace(ch, "")
        return s.strip()

    for loc in LOCALES:
        attrs = {"description": clean(DESC[loc]), "keywords": KEYWORDS[loc],
                 "promotionalText": PROMO[loc], "supportUrl": SUPPORT_URL[loc]}
        try:
            if loc in existing_vl:
                c.request("PATCH", f"/v1/appStoreVersionLocalizations/{existing_vl[loc]}",
                          body={"data": {"type": "appStoreVersionLocalizations", "id": existing_vl[loc], "attributes": attrs}})
                print(f"  ✓ versionLoc {loc} (patched)")
            else:
                attrs["locale"] = loc
                c.request("POST", "/v1/appStoreVersionLocalizations",
                          body={"data": {"type": "appStoreVersionLocalizations", "attributes": attrs,
                                         "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
                print(f"  + versionLoc {loc} (created)")
        except APIError as e:
            print(f"  ⚠ versionLoc {loc}: {e}")

    # 5) age rating — 4+ puzzle, everything NONE/false
    try:
        ard = c.request("GET", f"/v1/appInfos/{aid}/ageRatingDeclaration").get("data")
        if ard:
            rid = ard["id"]
            none_fields = ["alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated",
                           "medicalOrTreatmentInformation", "profanityOrCrudeHumor",
                           "sexualContentGraphicAndNudity", "sexualContentOrNudity",
                           "horrorOrFearThemes", "matureOrSuggestiveThemes",
                           "violenceCartoonOrFantasy", "violenceRealistic",
                           "violenceRealisticProlongedGraphicOrSadistic", "gunsOrOtherWeapons"]
            attrs = {f: "NONE" for f in none_fields}
            attrs.update({
                "gambling": False,
                "unrestrictedWebAccess": False,
                "advertising": True,           # app shows ads
                "healthOrWellnessTopics": False,
                "messagingAndChat": False,
                "gunsOrOtherWeapons": "NONE",
                "userGeneratedContent": False,
                "parentalControls": False,
                "lootBox": False,              # chests pay coins/gems; verify in ASC if needed
                "ageAssurance": False,
            })
            c.request("PATCH", f"/v1/ageRatingDeclarations/{rid}",
                      body={"data": {"type": "ageRatingDeclarations", "id": rid, "attributes": attrs}})
            print("✓ age rating (4+, all none)")
    except APIError as e:
        print(f"  ⚠ age rating: {e}")

    print("\n✓ Metadata bitti.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(f"\n✗ API hatası: {e}")
