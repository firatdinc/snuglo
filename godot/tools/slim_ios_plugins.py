"""ios/plugins altındaki xcframework'lerden iPhone cihazı (ios-arm64) dışındaki dilimleri siler.

RevenueCat çerçeveleri tvOS/watchOS/visionOS/macOS/simülatör kopyalarıyla ~850 MB geliyor;
oyun yalnız gerçek iPhone/iPad'e derleniyor (simülatör kullanılmıyor), geriye ~70 MB kalıyor.
Info.plist'teki AvailableLibraries da aynı şekilde süzülür, yoksa Xcode olmayan dilimi arar.

Kullanım: python3 tools/slim_ios_plugins.py [ios/plugins/revenue_cat]
"""
import os
import plistlib
import shutil
import sys

KEEP = {"ios-arm64", "ios-arm64_arm64e"}


def slim(xcf: str) -> int:
    plist_path = os.path.join(xcf, "Info.plist")
    with open(plist_path, "rb") as f:
        info = plistlib.load(f)
    libs = info.get("AvailableLibraries", [])
    kept = [lib for lib in libs if lib["LibraryIdentifier"] in KEEP]
    if not kept:
        print("atlandı (ios-arm64 yok):", xcf)
        return 0
    freed = 0
    for lib in libs:
        if lib["LibraryIdentifier"] in KEEP:
            continue
        d = os.path.join(xcf, lib["LibraryIdentifier"])
        if os.path.isdir(d):
            for root, _, files in os.walk(d):
                freed += sum(os.path.getsize(os.path.join(root, n)) for n in files if not os.path.islink(os.path.join(root, n)))
            shutil.rmtree(d)
    info["AvailableLibraries"] = kept
    with open(plist_path, "wb") as f:
        plistlib.dump(info, f)
    return freed


def main() -> None:
    root = sys.argv[1] if len(sys.argv) > 1 else "ios/plugins/revenue_cat"
    total = 0
    for name in sorted(os.listdir(root)):
        if name.endswith(".xcframework"):
            n = slim(os.path.join(root, name))
            total += n
            print("%-40s -%d MB" % (name, n // 2**20))
    print("toplam -%d MB" % (total // 2**20))


if __name__ == "__main__":
    main()
