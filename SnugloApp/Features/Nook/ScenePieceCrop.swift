import SwiftUI

// MARK: — ShardPieceView
// One glass shard of a scene, cut to its irregular polygon and cropped to its
// bounding box so the shard itself is the content (centred, draggable). Used as
// the tray/floating piece in the Nook and inside the milestone surprise reveal.
// `base` is the proportion reference (the canvas size, so the shard matches its
// slot); `displayHeight` is how tall to render the cropped shard.

struct ShardPieceView: View {
    let scene: String
    let shardIndex: Int
    let base: CGSize
    let displayHeight: CGFloat

    var body: some View {
        let shard = ShardGeometry.shards[min(shardIndex, ShardGeometry.count - 1)]
        let bb = ShardGeometry.bbox(shard)
        let cropW = bb.width * base.width
        let cropH = bb.height * base.height
        let scale = displayHeight / max(1, cropH)

        return ZStack(alignment: .topLeading) {
            Image(scene).resizable().scaledToFit()
                .frame(width: base.width, height: base.height)
                .mask(ShardShape(points: shard))
                .offset(x: -bb.minX * base.width, y: -bb.minY * base.height)
        }
        .frame(width: cropW, height: cropH, alignment: .topLeading)
        .clipped()
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: cropW * scale, height: cropH * scale, alignment: .topLeading)
    }
}
