import SwiftUI

struct OutputsView: View {
    @Binding var clips: [GeneratedClip]
    var onAddToSequence: (GeneratedClip) -> Bool = { _ in false }
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
            PageTitle(title: "Outputs", subtitle: "Your generated clips")
        } content: {
            if let confirmationMessage {
                Label(confirmationMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(PannotateTheme.Colors.success.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ForEach(clips) { clip in
                outputCard(clip)
            }
        }
        .sheet(item: $selectedClip) { clip in
            ClipPreviewPlaceholderSheet(clip: clip)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $clipToRename) { clip in
            ManagementRenameSheet(title: "Rename Clip", placeholder: "Clip name", initialName: clip.title) { newName in
                rename(clip, to: newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Clip?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let clipPendingDeletion {
                    delete(clipPendingDeletion)
                }

                clipPendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {
                clipPendingDeletion = nil
            }
        } message: {
            Text("This removes the clip from Outputs in this local prototype session.")
        }
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
                .overlay(Color.black.opacity(clip.status.label == "Done" ? 0.18 : 0.45))
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
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
            } else {
                Image(systemName: clip.status.label == "Queued" ? "clock" : "play.fill")
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
                .font(.headline.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .lineLimit(1)

            Text("\(clip.duration) · \(clip.createdAt)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .lineLimit(1)

            HStack(spacing: 12) {
                Button {
                    showConfirmation("Continue from last frame")
                } label: {
                    Label("Continue", systemImage: "arrow.clockwise")
                        .font(.headline.weight(.bold))
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

                PrimaryActionButton(title: "Sequence", systemImage: "arrow.right") {
                    addClipToSequence(clip)
                    onShowSequence()
                }
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
            Button {
                clipToRename = clip
            } label: {
                Label("Rename Clip", systemImage: "pencil")
            }

            Button {
                addClipToSequence(clip)
            } label: {
                Label("Add to Sequence", systemImage: "square.stack.3d.up")
            }

            Button(role: .destructive) {
                clipPendingDeletion = clip
                showDeleteConfirmation = true
            } label: {
                Label("Delete Clip", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial.opacity(0.72))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
        }
    }

    private func addClipToSequence(_ clip: GeneratedClip) {
        let didAdd = onAddToSequence(clip)
        showConfirmation(didAdd ? "Added to sequence" : "Already in sequence")
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
                image: clip.image
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
            .font(.subheadline.weight(.bold))
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
        }
    }

    private func statusColor(_ status: ClipStatus) -> Color {
        switch status {
        case .done:
            PannotateTheme.Colors.success
        case .processing, .queued:
            PannotateTheme.Colors.accent
        }
    }
}

private struct ClipPreviewPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let clip: GeneratedClip

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                ZStack {
                    clipThumbnail(cornerRadius: 26)

                    Image(systemName: clip.status.label == "Queued" ? "clock" : "play.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 78, height: 78)
                        .background(.ultraThinMaterial.opacity(0.62))
                        .clipShape(Circle())
                }
                .frame(height: 230)

                Text(clip.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Clip Preview Placeholder")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Real video playback will be connected later. This keeps the prototype tappable without adding media services.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Clip Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func clipThumbnail(cornerRadius: CGFloat) -> some View {
        Group {
            if let image = clip.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                MockThumbnail(style: clip.thumbnail, cornerRadius: cornerRadius)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    OutputsView(clips: .constant(MockPannotateData.generatedClips))
}
