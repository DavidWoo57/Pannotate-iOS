import SwiftUI

struct ProjectWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss

    let project: Project
    @Binding var outputs: [GeneratedClip]
    @Binding var sequenceClips: [SequenceClip]
    let studioState: StudioProjectState?
    let continuationContext: StudioContinuationContext?
    var onShowProjects: () -> Void = {}
    var onGeneratedClip: (GeneratedClip) -> Void = { _ in }
    var onStudioStateChanged: (StudioProjectState) -> Void = { _ in }
    var onClearContinuation: () -> Void = {}
    var onContinueClip: (GeneratedClip) -> Void = { _ in }
    var onAddToSequence: (GeneratedClip) -> Bool = { _ in false }
    var onRetryClip: (GeneratedClip) -> Void = { _ in }
    var onRenameProject: (Project, String) -> Void = { _, _ in }
    var onDuplicateProject: (Project) -> Void = { _ in }
    var onDeleteProject: (Project) -> Void = { _ in }

    @State private var selectedSection: ProjectWorkspaceSection = .overview
    @State private var projectToRename: Project?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            workspaceTopBar

            workspaceContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            workspaceBottomNavigation
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $projectToRename) { project in
            ManagementRenameSheet(
                title: L10n.string("projects.rename_project"),
                placeholder: L10n.string("projects.project_name"),
                initialName: project.title
            ) { newName in
                onRenameProject(project, newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(L10n.string("projects.delete_project_question"), isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) {
                onDeleteProject(project)
            }

            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("projects.delete_project_message")
        }
    }

    private var workspaceTopBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PannotateTheme.Colors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("common.go_to_projects"))

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)

                Text("workspace.title")
                    .font(PannotateTheme.Typography.label)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }

            Spacer()

            projectActionsMenu
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(PannotateTheme.Colors.background.opacity(0.97))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var workspaceContent: some View {
        switch selectedSection {
        case .overview:
            overview
        case .studio:
            StudioView(
                currentProject: project,
                isEmbeddedInWorkspace: true,
                continuationContext: continuationContext,
                persistedState: studioState,
                onShowProjects: onShowProjects,
                onClearContinuation: onClearContinuation
            ) { clip in
                onGeneratedClip(clip)
                withAnimation(.easeInOut) {
                    selectedSection = .outputs
                }
            } onStudioStateChanged: { state in
                onStudioStateChanged(state)
            }
        case .outputs:
            OutputsView(
                clips: $outputs,
                currentProject: project,
                isEmbeddedInWorkspace: true,
                onShowProjects: onShowProjects,
                onShowStudio: {
                    withAnimation(.easeInOut) {
                        selectedSection = .studio
                    }
                },
                onContinueClip: { clip in
                    onContinueClip(clip)
                    withAnimation(.easeInOut) {
                        selectedSection = .studio
                    }
                },
                onAddToSequence: onAddToSequence,
                onRetryClip: onRetryClip
            ) {
                withAnimation(.easeInOut) {
                    selectedSection = .sequence
                }
            }
        case .sequence:
            SequenceView(
                clips: $sequenceClips,
                currentProject: project,
                isEmbeddedInWorkspace: true,
                onShowProjects: onShowProjects,
                onShowOutputs: {
                    withAnimation(.easeInOut) {
                        selectedSection = .outputs
                    }
                }
            )
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(spacing: 16) {
                overviewHero
                statsGrid
                primaryActions
                recentOutputsSection
                sequencePreviewSection
                projectActionsSection
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 10)
        }
    }

    private var overviewHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            MockThumbnail(style: project.thumbnail, cornerRadius: 24)
                .frame(height: 174)
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.54)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(project.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(String.localizedStringWithFormat(L10n.string("workspace.updated_format"), project.updatedAt))
                            .font(PannotateTheme.Typography.metadataEmphasis)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(16)
                }

            Text("workspace.overview_message")
                .font(PannotateTheme.Typography.body)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .padding(12)
        .pannotateCard()
    }

    private var statsGrid: some View {
        HStack(spacing: 10) {
            workspaceStat(title: L10n.string("tab.outputs"), value: "\(outputs.count)", systemImage: "film")
            workspaceStat(title: L10n.string("tab.sequence"), value: "\(sequenceClips.count)", systemImage: "square.stack.3d.up")
        }
    }

    private func workspaceStat(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 34, height: 34)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text(title)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pannotateCard()
    }

    private var primaryActions: some View {
        VStack(spacing: 10) {
            PrimaryActionButton(
                title: outputs.isEmpty ? L10n.string("workspace.open_studio") : L10n.string("workspace.continue_in_studio"),
                systemImage: "video"
            ) {
                withAnimation(.easeInOut) {
                    selectedSection = .studio
                }
            }

            HStack(spacing: 10) {
                SecondaryActionButton(title: L10n.string("workspace.view_outputs"), systemImage: "film") {
                    withAnimation(.easeInOut) {
                        selectedSection = .outputs
                    }
                }

                SecondaryActionButton(title: L10n.string("workspace.edit_sequence"), systemImage: "square.stack.3d.up") {
                    withAnimation(.easeInOut) {
                        selectedSection = .sequence
                    }
                }
            }
        }
    }

    private var recentOutputsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.recent_outputs"))

            if outputs.isEmpty {
                compactEmptyState(
                    systemImage: "film.badge.plus",
                    title: L10n.string("workspace.no_clips_yet"),
                    message: L10n.string("empty.outputs.message")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(outputs.prefix(3)) { clip in
                        outputPreviewRow(clip)
                    }
                }
            }
        }
    }

    private var sequencePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.sequence_preview"))

            if sequenceClips.isEmpty {
                compactEmptyState(
                    systemImage: "square.stack.3d.up.slash",
                    title: L10n.string("workspace.no_sequence_clips_yet"),
                    message: L10n.string("empty.sequence.message")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(sequenceClips.prefix(3)) { clip in
                        sequencePreviewRow(clip)
                    }
                }
            }
        }
    }

    private func outputPreviewRow(_ clip: GeneratedClip) -> some View {
        HStack(spacing: 12) {
            FixedClipThumbnail(style: clip.thumbnail, image: clip.image, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)

                Text("\(clip.status.label) · \(clip.duration)")
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(12)
        .pannotateCard()
    }

    private func sequencePreviewRow(_ clip: SequenceClip) -> some View {
        HStack(spacing: 12) {
            Text("\(clip.order)")
                .font(PannotateTheme.Typography.metadataEmphasis)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .frame(width: 34, height: 34)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            FixedClipThumbnail(style: clip.thumbnail, image: clip.image, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)

                Text(clip.duration)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(12)
        .pannotateCard()
    }

    private func compactEmptyState(systemImage: String, title: String, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 42, height: 42)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(message)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pannotateCard()
    }

    private var projectActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.project_actions"))

            HStack(spacing: 10) {
                SecondaryActionButton(title: L10n.string("common.rename"), systemImage: "pencil") {
                    projectToRename = project
                }

                SecondaryActionButton(title: L10n.string("projects.duplicate_project"), systemImage: "plus.square.on.square") {
                    onDuplicateProject(project)
                }
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("common.delete", systemImage: "trash")
                    .font(PannotateTheme.Typography.control)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: PannotateTheme.Metrics.buttonHeight)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var projectActionsMenu: some View {
        Menu {
            Button {
                projectToRename = project
            } label: {
                Label("projects.rename_project", systemImage: "pencil")
            }

            Button {
                onDuplicateProject(project)
            } label: {
                Label("projects.duplicate_project", systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("projects.delete_project", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
    }

    private var workspaceBottomNavigation: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.primary.opacity(0.14))
                    .frame(height: 0.5)

                HStack(spacing: 4) {
                    ForEach(ProjectWorkspaceSection.allCases) { section in
                        workspaceNavigationButton(section)
                    }
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 9)
            }
            .background(PannotateTheme.Colors.background)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea(edges: .bottom))
    }

    private func workspaceNavigationButton(_ section: ProjectWorkspaceSection) -> some View {
        let isSelected = selectedSection == section

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                selectedSection = section
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: section.systemImage)
                    .font(.caption2.weight(.semibold))

                Text(section.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.62) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private enum ProjectWorkspaceSection: String, CaseIterable, Identifiable {
    case overview
    case studio
    case outputs
    case sequence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            L10n.string("workspace.overview")
        case .studio:
            L10n.string("tab.studio")
        case .outputs:
            L10n.string("tab.outputs")
        case .sequence:
            L10n.string("tab.sequence")
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "rectangle.grid.1x2"
        case .studio:
            "video"
        case .outputs:
            "film"
        case .sequence:
            "square.stack.3d.up"
        }
    }
}

#Preview {
    NavigationStack {
        ProjectWorkspaceView(
            project: MockPannotateData.projects[0],
            outputs: .constant(MockPannotateData.generatedClips),
            sequenceClips: .constant(MockPannotateData.sequenceClips),
            studioState: nil,
            continuationContext: nil
        )
    }
}
