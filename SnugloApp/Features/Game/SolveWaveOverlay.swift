import SwiftUI
import SnugloEngine

// MARK: — SolveWaveOverlay
// Renders all placed cells as individual SwiftUI views on top of GridView,
// then fires a diagonal (top-left → bottom-right) scale/brightness wave.
// Each cell at grid position (x, y) gets a delay of (x+y) * stepDelay so the
// wave travels diagonally. onComplete fires after all cells have settled.

struct SolveWaveOverlay: View {

    let level: Level
    let placements: [PieceID: Placement]
    let cellSize: CGFloat
    var onComplete: () -> Void

    @State private var triggered = false

    private var allCells: [(x: Int, y: Int, pieceID: PieceID)] {
        var out: [(Int, Int, PieceID)] = []
        for (pid, placement) in placements {
            guard let piece = level.pieces.first(where: { $0.id == pid }) else { continue }
            for cell in piece.cells {
                out.append((cell.x + placement.origin.x,
                            cell.y + placement.origin.y,
                            pid))
            }
        }
        return out
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(Array(allCells.enumerated()), id: \.offset) { _, c in
                WaveCell(
                    color: AppColors.blockColor(for: c.pieceID),
                    cellSize: cellSize,
                    gridX: c.x,
                    gridY: c.y,
                    delay: Double(c.x + c.y) * 0.055,
                    triggered: triggered
                )
            }
        }
        .onAppear {
            triggered = true
            let maxDiag = Double(level.width + level.height - 2)
            let total = maxDiag * 0.055 + 0.55
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(total))
                onComplete()
            }
        }
        // Absorbs all taps so nothing is tappable during the wave.
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

// MARK: — WaveCell

private struct WaveCell: View {

    let color: Color
    let cellSize: CGFloat
    let gridX: Int
    let gridY: Int
    let delay: Double
    let triggered: Bool

    @State private var scale: CGFloat = 1.0
    @State private var bright: Double = 0.0

    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.block)
            .fill(color)
            .brightness(bright)
            .frame(width: cellSize - 4, height: cellSize - 4)
            .scaleEffect(scale)
            .offset(x: CGFloat(gridX) * cellSize + 2,
                    y: CGFloat(gridY) * cellSize + 2)
            .onAppear  { if triggered { fire() } }
            .onChange(of: triggered) { _, t in if t { fire() } }
    }

    private func fire() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.17, dampingFraction: 0.40)) {
                scale = 1.26
                bright = 0.20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                    scale = 1.0
                    bright = 0.0
                }
            }
        }
    }
}
