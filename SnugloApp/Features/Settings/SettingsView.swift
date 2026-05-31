import SwiftUI
import AppTrackingTransparency
import UserNotifications

// MARK: — SettingsView (H-1: Localized)
// Ref: Designs/VibrantPlay/SPEC.md
// Faz 3c: Vibrant Play restyle — List → ScrollView + cardSurface sections.
// H-2: VoiceOver — Reset Progress button explicit destructive role; top-level a11y hints.
// All logic (bindings, alerts, AppStorage) is unchanged.

struct SettingsView: View {

    @AppStorage("musicEnabled")           private var musicEnabled         = true
    @AppStorage("sfxEnabled")             private var sfxEnabled           = true
    @AppStorage("hapticsEnabled")         private var hapticsEnabled       = true
    @AppStorage("appTheme")               private var appThemeRaw: Int     = 0
    @AppStorage("dailyReminderEnabled")   private var dailyReminderEnabled = false
    @AppStorage("dailyReminderTime")      private var dailyReminderTimeInterval: Double = 19 * 3600

    // Runtime language switching (restart-free) — see LocaleManager.
    @State private var localeManager = LocaleManager.shared

    @State private var showResetAlert            = false
    @State private var showNotifDeniedAlert      = false
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
                        // v1.1 bug fix: check authorization result before enabling.
                        // Previously, dailyReminderEnabled=true was set unconditionally
                        // even when the user denied permission (showNotifDeniedAlert was
                        // never triggered). Now we inspect the current status after request.
                        await NotificationService.shared.requestAuthorization()
                        let center = UNUserNotificationCenter.current()
                        let settings = await center.notificationSettings()
                        if settings.authorizationStatus == .authorized
                            || settings.authorizationStatus == .provisional {
                            dailyReminderEnabled = true
                            NotificationService.shared.reschedule(
                                enabled: true,
                                at: Date(timeIntervalSinceReferenceDate: dailyReminderTimeInterval)
                            )
                        } else {
                            dailyReminderEnabled = false
                            showNotifDeniedAlert = true
                        }
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
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(ver) (\(build))"
    }

    // MARK: — Body

    var body: some View {
        @Bindable var lm = localeManager
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {

                Text("settings.title")
                    .font(AppTypography.headlineLarge)
                    .tracking(-0.6)
                    .foregroundStyle(AppColors.onSurface)
                    .accessibilityIdentifier("title.settings")

                // — SOUND & FEEL —
                settingsSection("settings.sound.title") {
                    toggleRow(
                        icon: "music.note",
                        iconColor: AppColors.primaryContainer,
                        labelKey: "settings.sound.music",
                        isOn: $musicEnabled,
                        a11yId: "settings.sound_toggle"
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    toggleRow(
                        icon: "speaker.wave.2.fill",
                        iconColor: AppColors.secondaryContainer,
                        labelKey: "settings.sound.effects",
                        isOn: $sfxEnabled
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    toggleRow(
                        icon: "hand.tap.fill",
                        iconColor: AppColors.tertiaryContainer,
                        labelKey: "settings.haptics.enable",
                        isOn: $hapticsEnabled
                    )
                }

                // — APPEARANCE —
                settingsSection("settings.appearance.title") {
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
                        .accessibilityIdentifier("settings.theme_picker")
                    }
                    .accessibilityElement(children: .contain)
                    .padding(AppSpacing.md)
                }

                // — NOTIFICATIONS —
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    settingsSection("settings.notifications.title") {
                        toggleRow(
                            icon: "bell.fill",
                            iconColor: AppColors.blockCream.opacity(0.8),
                            labelKey: "settings.notifications.reminder",
                            isOn: reminderToggle
                        )
                        if dailyReminderEnabled {
                            RowDivider().padding(.horizontal, AppSpacing.md)
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
                            .padding(AppSpacing.md)
                        }
                    }
                    if dailyReminderEnabled {
                        Text(verbatim: String(
                            format: localeManager.localized("settings.notifications.reminderSet"),
                            formattedReminderTime
                        ))
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
                        .padding(.horizontal, AppSpacing.sm)
                    }
                }

                // — LANGUAGE (H-1) —
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    settingsSection("settings.language.title") {
                        HStack {
                            iconBadge("globe", color: AppColors.blockLavender.opacity(0.5))
                            Text("settings.language.label")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurface)
                            Spacer()
                            // Binds to LocaleManager — the change takes effect
                            // instantly via the root's `\.locale` environment; no
                            // app restart needed.
                            Picker("", selection: $lm.languageCode) {
                                Text("settings.language.system").tag("system")
                                Text("settings.language.en").tag("en")
                                Text("settings.language.tr").tag("tr")
                                Text("settings.language.es").tag("es")
                            }
                            .labelsHidden()
                            .tint(AppColors.primary)
                            .accessibilityIdentifier("settings.language_picker")
                        }
                        .padding(AppSpacing.md)
                    }
                    Text("settings.language.footer")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
                        .padding(.horizontal, AppSpacing.sm)
                }

                // — PRIVACY —
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    settingsSection("settings.privacy.title") {
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
                        .padding(AppSpacing.md)
                    }
                    Text("settings.privacy.adsFooter")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.6))
                        .padding(.horizontal, AppSpacing.sm)
                }

                // — ACCOUNT —
                settingsSection("settings.account.title") {
                    disclosureRow(
                        icon: "arrow.counterclockwise",
                        iconColor: AppColors.surfaceContainerHigh,
                        labelKey: "settings.account.restore"
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    disclosureRow(
                        icon: "hand.raised.fill",
                        iconColor: AppColors.surfaceContainerHigh,
                        labelKey: "settings.account.privacy"
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    disclosureRow(
                        icon: "doc.text.fill",
                        iconColor: AppColors.surfaceContainerHigh,
                        labelKey: "settings.account.terms"
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
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
                        .padding(AppSpacing.md)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset all progress")
                    .accessibilityHint("Permanently deletes all your game data. This cannot be undone.")
                    .accessibilityAddTraits(.isButton)
                }

                // — ABOUT —
                settingsSection("settings.about.title") {
                    HStack {
                        Text("settings.about.version")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurface)
                        Spacer()
                        Text(verbatim: appVersion)
                            .font(AppTypography.numericSmall)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }
                    .padding(AppSpacing.md)
                }

                Text("settings.about.credits")
                    .font(AppTypography.labelSmall)
                    .tracking(0.3)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.settings")
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
        let hr    = comps.hour   ?? 19
        let min   = comps.minute ?? 0
        let ampm  = hr >= 12 ? "PM" : "AM"
        let h12   = hr % 12 == 0 ? 12 : hr % 12
        return String(format: "%d:%02d %@", h12, min, ampm)
    }

    // MARK: — Section Layout

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(titleKey)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .padding(.horizontal, AppSpacing.xs)
            VStack(spacing: 0) {
                content()
            }
            .cardSurface()
        }
    }

    // MARK: — Row Sub-views

    private func toggleRow(
        icon: String,
        iconColor: Color,
        labelKey: LocalizedStringKey,
        isOn: Binding<Bool>,
        a11yId: String? = nil
    ) -> some View {
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
        .padding(AppSpacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(a11yId ?? "")
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
            .padding(AppSpacing.md)
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
