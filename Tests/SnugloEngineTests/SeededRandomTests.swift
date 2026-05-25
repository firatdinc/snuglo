import XCTest
@testable import SnugloEngine

final class SeededRandomTests: XCTestCase {

    // MARK: - SeededRandom deterministik

    /// Aynı seed → aynı 100 sayı dizisi.
    func testDeterministicSequence() {
        var rng1 = SeededRandom(seed: 42)
        var rng2 = SeededRandom(seed: 42)
        let seq1 = (0..<100).map { _ in rng1.next() }
        let seq2 = (0..<100).map { _ in rng2.next() }
        XCTAssertEqual(seq1, seq2, "Aynı seed → özdeş dizi")
    }

    /// Farklı seed → farklı dizi (ilk 10 sayı karşılaştır).
    func testDifferentSeeds() {
        var rng1 = SeededRandom(seed: 1)
        var rng2 = SeededRandom(seed: 2)
        let seq1 = (0..<10).map { _ in rng1.next() }
        let seq2 = (0..<10).map { _ in rng2.next() }
        XCTAssertNotEqual(seq1, seq2, "Farklı seed → farklı dizi")
    }

    /// seed = 0 → 1 olarak normalize edilmeli (crash olmamalı).
    func testZeroSeedIsSafe() {
        var rng = SeededRandom(seed: 0)
        let v = rng.next()
        XCTAssertNotEqual(v, 0, "seed 0 bile geçerli output üretmeli")
    }

    /// UInt64.max seed ile de çalışmalı.
    func testMaxSeedIsSafe() {
        var rng = SeededRandom(seed: UInt64.max)
        let vals = (0..<5).map { _ in rng.next() }
        XCTAssertEqual(vals.count, 5)
    }

    /// stdlib API uyumluluğu: Int.random(in:using:) ile çalışmalı.
    func testStdlibIntegration() {
        var rng = SeededRandom(seed: 99)
        let v = Int.random(in: 0..<100, using: &rng)
        XCTAssertTrue(v >= 0 && v < 100)
    }

    /// Array.shuffled(using:) uyumu + determinizm.
    func testArrayShuffledDeterminism() {
        let arr = Array(0..<20)
        var rng1 = SeededRandom(seed: 777)
        var rng2 = SeededRandom(seed: 777)
        XCTAssertEqual(arr.shuffled(using: &rng1), arr.shuffled(using: &rng2))
    }

    // MARK: - SeedHash

    /// "cozy-beginnings" → hardcoded FNV-1a değer.
    /// Bu değer bir kez hesaplanıp sabitlenmiştir; Swift sürümünden bağımsız.
    func testFNV1aStable() {
        // swift - <<'EOF'
        // var h: UInt64 = 0xcbf29ce484222325
        // for b in "cozy-beginnings".utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        // print("0x\(String(h, radix: 16, uppercase: true))")
        // EOF
        // → 0x89CF91E4E692ADC1
        XCTAssertEqual(SeedHash.fnv1a("cozy-beginnings"), 0x89CF91E4E692ADC1)
    }

    /// Boş string → FNV offset basis değeri (değişmemeli).
    func testFNV1aEmptyString() {
        XCTAssertEqual(SeedHash.fnv1a(""), 0xcbf29ce484222325)
    }

    /// Farklı stringler → farklı hash.
    func testFNV1aDifferentStrings() {
        XCTAssertNotEqual(SeedHash.fnv1a("pack-a"), SeedHash.fnv1a("pack-b"))
        XCTAssertNotEqual(SeedHash.fnv1a("abc"), SeedHash.fnv1a("ABC"))
    }

    /// Birleştirilmiş fonksiyon: aynı input → aynı output (cross-call kararlılık).
    func testFNV1aIdempotent() {
        let s = "hello-world"
        XCTAssertEqual(SeedHash.fnv1a(s), SeedHash.fnv1a(s))
    }
}
