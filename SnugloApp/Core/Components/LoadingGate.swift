import SwiftUI

// MARK: — LoadingView
// A cozy, on-brand full-screen loading indicator. Single-palette, Reduce-Motion
// safe (the bob is suppressed; the dots still cross-fade via ProgressView).

struct LoadingView: View {
    var message: LocalizedStringKey = "common.loading"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryContainer.opacity(0.4))
                    .frame(width: 72, height: 72)
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .offset(y: bob ? -5 : 4)
            }
            Text(message)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message))
    }
}

// MARK: — LoadingGate
// Renders the screen instantly with a LoadingView, then cross-fades to `content`
// once `isReady` flips true. The standard pattern for any screen whose content
// is heavy to build or depends on async work — the navigation transition is
// never blocked by the content build (it happens after, behind the spinner).

struct LoadingGate<Content: View>: View {
    let isReady: Bool
    var message: LocalizedStringKey = "common.loading"
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            if isReady {
                content()
                    .transition(.opacity)
            } else {
                LoadingView(message: message)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isReady)
    }
}
