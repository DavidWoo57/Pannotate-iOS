import SwiftUI

struct ProjectSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let project: Project
    let cover: ProjectCoverSource
    let outputCount: Int
    let sequenceClipCount: Int
    let activityCount: Int
    var onSave: (String, String) -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void

    @State private var projectName: String
    @State private var projectDescription: String
    @State private var showDeleteConfirmation = false

    init(
        project: Project,
        cover: ProjectCoverSource,
        outputCount: Int,
        sequenceClipCount: Int,
        activityCount: Int,
        onSave: @escaping (String, String) -> Void,
        onDuplicate: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.project = project
        self.cover = cover
        self.outputCount = outputCount
        self.sequenceClipCount = sequenceClipCount
        self.activityCount = activityCount
        self.onSave = onSave
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
        _projectName = State(initialValue: project.title)
        _projectDescription = State(initialValue: project.description)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("project.cover")) {
                    VStack(alignment: .leading, spacing: 10) {
                        ProjectCoverThumbnail(cover: cover, cornerRadius: 18)
                            .frame(height: 148)

                        Text("project.auto_cover_note")
                            .font(PannotateTheme.Typography.metadata)
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, 4)
                }

                Section(L10n.string("project.info")) {
                    TextField(L10n.string("projects.project_name"), text: $projectName)
                        .textInputAutocapitalization(.words)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("project.description")
                            .font(PannotateTheme.Typography.metadataEmphasis)
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)

                        ZStack(alignment: .topLeading) {
                            if projectDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("project.description_placeholder")
                                    .font(.body)
                                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }

                            TextEditor(text: $projectDescription)
                                .frame(minHeight: 96)
                                .scrollContentBackground(.hidden)
                        }
                    }
                }

                Section(L10n.string("project.metadata")) {
                    metadataRow(title: L10n.string("project.created"), value: formattedDate(project.createdAt), systemImage: "calendar")
                    metadataRow(title: L10n.string("project.last_updated"), value: formattedDate(project.updatedAtDate), systemImage: "clock")
                    metadataRow(title: L10n.string("project.clips"), value: "\(outputCount)", systemImage: "film")
                    metadataRow(title: L10n.string("project.sequence_clips"), value: "\(sequenceClipCount)", systemImage: "square.stack.3d.up")
                    metadataRow(title: L10n.string("activity.recent_activity"), value: "\(activityCount)", systemImage: "clock.arrow.circlepath")
                }

                Section(L10n.string("workspace.project_actions")) {
                    Button {
                        onDuplicate()
                    } label: {
                        Label("projects.duplicate_project", systemImage: "plus.square.on.square")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("projects.delete_project", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PannotateTheme.Colors.background)
            .navigationTitle(L10n.string("project.settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        onSave(projectName, projectDescription)
                        dismiss()
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
    }

    private func metadataRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Spacer()

            Text(value)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day().hour().minute())
    }
}

#Preview {
    ProjectSettingsView(
        project: MockPannotateData.projects[0],
        cover: ProjectCoverSource(thumbnail: .city, image: nil),
        outputCount: 3,
        sequenceClipCount: 2,
        activityCount: 4,
        onSave: { _, _ in },
        onDuplicate: {},
        onDelete: {}
    )
}
