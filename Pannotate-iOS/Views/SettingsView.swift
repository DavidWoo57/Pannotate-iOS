import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var selectedThemeRawValue = AppTheme.dark.rawValue
    @State private var pushNotificationsEnabled = true
    @State private var outputQuality = "Standard"
    @State private var autoChainClips = false
    @State private var motionSmoothing = true

    private let qualities = [
        ("Draft", "Fast, 480p"),
        ("Standard", "720p"),
        ("High", "1080p")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                settingsSection("Appearance") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Theme")
                            .font(.headline.weight(.bold))
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

                settingsSection("Notifications") {
                    toggleRow(
                        title: "Push Notifications",
                        subtitle: "Generation complete, exports ready",
                        systemImage: "bell",
                        isOn: $pushNotificationsEnabled
                    )
                }

                settingsSection("Generation") {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Output Quality")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)

                            HStack(spacing: 12) {
                                ForEach(qualities, id: \.0) { quality in
                                    optionTile(
                                        title: quality.0,
                                        subtitle: quality.1,
                                        systemImage: nil,
                                        isSelected: outputQuality == quality.0
                                    ) {
                                        outputQuality = quality.0
                                    }
                                }
                            }
                        }

                        toggleRowContent(
                            title: "Auto-chain Clips",
                            subtitle: "Continue from last frame automatically",
                            systemImage: "bolt",
                            isOn: $autoChainClips
                        )

                        toggleRowContent(
                            title: "Motion Smoothing",
                            subtitle: "Reduce jitter between frames",
                            systemImage: "waveform.path",
                            isOn: $motionSmoothing
                        )
                    }
                    .padding(16)
                    .pannotateCard()
                }

                settingsSection("Account") {
                    VStack(spacing: 0) {
                        settingsLink(title: "Subscription", systemImage: "creditcard")
                        settingsLink(title: "Privacy & Data", systemImage: "lock.shield")
                        settingsLink(title: "Connected Accounts", systemImage: "person.2")
                    }
                    .pannotateCard()
                }

                settingsSection("About") {
                    VStack(spacing: 0) {
                        settingsLink(title: "Pannotate", detail: "Version 1.0.0", systemImage: "bolt")
                        settingsLink(title: "Terms of Service", systemImage: "doc.text")
                        settingsLink(title: "Privacy Policy", systemImage: "hand.raised")
                    }
                    .pannotateCard()
                }
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 48)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Settings")
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
                    .font(.subheadline.weight(.bold))

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
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
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
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                if let detail {
                    Text(detail)
                        .font(.subheadline.weight(.semibold))
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
