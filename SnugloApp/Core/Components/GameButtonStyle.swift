import SwiftUI

// MARK: — GameButtonStyle
// 3D "pressable" button style adapted from Worplix UIKitComponents.
// Mechanism: two-layer background — a darker bottom slab + a coloured top face.
// At rest:   top face is offset Y=0, bottom slab shows at Y=+depth (peeks below).
// Pressed:   entire content shifts Y=+depth so top face lands on the slab (pressed-in feel).
// Layout:    .padding(.bottom, depth) reserves space so surrounding layout stays stable.
// Reduce Motion: offset and spring are suppressed; only the colour change remains.

struct GameButtonStyle: ButtonStyle {

    enum Variant {
        case primary    // Blue CTA (primary / primaryPressed tokens)
        case secondary  // White outlined (surfaceContainerLowest / outlineVariant tokens)
    }

    var variant: Variant = .primary
    /// Compact buttons (e.g. the power-up bar) use tighter vertical padding so
    /// they read as short horizontal pills rather than near-square circles —
    /// the pill `AppRadius.button` (100) only looks right when width > height.
    var compact: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        configuration.label
            .padding(.vertical, compact ? AppSpacing.xs : AppSpacing.md)
            .background(background)
            .offset(y: reduceMotion ? 0 : (isPressed ? depth : 0))
            .padding(.bottom, reduceMotion ? 0 : depth)
            .animation(
                reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7),
                value: isPressed
            )
    }

    // MARK: — Background layers

    @ViewBuilder
    private var background: some View {
        ZStack {
            bottomSlab
            topFace
        }
    }

    private var bottomSlab: some View {
        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            .fill(bottomColor)
            .offset(y: reduceMotion ? 0 : depth)
    }

    @ViewBuilder
    private var topFace: some View {
        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
            .fill(topColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }

    // MARK: — Color helpers (Snuglo Vibrant Play tokens only)

    private var topColor: Color {
        switch variant {
        case .primary:   return AppColors.primary
        case .secondary: return AppColors.surfaceContainerLowest
        }
    }

    private var bottomColor: Color {
        switch variant {
        case .primary:   return AppColors.primaryPressed
        case .secondary: return AppColors.outlineVariant
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:   return .clear
        case .secondary: return AppColors.divider
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .primary:   return 0
        case .secondary: return 1.5
        }
    }
}

// MARK: — Preview

#Preview {
    VStack(spacing: 24) {
        Button("Play Now") {}
            .buttonStyle(GameButtonStyle(variant: .primary))
            .foregroundStyle(AppColors.onPrimary)
            .font(AppTypography.headlineSmall)
            .frame(maxWidth: .infinity)

        Button("Restart") {}
            .buttonStyle(GameButtonStyle(variant: .secondary))
            .foregroundStyle(AppColors.softCocoa)
            .font(AppTypography.headlineSmall)
            .frame(maxWidth: .infinity)
    }
    .padding(AppSpacing.lg)
}
