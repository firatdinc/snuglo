import SwiftUI

// MARK: — DailyRewardView

struct DailyRewardView: View {

    @State private var vm = DailyRewardViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                SectionHeader("dailyReward.title")
                    .padding(.horizontal, AppSpacing.lg)

                dayStrip

                claimButton
                    .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(Text("dailyReward.title"))
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if vm.showBanner { claimedBanner.padding(.top, AppSpacing.sm) }
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.75),
            value: vm.showBanner
        )
        .onAppear { vm.refresh() }
        .accessibilityIdentifier("screen.dailyReward")
    }

    // MARK: — Day Strip

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(1...7, id: \.self) { day in
                    DayCell(
                        day: day,
                        currentDay: vm.currentDay,
                        canClaim: vm.canClaim,
                        isPremium: StoreManager.shared.adsRemoved
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: — Claim Button

    @ViewBuilder
    private var claimButton: some View {
        if vm.canClaim {
            PrimaryButton("dailyReward.claim.cta", systemImage: "gift.fill") {
                withAnimation { vm.claim() }
            }
            .accessibilityIdentifier("dailyReward.claim.button")
        } else {
            PrimaryButton("dailyReward.claim.disabled") {}
                .disabled(true)
                .opacity(0.5)
        }
    }

    // MARK: — Claimed Banner

    private var claimedBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("dailyReward.success.title")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)

                if let reward = vm.lastClaimedReward {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Currency.allCases) { currency in
                            if let amount = reward[currency], amount > 0 {
                                HStack(spacing: 2) {
                                    CurrencyIcon(currency: currency, size: 14)
                                    Text("+\(amount)")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundStyle(AppColors.onSurface)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .cardSurface()
        .padding(.horizontal, AppSpacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: — DayCell

private struct DayCell: View {

    let day: Int
    let currentDay: Int
    let canClaim: Bool
    let isPremium: Bool

    private var isPast: Bool { day < currentDay || (day == currentDay && !canClaim) }
    private var isCurrent: Bool { day == currentDay && canClaim }

    private var reward: [Currency: Int] {
        DailyRewardCalculator.reward(forDay: day, isPremium: isPremium)
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(String(format: NSLocalizedString("dailyReward.day", comment: ""), day))
                .font(AppTypography.labelSmall)
                .tracking(0.5)
                .foregroundStyle(isCurrent ? AppColors.primary : AppColors.onSurfaceVariant)

            VStack(spacing: 2) {
                ForEach(Currency.allCases) { currency in
                    if let amount = reward[currency], amount > 0 {
                        HStack(spacing: 2) {
                            CurrencyIcon(currency: currency, size: 14)
                            Text("+\(amount)")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(AppColors.onSurface)
                        }
                    }
                }
            }

            if isPast {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            } else {
                Color.clear.frame(height: 16)
            }
        }
        .frame(minWidth: 76)
        .padding(AppSpacing.md)
        .cardSurface()
        .opacity(day > currentDay ? 0.55 : 1.0)
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.primary, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("dailyReward.day", comment: ""), day)))
    }
}

#Preview {
    NavigationStack {
        DailyRewardView()
    }
    .environment(AppRouter())
}
