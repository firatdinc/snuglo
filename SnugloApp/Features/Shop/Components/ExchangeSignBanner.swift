import SwiftUI

// MARK: — ExchangeSignBanner
// A hanging "tavern sign" that drops from the top of the screen and gently
// swings to rest (a damped pendulum about its top mounting bar). Replaces the
// old AnnouncementBanner (with its leading accent strip) for exchange results.
//
// Success → shows the localized "Exchanged!" title plus the exchange detail
//           (−cost fromCurrency  →  +reward toCurrency).
// Failure → shows the insufficient-balance title + message in the same sign.
//
// Theme-compliant: every colour comes from AppColors tokens (no hardcoded hex).

struct ExchangeSignBanner: View {

    let titleKey: LocalizedStringKey
    /// Non-nil on success → renders the detail row. Nil → failure (uses messageKey).
    let receipt: ShopViewModel.ExchangeReceipt?
    let messageKey: LocalizedStringKey?
    let onDismiss: () -> Void

    @State private var swing: Double = 0
    @State private var lowered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barWidth: CGFloat = 132
    private let chainSpacing: CGFloat = 72

    var body: some View {
        VStack(spacing: 0) {
            mountingBar

            // Chains + board swing together, pivoting at the bar (anchor: .top).
            VStack(spacing: 0) {
                chains
                board
            }
            .rotationEffect(.degrees(swing), anchor: .top)
            .offset(y: lowered ? 0 : -10)
            .opacity(lowered ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .onAppear(perform: animateIn)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("announcement.dismiss"))
    }

    // MARK: — Mounting bar (static — the sign hangs from this)

    private var mountingBar: some View {
        Capsule()
            .fill(AppColors.outlineVariant)
            .frame(width: barWidth, height: 6)
            .overlay(
                Capsule()
                    .fill(AppColors.onSurfaceVariant.opacity(0.25))
                    .frame(width: barWidth, height: 2)
                    .offset(y: -1)
            )
            .shadowL1()
            .zIndex(1)
    }

    // MARK: — Chains

    private var chains: some View {
        HStack(spacing: chainSpacing) {
            chainLink
            chainLink
        }
        .frame(height: 18)
    }

    private var chainLink: some View {
        Capsule()
            .fill(AppColors.outlineVariant)
            .frame(width: 4, height: 18)
            .overlay(alignment: .top) {
                // little ring where the chain meets the bar
                Circle()
                    .strokeBorder(AppColors.outlineVariant, lineWidth: 2)
                    .frame(width: 9, height: 9)
                    .offset(y: -5)
            }
    }

    // MARK: — Sign board

    private var board: some View {
        VStack(spacing: AppSpacing.xs + 2) {
            Text(titleKey)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
                .multilineTextAlignment(.center)

            detail
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(minWidth: 200)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.surfaceContainerLowest)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.outlineVariant.opacity(0.6), lineWidth: 1.5)
        )
        // Two pegs at the top corners where the chains attach.
        .overlay(alignment: .top) {
            HStack {
                peg
                Spacer()
                peg
            }
            .padding(.horizontal, 18)
            .offset(y: -3)
        }
        .shadowL1()
    }

    private var peg: some View {
        Circle()
            .fill(AppColors.outlineVariant)
            .frame(width: 7, height: 7)
    }

    // MARK: — Detail row

    @ViewBuilder
    private var detail: some View {
        if let r = receipt {
            HStack(spacing: AppSpacing.sm) {
                amountChip(prefix: "−", value: r.cost, currency: r.fromCurrency)

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.onSurfaceVariant)

                amountChip(prefix: "+", value: r.reward, currency: r.toCurrency)
            }
        } else if let messageKey {
            Text(messageKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func amountChip(prefix: String, value: Int, currency: Currency) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: "\(prefix)\(value)")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
                .monospacedDigit()
            CurrencyIcon(currency: currency, size: 18)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule().fill(AppColors.surfaceContainerHigh)
        )
    }

    // MARK: — Animation

    private func animateIn() {
        guard !reduceMotion else {
            lowered = true
            return
        }
        // Drop in…
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            lowered = true
        }
        // …then swing: tilt, and let a low-damped spring oscillate back to rest.
        swing = 11
        withAnimation(.interpolatingSpring(stiffness: 80, damping: 4.0).delay(0.10)) {
            swing = 0
        }
    }
}

// MARK: — Preview

#Preview {
    ZStack(alignment: .top) {
        AppColors.background.ignoresSafeArea()

        VStack(spacing: 40) {
            ExchangeSignBanner(
                titleKey: "shop.exchange.success.title",
                receipt: .init(fromCurrency: .coin, cost: 100, toCurrency: .gem, reward: 1),
                messageKey: nil,
                onDismiss: {}
            )

            ExchangeSignBanner(
                titleKey: "shop.exchange.insufficient.title",
                receipt: nil,
                messageKey: "shop.exchange.insufficient.message",
                onDismiss: {}
            )
        }
        .padding(.top, 40)
    }
}
