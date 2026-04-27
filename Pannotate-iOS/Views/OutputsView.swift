import SwiftUI

struct OutputsView: View {
    @Binding var clips: [GeneratedClip]
    let currentProject: Project?
    var onShowProjects: () -> Void = {}
    var onShowStudio: () -> Void = {}
    var onContinueClip: (GeneratedClip) -> Void = { _ in }
    var onAddToSequence: (GeneratedClip) -> Bool = { _ in false }
    var onRetryClip: (GeneratedClip) -> Void = { _ in }
    var onShowSequence: () -> Void = {}

    @State private var selectedClip: GeneratedClip?
    @State private var clipToRename: GeneratedClip?
    @State private var clipPendingDeletion: GeneratedClip?
    @State private var showDeleteConfirmation = false
    @State private var confirmationMessage: String?

    private enum Metrics {
        static let mediaHeight: CGFloat = 190
        static let infoPanelHeight: CGFloat = 154
        static let cardRadius: CGFloat = 22
    }

    var body: some View {
        FixedHeaderPage {
            PageTitle(title: L10n.string("tab.outputs"), subtitle: outputsSubtitle)
        } content: {
            if let currentProject {
                CurrentProjectBanner(prefix: L10n.string("outputs.for_project"), project: currentProject)

                if let confirmationMessage {
                    Label(confirmationMessage, systemImage: "checkmark.circle.fill")
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.success)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(PannotateTheme.Colors.success.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if clips.isEmpty {
                    GuidedEmptyState(
                        systemImage: "film.badge.plus",
                        title: L10n.string("empty.outputs.title"),
                        message: L10n.string("empty.outputs.message"),
                        primaryTitle: L10n.string("empty.outputs.go_to_studio"),
                        primarySystemImage: "video"
                    ) {
                        onShowStudio()
                    }
                } else {
                    ForEach(clips) { clip in
                        outputCard(clip)
                    }
                }
            } else {
                ProjectRequiredEmptyState(
                    title: L10n.string("common.select_project_first"),
                    message: L10n.string("outputs.no_project_message"),
                    buttonTitle: L10n.string("common.go_to_projects"),
                    action: onShowProjects
                )
            }
        }
        .sheet(item: $selectedClip) { clip in
            ClipPreviewPlaceholderSheet(clip: clip) {
                onRetryClip(clip)
            }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $clipToRename) { clip in
            ManagementRenameSheet(title: L10n.string("outputs.rename_clip"), placeholder: L10n.string("outputs.clip_name"), initialName: clip.title) { newName in
                rename(clip, to: newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(L10n.string("outputs.delete_clip_question"), isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) {
                if let clipPendingDeletion {
                    delete(clipPendingDeletion)
                }

                clipPendingDeletion = nil
            }

            Button("common.cancel", role: .cancel) {
                clipPendingDeletion = nil
            }
        } message: {
            Text("outputs.delete_clip_message")
        }
    }

    private var outputsSubtitle: String {
        currentProject.map {
            String.localizedStringWithFormat(L10n.string("outputs.subtitle_for_project_format"), $0.title)
        } ?? L10n.string("common.select_project_first")
    }

    private func outputCard(_ clip: GeneratedClip) -> some View {
        VStack(spacing: 0) {
            outputMediaPreview(clip)

            outputInfoPanel(clip)
        }
        .frame(height: Metrics.mediaHeight + Metrics.infoPanelHeight)
        .background(PannotateTheme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .onTapGesture {
            selectedClip = clip
        }
    }

    private func outputMediaPreview(_ clip: GeneratedClip) -> some View {
        ZStack {
            clipThumbnail(clip, cornerRadius: 0)
                .overlay(Color.black.opacity(isCompleted(clip.status) ? 0.18 : 0.45))
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.48)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                }

            statusBadge(clip.status)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)

            clipMenu(clip)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(14)

            if case .processing(let progress) = clip.status {
                VStack(spacing: 12) {
                    ProgressView(value: Double(progress), total: 100)
                        .progressViewStyle(.circular)
                        .tint(PannotateTheme.Colors.accent)
                        .scaleEffect(1.55)

                    Text("\(progress)%")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            } else if isFailed(clip.status) {
                VStack(spacing: 10) {
                    Image(systemName: outputCenterIcon(for: clip.status))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .frame(width: 66, height: 66)
                        .background(Color.red.opacity(0.34))
                        .clipShape(Circle())

                    Text(clip.failureReason ?? L10n.string("generation.something_went_wrong"))
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 26)
                }
            } else {
                Image(systemName: outputCenterIcon(for: clip.status))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 72, height: 72)
                    .background(.ultraThinMaterial.opacity(0.55))
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.mediaHeight)
        .clipped()
    }

    private func outputInfoPanel(_ clip: GeneratedClip) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(clip.title)
                .font(PannotateTheme.Typography.cardTitle)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .lineLimit(1)

            Text("\(clip.duration) · \(clip.createdAt)")
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .lineLimit(1)

            if isFailed(clip.status) {
                failedClipActions(clip)
            } else {
                normalClipActions(clip)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: Metrics.infoPanelHeight, maxHeight: Metrics.infoPanelHeight, alignment: .topLeading)
        .background(PannotateTheme.Colors.outputInfoPanel)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private func showConfirmation(_ message: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            confirmationMessage = message
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    confirmationMessage = nil
                }
            }
        }
    }

    private func clipMenu(_ clip: GeneratedClip) -> some View {
        Menu {
            if isFailed(clip.status) {
                Button {
                    onRetryClip(clip)
                } label: {
                    Label("generation.retry", systemImage: "arrow.clockwise")
                }
            }

            Button {
                clipToRename = clip
            } label: {
                Label("outputs.rename_clip", systemImage: "pencil")
            }

            Button {
                addClipToSequence(clip)
            } label: {
                Label("outputs.add_to_sequence", systemImage: "square.stack.3d.up")
            }

            Button(role: .destructive) {
                clipPendingDeletion = clip
                showDeleteConfirmation = true
            } label: {
                Label(isFailed(clip.status) ? L10n.string("generation.delete_failed_job") : L10n.string("outputs.delete_clip"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(PannotateTheme.Typography.cardTitle)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial.opacity(0.72))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
        }
    }

    private func addClipToSequence(_ clip: GeneratedClip) {
        let didAdd = onAddToSequence(clip)
        showConfirmation(didAdd ? L10n.string("outputs.added_to_sequence") : L10n.string("outputs.already_in_sequence"))
    }

    private func rename(_ clip: GeneratedClip, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false,
              let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            clips[index] = GeneratedClip(
                id: clip.id,
                title: trimmedName,
                duration: clip.duration,
                createdAt: clip.createdAt,
                status: clip.status,
                thumbnail: clip.thumbnail,
                image: clip.image,
                generationRequestID: clip.generationRequestID,
                generationRequestSummary: clip.generationRequestSummary,
                interpretationMode: clip.interpretationMode,
                finalVideoPrompt: clip.finalVideoPrompt,
                originalGeneratedPrompt: clip.originalGeneratedPrompt,
                annotationCount: clip.annotationCount,
                generationMode: clip.generationMode,
                continuationSourceClipID: clip.continuationSourceClipID,
                continuationSourceClipTitle: clip.continuationSourceClipTitle,
                failureReason: clip.failureReason
            )
        }
    }

    private func delete(_ clip: GeneratedClip) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            clips.removeAll { $0.id == clip.id }
        }
    }

    private func clipThumbnail(_ clip: GeneratedClip, cornerRadius: CGFloat) -> some View {
        GeometryReader { geometry in
            Group {
                if let image = clip.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    MockThumbnail(style: clip.thumbnail, cornerRadius: cornerRadius)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func statusBadge(_ status: ClipStatus) -> some View {
        Label(status.label, systemImage: statusIcon(status))
            .font(PannotateTheme.Typography.metadataEmphasis)
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(statusColor(status).opacity(0.18))
            .clipShape(Capsule())
    }

    private func statusIcon(_ status: ClipStatus) -> String {
        switch status {
        case .done:
            "checkmark.circle"
        case .processing:
            "progress.indicator"
        case .queued:
            "clock"
        case .failed:
            "exclamationmark.triangle"
        }
    }

    private func statusColor(_ status: ClipStatus) -> Color {
        switch status {
        case .done:
            PannotateTheme.Colors.success
        case .processing, .queued:
            PannotateTheme.Colors.accent
        case .failed:
            .red
        }
    }

    private func outputCenterIcon(for status: ClipStatus) -> String {
        switch status {
        case .done:
            "play.fill"
        case .processing:
            "progress.indicator"
        case .queued:
            "clock"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    private func isCompleted(_ status: ClipStatus) -> Bool {
        if case .done = status {
            return true
        }

        return false
    }

    private func isFailed(_ status: ClipStatus) -> Bool {
        if case .failed = status {
            return true
        }

        return false
    }

    private func normalClipActions(_ clip: GeneratedClip) -> some View {
        HStack(spacing: 12) {
            Button {
                onContinueClip(clip)
            } label: {
                Label("common.continue", systemImage: "arrow.clockwise")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(PannotateTheme.Colors.outputSecondaryButton)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            PrimaryActionButton(title: L10n.string("tab.sequence"), systemImage: "arrow.right") {
                addClipToSequence(clip)
                onShowSequence()
            }
        }
    }

    private func failedClipActions(_ clip: GeneratedClip) -> some View {
        HStack(spacing: 12) {
            PrimaryActionButton(title: L10n.string("generation.retry"), systemImage: "arrow.clockwise") {
                onRetryClip(clip)
            }

            Button(role: .destructive) {
                clipPendingDeletion = clip
                showDeleteConfirmation = true
            } label: {
                Label("common.delete", systemImage: "trash")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(Color.red.opacity(0.22), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ClipPreviewPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let clip: GeneratedClip
    let onRetry: () -> Void

    private enum Metrics {
        static let previewHeight: CGFloat = 230
        static let previewRadius: CGFloat = 26
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    previewMedia

                    Text(clip.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("outputs.clip_preview_placeholder")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("outputs.clip_preview_note")
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if isFailed {
                        failedPreviewActions
                    }

                    generationDetails
                }
                .padding(PannotateTheme.Metrics.pagePadding)
            }
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("outputs.clip_preview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private var generationDetails: some View {
        if hasGenerationDetails {
            VStack(alignment: .leading, spacing: 12) {
                Text("generation.details")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.accent)

                detailRows

                if isFailed {
                    detailBlock(title: L10n.string("generation.failure_reason"), text: clip.failureReason ?? L10n.string("generation.something_went_wrong"))
                }

                if let finalVideoPrompt = clip.finalVideoPrompt {
                    detailBlock(title: L10n.string("generation.prompt_used"), text: finalVideoPrompt)
                }

                if let originalGeneratedPrompt = clip.originalGeneratedPrompt,
                   originalGeneratedPrompt != clip.finalVideoPrompt {
                    detailBlock(title: L10n.string("generation.original_generated_prompt"), text: originalGeneratedPrompt)
                }

                if let generationRequestSummary = clip.generationRequestSummary {
                    detailBlock(title: L10n.string("generation.request_summary"), text: generationRequestSummary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(PannotateTheme.Colors.cardMuted)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                    .stroke(PannotateTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    private var hasGenerationDetails: Bool {
        clip.generationRequestID != nil ||
            clip.generationRequestSummary != nil ||
            clip.interpretationMode != nil ||
            clip.finalVideoPrompt != nil ||
            clip.originalGeneratedPrompt != nil ||
            clip.annotationCount != nil ||
            clip.generationMode != nil ||
            clip.continuationSourceClipTitle != nil ||
            clip.failureReason != nil ||
            isFailed
    }

    private var detailRows: some View {
        VStack(spacing: 8) {
            metadataRow(label: L10n.string("common.status"), value: clip.status.label)
            metadataRow(label: L10n.string("studio.interpretation_mode"), value: clip.interpretationMode?.title ?? L10n.string("common.not_captured"))
            metadataRow(label: L10n.string("generation.annotation_count"), value: clip.annotationCount.map(String.init) ?? L10n.string("common.not_captured"))
            metadataRow(label: L10n.string("generation.request_id"), value: clip.generationRequestID.map { String($0.uuidString.prefix(8)) } ?? L10n.string("common.not_captured"))
            metadataRow(label: L10n.string("generation.context"), value: generationContextText)

            if let sourceClipTitle = clip.continuationSourceClipTitle {
                metadataRow(label: L10n.string("generation.source_clip"), value: sourceClipTitle)
            }
        }
    }

    private var failedPreviewActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.string("generation.generation_failed"), systemImage: "exclamationmark.triangle.fill")
                .font(PannotateTheme.Typography.metadataEmphasis)
                .foregroundStyle(.red)

            Text(clip.failureReason ?? L10n.string("generation.something_went_wrong"))
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryActionButton(title: L10n.string("generation.retry"), systemImage: "arrow.clockwise") {
                onRetry()
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.red.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                .stroke(Color.red.opacity(0.22), lineWidth: 1)
        )
    }

    private var isFailed: Bool {
        if case .failed = clip.status {
            return true
        }

        return false
    }

    private var generationContextText: String {
        if let generationMode = clip.generationMode {
            return generationMode.title
        }

        return clip.continuationSourceClipTitle == nil ? L10n.string("generation.new_shot") : L10n.string("generation.continue_from_last_frame")
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(PannotateTheme.Typography.label)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .frame(width: 132, alignment: .leading)

            Text(value)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(PannotateTheme.Typography.label)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            Text(text)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var previewMedia: some View {
        ZStack {
            clipThumbnail(cornerRadius: Metrics.previewRadius)

            Image(systemName: previewIcon(for: clip.status))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 78, height: 78)
                .background(.ultraThinMaterial.opacity(0.62))
                .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.previewRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.previewRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func clipThumbnail(cornerRadius: CGFloat) -> some View {
        GeometryReader { geometry in
            Group {
                if let image = clip.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    MockThumbnail(style: clip.thumbnail, cornerRadius: cornerRadius)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func previewIcon(for status: ClipStatus) -> String {
        switch status {
        case .done:
            "play.fill"
        case .processing:
            "progress.indicator"
        case .queued:
            "clock"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    OutputsView(clips: .constant(MockPannotateData.generatedClips), currentProject: MockPannotateData.projects.first)
}
