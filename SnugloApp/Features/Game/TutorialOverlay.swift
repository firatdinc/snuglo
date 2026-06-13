import SwiftUI

// MARK: — TutorialOverlay
// A one-time, multi-step intro shown on the very first level. A dimmed modal
// (swipeable cards + Next/Start) that fully explains the game, then dismisses so
// it never covers the tray pieces. Single-palette, Reduce-Motion safe.

struct TutorialOverlay: View {

    var onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: LocalizedStringKey
        let body: LocalizedStringKey
    }

    private let steps: [Step] = [
        Step(icon: "square.grid.3x3.fill", title: "tutorial.welcome.title", body: "tutorial.welcome.body"),
        Step(icon: "hand.draw.fill", title: "tutorial.drag.title", body: "tutorial.drag.body"),
        Step(icon: "wand.and.stars", title: "tutorial.power.title", body: "tutorial.power.body")
    ]

    private var isLast: Bool { page >= steps.count - 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                MascotView(name: "mascot-sloth", size: 92, clipCircle: false)
                    .padding(.top, AppSpacing.sm)

                TabView(selection: $page) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        VStack(spacing: AppSpacing.sm) {
                            ZStack {
                                Circle().fill(AppColors.primaryContainer)
                                    .frame(width: 56, height: 56)
                                Image(systemName: step.icon)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                            }
                            Text(step.title)
                                .font(AppTypography.headlineMedium)
                                .foregroundStyle(AppColors.onSurface)
                                .multilineTextAlignment(.center)
                            Text(step.body)
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, AppSpacing.sm)
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 170)

                // Page dots
                HStack(spacing: 7) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AppColors.primary : AppColors.outlineVariant)
                            .frame(width: i == page ? 18 : 7, height: 7)
                    }
                }

                PrimaryButton(isLast ? "tutorial.start" : "tutorial.next") {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { page += 1 }
                    }
                }

                Button("tutorial.skip") { onFinish() }
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.bottom, AppSpacing.xs)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 360)
            .background(AppColors.surfaceContainerLowest,
                        in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL3()
            .padding(AppSpacing.lg)
        }
        .accessibilityAddTraits(.isModal)
    }
}
