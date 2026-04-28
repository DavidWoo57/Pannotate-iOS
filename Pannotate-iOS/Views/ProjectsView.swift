import SwiftUI

struct ProjectsView: View {
    @Binding var projects: [Project]
    @Binding var currentProjectID: UUID?
    var projectCover: (Project) -> ProjectCoverSource = { ProjectCoverSource(thumbnail: $0.thumbnail, image: nil) }
    var projectOutputCount: (Project) -> Int = { $0.clipCount }
    var onProjectCreated: (Project) -> Void = { _ in }
    var onProjectRenamed: (Project, String) -> Void = { _, _ in }
    var onProjectDuplicated: (Project, Project) -> Void = { _, _ in }
    var onProjectDeleted: (Project) -> Void = { _ in }
    var onOpenProject: (Project) -> Void = { _ in }

    @State private var isPresentingNewProject = false
    @State private var projectToRename: Project?
    @State private var projectPendingDeletion: Project?
    @State private var showDeleteConfirmation = false

    var body: some View {
        FixedHeaderPage {
            BrandHeader(trailingSystemImage: "magnifyingglass")
            PageTitle(title: L10n.string("tab.projects"), subtitle: L10n.string("projects.subtitle"))
        } content: {
            createProjectCard

            if projects.isEmpty {
                GuidedEmptyState(
                    systemImage: "folder.badge.plus",
                    title: L10n.string("empty.projects.title"),
                    message: L10n.string("empty.projects.message"),
                    primaryTitle: L10n.string("empty.projects.create_first"),
                    primarySystemImage: "plus"
                ) {
                    isPresentingNewProject = true
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("projects.recent_projects")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    ForEach(projects) { project in
                        projectRow(project)
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingNewProject) {
            NewProjectSheet { name in
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let project = Project(
                    title: trimmedName.isEmpty ? L10n.string("projects.untitled_project") : trimmedName,
                    clipCount: 0,
                    updatedAt: L10n.string("common.just_now"),
                    thumbnail: .lights
                )

                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    projects.insert(project, at: 0)
                    currentProjectID = project.id
                }

                onProjectCreated(project)
                onOpenProject(project)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $projectToRename) { project in
            ManagementRenameSheet(title: L10n.string("projects.rename_project"), placeholder: L10n.string("projects.project_name"), initialName: project.title) { newName in
                rename(project, to: newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(L10n.string("projects.delete_project_question"), isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) {
                if let projectPendingDeletion {
                    delete(projectPendingDeletion)
                }

                projectPendingDeletion = nil
            }

            Button("common.cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
        } message: {
            Text("projects.delete_project_message")
        }
    }

    private var createProjectCard: some View {
        Button {
            isPresentingNewProject = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 78, height: 78)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.70))
                    .clipShape(Circle())

                Text("projects.create_new_project")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 188)
            .background(PannotateTheme.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(PannotateTheme.Colors.accent.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
            )
        }
        .buttonStyle(.plain)
    }

    private func projectRow(_ project: Project) -> some View {
        let isCurrent = project.id == currentProjectID

        return HStack(spacing: 14) {
            Button {
                currentProjectID = project.id
                onOpenProject(project)
            } label: {
                HStack(spacing: 14) {
                    ProjectCoverThumbnail(
                        cover: projectCover(project),
                        size: CGSize(width: 96, height: 68),
                        cornerRadius: 18
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(project.title)
                                .font(PannotateTheme.Typography.cardTitle)
                                .foregroundStyle(PannotateTheme.Colors.primaryText)

                            if isCurrent {
                                Label("common.current", systemImage: "checkmark.circle.fill")
                                    .font(PannotateTheme.Typography.label)
                                    .foregroundStyle(PannotateTheme.Colors.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(PannotateTheme.Colors.accentSoft.opacity(0.7))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(projectClipMetadata(project))
                            .font(PannotateTheme.Typography.metadata)
                            .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            projectMenu(project)
        }
        .padding(9)
        .pannotateCard()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isCurrent ? PannotateTheme.Colors.accent.opacity(0.72) : .clear, lineWidth: 2)
        )
    }

    private func projectMenu(_ project: Project) -> some View {
        Menu {
            Button {
                projectToRename = project
            } label: {
                Label("projects.rename_project", systemImage: "pencil")
            }

            Button {
                duplicate(project)
            } label: {
                Label("projects.duplicate_project", systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                confirmDelete(project)
            } label: {
                Label("projects.delete_project", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .frame(width: 42, height: 42)
                .contentShape(Circle())
        }
    }

    private func projectClipMetadata(_ project: Project) -> String {
        String.localizedStringWithFormat(
            L10n.string("projects.clip_metadata_format"),
            projectOutputCount(project),
            project.updatedAt
        )
    }

    private func rename(_ project: Project, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false,
              let index = projects.firstIndex(where: { $0.id == project.id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects[index] = Project(
                id: project.id,
                title: trimmedName,
                clipCount: project.clipCount,
                updatedAt: L10n.string("common.just_now"),
                thumbnail: project.thumbnail,
                description: project.description,
                createdAt: project.createdAt,
                updatedAtDate: Date()
            )
        }
        onProjectRenamed(project, trimmedName)
    }

    private func duplicate(_ project: Project) {
        let copy = Project(
            title: String.localizedStringWithFormat(L10n.string("projects.copy_format"), project.title),
            clipCount: project.clipCount,
            updatedAt: L10n.string("common.just_now"),
            thumbnail: project.thumbnail,
            description: project.description
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.insert(copy, at: 0)
        }

        onProjectDuplicated(project, copy)
    }

    private func confirmDelete(_ project: Project) {
        projectPendingDeletion = project
        showDeleteConfirmation = true
    }

    private func delete(_ project: Project) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.removeAll { $0.id == project.id }
        }

        onProjectDeleted(project)
    }
}

private struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""
    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("projects.project_name")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)

                    TextField(L10n.string("projects.untitled_project"), text: $projectName)
                        .font(.headline)
                        .textInputAutocapitalization(.words)
                        .padding(16)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                        )
                }

                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(PannotateTheme.Colors.accent)

                    Text("projects.image_placeholder")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text("projects.image_placeholder_note")
                        .font(PannotateTheme.Typography.metadata)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(PannotateTheme.cardGradient)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(PannotateTheme.Colors.accent.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                )

                Spacer()
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("projects.new_project"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        onCreate(projectName)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    ProjectsView(projects: .constant(MockPannotateData.projects), currentProjectID: .constant(MockPannotateData.projects.first?.id))
}
