import SwiftUI

struct ProjectsView: View {
    @Binding var projects: [Project]
    @Binding var currentProjectID: UUID?
    var onProjectCreated: (Project) -> Void = { _ in }
    var onProjectDeleted: (Project) -> Void = { _ in }

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

            VStack(alignment: .leading, spacing: 12) {
                Text("projects.recent_projects")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                ForEach(projects) { project in
                    projectRow(project)
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
            NavigationLink {
                ProjectDetailPlaceholderView(
                    project: project,
                    isCurrent: isCurrent,
                    onRename: { projectToRename = project },
                    onSelect: { currentProjectID = project.id },
                    onDelete: { delete(project) }
                )
            } label: {
                HStack(spacing: 14) {
                    FixedMockThumbnail(
                        style: project.thumbnail,
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
            .simultaneousGesture(TapGesture().onEnded {
                currentProjectID = project.id
            })

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
            project.clipCount,
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
                thumbnail: project.thumbnail
            )
        }
    }

    private func duplicate(_ project: Project) {
        let copy = Project(
            title: String.localizedStringWithFormat(L10n.string("projects.copy_format"), project.title),
            clipCount: project.clipCount,
            updatedAt: L10n.string("common.just_now"),
            thumbnail: project.thumbnail
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.insert(copy, at: 0)
        }

        onProjectCreated(copy)
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

private struct ProjectDetailPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showViewClipsPlaceholder = false
    let project: Project
    let isCurrent: Bool
    var onRename: () -> Void = {}
    var onSelect: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(spacing: 18) {
            MockThumbnail(style: project.thumbnail, cornerRadius: 26)
                .frame(height: 220)

            Text(project.title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text(projectClipMetadata(project))
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)

            Text("projects.detail_placeholder")
                .font(PannotateTheme.Typography.cardTitle)
                .foregroundStyle(PannotateTheme.Colors.accent)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
                .clipShape(Capsule())

            VStack(spacing: 12) {
                if isCurrent {
                    Label("projects.current_project", systemImage: "checkmark.circle.fill")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
                        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                } else {
                    PrimaryActionButton(title: L10n.string("projects.make_current"), systemImage: "checkmark.circle") {
                        onSelect()
                    }
                }

                SecondaryActionButton(title: L10n.string("common.rename"), systemImage: "pencil") {
                    onRename()
                }

                SecondaryActionButton(title: L10n.string("projects.view_clips"), systemImage: "film") {
                    showViewClipsPlaceholder = true
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("common.delete", systemImage: "trash")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(PannotateTheme.Metrics.pagePadding)
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.string("projects.project_clips"), isPresented: $showViewClipsPlaceholder) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("projects.project_clips_message")
        }
        .alert(L10n.string("projects.delete_project_question"), isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) {
                onDelete()
                dismiss()
            }

            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("projects.delete_project_message")
        }
    }

    private func projectClipMetadata(_ project: Project) -> String {
        String.localizedStringWithFormat(
            L10n.string("projects.clip_metadata_format"),
            project.clipCount,
            project.updatedAt
        )
    }
}

#Preview {
    ProjectsView(projects: .constant(MockPannotateData.projects), currentProjectID: .constant(MockPannotateData.projects.first?.id))
}
