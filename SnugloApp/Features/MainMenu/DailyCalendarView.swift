import SwiftUI

// MARK: — DailyCalendarView
// The 30-day reward calendar overlay. Self-contained, single-palette,
// Reduce-Motion safe.

struct DailyCalendarView: View {
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var justClaimed = false
    @State private var claimedIntensity: Double = 0.5

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private func cell(_ day: Int) -> some View {
        let store = DailyCalendarStore.shared
        let pos = store.currentDayInCycle
        let claimed = day < pos || (day == pos && !store.canClaim)
        let today = day == pos && store.canClaim
        let r = DailyCalendarStore.reward(forDay: day)
        return VStack(spacing: 2) {
            Text(verbatim: "\(day)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.onSurfaceVariant)
            Image(systemName: r.gems > 0 ? "diamond.fill" : "circle.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(r.gems > 0 ? AppColors.tertiary : AppColors.primary)
            Text(verbatim: r.gems > 0 ? "\(r.gems)" : "\(r.coins)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(today ? AppColors.primaryContainer.opacity(0.55) : AppColors.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(today ? AppColors.primary : AppColors.surfaceContainerHigh,
                        lineWidth: today ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.primary)
                    .padding(3)
            }
        }
        .opacity(claimed ? 0.5 : 1)
    }

    var body: some View {
        let store = DailyCalendarStore.shared
        ZStack {
            AppColors.background.opacity(0.6).ignoresSafeArea()
                .onTapGesture { onClose() }
            if justClaimed && !reduceMotion {
                SolveCelebration(intensity: claimedIntensity).allowsHitTesting(false)
            }

            VStack(spacing: AppSpacing.md) {
                Text("calendar.title")
                    .font(AppTypography.headlineLarge)
                    .foregroundStyle(AppColors.onSurface)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(1...DailyCalendarStore.cycleLength, id: \.self) { cell($0) }
                }

                if store.canClaim {
                    Button {
                        if let r = store.claim() {
                            claimedIntensity = RewardTierFX.intensity(coins: r.coins, gems: r.gems)
                            HapticService.shared.notify(.success)
                            SoundService.shared.play(.reward)
                            withAnimation { justClaimed = true }
                        }
                    } label: {
                        Text(verbatim: String(format: NSLocalizedString("calendar.claimDay", comment: ""), store.currentDayInCycle))
                            .font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm + 2)
                            .background(AppColors.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("calendar.comeBack")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Button(action: onClose) {
                    Text("common.close")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL3()
            .padding(AppSpacing.lg)
        }
    }
}
