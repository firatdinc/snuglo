import SwiftUI

// MARK: — ProfileView (Vibrant Play)
// Rightmost tab. Shows a compact profile header (mascot avatar + title) with the
// full Stats content embedded below — Stats is no longer a top-level tab.
// The header is fixed; StatsView owns its own scroll, so there is no nested scroll.

struct ProfileView: View {

    var body: some View {
        VStack(spacing: 0) {
            profileHeader
            StatsView()
        }
        .accessibilityIdentifier("screen.profile")
    }

    // MARK: — Header

    private var profileHeader: some View {
        HStack(spacing: AppSpacing.md) {
            Image("mascot-hippo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .padding(6)
                .background(AppColors.primaryContainer, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("profile.title")
                    .font(AppTypography.headlineSmall)
                    .tracking(-0.4)
                    .foregroundStyle(AppColors.onSurface)
                Text("profile.subtitle")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ProfileView()
        .environment(AppRouter())
}
