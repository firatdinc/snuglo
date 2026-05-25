import SwiftUI

// MARK: — SettingsView (Screen 11)
// Design reference: Designs/html/11-settings.html
//
// Push screen from gear icon. Sections:
//   SOUND & FEEL — Music / Sound Effects / Haptics toggles
//   APPEARANCE   — Theme disclosure (placeholder)
//   NOTIFICATIONS — Daily Reminder toggle + Reminder Time row
//   ACCOUNT       — Restore Purchases / Privacy Policy / Terms of Service
// Footer: "SNUGLO V1.0.4"
//
// Sound/haptics implementation: Faz F
// Notifications:                Faz F
// Restore Purchases:            Faz G

struct SettingsView: View {

    @Environment(AppRouter.self) private var router

    // SOUND & FEEL
    @AppStorage("settings.musicEnabled")    private var musicEnabled    = true
    @AppStorage("settings.sfxEnabled")      private var sfxEnabled      = true
    @AppStorage("settings.hapticsEnabled")  private var hapticsEnabled  = true

    // NOTIFICATIONS
    @AppStorage("settings.dailyReminder")   private var dailyReminder   = false
    @State private var reminderTime = Date()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        soundSection
                        appearanceSection
                        notificationsSection
                        accountSection
                        footer
                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: — Nav bar

    private var navBar: some View {
        HStack {
            Button {
                router.pop()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Settings")
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)

            Spacer()

            Color.clear.frame(width: 44, height: 44) // balance
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 56)
        .background(AppColors.background)
        .shadowL1()
    }

    // MARK: — Sound & Feel

    private var soundSection: some View {
        settingsGroup(header: "SOUND & FEEL") {
            settingsToggle(
                title: "Music",
                symbol: "music.note",
                symbolColor: AppColors.blockPeach,
                isOn: $musicEnabled
            )
            Divider().padding(.horizontal, AppSpacing.md)
            settingsToggle(
                title: "Sound Effects",
                symbol: "speaker.wave.2.fill",
                symbolColor: AppColors.blockSage,
                isOn: $sfxEnabled
            )
            Divider().padding(.horizontal, AppSpacing.md)
            settingsToggle(
                title: "Haptics",
                symbol: "waveform",
                symbolColor: AppColors.blockLavender,
                isOn: $hapticsEnabled
            )
        }
    }

    // MARK: — Appearance

    private var appearanceSection: some View {
        settingsGroup(header: "APPEARANCE") {
            settingsDisclosure(
                title: "Theme",
                value: "System Default",
                symbol: "paintpalette.fill",
                symbolColor: AppColors.blockCream
            )
        }
    }

    // MARK: — Notifications

    private var notificationsSection: some View {
        settingsGroup(header: "NOTIFICATIONS") {
            settingsToggle(
                title: "Daily Reminder",
                symbol: "bell.fill",
                symbolColor: AppColors.blockPeach,
                isOn: $dailyReminder
            )

            if dailyReminder {
                Divider().padding(.horizontal, AppSpacing.md)

                HStack {
                    HStack(spacing: AppSpacing.sm) {
                        iconBadge("clock.fill", color: AppColors.blockSage)
                        Text("Reminder Time")
                            .font(AppTypography.bodyLarge)
                            .foregroundStyle(AppColors.onSurface)
                    }
                    Spacer()
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(AppColors.primary)
                }
                .padding(AppSpacing.md)
            }
        }
    }

    // MARK: — Account

    private var accountSection: some View {
        settingsGroup(header: "ACCOUNT") {
            settingsLink(title: "Restore Purchases", symbol: "arrow.clockwise", action: {
                // Faz G: StoreKit restore
            })

            Divider().padding(.horizontal, AppSpacing.md)

            settingsLink(title: "Privacy Policy", symbol: "hand.raised.fill", action: {
                // Open URL in Faz H
            })

            Divider().padding(.horizontal, AppSpacing.md)

            settingsLink(title: "Terms of Service", symbol: "doc.text.fill", action: {
                // Open URL in Faz H
            })
        }
    }

    // MARK: — Footer

    private var footer: some View {
        Text("SNUGLO V1.0.4")
            .font(AppTypography.labelSmall)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.outlineVariant)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppSpacing.sm)
    }

    // MARK: — Reusable section components

    private func settingsGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(header)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: 0) {
                content()
            }
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadowL1()
        }
    }

    private func settingsToggle(
        title: String,
        symbol: String,
        symbolColor: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack {
            HStack(spacing: AppSpacing.sm) {
                iconBadge(symbol, color: symbolColor)
                Text(title)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.onSurface)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        .padding(AppSpacing.md)
    }

    private func settingsDisclosure(
        title: String,
        value: String,
        symbol: String,
        symbolColor: Color
    ) -> some View {
        HStack {
            HStack(spacing: AppSpacing.sm) {
                iconBadge(symbol, color: symbolColor)
                Text(title)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(AppColors.onSurface)
            }
            Spacer()
            Text(value)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurfaceVariant)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.outlineVariant)
        }
        .padding(AppSpacing.md)
    }

    private func settingsLink(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: symbol)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 30)
                    Text(title)
                        .font(AppTypography.bodyLarge)
                        .foregroundStyle(AppColors.onSurface)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.outlineVariant)
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private func iconBadge(_ symbol: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 36, height: 36)
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.primary)
        }
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppRouter())
}
