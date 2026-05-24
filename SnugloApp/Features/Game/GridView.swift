// GridView.swift — 5×5 grid arka planı + yerleştirilmiş parçalar
// Canvas: hücre çizgileri (performans için)
// ZStack overlay: placed BlockView'lar

import SwiftUI
import SnugloEngine

struct GridView: View {

    let viewModel: GameViewModel   // @Observable — otomatik tracked
    let cellSize: CGFloat

    // MARK: - Türetilmiş boyutlar

    private var cols: Int { viewModel.level?.width  ?? 5 }
    private var rows: Int { viewModel.level?.height ?? 5 }
    private var totalW: CGFloat { CGFloat(cols) * cellSize }
    private var totalH: CGFloat { CGFloat(rows) * cellSize }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ── Arka plan + hücre çizgileri ──────────────────────
            boardCanvas

            // ── Yerleştirilmiş bloklar ────────────────────────────
            ForEach(viewModel.placedPieces, id: \.piece.id) { item in
                BlockView(
                    piece: item.piece,
                    colorKey: viewModel.colorKey(for: item.piece.id),
                    cellSize: cellSize,
                    isInvalid: false,
                    isDragging: false
                )
                .offset(
                    x: CGFloat(item.placement.origin.x) * cellSize,
                    y: CGFloat(item.placement.origin.y) * cellSize
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.pickUp(pieceId: item.piece.id)
                    }
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .frame(width: totalW, height: totalH)
        .clipShape(RoundedRectangle(cornerRadius: SnugloSpacing.cardRadius))
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }

    // MARK: - Board Canvas

    private var boardCanvas: some View {
        Canvas { context, size in
            // Krem arka plan
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(SnugloColors.cream)
            )

            // Yatay ve dikey iç çizgiler (kenarlarda çizgi yok — clip ile kesilir)
            let cW = size.width  / CGFloat(cols)
            let cH = size.height / CGFloat(rows)
            var lines = Path()

            for col in 1..<cols {
                let x = CGFloat(col) * cW
                lines.move(to: CGPoint(x: x, y: 0))
                lines.addLine(to: CGPoint(x: x, y: size.height))
            }
            for row in 1..<rows {
                let y = CGFloat(row) * cH
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(lines, with: .color(SnugloColors.gridLine), lineWidth: 1)
        }
        .frame(width: totalW, height: totalH)
    }
}
