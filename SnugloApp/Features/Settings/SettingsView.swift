import SwiftUI
import AppTrackingTransparency

// MARK: — SettingsView (H-1: Localized)
// Ref: Designs/html/11-settings.html
// H-2: VoiceOver — Reset Progress button explicit destructive role; top-level a11y hints.

struct SettingsView: View {

    @AppStorage("musicEnabled")           private var musicEnabled         = true
    @AppStorage("sfxEnabled")             private var sfxEnabled           = true
    @AppStorage("hapticsEnabled")         private var hapticsEnabled       = true
    @AppStorage("appTheme")               private var appThemeRaw: Int     = 0
    @AppStorage("dailyReminderEnabled")   private var dailyReminderEnabled = false
    @AppStorage("dailyReminderTime")      private var dailyReminderTimeInterval: Double = 19 * 3600
    @AppStorage("snuglo.language.override") private var languageOverride: String = "system"

    @State private var showResetAlert            = false
    @State private var showNotifDeniedAlert      = false
    @State private var showLanguageRestartAlert  = false
    @State private var ads                       = AdsManager.shared

    private var reminderDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: dailyReminderTimeInterval) },
            set: { dailyReminderTimeInterval = $0.timeIntervalSinceReferenceDate }
        )
    }

    private var reminderToggle: Binding<Bool> {
        Binding(
            get: { dailyReminderEnabled },
            set: { newValue in
                if newValue {
                    Task { @MainActor in
                        await NotificationService.shared.requestAuthorization()
                        dailyReminderEnabled = true
                        NotificationService.shared.reschedule(
                            enabled: true,
                            at: Date(timeIntervalSinceReferenceDate: dailyReminderTimeInterval)
                        )
                    }
                } else {
                    dailyReminderEnabled = false
                    NotificationService.shared.reschedule(enabled: false, at: Date())
                }
            }
        )
    }

    private var adsConsentToggle: Binding<Bool> {
        Binding(
            get: { ads.hasConsented },
            set: { newValue in
                if newValue {
                    ATTrackingManager.requestTrackingAuthorization { status in
                        let granted = status == .authorized
                        DispatchQueue.main.async {
                            AdsManager.shared.setConsent(granted)
                        }
                    }
                } else {
                    AdsManager.shared.setConsent(false)
                }
            }
        )
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: — Body

    var body: some View {
        List {
            // — SOUND & FEEL —
            Section {
                toggleRow(
                    icon: "music.note",
                    iconColor: AppColors.primaryContainer,
                    labelKey: "settings.sound.music",
                    isOn: $musicEnabled
                )
                toggleRow(
                    icon: "speaker.wave.2.fill",
                    iconColor: AppColors.secondaryContainer,
                    labelKey: "settings.sound.effects",
                    isOn: $sfxEnabled
                )
                toggleRow(
                    icon: "hand.tap.fill",
                    iconColor: AppColors.tertiaryContainer,
                    labelKey: "settings.haptics.enable",
                    isOn: $hapticsEnabled
                )
            } header: {
                sectionHeader("settings.sound.title")
            }

            // — APPEARANCE —
            Section {
                HStack {
                    iconBadge("paintpalette.fill", color: AppColors.blockBlush.opacity(0.5))
                    Text("settings.appearance.theme")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Spacer()
                    Picker("", selection: $appThemeRaw) {
                        Text("settings.appearance.system").tag(0)
                        Text("settings.appearance.light").tag(1)
                        Text("settings.appearance.dark").tag(2)
                    }
                    .labelsHidden()
                    .tint(AppColors.primary)
                    // H-2: Picker is auto-accessible via SwiftUI, no custom label needed
                }
                .accessibilityElement(children: .contain)
            } header: {
                sectionHeader("settings.appearance.title")
            }

            // — NOTIFICATIONS —
            Section {
                toggleRow(
                    icon: "bell.fill",
                    iconColor: AppColors.blockCream.opacity(0.8),
                    labelKey: "settings.notifications.reminder",
                    isOn: reminderToggle
                )

                if dailyReminderEnabled {
                    HStack {
                        iconBadge("clock.fill", color: AppColors.blockCream.opacity(0.5))
                        Text("settings.notifications.time")
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
                        .onChange(of: dailyReminderTimeInterval) { _, _ in
                            NotificationService.shared.reschedule(
                                enabled: dailyReminderEnabled,
                                at: Date(timeIntervalSinceReferenceDate: dailyReminderTimeInterval)
                            )
                        }
                    }
                }
            } header: {
                sectionHeader("settings.notifications.title")
            } footer: {
                if dailyReminderEnabled {
                    Text(verbatim: String(
                        format: NSLocalizedString("settings.notifications.reminderSet", comment: ""),
                        formattedReminderTime
                    ))
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
                }
            }

            // — LANGUAGE (H-1) —
            Section {
                HStack {
                    iconBadge("globe", color: AppColors.blockLavender.opacity(0.5))
                    Text("settings.language.label")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Spacer()
                    Picker("", selection: $languageOverride) {
                        Text("settings.language.system").tag("system")
                        Text("settings.language.en").tag("en")
                        Text("settings.language.tr").tag("tr")
                        Text("settings.language.es").tag("es")
                    }
                    .labelsHidden()
                    .tint(AppColors.primary)
                    .onChange(of: languageOverride) { _, newValue in
                        if newValue == "system" {
                            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                        } else {
                            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        }
                        showLanguageRestartAlert = true
                    }
                }
            } header: {
                sectionHeader("settings.language.title")
            } footer: {
                Text("settings.language.footer")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
            }

            // — PRIVACY —
            Section {
                HStack {
                    iconBadge("hand.raised.fill", color: AppColors.primaryContainer.opacity(0.6))
                    Text("settings.privacy.personalizedAds")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Spacer()
                    Toggle("", isOn: adsConsentToggle)
                        .labelsHidden()
                        .tint(AppColors.primary)
                }
            } header: {
                sectionHeader("settings.privacy.title")
            } footer: {
                Text("settings.privacy.adsFooter")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
            }

            // — ACCOUNT —
            Section {
                disclosureRow(icon: "arrow.counterclockwise", iconColor: AppColors.surfaceContainerHigh, labelKey: "settings.account.restore")
                disclosureRow(icon: "hand.raised.fill", iconColor: AppColors.surfaceContainerHigh, labelKey: "settings.account.privacy")
                disclosureRow(icon: "doc.text.fill", iconColor: AppColors.surfaceContainerHigh, labelKey: "settings.account.terms")

                // H-2: Reset Progress — explicit destructive accessibility role
                Button {
                    showResetAlert = true
                } label: {
                    HStack {
                        iconBadge("trash.fill", color: Color(UIColor.systemRed).opacity(0.15))
                        Text("settings.account.reset")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset all progress")
                .accessibilityHint("Permanently deletes all your game data. This cannot be undone.")
                // H-2: mark as destructive so VoiceOver adds the "delete" tone
                .accessibilityAddTraits(.isButton)
            } header: {
                sectionHeader("settings.account.title")
            }

            // — ABOUT —
            Section {
                HStack {
                    Text("settings.about.version")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.onSurface)
                    Spacer()
                    Text(verbatim: appVersion)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            } header: {
                sectionHeader("settings.about.title")
            } footer: {
                Text("settings.about.credits")
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
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("notif.disabled.title", isPresented: $showNotifDeniedAlert) {
            Button("notif.openSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("notif.disabled.message")
        }
        .alert("settings.language.restartTitle", isPresented: $showLanguageRestartAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("settings.language.restartMessage")
        }
        .alert("settings.account.resetTitle", isPresented: $showResetAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("settings.account.resetAction", role: .destructive) {
                ProgressStore.shared.reset()
            }
        } message: {
            Text("settings.account.resetMessage")
        }
    }

    // MARK: — Helpers

    private var formattedReminderTime: String {
        let date  = Date(timeIntervalSinceReferenceDate: dailyReminderTimeInterval)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h     = comps.hour   ?? 19
        let m     = comps.minute ?? 0
        let ampm  = h >= 12 ? "PM" : "AM"
        let h12   = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", h12, m, ampm)
    }

    // MARK: — Sub-views

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppTypography.labelSmall)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.onSurfaceVariant)
    }

    private func toggleRow(icon: String, iconColor: Color, labelKey: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack {
            iconBadge(icon, color: iconColor)
                .accessibilityHidden(true)
            Text(labelKey)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        // SwiftUI Toggle is auto-accessible; combine row for cleaner VO navigation
        .accessibilityElement(children: .combine)
    }

    private func disclosureRow(icon: String, iconColor: Color, labelKey: LocalizedStringKey) -> some View {
        Button {} label: {
            HStack {
                iconBadge(icon, color: iconColor)
                    .accessibilityHidden(true)
                Text(labelKey)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.outlineVariant)
                    .accessibilityHidden(true)
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
