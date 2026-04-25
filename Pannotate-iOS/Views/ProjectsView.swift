import SwiftUI

struct ProjectsView: View {
    @Binding var projects: [Project]
    @State private var isPresentingNewProject = false
    @State private var projectToRename: Project?
    @State private var projectPendingDeletion: Project?
    @State private var showDeleteConfirmation = false

    var body: some View {
        FixedHeaderPage {
            BrandHeader(trailingSystemImage: "magnifyingglass")
            PageTitle(title: "Projects", subtitle: "Your creative workspace")
        } content: {
            createProjectCard

            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Projects")
                    .font(.title3.weight(.bold))
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
                    title: trimmedName.isEmpty ? "Untitled Project" : trimmedName,
                    clipCount: 0,
                    updatedAt: "Just now",
                    thumbnail: .lights
                )

                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    projects.insert(project, at: 0)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $projectToRename) { project in
            ManagementRenameSheet(title: "Rename Project", placeholder: "Project name", initialName: project.title) { newName in
                rename(project, to: newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let projectPendingDeletion {
                    delete(projectPendingDeletion)
                }

                projectPendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
        } message: {
            Text("This removes the project from this local prototype session.")
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

                Text("Create New Project")
                    .font(.title3.weight(.bold))
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
        HStack(spacing: 14) {
            NavigationLink {
                ProjectDetailPlaceholderView(
                    project: project,
                    onRename: { projectToRename = project },
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
                        Text(project.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(PannotateTheme.Colors.primaryText)

                        Text("\(project.clipCount) clips · \(project.updatedAt)")
                            .font(.subheadline.weight(.semibold))
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
    }

    private func projectMenu(_ project: Project) -> some View {
        Menu {
            Button {
                projectToRename = project
            } label: {
                Label("Rename Project", systemImage: "pencil")
            }

            Button {
                duplicate(project)
            } label: {
                Label("Duplicate Project", systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                confirmDelete(project)
            } label: {
                Label("Delete Project", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .frame(width: 42, height: 42)
                .contentShape(Circle())
        }
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
                updatedAt: "Just now",
                thumbnail: project.thumbnail
            )
        }
    }

    private func duplicate(_ project: Project) {
        let copy = Project(
            title: "\(project.title) Copy",
            clipCount: project.clipCount,
            updatedAt: "Just now",
            thumbnail: project.thumbnail
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.insert(copy, at: 0)
        }
    }

    private func confirmDelete(_ project: Project) {
        projectPendingDeletion = project
        showDeleteConfirmation = true
    }

    private func delete(_ project: Project) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.removeAll { $0.id == project.id }
        }
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
                    Text("Project Name")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)

                    TextField("Untitled Project", text: $projectName)
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

                    Text("Image Placeholder")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text("A real image picker comes later. For now this creates a local mock project.")
                        .font(.subheadline.weight(.semibold))
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
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
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
    var onRename: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(spacing: 18) {
            MockThumbnail(style: project.thumbnail, cornerRadius: 26)
                .frame(height: 220)

            Text(project.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text("\(project.clipCount) clips · \(project.updatedAt)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)

            Text("Project detail placeholder")
                .font(.headline.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
                .clipShape(Capsule())

            VStack(spacing: 12) {
                SecondaryActionButton(title: "Rename", systemImage: "pencil") {
                    onRename()
                }

                SecondaryActionButton(title: "View Clips", systemImage: "film") {
                    showViewClipsPlaceholder = true
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.headline.weight(.bold))
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
        .alert("Project Clips", isPresented: $showViewClipsPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Clip browsing for this project will be connected later in the prototype.")
        }
        .alert("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the project from this local prototype session.")
        }
    }
}

#Preview {
    ProjectsView(projects: .constant(MockPannotateData.projects))
}
