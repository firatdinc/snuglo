import SwiftUI

// MARK: — SettingsView
// Ref: Designs/html/11-settings.html
// Sections: SOUND & FEEL / APPEARANCE / NOTIFICATIONS / ACCOUNT / ABOUT

struct SettingsView: View {

    @AppStorage("soundEnabled")         private var soundEnabled         = true
    @AppStorage("sfxEnabled")           private var sfxEnabled           = true
    @AppStorage("hapticsEnabled")       private var hapticsEnabled       = true
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("reminderHour")         private var reminderHour         = 20
    @AppStorage("reminderMinute")       private var reminderMinute       = 0

    var body: some View {
        List {
            // — SOUND & FEEL —
            Section {
                toggleRow(
                    icon: "music.note",
                    iconColor: AppColors.primaryContainer,
                    label: "Music",
                    isOn: $soundEnabled
                )
                toggleRow(
                    icon: "speaker.wave.2.fill",
                    iconColor: AppColors.secondaryContainer,
                    label: "Sound Effects",
                    isOn: $sfxEnabled
                )
                toggleRow(
                    icon: "hand.tap.fill",
                    iconColor: AppColors.tertiaryContainer,
                    label: "Haptics",
                    isOn: $hapticsEnabled
                )
            } header: {
                sectionHeader("Sound & Feel")
            }

            // — APPEARANCE —
            Section {
                HStack {
                    iconBadge("paintpalette.fill", color: AppColors.blockBlush.opacity(0.5))
                    Text("Theme")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Spacer()
                    Text("System Default")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.outlineVariant)
                }
                .opacity(0.6)  // disabled — Faz H
            } header: {
                sectionHeader("Appearance")
            } footer: {
                Text("Dark mode & custom themes: coming soon")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
            }

            // — NOTIFICATIONS —
            Section {
                toggleRow(
                    icon: "bell.fill",
                    iconColor: AppColors.blockCream.opacity(0.8),
                    label: "Daily Reminder",
                    isOn: $dailyReminderEnabled
                )

                if dailyReminderEnabled {
                    HStack {
                        iconBadge("clock.fill", color: AppColors.blockCream.opacity(0.5))
                        Text("Reminder Time")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurface)
                        Spacer()
                        Text(String(format: "%d:%02d %@",
                                    reminderHour % 12 == 0 ? 12 : reminderHour % 12,
                                    reminderMinute,
                                    reminderHour >= 12 ? "PM" : "AM"))
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                }
            } header: {
                sectionHeader("Notifications")
            }

            // — ACCOUNT —
            Section {
                disclosureRow(icon: "arrow.counterclockwise", iconColor: AppColors.surfaceContainerHigh, label: "Restore Purchases")
                disclosureRow(icon: "hand.raised.fill",       iconColor: AppColors.surfaceContainerHigh, label: "Privacy Policy")
                disclosureRow(icon: "doc.text.fill",          iconColor: AppColors.surfaceContainerHigh, label: "Terms of Service")
            } header: {
                sectionHeader("Account")
            }

            // — ABOUT —
            Section {
                HStack {
                    Text("Version")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            } header: {
                sectionHeader("About")
            } footer: {
                Text("SNUGLO V1.0.0 — Made with ♥ and cozy vibes")
                    .font(AppTypography.labelSmall)
                    .tracking(0.3)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.xl)
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.labelSmall)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.onSurfaceVariant)
    }

    private func toggleRow(icon: String, iconColor: Color, label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            iconBadge(icon, color: iconColor)
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
    }

    private func disclosureRow(icon: String, iconColor: Color, label: String) -> some View {
        Button {} label: {
            HStack {
                iconBadge(icon, color: iconColor)
                Text(label)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.outlineVariant)
            }
        }
        .buttonStyle(.plain)
        .disabled(true)
        .opacity(0.6)
    }

    private func iconBadge(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 32, height: 32)
            Image(systemName: name)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.onSurface.opacity(0.7))
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
