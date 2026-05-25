import Foundation

/// Bundle içindeki `Resources/Levels/*.json` dosyalarından `Level` yükler.
///
/// v0.1'de tam çalışır durumdadır; `notFound`, `readFailed` ve `decodingFailed`
/// hatalarını ayrı ayrı raporlar.
public struct LevelLoader: Sendable {

    public init() {}

    // MARK: - Hata Türü

    public enum LoaderError: Error, Equatable {
        /// Belirtilen isimde JSON dosyası bundle'da bulunamadı.
        case notFound(String)
        /// Dosya bulundu fakat disk okuma işlemi başarısız oldu.
        case readFailed(name: String, underlying: Error)
        /// JSON decode başarısız — içerik bozuk ya da şema değişti.
        case decodingFailed(name: String, underlying: Error)

        // `Error` protokolü `Equatable` değil; sadece name + case eşleşmesi yeter.
        public static func == (lhs: LoaderError, rhs: LoaderError) -> Bool {
            switch (lhs, rhs) {
            case (.notFound(let l), .notFound(let r)):
                return l == r
            case (.readFailed(let ln, _), .readFailed(let rn, _)):
                return ln == rn
            case (.decodingFailed(let ln, _), .decodingFailed(let rn, _)):
                return ln == rn
            default:
                return false
            }
        }
    }

    // MARK: - Public API (D3 — LevelGenerator entegrasyonu)

    /// Pack ID'den grid boyutunu döner (BLOCKER D3).
    ///
    /// | Pack ID             | Size |
    /// |---------------------|------|
    /// | "cozy-beginnings"   | 5    |
    /// | "spice-route"       | 6    |
    /// | "mambo-nights"      | 7    |
    /// | "woodland-retreat"  | 8    |
    ///
    /// Kısa form ("cozy", "spice", "mambo", "woodland") de desteklenir.
    public static func gridSize(for packId: String) -> Int {
        switch packId {
        case "cozy-beginnings", "cozy":     return 5
        case "spice-route", "spice":    return 6
        case "mambo-nights", "mambo":    return 7
        case "woodland-retreat", "woodland": return 8
        default:                            return 5
        }
    }

    /// Deterministik LevelGenerator üzerinden Level yükler (BLOCKER D3).
    ///
    /// `LevelGenerator.generate` hiçbir zaman throw etmez; imza BLOCKER D3 spec'i için
    /// `throws` olarak tanımlanmıştır (gelecekte disk/network kaynakları için).
    ///
    /// - Parameters:
    ///   - packId:     Pack tanımlayıcısı (örn. "cozy-beginnings").
    ///   - levelIndex: 1-tabanlı level numarası.
    ///   - seedBase:   Override seed (varsayılan: `LevelGenerator.defaultSeedBase`).
    /// - Returns: Deterministik `Level`.
    public func loadGenerated(
        packId: String,
        levelIndex: Int,
        seedBase: UInt64 = LevelGenerator.defaultSeedBase
    ) throws -> Level {
        let size = LevelLoader.gridSize(for: packId)
        return LevelGenerator().generate(
            packId: packId,
            levelIndex: levelIndex,
            gridSize: size,
            seedBase: seedBase
        )
        // NOTE: never actually throws — LevelGenerator.generate is infallible
    }

    // MARK: - Public API (JSON bundles)

    /// SPM module bundle'ından `<name>.json` yükler.
    ///
    /// `Bundle.module` SPM tarafından `internal` üretildiğinden default
    /// parametre olarak kullanılamaz; bu overload onu kapsüller.
    ///
    /// - Parameter name: Dosya adı (uzantısız), örn. `"level_5x5"`.
    /// - Throws: `LoaderError.notFound`, `.readFailed`, ya da `.decodingFailed`.
    public func loadLevel(named name: String) throws -> Level {
        try loadLevel(named: name, in: .module)
    }

    /// Özel bundle ile `<name>.json` yükler (test injection için).
    ///
    /// Not: SPM `.process("Resources")` kuralı tüm alt-dizinleri bundle root'una
    /// flatten ettiğinden `subdirectory` parametresi kullanılmaz.
    ///
    /// - Parameters:
    ///   - name: Dosya adı (uzantısız).
    ///   - bundle: Aranacak bundle.
    /// - Throws: `LoaderError.notFound`, `.readFailed`, ya da `.decodingFailed`.
    public func loadLevel(named name: String, in bundle: Bundle) throws -> Level {
        guard let url = bundle.url(
            forResource: name,
            withExtension: "json"
        ) else {
            throw LoaderError.notFound(name)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoaderError.readFailed(name: name, underlying: error)
        }

        do {
            return try JSONDecoder().decode(Level.self, from: data)
        } catch {
            throw LoaderError.decodingFailed(name: name, underlying: error)
        }
    }
}
