import SwiftUI

// MARK: — SettingsView
// Ref: Designs/html/11-settings.html
// Sections: SOUND & FEEL / APPEARANCE / NOTIFICATIONS / ACCOUNT / ABOUT
// Faz F: @Bindable wrappers → AudioManager, HapticsManager, NotificationScheduler.

struct SettingsView: View {

    // MARK: — Manager bindings (Faz F)
    // @Bindable wraps @Observable singletons so we can use $ syntax in Toggles.

    @Bindable private var audio   = AudioManager.shared
    @Bindable private var haptics = HapticsManager.shared
    @Bindable private var notif   = NotificationScheduler.shared

    // MARK: — Local UI state

    @State private var showResetAlert        = false
    @State private var showNotifDeniedAlert  = false

    // MARK: — Computed: Date ↔ (hour, minute) bridge for DatePicker

    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var dc = DateComponents()
                dc.hour   = notif.reminderHour
                dc.minute = notif.reminderMinute
                return Calendar.current.date(from: dc) ?? Date()
            },
            set: { date in
                let dc = Calendar.current.dateComponents([.hour, .minute], from: date)
                notif.reminderHour   = dc.hour   ?? 19
                notif.reminderMinute = dc.minute  ?? 0
            }
        )
    }

    // MARK: — Notification toggle binding (requests authorization if needed)

    private var reminderToggle: Binding<Bool> {
        Binding(
            get: { notif.reminderEnabled },
            set: { newValue in
                if newValue {
                    Task { @MainActor in
                        let granted = await notif.requestAuthorization()
                        if granted {
                            notif.reminderEnabled = true
                        } else {
                            // Keep off + show alert
                            notif.reminderEnabled = false
                            showNotifDeniedAlert  = true
                        }
                    }
                } else {
                    notif.reminderEnabled = false
                }
            }
        )
    }

    // MARK: — Body

    var body: some View {
        List {
            // — SOUND & FEEL —
            Section {
                toggleRow(
                    icon: "music.note",
                    iconColor: AppColors.primaryContainer,
                    label: "Music",
                    isOn: $audio.musicEnabled
                )
                toggleRow(
                    icon: "speaker.wave.2.fill",
                    iconColor: AppColors.secondaryContainer,
                    label: "Sound Effects",
                    isOn: $audio.soundEnabled
                )
                toggleRow(
                    icon: "hand.tap.fill",
                    iconColor: AppColors.tertiaryContainer,
                    label: "Haptics",
                    isOn: $haptics.enabled
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
                    isOn: reminderToggle
                )

                if notif.reminderEnabled {
                    HStack {
                        iconBadge("clock.fill", color: AppColors.blockCream.opacity(0.5))
                        Text("Reminder Time")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurface)
                        Spacer()
                        DatePicker(
                            "",
                            selection: reminderDate,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(AppColors.primary)
                    }
                }
            } header: {
                sectionHeader("Notifications")
            } footer: {
                if notif.reminderEnabled {
                    Text("Daily reminder set for \(formattedReminderTime)")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
                }
            }

            // — ACCOUNT —
            Section {
                disclosureRow(icon: "arrow.counterclockwise", iconColor: AppColors.surfaceContainerHigh, label: "Restore Purchases")
                disclosureRow(icon: "hand.raised.fill",       iconColor: AppColors.surfaceContainerHigh, label: "Privacy Policy")
                disclosureRow(icon: "doc.text.fill",          iconColor: AppColors.surfaceContainerHigh, label: "Terms of Service")

                // Reset Progress — destructive, confirm alert
                Button {
                    showResetAlert = true
                } label: {
                    HStack {
                        iconBadge("trash.fill", color: Color(UIColor.systemRed).opacity(0.15))
                        Text("Reset Progress")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .alert("Reset All Progress?", isPresented: $showResetAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        ProgressStore.shared.reset()
                    }
                } message: {
                    Text("This will permanently delete all completed levels, stars, streaks, and daily puzzle history. This action cannot be undone.")
                }
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
        // Notifications denied alert
        .alert("Notifications Disabled", isPresented: $showNotifDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To enable daily reminders, allow Snuglo to send notifications in Settings → Snuglo → Notifications.")
        }
    }

    // MARK: — Helpers

    private var formattedReminderTime: String {
        let h = notif.reminderHour
        let m = notif.reminderMinute
        let ampm = h >= 12 ? "PM" : "AM"
        let h12  = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", h12, m, ampm)
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
