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
    @AppStorage("musicVolume")            private var musicVolume: Double   = 0.6
    @AppStorage("musicTrack")             private var musicTrack           = "auto"
    @AppStorage("sfxEnabled")             private var sfxEnabled           = true
    @AppStorage("sfxVolume")              private var sfxVolume: Double     = 1.0
    @AppStorage("hapticsEnabled")         private var hapticsEnabled       = true
    @AppStorage("zenMode")                private var zenMode              = false
    @AppStorage("blockSkin")              private var blockSkin            = "nordic"
    @AppStorage("boardBackground")        private var boardBackground      = "parchment"
    @AppStorage("colorblindMode")         private var colorblindMode       = false
    @AppStorage("soundPack")              private var soundPack            = "classic"
    @AppStorage("hapticLevel")            private var hapticLevel          = "full"
    @AppStorage("appTheme")               private var appThemeRaw: Int     = 0
    @AppStorage("dailyReminderEnabled")   private var dailyReminderEnabled = false
    @AppStorage("dailyReminderTime")      private var dailyReminderTimeInterval: Double = 19 * 3600
    @AppStorage("comebackRemindersEnabled") private var comebackRemindersEnabled = false

    // Runtime language switching (restart-free) — see LocaleManager.
    @State private var localeManager = LocaleManager.shared

    @State private var showResetAlert            = false
    @State private var showTransferSheet         = false
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

    private var comebackToggle: Binding<Bool> {
        Binding(
            get: { comebackRemindersEnabled },
            set: { newValue in
                if newValue {
                    Task { @MainActor in
                        await NotificationService.shared.requestAuthorization()
                        let settings = await UNUserNotificationCenter.current().notificationSettings()
                        if settings.authorizationStatus == .authorized
                            || settings.authorizationStatus == .provisional {
                            comebackRemindersEnabled = true   // armed on next background
                        } else {
                            comebackRemindersEnabled = false
                            showNotifDeniedAlert = true
                        }
                    }
                } else {
                    comebackRemindersEnabled = false
                    NotificationService.shared.cancelComeback()
                }
            }
        )
    }

    private var adsConsentToggle: Binding<Bool> {
        Binding(
            get: { ads.hasConsented },
            set: { newValue in
                if newValue {
                    switch ATTrackingManager.trackingAuthorizationStatus {
                    case .notDetermined:
                        ATTrackingManager.requestTrackingAuthorization { status in
                            DispatchQueue.main.async {
                                AdsManager.shared.setConsent(status == .authorized)
                            }
                        }
                    case .denied, .restricted:
                        // iOS won't re-prompt once answered — deep-link to Settings.
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    default:
                        AdsManager.shared.setConsent(true)
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

                // — ZEN MODE (prominent, top of settings) —
                zenModeCard

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
                    volumeRow(icon: "music.note", color: AppColors.primaryContainer,
                              value: $musicVolume, enabled: musicEnabled) {
                        MusicService.shared.applyVolume()
                    }
                    if musicEnabled {
                        RowDivider().padding(.horizontal, AppSpacing.md)
                        HStack {
                            iconBadge("music.quarternote.3", color: AppColors.primaryContainer)
                            Text("settings.sound.track")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurface)
                            Spacer()
                            Picker("", selection: $musicTrack) {
                                Text("settings.sound.track.auto").tag("auto")
                                Text("settings.sound.track.calm").tag("calm")
                                Text("settings.sound.track.zen").tag("zen")
                            }
                            .pickerStyle(.menu)
                            .tint(AppColors.primary)
                            .onChange(of: musicTrack) { _, _ in MusicService.shared.refresh() }
                        }
                        .padding(AppSpacing.md)
                    }
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    toggleRow(
                        icon: "speaker.wave.2.fill",
                        iconColor: AppColors.secondaryContainer,
                        labelKey: "settings.sound.effects",
                        isOn: $sfxEnabled
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    volumeRow(icon: "speaker.wave.2.fill", color: AppColors.secondaryContainer,
                              value: $sfxVolume, enabled: sfxEnabled) {
                        SoundService.shared.play(.click)   // preview the new level
                    }
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    toggleRow(
                        icon: "hand.tap.fill",
                        iconColor: AppColors.tertiaryContainer,
                        labelKey: "settings.haptics.enable",
                        isOn: $hapticsEnabled
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    HStack {
                        iconBadge("hand.tap.fill", color: AppColors.tertiaryContainer)
                        Text("haptic.strength")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurface)
                        Spacer()
                        Picker("", selection: $hapticLevel) {
                            Text("haptic.full").tag("full")
                            Text("haptic.light").tag("light")
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.primary)
                        .disabled(!hapticsEnabled)
                        .accessibilityIdentifier("settings.haptic_level")
                    }
                    .padding(AppSpacing.md)
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    HStack {
                        iconBadge("waveform", color: AppColors.secondaryContainer)
                        Text("soundpack.title")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurface)
                        Spacer()
                        Picker("", selection: $soundPack) {
                            ForEach(SoundPack.allCases) { pack in
                                Text(NSLocalizedString(pack.nameKey, comment: "")).tag(pack.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.primary)
                        .accessibilityIdentifier("settings.soundpack_picker")
                    }
                    .padding(AppSpacing.md)
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    soundPreviewRow
                }

                // — GAMEPLAY (Zen toggle now lives in the top zenModeCard) —
                settingsSection("settings.gameplay.title") {
                    toggleRow(
                        icon: "eye.fill",
                        iconColor: AppColors.tertiaryContainer,
                        labelKey: "settings.gameplay.colorblind",
                        isOn: $colorblindMode,
                        a11yId: "settings.colorblind_toggle"
                    )
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    streakFreezeRow
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

                    RowDivider().padding(.horizontal, AppSpacing.md)
                    skinSelector
                    RowDivider().padding(.horizontal, AppSpacing.md)
                    boardBgSelector
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
                        RowDivider().padding(.horizontal, AppSpacing.md)
                        toggleRow(
                            icon: "heart.fill",
                            iconColor: AppColors.blockBlush.opacity(0.8),
                            labelKey: "settings.notifications.comeback",
                            isOn: comebackToggle
                        )
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
                    Button {
                        showTransferSheet = true
                    } label: {
                        HStack {
                            iconBadge("arrow.up.arrow.down.circle.fill", color: AppColors.primaryContainer)
                            Text("settings.account.transfer")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.onSurface)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.outlineVariant)
                        }
                        .padding(AppSpacing.md)
                    }
                    .buttonStyle(.plain)
                    RowDivider().padding(.horizontal, AppSpacing.md)
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
                    .accessibilityLabel(Text("a11y.resetLabel"))
                    .accessibilityHint(Text("a11y.resetHint"))
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

                Text(verbatim: String(
                    format: NSLocalizedString("settings.about.footer", comment: ""),
                    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                ))
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
        // Start/stop background music live when the toggle flips.
        .onChange(of: musicEnabled) { _, _ in MusicService.shared.refresh() }
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
        .sheet(isPresented: $showTransferSheet) { SaveTransferSheet() }
        .alert("settings.account.resetTitle", isPresented: $showResetAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("settings.account.resetAction", role: .destructive) {
                // Wipe level progress + stats + streaks, the Nook (scene pieces) and
                // energy too (wallet, purchases, premium, achievements survive). Drop
                // in-progress sessions and push the wipe to iCloud so a higher-rev
                // cloud save can't restore it.
                ProgressStore.shared.reset()
                NookStore.shared.reset()
                EnergyStore.shared.reset()
                GameSessionStore.shared.clearAll()
                CloudSync.shared.pushToCloud()
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

    // MARK: — Streak freeze row

    private var streakFreezeRow: some View {
        let held = ProgressStore.shared.streakFreezes
        return HStack {
            iconBadge("snowflake", color: AppColors.secondaryContainer)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("freeze.title")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurface)
                Text(verbatim: String(format: NSLocalizedString("freeze.held", comment: ""), held))
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            Spacer()
            Button {
                if ProgressStore.shared.buyStreakFreeze() {
                    HapticService.shared.notify(.success)
                } else {
                    HapticService.shared.notify(.error)
                }
            } label: {
                Text(verbatim: "\(ProgressStore.freezeCostGems) 💎")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.primaryContainer.opacity(0.5), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.buy_freeze")
        }
        .padding(AppSpacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: — Block skin selector

    @ViewBuilder
    private func skinSwatch(_ skin: AppColors.BlockSkin) -> some View {
        let level = XPStore.shared.level
        // Premium skins are gem-only (never level-unlocked); free skins keep the
        // level-derived price and can also be bought early with gems.
        let cost = skin.premiumCost ?? CosmeticsStore.skinCost(unlockLevel: skin.unlockLevel)
        let unlocked = level >= skin.unlockLevel || CosmeticsStore.shared.isSkinUnlocked(skin.id)
        let selected = blockSkin == skin.id
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.surfaceContainerLowest)
                    .frame(width: 64, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selected ? AppColors.primary : AppColors.surfaceContainerHigh,
                                    lineWidth: selected ? 2 : 1)
                    )
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(skin.palette[i])
                            .frame(width: 10, height: 18)
                    }
                }
                .opacity(unlocked ? 1 : 0.35)
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                if skin.premiumCost != nil {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.tertiary)
                        .padding(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            Text(verbatim: unlocked
                 ? NSLocalizedString(skin.nameKey, comment: "")
                 : "💎\(cost)")
                .font(AppTypography.labelSmall)
                .foregroundStyle(selected ? AppColors.primary : AppColors.onSurfaceVariant)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if unlocked {
                blockSkin = skin.id
                HapticService.shared.impact(.light)
            } else if CosmeticsStore.shared.buySkin(skin.id, costGems: cost) {
                blockSkin = skin.id
                HapticService.shared.notify(.success)   // bought + equipped
            } else {
                HapticService.shared.notify(.error)     // not enough gems
            }
        }
        .accessibilityLabel(NSLocalizedString(skin.nameKey, comment: "") + (unlocked ? "" : ", locked, costs \(cost) gems"))
    }

    @ViewBuilder
    private func boardSwatch(_ bg: BoardBackground) -> some View {
        let selected = boardBackground == bg.rawValue
        // Premium boards (gemCost != nil) are gem-only; free boards have no cost.
        let cost = bg.gemCost
        let unlocked = cost == nil || CosmeticsStore.shared.isBoardUnlocked(bg.rawValue)
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: bg.colors, startPoint: .top, endPoint: .bottom))
                    .frame(width: 64, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selected ? AppColors.primary : AppColors.surfaceContainerHigh,
                                    lineWidth: selected ? 2 : 1)
                    )
                    .opacity(unlocked ? 1 : 0.5)
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
                if cost != nil {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.tertiary)
                        .padding(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            Text(verbatim: unlocked
                 ? NSLocalizedString(bg.nameKey, comment: "")
                 : "💎\(cost ?? 0)")
                .font(AppTypography.labelSmall)
                .foregroundStyle(selected ? AppColors.primary : AppColors.onSurfaceVariant)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if unlocked {
                boardBackground = bg.rawValue
                HapticService.shared.impact(.light)
            } else if let c = cost, CosmeticsStore.shared.buyBoard(bg.rawValue, costGems: c) {
                boardBackground = bg.rawValue
                HapticService.shared.notify(.success)
            } else {
                HapticService.shared.notify(.error)
            }
        }
        .accessibilityLabel(NSLocalizedString(bg.nameKey, comment: "") + (unlocked ? "" : ", locked, costs \(cost ?? 0) gems"))
    }

    private var boardBgSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("board.title")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(BoardBackground.allCases) { boardSwatch($0) }
                }
            }
        }
        .padding(AppSpacing.md)
    }

    private var skinSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("skin.title")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.onSurface)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(AppColors.blockSkins) { skinSwatch($0) }
                }
            }
        }
        .padding(AppSpacing.md)
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

    /// Prominent Zen Mode card at the very top of Settings — many players prefer
    /// the calm, no-timer experience, so it leads.
    private var zenModeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                iconBadge("leaf.fill", color: AppColors.blockSage.opacity(0.6))
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.gameplay.zen")
                        .font(AppTypography.headlineSmall)
                        .foregroundStyle(AppColors.onSurface)
                    Text("settings.gameplay.zenFooter")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: AppSpacing.sm)
                Toggle("", isOn: $zenMode)
                    .labelsHidden()
                    .tint(AppColors.primary)
                    .accessibilityIdentifier("settings.zen_toggle")
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceContainerLowest, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(AppColors.blockSage.opacity(0.4), lineWidth: 1)
        )
        .shadowL1()
        .accessibilityElement(children: .combine)
    }

    /// Tap-to-preview chips for each SFX event — lets the player audition the
    /// active sound pack + volume (handy after dropping in custom audio).
    private var soundPreviewRow: some View {
        let events: [(SoundService.Sound, String, String)] = [
            (.place,  "place",  "square.fill"),
            (.snap,   "snap",   "arrow.down.to.line"),
            (.solve,  "solve",  "checkmark"),
            (.reward, "reward", "gift.fill"),
            (.error,  "error",  "xmark"),
        ]
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                iconBadge("speaker.wave.2.circle.fill", color: AppColors.secondaryContainer)
                Text("settings.sound.preview")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.onSurface)
                Spacer()
            }
            HStack(spacing: AppSpacing.sm) {
                ForEach(events, id: \.1) { sound, _, icon in
                    Button {
                        SoundService.shared.play(sound)
                        HapticService.shared.impact(.light)
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 44, height: 44)
                            .background(AppColors.surfaceContainerHigh, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!sfxEnabled)
                }
            }
            .opacity(sfxEnabled ? 1 : 0.45)
        }
        .padding(AppSpacing.md)
    }

    /// A labelled volume slider (0…1) that dims when its parent toggle is off.
    /// `onChange` lets the caller preview / apply the new level live.
    private func volumeRow(
        icon: String,
        color: Color,
        value: Binding<Double>,
        enabled: Bool,
        onChange: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppSpacing.sm) {
            iconBadge(icon, color: color)
                .accessibilityHidden(true)
            Image(systemName: "speaker.fill")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.onSurfaceVariant)
                .accessibilityHidden(true)
            Slider(value: value, in: 0...1)
                .tint(AppColors.primary)
                .disabled(!enabled)
                .onChange(of: value.wrappedValue) { _, _ in onChange() }
                .accessibilityLabel(Text("settings.sound.volume"))
                .accessibilityValue(Text(verbatim: "\(Int((value.wrappedValue * 100).rounded()))%"))
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.onSurfaceVariant)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .opacity(enabled ? 1 : 0.45)
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
