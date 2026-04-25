import PhotosUI
import SwiftUI
import UIKit

struct StudioView: View {
    @State private var motionPrompt = ""
    @State private var isGenerating = false
    @State private var successMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedMockThumbnail: ThumbnailStyle?
    @State private var imageSelectionMessage: String?
    @State private var imageScale: CGFloat = 1
    @State private var imageOffset: CGSize = .zero
    @State private var activeImageAdjustment: ImageAdjustmentSession?
    @State private var annotations: [StudioAnnotation] = []
    @State private var annotationEditorSession: AnnotationEditorSession?
    @State private var isPresentingPromptPreview = false
    @State private var annotationCanvasSize = CGSize(width: 360, height: 224)
    @State private var lastGeneratedInstruction: String?
    @State private var lastGenerationRequest: GenerationRequest?

    let currentProject: Project?
    var continuationContext: StudioContinuationContext? = nil
    var onShowProjects: () -> Void = {}
    var onClearContinuation: () -> Void = {}
    var onGeneratedClip: (GeneratedClip) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            studioHeader

            if let currentProject {
                ScrollView {
                    VStack(spacing: 20) {
                        CurrentProjectBanner(prefix: "Editing", project: currentProject)

                        if let continuationContext {
                            continuationBanner(continuationContext)
                        }

                        canvas

                        annotationEntryPoint

                        TextField("Describe the motion...", text: $motionPrompt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(PannotateTheme.Colors.primaryText)
                            .padding(.horizontal, 16)
                            .frame(height: 58)
                            .background(PannotateTheme.Colors.cardMuted)
                            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                    .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                            )

                        promptPreviewButton

                        generateButton

                        if let successMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(successMessage, systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(PannotateTheme.Colors.success)

                                if lastGeneratedInstruction != nil {
                                    Button {
                                        isPresentingPromptPreview = true
                                    } label: {
                                        Text("View request used")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(PannotateTheme.Colors.accent)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if let imageSelectionMessage {
                            Label(imageSelectionMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(PannotateTheme.Metrics.pagePadding)
                    .padding(.top, 50)
                    .padding(.bottom, PannotateTheme.Metrics.tabBarContentInset)
                }
            } else {
                ProjectRequiredEmptyState(
                    title: "Select or create a project first",
                    message: "Studio tools are scoped to the current project. Choose a project before selecting images, annotating, or generating mock clips.",
                    buttonTitle: "Go to Projects",
                    action: onShowProjects
                )
            }
        }
        .pannotatePage()
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onAppear {
            applyContinuationContextIfNeeded()
        }
        .onChange(of: continuationContext?.id) { _, _ in
            applyContinuationContextIfNeeded()
        }
        .fullScreenCover(item: $annotationEditorSession) { session in
            AnnotationEditorView(
                image: session.image,
                thumbnail: session.thumbnail,
                initialAnnotations: session.annotations,
                baseCanvasSize: annotationCanvasSize,
                imageScale: imageScale,
                imageOffset: imageOffset
            ) { editedAnnotations in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    annotations = editedAnnotations
                    successMessage = nil
                }

                annotationEditorSession = nil
            }
        }
        .fullScreenCover(item: $activeImageAdjustment) { session in
            ImageAdjustmentView(session: session) { image, scale, offset in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    selectedImage = image
                    selectedMockThumbnail = nil
                    imageScale = scale
                    imageOffset = offset
                    if session.clearsAnnotationsOnConfirm {
                        clearAnnotations()
                    }
                    successMessage = nil
                }

                if session.exitsContinuationOnConfirm {
                    onClearContinuation()
                }
                activeImageAdjustment = nil
            } onCancel: {
                activeImageAdjustment = nil
            }
        }
        .sheet(isPresented: $isPresentingPromptPreview) {
            PromptPreviewSheet(preview: promptPreview)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var generateButton: some View {
        Button {
            generateMockVideo()
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }

                Text(isGenerating ? "Generating..." : "Generate Video")
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(generateButtonColor)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .shadow(color: hasRequiredInputs ? PannotateTheme.Colors.accent.opacity(0.32) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!hasRequiredInputs || isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .animation(.easeInOut(duration: 0.2), value: hasRequiredInputs)
    }

    private var hasRequiredInputs: Bool {
        currentProject != nil && hasCanvasSource && !motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasCanvasSource: Bool {
        selectedImage != nil || selectedMockThumbnail != nil
    }

    private var activeGenerationMode: GenerationMode {
        continuationContext == nil ? .newShot : .continueFromLastFrame
    }

    private var generateButtonColor: Color {
        if isGenerating {
            return PannotateTheme.Colors.accent.opacity(0.72)
        }

        return hasRequiredInputs ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText.opacity(0.52)
    }

    private func generateMockVideo() {
        guard currentProject != nil, hasCanvasSource else { return }

        let request = currentGenerationRequest
        let shouldClearContinuationAfterGeneration = continuationContext != nil
        successMessage = nil
        lastGeneratedInstruction = request.generatedInstruction
        lastGenerationRequest = request
        isGenerating = true

        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)

            await MainActor.run {
                let clip = GeneratedClip(
                    title: generatedClipTitle,
                    duration: "4s",
                    createdAt: "Just now",
                    status: .done,
                    thumbnail: selectedMockThumbnail ?? .city,
                    image: selectedImage,
                    generationRequestID: request.id,
                    generationRequestSummary: generationRequestSummary(for: request),
                    continuationSourceClipID: continuationContext?.id,
                    continuationSourceClipTitle: continuationContext?.title
                )

                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isGenerating = false
                    successMessage = "Mock clip generated"
                }

                onGeneratedClip(clip)
                if shouldClearContinuationAfterGeneration {
                    onClearContinuation()
                    selectedImage = nil
                    selectedMockThumbnail = nil
                    imageScale = 1
                    imageOffset = .zero
                    clearAnnotations()
                }
            }
        }
    }

    private var generatedClipTitle: String {
        if let continuationContext {
            return "\(continuationContext.title) - Continued"
        }

        let prompt = motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        if prompt.count <= 32 {
            return prompt.isEmpty ? "Studio Mock Clip" : prompt
        }

        return "\(prompt.prefix(32))..."
    }

    private var promptPreviewButton: some View {
        Button {
            isPresentingPromptPreview = true
        } label: {
            Label("Preview Request", systemImage: "doc.text.magnifyingglass")
                .font(.headline.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                        .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        imageSelectionMessage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        imageSelectionMessage = "Could not load that photo"
                    }
                    return
                }

                await MainActor.run {
                    activeImageAdjustment = ImageAdjustmentSession(image: image)
                }
            } catch {
                await MainActor.run {
                    imageSelectionMessage = "Photo selection was cancelled or unavailable"
                }
            }
        }
    }

    private var studioHeader: some View {
        HStack {
            Text("Studio")
                .font(.title2.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Spacer()

            Image(systemName: "ellipsis")
                .font(.title2.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .frame(height: 62)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private func continuationBanner(_ context: StudioContinuationContext) -> some View {
        HStack(spacing: 12) {
            Group {
                if let image = context.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    MockThumbnail(style: context.thumbnail, cornerRadius: 12)
                }
            }
            .frame(width: 58, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Continuing from")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(PannotateTheme.Colors.accent)

                Text(context.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                exitContinuationMode()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.accent.opacity(0.36), lineWidth: 1)
        )
    }

    private var canvas: some View {
        ZStack {
            if hasCanvasSource {
                annotatedImageCanvas()

                HStack(spacing: 10) {
                    if let selectedImage {
                        Button {
                            activeImageAdjustment = ImageAdjustmentSession(
                                image: selectedImage,
                                initialScale: imageScale,
                                initialOffset: imageOffset,
                                clearsAnnotationsOnConfirm: false,
                                exitsContinuationOnConfirm: false
                            )
                        } label: {
                            canvasOverlayLabel("Adjust", systemImage: "crop")
                        }
                        .buttonStyle(.plain)
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        canvasOverlayLabel("Change", systemImage: "photo")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(14)
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(PannotateTheme.Colors.accent)

                        Text("Select an Image")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(PannotateTheme.Colors.primaryText)

                        Text("Choose a photo to start guiding motion")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 224)
                    .background(PannotateTheme.cardGradient)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 224)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func annotatedImageCanvas() -> some View {
        GeometryReader { geometry in
            ZStack {
                canvasSourceView()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                annotationOverlay
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onAppear {
                annotationCanvasSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                annotationCanvasSize = newSize
            }
        }
    }

    @ViewBuilder
    private func canvasSourceView() -> some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .scaleEffect(imageScale)
                .offset(imageOffset)
                .clipped()
        } else if let selectedMockThumbnail {
            MockThumbnail(style: selectedMockThumbnail, cornerRadius: 0)
        }
    }

    private func canvasOverlayLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(Capsule())
    }

    private var annotationEntryPoint: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Annotations")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(annotationCountSummary)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                }

                Spacer()
            }

            Button {
                openAnnotationEditor()
            } label: {
                Label(hasCanvasSource ? "Edit Annotations" : "Select Image First", systemImage: "pencil.and.outline")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(hasCanvasSource ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(hasCanvasSource ? PannotateTheme.Colors.accent.opacity(0.42) : PannotateTheme.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!hasCanvasSource)
        }
        .padding(14)
        .background(PannotateTheme.Colors.cardMuted.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
    }

    private var annotationCountSummary: String {
        let strokeCount = annotations.compactMap(\.stroke).count
        let circleCount = annotations.compactMap(\.circle).count
        let textCount = annotations.compactMap(\.text).count

        if annotations.isEmpty {
            return "No annotations yet. Open the full-screen editor to draw, circle, label, or erase."
        }

        return "\(strokeCount) strokes · \(circleCount) circles · \(textCount) text labels"
    }

    private func openAnnotationEditor() {
        guard hasCanvasSource else { return }

        annotationEditorSession = AnnotationEditorSession(
            image: selectedImage,
            thumbnail: selectedMockThumbnail,
            annotations: annotations
        )
    }

    private var annotationOverlay: some View {
        AnnotationOverlayView(
            annotations: annotations,
            baseSize: annotationCanvasSize
        )
    }

    private func clearAnnotations() {
        annotations.removeAll()
    }

    private func applyContinuationContextIfNeeded() {
        guard let continuationContext else { return }

        selectedImage = continuationContext.image
        selectedMockThumbnail = continuationContext.image == nil ? continuationContext.thumbnail : nil
        imageScale = 1
        imageOffset = .zero
        annotations.removeAll()
        successMessage = nil
        imageSelectionMessage = nil
    }

    private func exitContinuationMode() {
        onClearContinuation()
        selectedImage = nil
        selectedMockThumbnail = nil
        imageScale = 1
        imageOffset = .zero
        annotations.removeAll()
        successMessage = nil
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private var promptPreview: StudioPromptPreview {
        StudioPromptPreview(request: currentGenerationRequest)
    }

    private var currentGenerationRequest: GenerationRequest {
        let trimmedPrompt = motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let strokes = annotations.compactMap(\.stroke)
        let circles = annotations.compactMap(\.circle)
        let texts = annotations.compactMap(\.text)
        let textDetails = texts.map { text in
            "\"\(text.text)\" near \(positionLabel(for: text.position))"
        }

        let annotationSummary = annotationSummaryText(
            strokeCount: strokes.count,
            circleCount: circles.count,
            textAnnotations: textDetails
        )

        let generatedInstruction = generatedInstructionText(
            prompt: trimmedPrompt,
            strokeCount: strokes.count,
            circleCount: circles.count,
            textAnnotations: textDetails
        )

        return GenerationRequest(
            projectID: currentProject?.id,
            projectName: currentProject?.title,
            sourceImageStatus: sourceImageStatus,
            sourceClipID: continuationContext?.id,
            sourceClipTitle: continuationContext?.title,
            motionPrompt: trimmedPrompt.isEmpty ? "No motion prompt yet" : trimmedPrompt,
            annotationSummary: annotationSummary,
            strokeCount: strokes.count,
            circleCount: circles.count,
            textAnnotations: textDetails,
            generationMode: activeGenerationMode,
            mockDuration: "4s",
            outputStyle: "Cinematic creator prototype",
            quality: "Mock preview quality",
            startsFromPreviousFrame: continuationContext != nil,
            generatedInstruction: generatedInstruction
        )
    }

    private func generationRequestSummary(for request: GenerationRequest) -> String {
        """
        Request \(request.id.uuidString.prefix(8)) · \(request.generationMode.title)
        Project: \(request.projectName ?? "No project")
        Source clip: \(request.sourceClipTitle ?? "None")
        Prompt: \(request.motionPrompt)
        Annotations: \(request.strokeCount) strokes, \(request.circleCount) circles, \(request.textAnnotations.count) text labels
        Duration: \(request.mockDuration) · Quality: \(request.quality)
        """
    }

    private var sourceImageStatus: String {
        if let continuationContext {
            return continuationContext.image == nil
                ? "Mock last frame from output clip \"\(continuationContext.title)\""
                : "Image from output clip \"\(continuationContext.title)\""
        }

        return selectedImage == nil ? "No image selected yet" : "Selected local Photos image"
    }

    private func annotationSummaryText(strokeCount: Int, circleCount: Int, textAnnotations: [String]) -> String {
        var lines = [
            "Freehand strokes: \(strokeCount)",
            "Circles / ellipses: \(circleCount)",
            "Text annotations: \(textAnnotations.count)"
        ]

        if textAnnotations.isEmpty == false {
            lines.append("Text content: \(textAnnotations.joined(separator: "; "))")
        }

        if strokeCount == 0 && circleCount == 0 && textAnnotations.isEmpty {
            lines.append("No annotations have been added yet.")
        }

        return lines.joined(separator: "\n")
    }

    private func generatedInstructionText(prompt: String, strokeCount: Int, circleCount: Int, textAnnotations: [String]) -> String {
        let promptText = prompt.isEmpty ? "No motion prompt has been provided yet." : "The user's motion prompt is: \"\(prompt)\"."
        let imageText = hasCanvasSource ? "The user selected an image and added visual annotations." : "The user has not selected an image yet."
        let modeText: String
        if let continuationContext {
            modeText = "This request should continue from the last frame of the output clip \"\(continuationContext.title)\" conceptually; no real last-frame extraction is available yet."
        } else {
            modeText = "This request should create a new shot."
        }
        let textAnnotationSentence = textAnnotations.isEmpty ? "" : " Text annotations include: \(textAnnotations.joined(separator: "; "))."

        return "\(imageText) \(modeText) Use the annotations to identify the intended subject and motion. \(promptText) There are \(circleCount) circles or ellipses, \(textAnnotations.count) text labels, and \(strokeCount) drawing strokes on the image.\(textAnnotationSentence) Treat these annotations as guidance for what should move, what should be emphasized, or which subject the future video generation model should follow."
    }

    private func positionLabel(for point: CGPoint) -> String {
        let horizontal: String
        let vertical: String
        let width = max(annotationCanvasSize.width, 1)
        let height = max(annotationCanvasSize.height, 1)

        switch point.x / width {
        case ..<0.34:
            horizontal = "left"
        case 0.34..<0.67:
            horizontal = "center"
        default:
            horizontal = "right"
        }

        switch point.y / height {
        case ..<0.34:
            vertical = "upper"
        case 0.34..<0.67:
            vertical = "middle"
        default:
            vertical = "lower"
        }

        if horizontal == "center" && vertical == "middle" {
            return "center"
        }

        if horizontal == "center" {
            return "\(vertical)-center"
        }

        if vertical == "middle" {
            return "center-\(horizontal)"
        }

        return "\(vertical)-\(horizontal)"
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), size.width),
            y: min(max(point.y, 0), size.height)
        )
    }
}

private struct AnnotationEditorSession: Identifiable {
    let id = UUID()
    let image: UIImage?
    let thumbnail: ThumbnailStyle?
    let annotations: [StudioAnnotation]
}

private struct AnnotationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTool = "Pan"
    @State private var draftAnnotations: [StudioAnnotation]
    @State private var activeStroke: AnnotationStroke?
    @State private var activeCircle: AnnotationCircle?
    @State private var activeTextDragID: UUID?
    @State private var activeTextDragStartPosition: CGPoint?
    @State private var pendingTextPosition: CGPoint?
    @State private var isPresentingTextAnnotation = false

    let image: UIImage?
    let thumbnail: ThumbnailStyle?
    let baseCanvasSize: CGSize
    let imageScale: CGFloat
    let imageOffset: CGSize
    let onDone: ([StudioAnnotation]) -> Void

    private let tools = [
        ("Pan", "hand.draw"),
        ("Draw", "pencil.tip"),
        ("Circle", "circle"),
        ("Text", "textformat"),
        ("Eraser", "eraser")
    ]

    init(
        image: UIImage?,
        thumbnail: ThumbnailStyle?,
        initialAnnotations: [StudioAnnotation],
        baseCanvasSize: CGSize,
        imageScale: CGFloat,
        imageOffset: CGSize,
        onDone: @escaping ([StudioAnnotation]) -> Void
    ) {
        self.image = image
        self.thumbnail = thumbnail
        self.baseCanvasSize = baseCanvasSize
        self.imageScale = imageScale
        self.imageOffset = imageOffset
        self.onDone = onDone
        _draftAnnotations = State(initialValue: initialAnnotations)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                editorCanvas

                toolControls

                Text(selectedToolHint)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Annotation Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(draftAnnotations)
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $isPresentingTextAnnotation) {
            ManagementRenameSheet(title: "Add Text", placeholder: "Annotation text", initialName: "") { text in
                addTextAnnotation(text)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var editorCanvas: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let maxHeight = max(proxy.size.height, 320)
            let aspectRatio = canvasAspectRatio
            let canvasHeight = min(max(width / aspectRatio, 320), maxHeight)

            VStack {
                ZStack {
                    editorSourceView(displaySize: CGSize(width: width, height: canvasHeight))
                        .frame(width: width, height: canvasHeight)

                    AnnotationOverlayView(
                        annotations: draftAnnotations,
                        baseSize: baseCanvasSize,
                        activeStroke: activeStroke,
                        activeCircle: activeCircle
                    )
                    .frame(width: width, height: canvasHeight)
                    .allowsHitTesting(false)
                }
                .frame(width: width, height: canvasHeight)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .contentShape(Rectangle())
                .gesture(annotationGesture(in: CGSize(width: width, height: canvasHeight)))
                .overlay(alignment: .topLeading) {
                    Label(selectedTool, systemImage: selectedToolIcon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial.opacity(0.72))
                        .clipShape(Capsule())
                        .padding(14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
        }
    }

    private var toolControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(tools, id: \.0) { tool in
                    let isSelected = selectedTool == tool.0

                    Button {
                        selectedTool = tool.0
                        finishTextDrag()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tool.1)
                                .font(.headline.weight(.bold))

                            Text(tool.0)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.72) : PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? PannotateTheme.Colors.accent.opacity(0.8) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Button {
                    undoLastAnnotation()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(canUndoAnnotations ? PannotateTheme.Colors.secondaryText : PannotateTheme.Colors.tertiaryText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canUndoAnnotations)

                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        clearAnnotations()
                    }
                } label: {
                    Label("Clear", systemImage: "eraser")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(canUndoAnnotations ? .red : PannotateTheme.Colors.tertiaryText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canUndoAnnotations)
            }
        }
    }

    private var canUndoAnnotations: Bool {
        draftAnnotations.isEmpty == false || activeStroke != nil || activeCircle != nil
    }

    private var selectedToolIcon: String {
        tools.first(where: { $0.0 == selectedTool })?.1 ?? "hand.draw"
    }

    private var canvasAspectRatio: CGFloat {
        if let image {
            return max(image.size.width / max(image.size.height, 1), 0.62)
        }

        return 16 / 9
    }

    @ViewBuilder
    private func editorSourceView(displaySize: CGSize) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(imageScale)
                .offset(scaledImageOffset(for: displaySize))
                .clipped()
        } else if let thumbnail {
            MockThumbnail(style: thumbnail, cornerRadius: 0)
        }
    }

    private var selectedToolHint: String {
        switch selectedTool {
        case "Draw":
            return "Drag on the image to sketch guidance strokes."
        case "Circle":
            return "Drag to draw an ellipse around the subject or area to emphasize."
        case "Text":
            return "Tap to add a label, or drag an existing label to reposition it."
        case "Eraser":
            return "Tap or drag over an annotation to remove it."
        default:
            return "Pan is a safe mode. Existing text labels can still be repositioned."
        }
    }

    private func scaledImageOffset(for displaySize: CGSize) -> CGSize {
        CGSize(
            width: imageOffset.width * displaySize.width / max(baseCanvasSize.width, 1),
            height: imageOffset.height * displaySize.height / max(baseCanvasSize.height, 1)
        )
    }

    private func annotationGesture(in displaySize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: selectedTool == "Text" || selectedTool == "Eraser" ? 0 : 2)
            .onChanged { value in
                let start = basePoint(for: value.startLocation, in: displaySize)
                let current = basePoint(for: value.location, in: displaySize)

                switch selectedTool {
                case "Draw":
                    updateActiveStroke(with: current)
                case "Circle":
                    updateActiveCircle(start: start, current: current)
                case "Pan", "Text":
                    updateTextDrag(start: start, current: current)
                case "Eraser":
                    eraseAnnotation(near: current)
                default:
                    break
                }
            }
            .onEnded { value in
                let start = basePoint(for: value.startLocation, in: displaySize)
                let current = basePoint(for: value.location, in: displaySize)

                switch selectedTool {
                case "Draw":
                    commitActiveStroke()
                case "Circle":
                    commitActiveCircle()
                case "Text":
                    if activeTextDragID != nil {
                        finishTextDrag()
                    } else if distance(from: start, to: current) < 8 {
                        pendingTextPosition = current
                        isPresentingTextAnnotation = true
                    }
                case "Pan":
                    finishTextDrag()
                case "Eraser":
                    eraseAnnotation(near: current)
                default:
                    break
                }
            }
    }

    private func updateActiveStroke(with point: CGPoint) {
        if activeStroke == nil {
            activeStroke = AnnotationStroke(points: [point])
        } else {
            activeStroke?.points.append(point)
        }
    }

    private func commitActiveStroke() {
        guard let activeStroke, activeStroke.points.count > 1 else {
            activeStroke = nil
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            draftAnnotations.append(.stroke(activeStroke))
        }
        self.activeStroke = nil
    }

    private func updateActiveCircle(start: CGPoint, current: CGPoint) {
        activeCircle = AnnotationCircle(rect: CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        ))
    }

    private func commitActiveCircle() {
        guard let activeCircle, activeCircle.rect.width > 8, activeCircle.rect.height > 8 else {
            activeCircle = nil
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            draftAnnotations.append(.circle(activeCircle))
        }
        self.activeCircle = nil
    }

    private func addTextAnnotation(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false, let pendingTextPosition else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            draftAnnotations.append(.text(AnnotationText(text: trimmedText, position: pendingTextPosition)))
        }

        self.pendingTextPosition = nil
    }

    private func updateTextDrag(start: CGPoint, current: CGPoint) {
        if activeTextDragID == nil {
            guard let hit = hitTextAnnotation(at: start) else { return }
            activeTextDragID = hit.id
            activeTextDragStartPosition = hit.position
        }

        guard let activeTextDragID,
              let activeTextDragStartPosition,
              let index = draftAnnotations.firstIndex(where: { $0.id == activeTextDragID }) else { return }

        let translation = CGSize(width: current.x - start.x, height: current.y - start.y)
        let proposedPosition = CGPoint(
            x: activeTextDragStartPosition.x + translation.width,
            y: activeTextDragStartPosition.y + translation.height
        )

        if case .text(let text) = draftAnnotations[index] {
            draftAnnotations[index] = .text(AnnotationText(
                id: text.id,
                text: text.text,
                position: clampedPoint(proposedPosition)
            ))
        }
    }

    private func finishTextDrag() {
        activeTextDragID = nil
        activeTextDragStartPosition = nil
    }

    private func eraseAnnotation(near point: CGPoint) {
        guard let index = draftAnnotations.lastIndex(where: { annotationHits($0, at: point) }) else { return }

        withAnimation(.easeInOut(duration: 0.12)) {
            _ = draftAnnotations.remove(at: index)
        }
    }

    private func undoLastAnnotation() {
        withAnimation(.easeInOut(duration: 0.18)) {
            if activeStroke != nil {
                activeStroke = nil
            } else if activeCircle != nil {
                activeCircle = nil
            } else if draftAnnotations.isEmpty == false {
                draftAnnotations.removeLast()
            }
        }
    }

    private func clearAnnotations() {
        draftAnnotations.removeAll()
        activeStroke = nil
        activeCircle = nil
        finishTextDrag()
        pendingTextPosition = nil
    }

    private func hitTextAnnotation(at point: CGPoint) -> AnnotationText? {
        draftAnnotations.compactMap(\.text).last { text in
            textHitRect(for: text).contains(point)
        }
    }

    private func annotationHits(_ annotation: StudioAnnotation, at point: CGPoint) -> Bool {
        let hitRadius: CGFloat = 24

        switch annotation {
        case .stroke(let stroke):
            return stroke.points.contains { distance(from: $0, to: point) <= hitRadius }
        case .circle(let circle):
            return circle.rect.insetBy(dx: -hitRadius, dy: -hitRadius).contains(point)
        case .text(let text):
            return textHitRect(for: text).insetBy(dx: -hitRadius, dy: -hitRadius).contains(point)
        }
    }

    private func textHitRect(for text: AnnotationText) -> CGRect {
        let width = max(CGFloat(text.text.count) * 9 + 28, 72)
        let height: CGFloat = 42

        return CGRect(
            x: text.position.x - width / 2,
            y: text.position.y - height / 2,
            width: width,
            height: height
        )
    }

    private func basePoint(for displayPoint: CGPoint, in displaySize: CGSize) -> CGPoint {
        clampedPoint(CGPoint(
            x: displayPoint.x * max(baseCanvasSize.width, 1) / max(displaySize.width, 1),
            y: displayPoint.y * max(baseCanvasSize.height, 1) / max(displaySize.height, 1)
        ))
    }

    private func clampedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), max(baseCanvasSize.width, 1)),
            y: min(max(point.y, 0), max(baseCanvasSize.height, 1))
        )
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}

private struct AnnotationOverlayView: View {
    let annotations: [StudioAnnotation]
    let baseSize: CGSize
    var activeStroke: AnnotationStroke?
    var activeCircle: AnnotationCircle?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(annotations) { annotation in
                    annotationView(annotation, displaySize: geometry.size)
                }

                if let activeStroke {
                    strokeView(activeStroke, displaySize: geometry.size)
                }

                if let activeCircle {
                    circleView(activeCircle, displaySize: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    @ViewBuilder
    private func annotationView(_ annotation: StudioAnnotation, displaySize: CGSize) -> some View {
        switch annotation {
        case .stroke(let stroke):
            strokeView(stroke, displaySize: displaySize)
        case .circle(let circle):
            circleView(circle, displaySize: displaySize)
        case .text(let text):
            textView(text, displaySize: displaySize)
        }
    }

    private func strokeView(_ stroke: AnnotationStroke, displaySize: CGSize) -> some View {
        Path { path in
            guard let firstPoint = stroke.points.first else { return }

            path.move(to: displayPoint(for: firstPoint, in: displaySize))

            for point in stroke.points.dropFirst() {
                path.addLine(to: displayPoint(for: point, in: displaySize))
            }
        }
        .stroke(PannotateTheme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func circleView(_ circle: AnnotationCircle, displaySize: CGSize) -> some View {
        let rect = displayRect(for: circle.rect, in: displaySize)

        return Ellipse()
            .stroke(PannotateTheme.Colors.accent, lineWidth: 4)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func textView(_ text: AnnotationText, displaySize: CGSize) -> some View {
        Text(text.text)
            .font(.headline.weight(.heavy))
            .foregroundStyle(PannotateTheme.Colors.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(PannotateTheme.Colors.accent.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .position(displayPoint(for: text.position, in: displaySize))
    }

    private func displayPoint(for point: CGPoint, in displaySize: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * displaySize.width / max(baseSize.width, 1),
            y: point.y * displaySize.height / max(baseSize.height, 1)
        )
    }

    private func displayRect(for rect: CGRect, in displaySize: CGSize) -> CGRect {
        CGRect(
            x: rect.minX * displaySize.width / max(baseSize.width, 1),
            y: rect.minY * displaySize.height / max(baseSize.height, 1),
            width: rect.width * displaySize.width / max(baseSize.width, 1),
            height: rect.height * displaySize.height / max(baseSize.height, 1)
        )
    }
}

private struct ImageAdjustmentSession: Identifiable {
    let id = UUID()
    let image: UIImage
    var initialScale: CGFloat = 1
    var initialOffset: CGSize = .zero
    var clearsAnnotationsOnConfirm = true
    var exitsContinuationOnConfirm = true
}

private struct AnnotationStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
}

private struct AnnotationCircle: Identifiable {
    let id = UUID()
    var rect: CGRect
}

private struct AnnotationText: Identifiable {
    let id: UUID
    var text: String
    var position: CGPoint

    init(id: UUID = UUID(), text: String, position: CGPoint) {
        self.id = id
        self.text = text
        self.position = position
    }
}

private enum StudioAnnotation: Identifiable {
    case stroke(AnnotationStroke)
    case circle(AnnotationCircle)
    case text(AnnotationText)

    var id: UUID {
        switch self {
        case .stroke(let stroke):
            stroke.id
        case .circle(let circle):
            circle.id
        case .text(let text):
            text.id
        }
    }

    var stroke: AnnotationStroke? {
        if case .stroke(let stroke) = self {
            return stroke
        }

        return nil
    }

    var circle: AnnotationCircle? {
        if case .circle(let circle) = self {
            return circle
        }

        return nil
    }

    var text: AnnotationText? {
        if case .text(let text) = self {
            return text
        }

        return nil
    }
}

private struct StudioPromptPreview {
    let request: GenerationRequest

    var humanSummary: String {
        """
        Request \(request.id.uuidString.prefix(8)) will create a \(request.mockDuration) mock clip in \(request.generationMode.title) mode for \(request.projectName ?? "the current project"). It uses \(request.sourceImageStatus.lowercased()), \(request.strokeCount) strokes, \(request.circleCount) circles, and \(request.textAnnotations.count) text labels as local guidance.
        """
    }

    var structuredFields: String {
        """
        Request ID: \(request.id.uuidString)
        Created: \(request.createdAt.formatted(date: .abbreviated, time: .shortened))
        Project: \(request.projectName ?? "No project")\(request.projectID.map { " (\($0.uuidString))" } ?? "")
        Source image: \(request.sourceImageStatus)
        Source clip: \(request.sourceClipTitle ?? "None")\(request.sourceClipID.map { " (\($0.uuidString))" } ?? "")
        Mode: \(request.generationMode.title) (\(request.generationMode.requestValue))
        Continuation: \(request.startsFromPreviousFrame ? "Yes" : "No")
        Mock duration: \(request.mockDuration)
        Output style: \(request.outputStyle)
        Quality: \(request.quality)
        Motion prompt: \(request.motionPrompt)
        Text annotations: \(request.textAnnotations.isEmpty ? "None" : request.textAnnotations.joined(separator: "; "))
        """
    }

    var jsonPreview: String {
        let textValues = request.textAnnotations
            .map { "\"\(jsonEscaped($0))\"" }
            .joined(separator: ", ")

        return """
        {
          "requestId": "\(request.id.uuidString)",
          "project": {
            "id": "\(request.projectID?.uuidString ?? "none")",
            "name": "\(jsonEscaped(request.projectName ?? "No project"))"
          },
          "mode": "\(request.generationMode.requestValue)",
          "sourceImage": "\(jsonEscaped(request.sourceImageStatus))",
          "sourceClip": {
            "id": "\(request.sourceClipID?.uuidString ?? "none")",
            "title": "\(jsonEscaped(request.sourceClipTitle ?? "None"))"
          },
          "motionPrompt": "\(jsonEscaped(request.motionPrompt))",
          "annotationSummary": "\(jsonEscaped(request.annotationSummary))",
          "annotations": {
            "strokes": \(request.strokeCount),
            "circles": \(request.circleCount),
            "texts": [\(textValues)]
          },
          "duration": "\(request.mockDuration)",
          "outputStyle": "\(jsonEscaped(request.outputStyle))",
          "quality": "\(jsonEscaped(request.quality))",
          "continueFromLastFrame": \(request.startsFromPreviousFrame ? "true" : "false")
        }
        """
    }

    private func jsonEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

private struct PromptPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preview: StudioPromptPreview

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    previewSection(title: "Summary", text: preview.humanSummary)
                    previewSection(title: "Structured Fields", text: preview.structuredFields)
                    previewSection(title: "Annotation Summary", text: preview.request.annotationSummary)
                    previewSection(title: "Generated AI Instruction", text: preview.request.generatedInstruction)
                    previewSection(title: "JSON-Style Preview", text: preview.jsonPreview, monospaced: true)
                }
                .padding(PannotateTheme.Metrics.pagePadding)
            }
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Request Preview")
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

    private func previewSection(title: String, text: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            Text(text)
                .font(monospaced ? .system(.footnote, design: .monospaced).weight(.semibold) : .body.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }
}

private struct ImageAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    let session: ImageAdjustmentSession
    let onConfirm: (UIImage, CGFloat, CGSize) -> Void
    let onCancel: () -> Void

    @State private var imageScale: CGFloat
    @State private var lastImageScale: CGFloat
    @State private var imageOffset: CGSize
    @State private var lastImageOffset: CGSize

    init(
        session: ImageAdjustmentSession,
        onConfirm: @escaping (UIImage, CGFloat, CGSize) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.session = session
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _imageScale = State(initialValue: session.initialScale)
        _lastImageScale = State(initialValue: session.initialScale)
        _imageOffset = State(initialValue: session.initialOffset)
        _lastImageOffset = State(initialValue: session.initialOffset)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Text("Frame the image before annotating. This is a local prototype adjustment only.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

                adjustmentCanvas
                    .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

                Label("Drag to reposition. Pinch to zoom.", systemImage: "hand.draw")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                Spacer()

                PrimaryActionButton(title: "Use This Framing", systemImage: "checkmark") {
                    onConfirm(session.image, imageScale, imageOffset)
                    dismiss()
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.bottom, 18)
            }
            .padding(.top, 20)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Adjust Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            imageScale = 1
                            lastImageScale = 1
                            imageOffset = .zero
                            lastImageOffset = .zero
                        }
                    }
                }
            }
        }
    }

    private var adjustmentCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                Image(uiImage: session.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(imageAdjustmentGesture(in: geometry.size))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func imageAdjustmentGesture(in canvasSize: CGSize) -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let proposedOffset = CGSize(
                        width: lastImageOffset.width + value.translation.width,
                        height: lastImageOffset.height + value.translation.height
                    )

                    imageOffset = clampedOffset(proposedOffset, canvasSize: canvasSize, scale: imageScale)
                }
                .onEnded { _ in
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                    lastImageOffset = imageOffset
                },
            MagnificationGesture()
                .onChanged { value in
                    imageScale = clampedScale(lastImageScale * value)
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                }
                .onEnded { _ in
                    imageScale = clampedScale(imageScale)
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                    lastImageScale = imageScale
                    lastImageOffset = imageOffset
                }
        )
    }

    private func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, 1), 4)
    }

    private func clampedOffset(_ offset: CGSize, canvasSize: CGSize, scale: CGFloat) -> CGSize {
        let maxX = canvasSize.width * max(scale - 1, 0) / 2
        let maxY = canvasSize.height * max(scale - 1, 0) / 2

        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

#Preview {
    StudioView(currentProject: MockPannotateData.projects.first)
}
