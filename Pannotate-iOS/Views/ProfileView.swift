import SwiftUI

struct ProfileStats {
    let projectCount: Int
    let clipCount: Int
    let exportCount: Int

    static let preview = ProfileStats(
        projectCount: MockPannotateData.profile.projectCount,
        clipCount: MockPannotateData.profile.clipCount,
        exportCount: 0
    )
}

struct ProfileView: View {
    var developerToolsActions: DeveloperToolsActions = .preview
    var stats: ProfileStats = .preview

    private let profile = MockPannotateData.profile
    private let activity = MockPannotateData.activity

    var body: some View {
        FixedHeaderPage(bottomPadding: PannotateTheme.Metrics.tabBarContentInset + 12) {
            HStack {
                BrandHeader()

                NavigationLink {
                    SettingsView(developerToolsActions: developerToolsActions)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .frame(width: 46, height: 46)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(PannotateTheme.Colors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        } content: {
            userCard

            statsGrid

            VStack(spacing: 14) {
                SectionLabel(title: L10n.string("profile.recent_activity"))

                VStack(spacing: 0) {
                    ForEach(activity) { item in
                        activityRow(item)
                    }
                }
                .pannotateCard()
            }

            settingsRow

            prototypeRows
        }
    }

    private var userCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(PannotateTheme.brandGradient)
                    .frame(width: 82, height: 82)
                    .overlay {
                        Text("JD")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(profile.handle)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)

                    Text(profile.plan)
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(PannotateTheme.Colors.accent.opacity(0.4), lineWidth: 1))
                }

                Spacer()
            }

            Divider()
                .overlay(PannotateTheme.Colors.border)

            VStack(spacing: 10) {
                HStack {
                    Text("profile.monthly_credits")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)

                    Spacer()

                    Text("\(profile.monthlyCreditsUsed) / \(profile.monthlyCreditsTotal)")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                }

                ProgressView(value: Double(profile.monthlyCreditsUsed), total: Double(profile.monthlyCreditsTotal))
                    .tint(PannotateTheme.Colors.accent)
                    .background(PannotateTheme.Colors.tertiaryText.opacity(0.35))
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .pannotateCard()
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(title: L10n.string("tab.projects"), value: stats.projectCount, systemImage: "folder")
            statCard(title: L10n.string("profile.clips"), value: stats.clipCount, systemImage: "film")
            statCard(title: L10n.string("profile.exports"), value: stats.exportCount, systemImage: "square.stack.3d.up")
        }
    }

    private func statCard(title: String, value: Int, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)

            Text("\(value)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text(title)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .pannotateCard()
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            FixedMockThumbnail(
                style: item.thumbnail,
                size: CGSize(width: 62, height: 44),
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(item.timeAgo)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
        }
        .padding(16)
    }

    private var settingsRow: some View {
        NavigationLink {
            SettingsView(developerToolsActions: developerToolsActions)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "gearshape")
                    .font(.headline)
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                    .clipShape(Circle())

                Text("settings.title")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .padding(16)
            .pannotateCard()
        }
        .buttonStyle(.plain)
    }

    private var prototypeRows: some View {
        VStack(spacing: 14) {
            SectionLabel(title: L10n.string("profile.account_support"))

            VStack(spacing: 0) {
                profileLink(title: L10n.string("settings.subscription"), subtitle: L10n.string("profile.subscription_subtitle"), systemImage: "creditcard")
                profileLink(title: L10n.string("profile.help"), subtitle: L10n.string("profile.help_subtitle"), systemImage: "questionmark.circle")
                profileLink(title: L10n.string("profile.privacy"), subtitle: L10n.string("profile.privacy_subtitle"), systemImage: "lock.shield")
                profileLink(title: L10n.string("profile.rate_pannotate"), subtitle: L10n.string("profile.rate_pannotate_subtitle"), systemImage: "star")
            }
            .pannotateCard()
        }
    }

    private func profileLink(title: String, subtitle: String, systemImage: String) -> some View {
        NavigationLink {
            ProfilePlaceholderDetailView(title: title, subtitle: subtitle, systemImage: systemImage)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(subtitle)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfilePlaceholderDetailView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 104, height: 104)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            Text(title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text(subtitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)

            Text("profile.placeholder_detail_note")
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()
        }
        .padding(PannotateTheme.Metrics.pagePadding)
        .frame(maxWidth: .infinity)
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
