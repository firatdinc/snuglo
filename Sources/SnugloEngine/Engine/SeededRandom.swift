import Foundation

/// SplitMix64 tabanlı, deterministik, seed'li rastgele sayı üreteci.
/// Swift'in `RandomNumberGenerator` protokolünü uyguladığı için
/// `Int.random(in:using:)`, `Array.shuffled(using:)` gibi stdlib API'larıyla çalışır.
///
/// Referans: https://prng.di.unimi.it/splitmix64.c
public struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        // 0 state'i SplitMix64 için geçersiz — en az 1 yap
        self.state = seed == 0 ? 1 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}

// MARK: - SeedHash

public enum SeedHash {
    /// FNV-1a 64-bit, cross-run kararlı hash.
    ///
    /// Swift'in `Hashable.hashValue` / `String.hashValue` run'dan run'a farklı olabilir
    /// (randomized hashing), bu yüzden level seed'leri için FNV-1a kullanıyoruz.
    /// Aynı girdi her zaman aynı çıktıyı verir.
    public static func fnv1a(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325 // FNV offset basis
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 0x100000001b3       // FNV prime
        }
        return h
    }
}
