import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var selectedThemeRawValue = AppTheme.dark.rawValue
    @State private var pushNotificationsEnabled = true
    @State private var outputQuality = "Standard"
    @State private var autoChainClips = false
    @State private var motionSmoothing = true

    private let qualities = [
        ("Draft", "settings.quality.draft", "settings.quality.draft_subtitle"),
        ("Standard", "settings.quality.standard", "settings.quality.standard_subtitle"),
        ("High", "settings.quality.high", "settings.quality.high_subtitle")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                settingsSection(L10n.string("settings.section.appearance")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("settings.theme")
                            .font(PannotateTheme.Typography.cardTitle)
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)

                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                optionTile(
                                    title: theme.title,
                                    subtitle: nil,
                                    systemImage: theme.systemImage,
                                    isSelected: selectedTheme == theme
                                ) {
                                    selectedTheme = theme
                                }
                            }
                        }
                    }
                    .padding(16)
                    .pannotateCard()
                }

                settingsSection(L10n.string("settings.notifications")) {
                    toggleRow(
                        title: L10n.string("settings.push_notifications"),
                        subtitle: L10n.string("settings.push_notifications_subtitle"),
                        systemImage: "bell",
                        isOn: $pushNotificationsEnabled
                    )
                }

                settingsSection(L10n.string("settings.section.generation")) {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.output_quality")
                                .font(PannotateTheme.Typography.cardTitle)
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)

                            HStack(spacing: 12) {
                                ForEach(qualities, id: \.0) { quality in
                                    optionTile(
                                        title: L10n.string(quality.1),
                                        subtitle: L10n.string(quality.2),
                                        systemImage: nil,
                                        isSelected: outputQuality == quality.0
                                    ) {
                                        outputQuality = quality.0
                                    }
                                }
                            }
                        }

                        toggleRowContent(
                            title: L10n.string("settings.auto_chain_clips"),
                            subtitle: L10n.string("settings.auto_chain_clips_subtitle"),
                            systemImage: "bolt",
                            isOn: $autoChainClips
                        )

                        toggleRowContent(
                            title: L10n.string("settings.motion_smoothing"),
                            subtitle: L10n.string("settings.motion_smoothing_subtitle"),
                            systemImage: "waveform.path",
                            isOn: $motionSmoothing
                        )
                    }
                    .padding(16)
                    .pannotateCard()
                }

                settingsSection(L10n.string("settings.account")) {
                    VStack(spacing: 0) {
                        settingsLink(title: L10n.string("settings.subscription"), systemImage: "creditcard")
                        settingsLink(title: L10n.string("settings.privacy_data"), systemImage: "lock.shield")
                        settingsLink(title: L10n.string("settings.connected_accounts"), systemImage: "person.2")
                    }
                    .pannotateCard()
                }

                settingsSection(L10n.string("settings.about")) {
                    VStack(spacing: 0) {
                        settingsLink(title: L10n.string("app.name"), detail: L10n.string("settings.version_1"), systemImage: "bolt")
                        settingsLink(title: L10n.string("settings.terms"), systemImage: "doc.text")
                        settingsLink(title: L10n.string("settings.privacy_policy"), systemImage: "hand.raised")
                    }
                    .pannotateCard()
                }
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 48)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(L10n.string("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PannotateTheme.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var selectedTheme: AppTheme {
        get {
            AppTheme(rawValue: selectedThemeRawValue) ?? .system
        }
        nonmutating set {
            selectedThemeRawValue = newValue.rawValue
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            SectionLabel(title: title)
            content()
        }
    }

    private func optionTile(
        title: String,
        subtitle: String?,
        systemImage: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                }

                Text(title)
                    .font(PannotateTheme.Typography.metadataEmphasis)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
            }
            .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.62) : PannotateTheme.Colors.cardMuted)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                    .stroke(isSelected ? PannotateTheme.Colors.accent.opacity(0.72) : PannotateTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        toggleRowContent(title: title, subtitle: subtitle, systemImage: systemImage, isOn: isOn)
            .padding(16)
            .pannotateCard()
    }

    private func toggleRowContent(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(width: 46, height: 46)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(subtitle)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(PannotateTheme.Colors.accent)
        }
    }

    private func settingsLink(title: String, detail: String? = nil, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 38, height: 38)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                if let detail {
                    Text(detail)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
        }
        .padding(16)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
