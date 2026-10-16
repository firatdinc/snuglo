import Foundation
// Swift referans çıktısı: Godot portunun birebir aynı level ürettiğini doğrulamak için.
let gen = LevelGenerator()
var out: [[String: Any]] = []
func enc(_ l: Level) -> [String: Any] {
    ["id": l.id, "w": l.width, "h": l.height,
     "pieces": l.pieces.map { ["id": $0.id, "cells": $0.cells.map { [$0.x, $0.y] }] },
     "solution": l.solution.map { ["id": $0.pieceId, "o": [$0.origin.x, $0.origin.y]] }]
}
for (p, s) in [("cozy-beginnings",5),("spice-route",6),("mambo-nights",7),("woodland-retreat",8)] {
    for i in 1...60 { out.append(enc(gen.generate(packId: p, levelIndex: i, gridSize: s))) }
}
let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(identifier: "UTC")
for d in ["2026-01-01","2026-10-16","2026-10-17","2027-02-28","2026-06-03"] {
    for i in 0..<3 { var e = enc(DailyPuzzle.forDate(f.date(from: d)!.addingTimeInterval(43200), index: i)); e["date"] = d; out.append(e) }
}
let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
FileManager.default.createFile(atPath: CommandLine.arguments[1], contents: data)
print("levels:", out.count)
