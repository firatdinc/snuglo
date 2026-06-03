import SwiftUI

// MARK: — ResultCard
// A branded, fixed-size card rendered to an image for sharing (ImageRenderer).
// Self-contained & single-palette; renders standalone (no environment needed).

struct ResultCard: View {
    let stars: Int
    let seconds: Int
    let playerLevel: Int
    let streak: Int

    private var timeStr: String { String(format: "%d:%02d", seconds / 60, seconds % 60) }

    private func stat(_ key: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.onSurface)
            Text(NSLocalizedString(key, comment: ""))
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        VStack(spacing: 22) {
            Text(verbatim: "SNUGLO")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .tracking(6)
                .foregroundStyle(AppColors.primary)

            Image("mascot-sloth")
                .resizable().scaledToFit()
                .frame(width: 96, height: 96)

            Text("share.solved")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.onSurface)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 26))
                        .foregroundStyle(i < stars ? AppColors.tertiary : AppColors.outlineVariant)
                }
            }

            HStack(spacing: 0) {
                stat("share.time", timeStr)
                stat("share.level", "\(playerLevel)")
                if streak > 1 { stat("share.streak", "\(streak)") }
            }
            .padding(.horizontal, 24)

            Text("share.tagline")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
        }
        .padding(28)
        .frame(width: 340, height: 460)
        .background(
            LinearGradient(
                colors: [AppColors.primaryContainer.opacity(0.5), AppColors.background],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}
