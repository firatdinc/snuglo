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

    // MARK: - Public API

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
