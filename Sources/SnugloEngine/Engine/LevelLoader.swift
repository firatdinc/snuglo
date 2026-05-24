import Foundation

/// Bundle içindeki `Resources/Levels/*.json` dosyalarından `Level` yükler.
///
/// > **v0.1 İskelet:** JSON dosyaları henüz eklenmedi.
/// > Gerçek içerik `v0.2` task'ında tamamlanacak.
/// > Şu an herhangi bir isim için `LoaderError.notFound` fırlatır.
public struct LevelLoader: Sendable {

    public init() {}

    // MARK: - Hata Türü

    public enum LoaderError: Error, Equatable {
        /// Belirtilen isimde JSON dosyası bundle'da bulunamadı.
        case notFound(String)
        /// JSON decode başarısız.
        case decodingFailed(String)
    }

    // MARK: - Public API

    /// SPM module bundle'ından `Resources/Levels/<name>.json` yükler.
    ///
    /// `Bundle.module` SPM tarafından `internal` üretildiğinden default
    /// parametre olarak kullanılamaz; bu overload onu kapsüller.
    ///
    /// - Parameter name: Dosya adı (uzantısız), örn. `"pack1-01"`.
    /// - Throws: `LoaderError.notFound` veya `LoaderError.decodingFailed`.
    public func loadLevel(named name: String) throws -> Level {
        try loadLevel(named: name, in: .module)
    }

    /// Özel bundle ile `Resources/Levels/<name>.json` yükler (test injection için).
    ///
    /// - Parameters:
    ///   - name: Dosya adı (uzantısız).
    ///   - bundle: Aranacak bundle.
    /// - Throws: `LoaderError.notFound` veya `LoaderError.decodingFailed`.
    public func loadLevel(named name: String, in bundle: Bundle) throws -> Level {
        guard let url = bundle.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "Levels"
        ) else {
            throw LoaderError.notFound(name)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoaderError.notFound(name)
        }

        do {
            return try JSONDecoder().decode(Level.self, from: data)
        } catch {
            throw LoaderError.decodingFailed(name)
        }
    }
}
